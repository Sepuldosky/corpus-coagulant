-- corpus_coagulant_config.lua — convars + tablas de balance + funciones puras (SHARED)
-- Coagulant_Architecture.md §3-§5, §11. Los números viven acá como data: se tunean
-- editando este archivo o por convar, sin tocar lógica. Todo lo de este archivo es
-- puro (sin hooks, sin estado de jugador).

local COAGULANT = Corpus.GetModule("coagulant")

COAGULANT.Config = COAGULANT.Config or {}
local Config = COAGULANT.Config

-- ============================================================
-- Convars (§11). Replicadas para que el cliente (HUD, slice 4) lea los mismos
-- valores sin net propio.
-- ============================================================
local FLAGS = { FCVAR_ARCHIVE, FCVAR_REPLICATED }
Config.cv_enabled       = CreateConVar("coagulant_enabled", "1", FLAGS, "Enables/disables the whole Coagulant system")
Config.cv_bleed_scale   = CreateConVar("coagulant_bleed_scale", "1.0", FLAGS, "Global blood drain multiplier")
Config.cv_regen_scale   = CreateConVar("coagulant_regen_scale", "1.0", FLAGS, "Natural blood regeneration multiplier")
Config.cv_hpdrain_scale = CreateConVar("coagulant_hpdrain_scale", "1.0", FLAGS, "HP drain multiplier while blood is critical")
Config.cv_debug         = CreateConVar("coagulant_debug", "0", FLAGS, "Logs wounds/critical transitions to console")

function Config.Enabled()
    return Config.cv_enabled:GetBool()
end

-- ============================================================
-- Balance (§2-§5) — propuesta inicial ratificada como tunable
-- ============================================================
Config.BLOOD_MAX      = 100
Config.BLOOD_CRITICAL = 40    -- por debajo: drenaje de HP (§5)
Config.REGEN_PER_S    = 0.10  -- unidades/s sin sangrado activo (~17 min 0→100)
Config.HP_DRAIN_BASE  = 1     -- HP/s al entrar en crítico...
Config.HP_DRAIN_EXTRA = 4     -- ...+ escala lineal hasta +4 con sangre 0

Config.SEVERITY_MEDIUM_AT = 15  -- daño final >= 15 → severidad 2
Config.SEVERITY_GRAVE_AT  = 40  -- daño final  > 40 → severidad 3
Config.MAX_WOUNDS_PER_ZONE = 5  -- al exceder: se agrava la más leve (§3)

-- Drenaje base por severidad (unidades de sangre/s), × mult del tipo
Config.BLEED_BASE = { [1] = 0.15, [2] = 0.40, [3] = 1.00 }

-- Tipos de herida (§3). label es de cara al jugador (idioma del mod: inglés).
Config.WOUND_TYPES = {
    bala      = { mult = 1.0, label = "Gunshot wound" },
    corte     = { mult = 0.8, label = "Laceration" },
    metralla  = { mult = 0.9, label = "Shrapnel wound" },
    quemadura = { mult = 0.2, label = "Burn" },
    contusion = { mult = 0.0, label = "Bruise" },
}

-- ============================================================
-- Tratamiento (§7) — tiempos en segundos, efectos por tipo
-- ============================================================
Config.TREATMENTS = {
    bandage    = { time = 4,  item = "corpus_coagulant_bandage" },
    tourniquet = { time = 2,  item = "corpus_coagulant_tourniquet" }, -- aplicar Y quitar
    medkit     = { time = 10, item = "corpus_coagulant_medkit", heal = 50 },
    bloodbag   = { time = 8,  item = "corpus_coagulant_bloodbag", blood = 40 },
}
Config.ARM_TIME_MULT       = 1.25 -- brazo herido: tratamientos más lentos (§6)
Config.TOURNIQUET_ISCHEMIA_S = 90 -- puesto más de esto: isquemia (§7)
Config.ISCHEMIA_LINGER_S   = 60   -- la isquemia persiste tras quitarlo
Config.ISCHEMIA_SCORE      = 6    -- score de debuff que impone la isquemia
Config.DEGRADED_COOLDOWN_S = 30   -- sin Cargo: tratamiento gratis con cooldown (§7)
Config.CANCEL_SPEED_MULT   = 1.15 -- cancelar si velocidad > walk × esto

Config.EXTREMITIES = {
    left_arm = true, right_arm = true, left_leg = true, right_leg = true,
}

-- ============================================================
-- Funciones puras
-- ============================================================

-- Damage types que NO crean herida (no son trauma localizable, §3)
local DMG_IGNORAR = bit.bor(DMG_DROWN, DMG_POISON, DMG_NERVEGAS, DMG_RADIATION)
local DMG_BALA    = bit.bor(DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER, DMG_AIRBOAT)
local DMG_QUEMA   = bit.bor(DMG_BURN, DMG_SLOWBURN, DMG_ENERGYBEAM, DMG_SHOCK, DMG_PLASMA)
local DMG_GOLPE   = bit.bor(DMG_FALL, DMG_CRUSH, DMG_CLUB)

-- Resuelve el bitfield de damage type a tipo de herida, o nil si no corresponde
-- herida. El orden de chequeo es la prioridad de la tabla de §3 (un evento puede
-- combinar bits: bala incendiaria = BULLET|BURN → gana bala).
function Config.WoundTypeFromDMG(dmgtype)
    if bit.band(dmgtype, DMG_IGNORAR) ~= 0 then return nil end
    if bit.band(dmgtype, DMG_BALA) ~= 0 then return "bala" end
    if bit.band(dmgtype, DMG_BLAST) ~= 0 then return "metralla" end
    if bit.band(dmgtype, DMG_SLASH) ~= 0 then return "corte" end
    if bit.band(dmgtype, DMG_QUEMA) ~= 0 then return "quemadura" end
    if bit.band(dmgtype, DMG_GOLPE) ~= 0 then return "contusion" end
    return "contusion" -- default conservador (§3)
end

-- Severidad 1-3 según daño FINAL del evento (post-mitigación, §3)
function Config.SeverityFromDamage(dmg)
    if dmg > Config.SEVERITY_GRAVE_AT then return 3 end
    if dmg >= Config.SEVERITY_MEDIUM_AT then return 2 end
    return 1
end

-- Drenaje de una herida en unidades de sangre/s (0 si está tratada, §4)
function Config.BleedRate(wound)
    if wound.treated then return 0 end
    local tipo = Config.WOUND_TYPES[wound.type]
    if tipo == nil then return 0 end
    return Config.BLEED_BASE[wound.severity] * tipo.mult
end

-- Drenaje de HP por segundo dada la sangre actual (0 si no es crítica, §5)
function Config.HPDrainRate(blood)
    if blood >= Config.BLOOD_CRITICAL then return 0 end
    local falta = (Config.BLOOD_CRITICAL - blood) / Config.BLOOD_CRITICAL
    return Config.HP_DRAIN_BASE + Config.HP_DRAIN_EXTRA * falta
end

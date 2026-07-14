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

-- Debuffs zonales (§6, §11). REPLICADAS por necesidad, no por comodidad: la
-- cojera se aplica en un hook Move PREDICHO (ambos realms) — si el cliente
-- leyera un valor distinto al del server, el jugador haría rubber-band.
Config.cv_debuff_legs = CreateConVar("coagulant_debuff_legs", "1", FLAGS, "Leg wounds slow you down (limp)")
Config.cv_debuff_arms = CreateConVar("coagulant_debuff_arms", "1", FLAGS, "Arm wounds sway your aim")
Config.cv_debuff_head = CreateConVar("coagulant_debuff_head", "1", FLAGS, "Head wounds blur and darken your vision")

-- Convar de CLIENTE (§11): apaga la silueta del HUD. El vignette de sangre crítica
-- NO cuelga de acá a propósito — es información vital, no decoración (§11).
if CLIENT then
    Config.cv_hud = CreateClientConVar("coagulant_hud", "1", true, false,
        "Show the wound silhouette HUD (the critical-blood overlay is never hidden)")
end

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
-- El Medkit es la ÚNICA cura de la secuela (§7, decisión del autor 2026-07-14): una
-- herida vendada deja de sangrar pero su score sigue pesando a la mitad para siempre
-- — el Medkit cierra las heridas ya TRATADAS de una zona. Las no tratadas no: hay
-- que vendarlas primero.
Config.TREATMENTS = {
    bandage    = { time = 4,  item = "corpus_coagulant_bandage" },
    tourniquet = { time = 2,  item = "corpus_coagulant_tourniquet" }, -- aplicar Y quitar
    medkit     = { time = 10, item = "corpus_coagulant_medkit", heal = 50, healsWounds = true },
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
-- Debuffs zonales (§6) — score de zona = Σ severidades (tratadas cuentan la mitad)
-- ============================================================
Config.LIMP_PER_SCORE  = 0.12  -- cada punto de score de pierna quita 12 % de velocidad
Config.LIMP_MIN_MULT   = 0.45  -- piso: cojo, nunca inmóvil
Config.LIMP_SPEED_FLOOR = 30   -- piso ABSOLUTO en el Move hook (mismo que el movecompat
                               -- de Cargo): componiendo dos multiplicadores, el producto
                               -- podría dejar al jugador clavado
-- Sway (§6, reescrito el 2026-07-14 tras la ronda 5): el ViewPunch periódico se
-- sentía débil y llegaba estando idle. Ahora es una DERIVA CONTINUA en dos capas
-- (temblor sutil con el arma en mano; deriva fuerte al apuntar), sobre todo
-- horizontal, estilo ARMA 3 — pedido del autor.
--
-- Tuning de la ronda 6 (pedido del autor: "un poco más de sway en ambos casos, y es
-- medio tosco: pasa muy fuerte al apuntar, hacé una curva para pasar de un estado al
-- otro"). Dos cambios: sube la amplitud de las dos capas, y el salto entre ellas deja
-- de ser instantáneo — las capas ya no son un if, son los extremos de una rampa.
Config.SWAY_PER_SCORE  = 0.45  -- grados de amplitud base por punto de score de brazo
Config.SWAY_IDLE_MULT  = 0.60  -- capa 1: arma en mano, sin apuntar (perceptible, no ciego)
Config.SWAY_ADS_MULT   = 4.5   -- capa 2: apuntando (incapacitante — el número a tunear)
Config.SWAY_ADS_RAMP_S = 0.45  -- segundos de la transición idle↔ADS (el "tosco" de la ronda 6)
Config.SWAY_VERTICAL   = 0.30  -- el cabeceo es una fracción del bamboleo: deriva HORIZONTAL

Config.VISION_FULL_AT  = 6     -- score de cabeza donde el oscurecimiento satura
Config.BLACKOUT_S      = 2     -- fade a negro al recibir una herida de cabeza...
Config.BLACKOUT_MIN_SEVERITY = 2 -- ...media o grave (§6: es visual, sin pérdida de control)
Config.PULSE_HZ        = 1.1   -- latido del vignette de sangre crítica (ciclos/s)

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

-- --- Debuffs (§6): puras, sin estado — el server las usa para publicar, el
-- --- cliente las usa para pintar. Misma fórmula en ambos realms.

-- Multiplicador de velocidad por heridas de pierna (score = suma de AMBAS piernas)
function Config.LimpMult(scorePiernas)
    return math.max(Config.LIMP_MIN_MULT, 1 - Config.LIMP_PER_SCORE * scorePiernas)
end

-- Amplitud base de la deriva en grados por heridas de brazo (score = ambos brazos)
function Config.SwayAmplitude(scoreBrazos)
    return Config.SWAY_PER_SCORE * scoreBrazos
end

-- Suavizado de la transición entre capas (smoothstep): sale y entra despacio, así el
-- cambio no se siente como un tirón. Es la "curva" que pidió el autor en la ronda 6 —
-- antes las dos capas eran un if, y pasar de no-apuntar a apuntar era un escalón.
function Config.SwayEase(t)
    t = math.Clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

-- Amplitud EFECTIVA según cuánto se esté apuntando (§6). `ads` es un factor CONTINUO
-- 0..1 (0 = arma en mano, 1 = apuntando del todo): el cliente lo rampa en el tiempo,
-- las capas son sus extremos. Acepta un booleano por comodidad del selftest/status.
function Config.SwayFor(scoreBrazos, ads)
    if ads == true then ads = 1 end
    if type(ads) ~= "number" then ads = 0 end

    local t = Config.SwayEase(ads)
    local mult = Config.SWAY_IDLE_MULT + (Config.SWAY_ADS_MULT - Config.SWAY_IDLE_MULT) * t
    return Config.SwayAmplitude(scoreBrazos) * mult
end

-- Offset de la deriva en el instante t (grados: bamboleo, cabeceo). Dos senos de
-- períodos inconmensurables: nunca repite un patrón legible, así que no se puede
-- "aprender" a compensar. Pura: el cliente la usa para mover la mira y el selftest
-- para verificarla.
function Config.SwayOffset(t, amp)
    local yaw = (math.sin(t * 1.13) * 0.7 + math.sin(t * 0.37) * 0.3) * amp
    local pitch = math.sin(t * 0.83) * amp * Config.SWAY_VERTICAL
    return yaw, pitch
end

-- Intensidad 0..1 del oscurecimiento de visión por heridas de cabeza
function Config.VisionIntensity(scoreCabeza)
    return math.Clamp(scoreCabeza / Config.VISION_FULL_AT, 0, 1)
end

-- Intensidad 0..1 de la capa visual de sangre crítica (§5-§6): 0 sobre el umbral,
-- 1 con sangre 0. Es información vital: no se apaga por convar (§11).
function Config.CriticalIntensity(blood)
    if blood >= Config.BLOOD_CRITICAL then return 0 end
    return math.Clamp((Config.BLOOD_CRITICAL - blood) / Config.BLOOD_CRITICAL, 0, 1)
end

-- --- UI (§10): puras, para que el HUD y el menú médico pinten LO MISMO. La silueta
-- --- se dibuja dos veces (chica en el HUD, grande y clickeable en el menú) y las dos
-- --- veces sale de esta tabla: una sola verdad sobre dónde está cada zona.

-- El snapshot viaja comprimido, así que sus claves son de una letra ({t,s,tr}) — las
-- funciones de balance esperan la herida entera ({type,severity,treated}). Traducir
-- acá y no en cada llamador: si el snapshot cambia de forma, cambia un solo lugar.
function Config.WoundFromSnap(w)
    return { type = w.t, severity = w.s, treated = w.tr }
end

-- Score de zona → 0..1 para colorear (sano → amarillo → rojo). Satura en ZONE_FULL_AT:
-- de ahí para arriba la zona ya está tan roja como puede.
Config.ZONE_FULL_AT = 6
function Config.ZoneDamageFrac(score)
    return math.Clamp(score / Config.ZONE_FULL_AT, 0, 1)
end

-- Progreso 0..1 del tratamiento en curso, desde el {endsAt, duration} del snapshot
-- (§9: la barra se calcula client-side, sin tick de red). `now` se pasa para que sea
-- pura y el selftest la pueda ejercitar.
function Config.TreatmentProgress(tr, now)
    if tr == nil or not tr.duration or tr.duration <= 0 then return 0 end
    return math.Clamp(1 - (tr.endsAt - now) / tr.duration, 0, 1)
end

-- Silueta de 6 zonas en coordenadas normalizadas 0..1 dentro de su caja (§10). Se ve
-- desde la perspectiva del jugador (su brazo izquierdo, a la izquierda del dibujo):
-- la alternativa —espejarla como un espejo— confunde al vendar bajo presión.
Config.SILHOUETTE = {
    { zone = "head",      x = 0.37, y = 0.00, w = 0.26, h = 0.16 },
    { zone = "torso",     x = 0.32, y = 0.18, w = 0.36, h = 0.37 },
    { zone = "left_arm",  x = 0.10, y = 0.19, w = 0.19, h = 0.36 },
    { zone = "right_arm", x = 0.71, y = 0.19, w = 0.19, h = 0.36 },
    { zone = "left_leg",  x = 0.33, y = 0.57, w = 0.16, h = 0.43 },
    { zone = "right_leg", x = 0.51, y = 0.57, w = 0.16, h = 0.43 },
}

-- Zona bajo un punto (x,y ya normalizados a la caja de la silueta), o nil. La usa el
-- menú médico para el clic; vive acá porque el rectángulo que se pinta y el que se
-- clickea tienen que ser el MISMO.
function Config.ZoneAt(nx, ny)
    for _, p in ipairs(Config.SILHOUETTE) do
        if nx >= p.x and nx <= p.x + p.w and ny >= p.y and ny <= p.y + p.h then
            return p.zone
        end
    end
    return nil
end

-- corpus_coagulant_core.lua — estado clínico por jugador + creación de heridas (SERVER)
-- Coagulant_Architecture.md §2-§3, §8. La herida se crea en PostEntityTakeDamage
-- con el daño FINAL (post-mitigación de cualquier mod, y de Caliber Block 3 cuando
-- exista): ScalePlayerDamage solo captura el hitgroup del evento. Coagulant nunca
-- re-escala daño — solo observa.

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

-- Estado clínico en memoria, por SteamID64 (§2). Sin persistencia a disco (spawn =
-- cuerpo nuevo, decisión F de la semilla).
COAGULANT.State = COAGULANT.State or {}

local function NuevoEstado()
    local st = {
        blood       = Config.BLOOD_MAX,
        zones       = {},
        treatment   = nil,   -- { kind, zone, endsAt } — llega con el slice 2
        encumbrance = 0,     -- último fraction reportado por Cargo (§12), sin efecto v1
        critical    = false, -- para detectar el cruce del umbral (§5)
        dirty       = true,  -- snapshot pendiente de enviar (§9)
        lastHit     = nil,   -- debug
    }
    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        st.zones[zona] = { wounds = {}, tourniquet = false }
    end
    return st
end

-- Devuelve (creando si hace falta) el estado clínico del jugador.
function COAGULANT.GetState(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return nil end
    local sid = ply:SteamID64() or "singleplayer"
    COAGULANT.State[sid] = COAGULANT.State[sid] or NuevoEstado()
    return COAGULANT.State[sid]
end

-- Resetea el estado clínico del jugador (spawn = cuerpo nuevo).
function COAGULANT.ResetState(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    local sid = ply:SteamID64() or "singleplayer"
    COAGULANT.State[sid] = NuevoEstado()
    ply:SetNW2Float("coagulant_blood", Config.BLOOD_MAX)
end

-- ============================================================
-- CONTRATO PÚBLICO (lectura) — §8
-- ============================================================

function COAGULANT.GetBlood(ply)
    local st = COAGULANT.GetState(ply)
    return st and st.blood or Config.BLOOD_MAX
end

function COAGULANT.IsBleeding(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return false end
    for _, zdata in pairs(st.zones) do
        if not zdata.tourniquet then
            for _, w in ipairs(zdata.wounds) do
                if Config.BleedRate(w) > 0 then return true end
            end
        end
    end
    return false
end

-- Score de debuff de la zona (§6): Σ severidades; las tratadas cuentan la mitad.
function COAGULANT.GetZoneScore(ply, zone)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return 0 end
    local score = 0
    for _, w in ipairs(st.zones[zone].wounds) do
        score = score + (w.treated and w.severity * 0.5 or w.severity)
    end
    return score
end

-- Contrato YA congelado por Cargo (corpus_cargo_movement.lua nos llama con pcall
-- en cada cambio de peso). v1: almacenar; la stamina/fatiga es bloque futuro (§1).
function COAGULANT.OnEncumbrance(ply, fraction)
    local st = COAGULANT.GetState(ply)
    if st == nil then return end
    st.encumbrance = fraction or 0
end

-- ============================================================
-- Heridas (§3)
-- ============================================================

-- Agrega una herida a la zona, respetando el tope por zona: al exceder, se agrava
-- la herida más leve (preferentemente no tratada) en vez de apilar sin límite.
-- Off-contract: la usan PostEntityTakeDamage y el selftest.
function COAGULANT.AddWound(ply, zone, wtype, severity)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return nil end
    local wounds = st.zones[zone].wounds

    local wound
    if #wounds >= Config.MAX_WOUNDS_PER_ZONE then
        local candidata
        for _, w in ipairs(wounds) do
            if candidata == nil
                or (not w.treated and candidata.treated)
                or (w.treated == candidata.treated and w.severity < candidata.severity) then
                candidata = w
            end
        end
        candidata.severity = math.min(3, candidata.severity + 1)
        candidata.treated = false
        wound = candidata
    else
        wound = { type = wtype, severity = severity, treated = false }
        wounds[#wounds + 1] = wound
    end

    st.dirty = true
    hook.Run("Coagulant_WoundAdded", ply, zone, wound)
    if Config.cv_debug:GetBool() then
        Corpus.Log("coagulant", string.format("herida: %s sev %d en %s (%s)",
            wound.type, wound.severity, zone, ply:Nick()))
    end
    return wound
end

-- ============================================================
-- Tratamiento — efecto de la venda (§7). La mecánica de tiempo/consumo/intents
-- llega con el slice 2 (ApplyTreatment); este es el efecto puro, y ApplyBandage
-- (contrato congelado desde el scaffold) lo aplica instantáneo mientras tanto.
-- ============================================================

-- Efecto venda sobre una zona: cierra la peor herida sangrante leve/media; una
-- grave la reduce a media sin cerrarla (una grave cuesta 2 vendas).
function COAGULANT.BandageEffect(ply, zone)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return false end

    local objetivo
    for _, w in ipairs(st.zones[zone].wounds) do
        if Config.BleedRate(w) > 0 and (objetivo == nil or w.severity > objetivo.severity) then
            objetivo = w
        end
    end
    if objetivo == nil then return false end

    if objetivo.severity >= 3 then
        objetivo.severity = 2
    else
        objetivo.treated = true
        hook.Run("Coagulant_WoundClosed", ply, zone, objetivo)
    end
    st.dirty = true
    return true
end

-- Azúcar congelada (§8): venda con zona automática — la zona con la herida
-- sangrante más grave. true si tuvo efecto (el onUse de Cargo consume con true;
-- el consumo al completar llega con el slice 2).
function COAGULANT.ApplyBandage(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return false end

    local mejorZona, mejorSev = nil, 0
    for zona, zdata in pairs(st.zones) do
        for _, w in ipairs(zdata.wounds) do
            if Config.BleedRate(w) > 0 and w.severity > mejorSev then
                mejorZona, mejorSev = zona, w.severity
            end
        end
    end
    if mejorZona == nil then return false end
    return COAGULANT.BandageEffect(ply, mejorZona)
end

-- ============================================================
-- Hooks del pipeline (§3)
-- ============================================================

-- Captura el hitgroup del evento; la herida se crea después, con el daño final.
hook.Add("ScalePlayerDamage", "corpus_coagulant_hit", function(ply, hitgroup, dmginfo)
    if not Config.Enabled() then return end
    ply.m_coagHitgroup = hitgroup
    ply.m_coagHitTime = CurTime()
end)

-- Crea la herida con el daño realmente aplicado. st._selfDrain evita el bucle:
-- el drenaje de HP crítico (bleeding, §5) también dispara este hook.
hook.Add("PostEntityTakeDamage", "corpus_coagulant_wound", function(ent, dmginfo, took)
    if not took or not Config.Enabled() then return end
    if not (IsValid(ent) and ent:IsPlayer()) then return end
    local st = COAGULANT.GetState(ent)
    if st == nil or st._selfDrain then return end

    local wtype = Config.WoundTypeFromDMG(dmginfo:GetDamageType())
    if wtype == nil then return end

    -- Zona: hitgroup capturado en este mismo evento (ventana corta); las caídas
    -- no pasan por ScalePlayerDamage → pierna al azar; resto sin dato → torso.
    local zona
    if ent.m_coagHitTime ~= nil and CurTime() - ent.m_coagHitTime < 0.1 then
        zona = COAGULANT.Zones.FromHitgroup(ent.m_coagHitgroup)
    elseif bit.band(dmginfo:GetDamageType(), DMG_FALL) ~= 0 then
        zona = math.random(2) == 1 and "left_leg" or "right_leg"
    else
        zona = "torso"
    end

    local dano = dmginfo:GetDamage()
    COAGULANT.AddWound(ent, zona, wtype, Config.SeverityFromDamage(dano))
    st.lastHit = { zone = zona, damage = dano, time = CurTime() }
end)

hook.Add("PlayerSpawn", "corpus_coagulant_spawn", function(ply)
    COAGULANT.ResetState(ply)
end)

hook.Add("PlayerDisconnected", "corpus_coagulant_disconnect", function(ply)
    local sid = ply:SteamID64()
    if sid ~= nil then COAGULANT.State[sid] = nil end
end)

-- corpus_coagulant_core.lua — estado clínico por jugador + hooks sustrato (SERVER)
-- SCAFFOLD PRE-BLOCK 3: fija la forma del estado y el punto de enganche del
-- pipeline (dónde entra un impacto, dónde se resetea), SIN efecto de gameplay.
-- Las curvas reales (sangrado, vitales, heridas) son dominio del Block 3 y NO se
-- inventan acá — este archivo solo registra la zona del último impacto como
-- evidencia verificable de que el slice corre de punta a punta.

local COAGULANT = Corpus.GetModule("coagulant")

-- Estado clínico en memoria, por SteamID64. La persistencia (Corpus.Data,
-- namespace "coagulant") llega con Block 3, cuando exista un estado que valga
-- la pena persistir — no antes.
COAGULANT.State = COAGULANT.State or {}

-- Forma del estado por jugador (sustrato; Block 3 la puebla de verdad):
--   zones[zona] = { wounds = {}, bleeding = 0 }   -- placeholders, sin semántica aún
--   lastHit     = { zone, damage, time }           -- evidencia del slice, debug
local function NuevoEstado()
    local st = { zones = {}, lastHit = nil }
    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        st.zones[zona] = { wounds = {}, bleeding = 0 }
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
end

-- ============================================================
-- CONTRATO PÚBLICO — ApplyBandage(ply) -> bool
-- Firma congelada (es el onUse del ítem de Cargo, CORPUS_Architecture.md §5).
-- Stub: hoy solo limpia el placeholder de sangrado y loguea. La semántica real
-- (qué venda, qué herida, cuánto tarda) es diseño de Block 3.
-- ============================================================
function COAGULANT.ApplyBandage(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return false end

    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        st.zones[zona].bleeding = 0
    end
    Corpus.Log("coagulant", "ApplyBandage (stub) sobre " .. ply:Nick())
    return true -- consumir una unidad (contrato onUse de Cargo)
end

-- ============================================================
-- Hooks sustrato — puntos de enganche del pipeline, sin gameplay
-- ============================================================

-- Punto de entrada de un impacto a jugador. ScalePlayerDamage es el hook server
-- que trae hitgroup; NO se modifica el daño (eso, si corresponde, es de Caliber).
-- Lazy-check de Caliber (soft-dep, §6 de la arquitectura): su hit-location
-- enriquecido aún no existe (Caliber.Limbs vacío en su Block 2) — mock-first,
-- la rama se cablea cuando Caliber cierre su pipeline de jugador.
hook.Add("ScalePlayerDamage", "corpus_coagulant_hit", function(ply, hitgroup, dmginfo)
    local st = COAGULANT.GetState(ply)
    if st == nil then return end

    local zona = COAGULANT.Zones.FromHitgroup(hitgroup)
    local caliber = Corpus.GetModule("caliber")
    if caliber ~= nil then
        -- Enriquecer con datos de zona/armadura cuando Caliber exponga la
        -- superficie (Block 3 de Caliber). Hoy no hay nada que consumir.
    end

    st.lastHit = { zone = zona, damage = dmginfo:GetDamage(), time = CurTime() }
end)

hook.Add("PlayerSpawn", "corpus_coagulant_spawn", function(ply)
    COAGULANT.ResetState(ply)
end)

hook.Add("PlayerDisconnected", "corpus_coagulant_disconnect", function(ply)
    local sid = ply:SteamID64()
    if sid ~= nil then COAGULANT.State[sid] = nil end
end)

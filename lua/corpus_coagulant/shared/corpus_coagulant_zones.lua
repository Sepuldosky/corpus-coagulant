-- corpus_coagulant_zones.lua — zonas clínicas + mapa hitgroup nativo -> zona (SHARED, puro)
-- Es la VÍA DE DEGRADACIÓN de Coagulant sin Caliber (CORPUS_Architecture.md §2):
-- hit-location por hitgroup crudo del engine. Cuando Caliber exponga su
-- hit-location enriquecido (Block 3 de Caliber), este mapa queda como fallback —
-- nunca se borra: un usuario puede correr Coagulant solo.
--
-- Data pura, sin hooks ni estado. La granularidad (6 zonas estilo ACE3) es
-- sustrato del scaffold; Block 3 puede refinarla, pero los IDs de zona ya son
-- contrato: los usan las keys de estado clínico y los usarán los ítems médicos.

local COAGULANT = Corpus.GetModule("coagulant")

COAGULANT.Zones = COAGULANT.Zones or {}
local Zones = COAGULANT.Zones

-- Zonas clínicas estilo ACE3 (6 partes de cuerpo). El orden es estable para UI.
Zones.LIST = {
    "head",
    "torso",
    "left_arm",
    "right_arm",
    "left_leg",
    "right_leg",
}

-- Nombres de cara al jugador (el idioma del mod es inglés).
Zones.LABELS = {
    head      = "Head",
    torso     = "Torso",
    left_arm  = "Left Arm",
    right_arm = "Right Arm",
    left_leg  = "Left Leg",
    right_leg = "Right Leg",
}

-- Hitgroups nativos del engine -> zona clínica. HITGROUP_GENERIC y HITGROUP_GEAR
-- no traen ubicación real: caen a torso (decisión conservadora del scaffold).
local HITGROUP_A_ZONA = {
    [HITGROUP_HEAD]     = "head",
    [HITGROUP_CHEST]    = "torso",
    [HITGROUP_STOMACH]  = "torso",
    [HITGROUP_LEFTARM]  = "left_arm",
    [HITGROUP_RIGHTARM] = "right_arm",
    [HITGROUP_LEFTLEG]  = "left_leg",
    [HITGROUP_RIGHTLEG] = "right_leg",
    [HITGROUP_GENERIC]  = "torso",
    [HITGROUP_GEAR]     = "torso",
}

-- Resuelve un hitgroup nativo a zona clínica. Siempre devuelve una zona válida
-- (torso como fallback): el llamador nunca tiene que manejar nil.
function Zones.FromHitgroup(hitgroup)
    return HITGROUP_A_ZONA[hitgroup] or "torso"
end

-- true si el string es un ID de zona del contrato.
function Zones.IsValid(zone)
    return Zones.LABELS[zone] ~= nil
end

-- corpus_coagulant_zones.lua — zonas clínicas + mapa hitgroup nativo -> zona (SHARED, puro)
-- Es la VÍA DE DEGRADACIÓN de Coagulant sin Caliber (CORPUS_Architecture.md §2):
-- hit-location por hitgroup crudo del engine. Cuando Caliber exponga su
-- hit-location enriquecido (Block 3 de Caliber), este mapa queda como fallback —
-- nunca se borra: un usuario puede correr Coagulant solo.
--
-- Data pura, sin hooks ni estado. Las 7 zonas (enmienda 2026-07-21, COA-8: `torso`
-- se partió en `chest` y `stomach` — el Source ya separaba esos hitgroups) son
-- contrato: los usan las keys de estado clínico y los ítems médicos.

local COAGULANT = Corpus.GetModule("coagulant")

COAGULANT.Zones = COAGULANT.Zones or {}
local Zones = COAGULANT.Zones

-- Zonas clínicas (7 partes de cuerpo). El orden es estable para UI.
Zones.LIST = {
    "head",
    "chest",
    "stomach",
    "left_arm",
    "right_arm",
    "left_leg",
    "right_leg",
}

-- Nombres de cara al jugador (el idioma del mod es inglés).
Zones.LABELS = {
    head      = "Head",
    chest     = "Chest",
    stomach   = "Stomach",
    left_arm  = "Left Arm",
    right_arm = "Right Arm",
    left_leg  = "Left Leg",
    right_leg = "Right Leg",
}

-- Hitgroups nativos del engine -> zona clínica. HITGROUP_GENERIC y HITGROUP_GEAR
-- no traen ubicación real: caen a chest (COA-7, alineado con Caliber — GENERIC va
-- a chest en su mult de zona y en el fallback de placas).
local HITGROUP_A_ZONA = {
    [HITGROUP_HEAD]     = "head",
    [HITGROUP_CHEST]    = "chest",
    [HITGROUP_STOMACH]  = "stomach",
    [HITGROUP_LEFTARM]  = "left_arm",
    [HITGROUP_RIGHTARM] = "right_arm",
    [HITGROUP_LEFTLEG]  = "left_leg",
    [HITGROUP_RIGHTLEG] = "right_leg",
    [HITGROUP_GENERIC]  = "chest",
    [HITGROUP_GEAR]     = "chest",
}

-- Resuelve un hitgroup nativo a zona clínica. Siempre devuelve una zona válida
-- (chest como fallback, COA-7): el llamador nunca tiene que manejar nil.
function Zones.FromHitgroup(hitgroup)
    return HITGROUP_A_ZONA[hitgroup] or "chest"
end

-- true si el string es un ID de zona del contrato. `torso` murió sin alias
-- (COA-8, enmienda 2026-07-21): acá devuelve false a propósito.
function Zones.IsValid(zone)
    return Zones.LABELS[zone] ~= nil
end

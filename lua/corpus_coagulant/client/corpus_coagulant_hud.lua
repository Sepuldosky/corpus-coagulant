-- corpus_coagulant_hud.lua — estado replicado + debuff de visión (CLIENT)
-- Coagulant_Architecture.md §6 (cabeza → visión), §9 (snapshot), §10.
--
-- SLICE 3: este archivo nace con el receptor del snapshot (COAGULANT.ClientState —
-- la única fuente de verdad del cliente; nunca inventa estado) y la capa de visión:
-- vignette por heridas de cabeza, fade a negro al recibir una, y la capa de sangre
-- crítica. La silueta de 6 zonas, la barra de progreso de tratamiento y el
-- StatusPanel de Cargo llegan con el slice 4 y crecen sobre este mismo archivo.
--
-- Sin materiales externos a propósito: el vignette se pinta con bandas de rects
-- (las esquinas se oscurecen solas por superposición) — nada que pueda faltar en
-- un cliente ni orientarse al revés.

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

local MSG_STATE = Corpus.Net.Register("coagulant", "state")

-- Espejo del estado clínico propio (§9). Llega on-change, no por tick.
COAGULANT.ClientState = COAGULANT.ClientState or { blood = Config.BLOOD_MAX, zones = {} }

local blackoutHasta = 0
local sevCabezaPrev = {}  -- severidades de la cabeza en el snapshot anterior

-- Score de cabeza desde el snapshot — misma fórmula que GetZoneScore en server
-- (§6: tratadas cuentan la mitad). La cabeza no admite torniquete, así que acá no
-- hay isquemia que reconciliar: el número coincide siempre.
local function ScoreCabeza()
    local head = COAGULANT.ClientState.zones and COAGULANT.ClientState.zones.head
    if head == nil then return 0 end
    local score = 0
    for _, w in ipairs(head.w or {}) do
        score = score + (w.tr and w.s * 0.5 or w.s)
    end
    return score
end

-- Fade a negro al recibir una herida de cabeza media/grave (§6). Se detecta
-- comparando el snapshot con el anterior — sin mensaje de red nuevo (§9 congela
-- los canales): una herida NUEVA en el índice i, o una vieja que se AGRAVÓ.
local function DetectarBlackout(zonas)
    local ws = (zonas and zonas.head and zonas.head.w) or {}

    for i, w in ipairs(ws) do
        local antes = sevCabezaPrev[i]
        if (antes == nil or w.s > antes) and w.s >= Config.BLACKOUT_MIN_SEVERITY then
            blackoutHasta = CurTime() + Config.BLACKOUT_S
            break
        end
    end

    sevCabezaPrev = {}
    for i, w in ipairs(ws) do sevCabezaPrev[i] = w.s end
end

net.Receive(MSG_STATE, function()
    local n = net.ReadUInt(16)
    local blob = net.ReadData(n)
    local crudo = util.Decompress(blob)
    if crudo == nil then return end
    local tbl = util.JSONToTable(crudo)
    if not istable(tbl) then return end

    tbl.zones = istable(tbl.zones) and tbl.zones or {}
    DetectarBlackout(tbl.zones)
    COAGULANT.ClientState = tbl
end)

-- ============================================================
-- Capa de visión (§6 cabeza + §5 crítico)
-- ============================================================

-- La sangre viaja por NW2 (no por el snapshot): siempre está, incluso antes del
-- primer snapshot de la vida.
local function SangreActual()
    local ply = LocalPlayer()
    if not IsValid(ply) then return Config.BLOOD_MAX end
    return ply:GetNW2Float("coagulant_blood", Config.BLOOD_MAX)
end

-- Intensidad del debuff de cabeza (0 si la convar lo apaga)
local function IntensidadCabeza()
    if not Config.cv_debuff_head:GetBool() then return 0 end
    return Config.VisionIntensity(ScoreCabeza())
end

-- Screenspace: la sangre crítica dessatura y apaga el contraste; la herida de
-- cabeza oscurece. Son capas distintas a propósito — desangrarse y estar
-- conmocionado no se sienten igual.
hook.Add("RenderScreenspaceEffects", "corpus_coagulant_vision", function()
    if not Config.Enabled() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local crit = Config.CriticalIntensity(SangreActual())
    local head = IntensidadCabeza()
    if crit <= 0 and head <= 0 then return end

    DrawColorModify({
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.10 * head,
        ["$pp_colour_contrast"]   = 1 - 0.20 * crit,
        ["$pp_colour_colour"]     = 1 - 0.70 * crit, -- 1 = normal, 0 = escala de grises
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0,
    })
end)

-- Vignette por bandas concéntricas: cada banda pinta los 4 bordes, así que las
-- esquinas acumulan alpha solas. La curva cuadrática deja el centro limpio.
local BANDAS = 24
local function PintarVignette(intensidad, r, g, b)
    local w, h = ScrW(), ScrH()
    local pasoX = (w * 0.18) / BANDAS
    local pasoY = (h * 0.18) / BANDAS

    for i = 1, BANDAS do
        local f = (BANDAS - i + 1) / BANDAS -- 1 en el borde, ~0 hacia el centro
        local a = intensidad * f * f * 255
        if a >= 1 then
            surface.SetDrawColor(r, g, b, a)
            local x = (i - 1) * pasoX
            local y = (i - 1) * pasoY
            surface.DrawRect(x, 0, pasoX, h)
            surface.DrawRect(w - x - pasoX, 0, pasoX, h)
            surface.DrawRect(0, y, w, pasoY)
            surface.DrawRect(0, h - y - pasoY, w, pasoY)
        end
    end
end

local avisado = false
local function PintarVision()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local head = IntensidadCabeza()
    if head > 0 then PintarVignette(head * 0.85, 0, 0, 0) end

    -- Sangre crítica: vignette rojo. NO se apaga por convar — es información
    -- vital (§11): el jugador tiene que sentir que se desangra sin mirar el HUD.
    local crit = Config.CriticalIntensity(SangreActual())
    if crit > 0 then PintarVignette(crit * 0.75, 90, 0, 0) end

    -- Fade a negro por herida de cabeza: arranca opaco y se desvanece (§6). Es
    -- solo visual: el jugador nunca pierde el control.
    if CurTime() < blackoutHasta then
        local f = math.Clamp((blackoutHasta - CurTime()) / Config.BLACKOUT_S, 0, 1)
        surface.SetDrawColor(0, 0, 0, 255 * f)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end

-- pcall obligatorio: GMod DESENGANCHA un hook de HUDPaint que erra — un error de
-- pintado mataría la capa entera en silencio por el resto de la sesión (trampa
-- pagada por Cargo). Se avisa una sola vez para no inundar la consola.
hook.Add("HUDPaint", "corpus_coagulant_vision_hud", function()
    if not Config.Enabled() then return end
    local ok, err = pcall(PintarVision)
    if not ok and not avisado then
        avisado = true
        Corpus.Log("coagulant", "error pintando la capa de visión: " .. tostring(err))
    end
end)

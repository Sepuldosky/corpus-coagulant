-- corpus_coagulant_hud.lua — estado replicado, sway y capa de visión (CLIENT)
-- Coagulant_Architecture.md §6 (brazos → sway, cabeza → visión), §9 (snapshot), §10.
--
-- SLICE 3: este archivo tiene el receptor del snapshot (COAGULANT.ClientState — la
-- única fuente de verdad del cliente; nunca inventa estado), el sway de la mira y la
-- capa de visión. La silueta de 6 zonas, la barra de progreso de tratamiento y el
-- StatusPanel de Cargo llegan con el slice 4 y crecen sobre este mismo archivo.
--
-- POR QUÉ EL SWAY ES CLIENTE: es una deriva CONTINUA de la puntería. La única forma
-- de mover la mira sin pelear contra el mouse del jugador es tocar el usercmd ANTES
-- de que salga (hook CreateMove) — y se aplica el DELTA del offset, no el offset
-- absoluto, o la vista derivaría sin control en vez de oscilar. El score de brazos
-- llega en el snapshot con la isquemia ya incluida, así que el número es el mismo que
-- calcula el server.

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

local MSG_STATE = Corpus.Net.Register("coagulant", "state")

-- Espejo del estado clínico propio (§9). Llega on-change, no por tick.
COAGULANT.ClientState = COAGULANT.ClientState or { blood = Config.BLOOD_MAX, zones = {} }

local blackoutHasta = 0
local sevCabezaPrev = {}  -- severidades de la cabeza en el snapshot anterior

-- Superficie que el menú médico (slice 4) consume: lee el MISMO snapshot que pinta el
-- HUD, nunca un estado propio. Client-side y off-contract — el contrato público de §8
-- es del server.
COAGULANT.HUD = COAGULANT.HUD or {}
local HUD = COAGULANT.HUD

-- Score de una zona desde el snapshot — misma fórmula que GetZoneScore en server
-- (§6: tratadas cuentan la mitad; la isquemia impone su piso).
local function ScoreZona(zona)
    local z = COAGULANT.ClientState.zones and COAGULANT.ClientState.zones[zona]
    if z == nil then return 0 end
    local score = 0
    for _, w in ipairs(z.w or {}) do
        score = score + (w.tr and w.s * 0.5 or w.s)
    end
    if z.isq then score = math.max(score, Config.ISCHEMIA_SCORE) end
    return score
end
HUD.ZoneScore = ScoreZona

local function ScoreBrazos()
    return ScoreZona("left_arm") + ScoreZona("right_arm")
end

-- Datos crudos de una zona en el snapshot ({w = heridas, tq, isq}), o una tabla vacía.
function HUD.ZoneData(zona)
    local z = COAGULANT.ClientState.zones and COAGULANT.ClientState.zones[zona]
    return z or {}
end

-- ¿Sangra la zona? Misma pregunta que se hace el server, con la misma curva: una
-- herida sin tratar cuyo BleedRate es > 0.
function HUD.ZoneBleeding(zona)
    for _, w in ipairs(HUD.ZoneData(zona).w or {}) do
        if Config.BleedRate(Config.WoundFromSnap(w)) > 0 then return true end
    end
    return false
end

function HUD.Blood()
    local ply = LocalPlayer()
    if not IsValid(ply) then return Config.BLOOD_MAX end
    return ply:GetNW2Float("coagulant_blood", Config.BLOOD_MAX)
end

function HUD.Treatment()
    return COAGULANT.ClientState.treatment
end

-- Fade a negro al recibir una herida de cabeza media/grave (§6). Se detecta
-- comparando el snapshot con el anterior — sin mensaje de red nuevo (§9 congela los
-- canales): una herida NUEVA en el índice i, o una vieja que se AGRAVÓ.
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
-- Brazos → sway de la mira (§6)
-- ============================================================

-- El offset aplicado en el frame anterior: se resta para que la mira OSCILE en vez
-- de derivar (sumar el offset absoluto cada tick lo acumularía sin control).
local swayYawPrev, swayPitchPrev = 0, 0

-- Cuánto se está apuntando, 0..1. NO es el booleano del clic derecho: es una rampa en
-- el tiempo hacia él (ronda 6 — el salto instantáneo entre capas se sentía tosco). La
-- amplitud viaja por esta curva, la fase del bamboleo nunca se corta: la mira nunca da
-- un tirón, solo se abre y se cierra el bamboleo.
local swayADS = 0

local function CortarSway()
    swayYawPrev, swayPitchPrev = 0, 0
    swayADS = 0
end

hook.Add("CreateMove", "corpus_coagulant_sway", function(cmd)
    if not Config.Enabled() or not Config.cv_debuff_arms:GetBool() then
        CortarSway()
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then CortarSway() return end
    if not IsValid(ply:GetActiveWeapon()) then CortarSway() return end -- sin arma, sin sway

    local score = ScoreBrazos()
    if score <= 0 then CortarSway() return end

    -- Dos capas (§6), ahora como los extremos de una rampa: con el arma en mano el
    -- temblor es leve; apuntando (clic derecho — el ADS de ARC9/TFA/MW, y agnóstico al
    -- arma) la deriva se vuelve incapacitante. Ahí es donde una herida de brazo tiene
    -- que doler. El tránsito entre las dos tarda SWAY_ADS_RAMP_S y va por smoothstep.
    local objetivo = cmd:KeyDown(IN_ATTACK2) and 1 or 0
    local paso = math.min(FrameTime(), 0.1) / Config.SWAY_ADS_RAMP_S -- clamp: un frame largo no teletransporta la rampa
    swayADS = math.Approach(swayADS, objetivo, paso)

    local amp = Config.SwayFor(score, swayADS)
    local yaw, pitch = Config.SwayOffset(CurTime(), amp)

    local ang = cmd:GetViewAngles()
    ang.y = ang.y + (yaw - swayYawPrev)
    ang.p = math.Clamp(ang.p + (pitch - swayPitchPrev), -89, 89)
    cmd:SetViewAngles(ang)

    swayYawPrev, swayPitchPrev = yaw, pitch
end)

-- ============================================================
-- Cabeza → visión, y la capa de sangre crítica (§5-§6)
-- ============================================================

-- La sangre viaja por NW2 (no por el snapshot): siempre está, incluso antes del
-- primer snapshot de la vida.
local function SangreActual()
    local ply = LocalPlayer()
    if not IsValid(ply) then return Config.BLOOD_MAX end
    return ply:GetNW2Float("coagulant_blood", Config.BLOOD_MAX)
end

local function IntensidadCabeza()
    if not Config.cv_debuff_head:GetBool() then return 0 end
    return Config.VisionIntensity(ScoreZona("head"))
end

-- Screenspace: la sangre crítica dessatura y apaga el contraste; la herida de cabeza
-- oscurece. Son capas distintas a propósito — desangrarse y estar conmocionado no se
-- sienten igual.
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

-- Vignette ELÍPTICO (reescrito el 2026-07-14 tras la ronda 5: la versión de bandas
-- rectangulares daba un marco cuadrado con esquinas duras — "se ve raro", y con
-- razón). Anillos concéntricos triangulados: geometría propia, sin materiales
-- externos, así que no depende de ningún asset ni de la licencia de nadie.
local CAPAS, SEG = 10, 24
local geoW, geoH, geo = 0, 0, nil

local function ConstruirGeo(w, h)
    local cx, cy = w * 0.5, h * 0.5
    local rxIn,  ryIn  = w * 0.34, h * 0.30 -- donde arranca el oscurecimiento
    local rxOut, ryOut = w * 0.80, h * 0.88 -- fuera de pantalla: cubre las esquinas

    geo = {}
    for i = 1, CAPAS do
        local f0, f1 = (i - 1) / CAPAS, i / CAPAS
        local rx0, ry0 = Lerp(f0, rxIn, rxOut), Lerp(f0, ryIn, ryOut)
        local rx1, ry1 = Lerp(f1, rxIn, rxOut), Lerp(f1, ryIn, ryOut)

        local quads = {}
        for s = 1, SEG do
            local a0 = (s - 1) / SEG * math.pi * 2
            local a1 = s / SEG * math.pi * 2
            local c0, s0 = math.cos(a0), math.sin(a0)
            local c1, s1 = math.cos(a1), math.sin(a1)
            -- horario en pantalla (y crece hacia abajo): DrawPoly no pinta al revés
            quads[s] = {
                { x = cx + c0 * rx0, y = cy + s0 * ry0 },
                { x = cx + c1 * rx0, y = cy + s1 * ry0 },
                { x = cx + c1 * rx1, y = cy + s1 * ry1 },
                { x = cx + c0 * rx1, y = cy + s0 * ry1 },
            }
        end
        geo[i] = { alpha = f1 * f1, quads = quads } -- curva cuadrática: centro limpio
    end
    geoW, geoH = w, h
end

local function PintarVignette(intensidad, r, g, b)
    local w, h = ScrW(), ScrH()
    if geo == nil or geoW ~= w or geoH ~= h then ConstruirGeo(w, h) end

    draw.NoTexture()
    for _, capa in ipairs(geo) do
        local a = intensidad * capa.alpha * 255
        if a >= 1 then
            surface.SetDrawColor(r, g, b, math.min(a, 255))
            for _, q in ipairs(capa.quads) do
                surface.DrawPoly(q)
            end
        end
    end
end

local avisado = false
local function PintarVision()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local head = IntensidadCabeza()
    if head > 0 then PintarVignette(head * 0.85, 0, 0, 0) end

    -- Sangre crítica: vignette rojo que LATE. NO se apaga por convar — es información
    -- vital (§11): el jugador tiene que sentir que se desangra sin mirar el HUD.
    local crit = Config.CriticalIntensity(SangreActual())
    if crit > 0 then
        local pulso = 1 + 0.18 * math.sin(CurTime() * math.pi * 2 * Config.PULSE_HZ)
        PintarVignette(crit * 0.75 * pulso, 95, 0, 0)
    end

    -- Fade a negro por herida de cabeza: arranca opaco y se desvanece (§6). Es solo
    -- visual: el jugador nunca pierde el control.
    if CurTime() < blackoutHasta then
        local f = math.Clamp((blackoutHasta - CurTime()) / Config.BLACKOUT_S, 0, 1)
        surface.SetDrawColor(0, 0, 0, 255 * f)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end

-- pcall obligatorio (cita COA-14, sede en la arquitectura §10): GMod DESENGANCHA un
-- hook de HUDPaint que erra — un error de pintado mataría la capa entera en silencio
-- por el resto de la sesión (trampa pagada por Cargo). Se avisa una sola vez.
hook.Add("HUDPaint", "corpus_coagulant_vision_hud", function()
    if not Config.Enabled() then return end
    local ok, err = pcall(PintarVision)
    if not ok and not avisado then
        avisado = true
        Corpus.Log("coagulant", "error pintando la capa de visión: " .. tostring(err))
    end
end)

-- ============================================================
-- Silueta de 6 zonas + barra de tratamiento (§10) — slice 4
-- ============================================================

local COL_SANO   = Color(70, 90, 70)
local COL_MEDIO  = Color(200, 170, 60)
local COL_GRAVE  = Color(190, 45, 40)
local COL_BORDE  = Color(20, 20, 20)
local COL_TEXTO  = Color(215, 215, 215)
local COL_TQ     = Color(60, 140, 220)   -- torniquete: azul, no compite con el rojo de la herida
local COL_ISQ    = Color(150, 60, 200)   -- isquemia: morado — la zona se está muriendo, no sangrando

-- Color de una zona por su score: sano → amarillo → rojo. Dos tramos, no un lerp
-- único: el amarillo se pierde si se interpola directo de verde a rojo.
function HUD.ZoneColor(score)
    local f = Config.ZoneDamageFrac(score)
    if f <= 0 then return COL_SANO end
    if f < 0.5 then
        local t = f / 0.5
        return Color(Lerp(t, COL_SANO.r, COL_MEDIO.r), Lerp(t, COL_SANO.g, COL_MEDIO.g),
                     Lerp(t, COL_SANO.b, COL_MEDIO.b))
    end
    local t = (f - 0.5) / 0.5
    return Color(Lerp(t, COL_MEDIO.r, COL_GRAVE.r), Lerp(t, COL_MEDIO.g, COL_GRAVE.g),
                 Lerp(t, COL_MEDIO.b, COL_GRAVE.b))
end

-- Pinta la silueta en la caja dada. La geometría sale de Config.SILHOUETTE — la misma
-- tabla que usa el menú médico para saber DÓNDE hizo clic el jugador: si el dibujo y
-- el área clickeable salieran de tablas distintas, se desincronizarían en el primer
-- retoque. `sel` resalta una zona (el menú marca la elegida).
function HUD.DrawSilhouette(x, y, w, h, alpha, sel)
    for _, p in ipairs(Config.SILHOUETTE) do
        local zx, zy = x + p.x * w, y + p.y * h
        local zw, zh = p.w * w, p.h * h
        local score = ScoreZona(p.zone)
        local col = HUD.ZoneColor(score)

        -- Sangrando: la zona LATE. Es la única señal que hay que ver sin leer nada.
        local a = alpha
        if HUD.ZoneBleeding(p.zone) then
            a = alpha * (0.55 + 0.45 * math.abs(math.sin(CurTime() * math.pi * 1.6)))
        end

        surface.SetDrawColor(col.r, col.g, col.b, a)
        surface.DrawRect(zx, zy, zw, zh)

        surface.SetDrawColor(COL_BORDE.r, COL_BORDE.g, COL_BORDE.b, alpha)
        surface.DrawOutlinedRect(zx, zy, zw, zh, 1)

        if sel == p.zone then
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.DrawOutlinedRect(zx - 1, zy - 1, zw + 2, zh + 2, 2)
        end

        -- Torniquete: banda azul cruzando la zona. Isquemia: la banda se pone morada
        -- (el torniquete lleva demasiado puesto — la extremidad se muere).
        local zd = HUD.ZoneData(p.zone)
        if zd.tq or zd.isq then
            local c = zd.isq and COL_ISQ or COL_TQ
            surface.SetDrawColor(c.r, c.g, c.b, alpha)
            surface.DrawRect(zx, zy + zh * 0.42, zw, math.max(2, zh * 0.12))
        end
    end
end

-- Barra de progreso del tratamiento (§9/§10): se calcula acá con el {endsAt, duration}
-- del snapshot — el server no manda un tick de progreso.
local KIND_LABEL = {
    bandage = "Bandaging", tourniquet = "Applying tourniquet",
    medkit = "Using medkit", bloodbag = "Transfusing",
}

local function PintarBarraTratamiento()
    local tr = HUD.Treatment()
    if tr == nil then return end

    local w, h = 320, 16
    local x, y = (ScrW() - w) * 0.5, ScrH() - 140
    local f = Config.TreatmentProgress(tr, CurTime())

    surface.SetDrawColor(15, 15, 15, 200)
    surface.DrawRect(x - 2, y - 2, w + 4, h + 4)
    surface.SetDrawColor(50, 130, 60, 230)
    surface.DrawRect(x, y, w * f, h)
    surface.SetDrawColor(200, 200, 200, 90)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    local etiqueta = KIND_LABEL[tr.kind] or tr.kind
    if tr.kind == "tourniquet" and tr.removing then etiqueta = "Removing tourniquet" end
    if tr.zone ~= nil and tr.kind ~= "bloodbag" then
        etiqueta = etiqueta .. " — " .. (COAGULANT.Zones.LABELS[tr.zone] or tr.zone)
    end

    draw.SimpleText(etiqueta, "DermaDefaultBold", ScrW() * 0.5, y - 6, COL_TEXTO,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText("Hold still", "DermaDefault", ScrW() * 0.5, y + h + 3, COL_TEXTO,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

-- La silueta se DESVANECE cuando no hay nada que mirar (§10): cuerpo sano y sangre
-- llena. No se apaga de golpe — un corte seco se lee como un bug del HUD.
local alphaHUD = 0

local function HayQueMostrar()
    if HUD.Treatment() ~= nil then return true end
    if HUD.Blood() < Config.BLOOD_MAX - 0.5 then return true end
    for _, z in ipairs(COAGULANT.Zones.LIST) do
        if ScoreZona(z) > 0 then return true end
        local zd = HUD.ZoneData(z)
        if zd.tq or zd.isq then return true end
    end
    return false
end

local function PintarSilueta()
    if not Config.cv_hud:GetBool() then alphaHUD = 0 return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then alphaHUD = 0 return end

    local objetivo = HayQueMostrar() and 255 or 0
    alphaHUD = math.Approach(alphaHUD, objetivo, FrameTime() * 400)
    if alphaHUD < 1 then return end

    local w, h = 78, 132
    local x, y = 24, ScrH() * 0.5 - h * 0.5
    HUD.DrawSilhouette(x, y, w, h, alphaHUD)

    -- Sin Cargo no hay StatusPanel donde poner la sangre: mini-barra propia bajo la
    -- silueta (§14 — degradación honesta: la información no puede depender de un
    -- soft-dep). Con Cargo montado, la barra vive en SU panel y acá no se duplica.
    if not Corpus.HasModule("cargo") then
        local sangre = HUD.Blood() / Config.BLOOD_MAX
        local by = y + h + 8
        surface.SetDrawColor(15, 15, 15, alphaHUD * 0.8)
        surface.DrawRect(x - 1, by - 1, w + 2, 8)
        surface.SetDrawColor(150, 30, 30, alphaHUD)
        surface.DrawRect(x, by, w * sangre, 6)
        draw.SimpleText("Blood", "DermaDefault", x, by + 9, Color(200, 200, 200, alphaHUD))
    end
end

local avisadoHUD = false
hook.Add("HUDPaint", "corpus_coagulant_hud", function()
    if not Config.Enabled() then return end
    -- pcall por la misma razón que la capa de visión: un error de pintado deja el HUD
    -- muerto en silencio el resto de la sesión.
    local ok, err = pcall(function()
        PintarSilueta()
        PintarBarraTratamiento()
    end)
    if not ok and not avisadoHUD then
        avisadoHUD = true
        Corpus.Log("coagulant", "error pintando el HUD: " .. tostring(err))
    end
end)

-- ============================================================
-- Barra de sangre en el StatusPanel de Cargo (§10, §12)
-- ============================================================

-- Lazy-check en OnReady, nunca en file-scope: el orden de mount no está garantizado
-- (§6 del framework). Sin Cargo no se registra nada y la mini-barra de arriba cubre
-- el hueco — degradación honesta, sin un solo `if` de más en el resto del archivo.
Corpus.OnReady(function()
    local cargo = Corpus.GetModule("cargo")
    if cargo == nil or cargo.StatusPanel == nil then return end

    cargo.StatusPanel.RegisterBar("coagulant", {
        id = "blood",
        label = "Blood",
        color = Color(150, 30, 30),
        getValue = function(ply)  -- la firma real de Cargo: devuelve 0..100
            if not IsValid(ply) then return 100 end
            return ply:GetNW2Float("coagulant_blood", Config.BLOOD_MAX)
        end,
    })
    Corpus.Log("coagulant", "barra de sangre registrada en el StatusPanel de Cargo")
end)

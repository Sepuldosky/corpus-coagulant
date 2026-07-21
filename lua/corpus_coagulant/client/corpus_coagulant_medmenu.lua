-- corpus_coagulant_medmenu.lua — menú médico por zona (CLIENT)
-- Coagulant_Architecture.md §10 (pieza 2), §9 (intents). Comando: coagulant_menu.
--
-- Silueta clickeable → heridas de la zona → botones de tratamiento. El cliente NUNCA
-- es autoridad: manda el intent `treat` con {kind, zone} y el server re-valida todo
-- (ítem presente, zona válida, nada en curso). Habilitar o no un botón es puro UX —
-- si el cliente se equivoca, el server lo rechaza con un aviso por chat.
--
-- Todo lo que se muestra sale de COAGULANT.ClientState (el snapshot) vía COAGULANT.HUD:
-- este archivo no tiene estado clínico propio. Se pinta en los Paint leyendo el
-- snapshot en vivo, no se reconstruye el panel en callbacks — patrón del frame de
-- Cargo (reconstruir en callback es lo que hace parpadear los menús de VGUI).

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config
local HUD = COAGULANT.HUD

local MSG_TREAT  = Corpus.Net.Register("coagulant", "treat")
local MSG_CANCEL = Corpus.Net.Register("coagulant", "cancel")

local COL_FONDO  = Color(28, 28, 30)
local COL_PANEL  = Color(38, 38, 42)
local COL_TEXTO  = Color(220, 220, 220)
local COL_TENUE  = Color(150, 150, 150)
local COL_ALERTA = Color(215, 70, 60)

local SEV_LABEL = { [1] = "Minor", [2] = "Moderate", [3] = "Severe" }
local TIPO_LABEL = {
    bala = "Gunshot", metralla = "Shrapnel", corte = "Laceration",
    quemadura = "Burn", contusion = "Blunt trauma",
}

local frame, zonaSel

-- Cuántas unidades del ítem lleva encima, leído del snapshot CLIENTE de Cargo, o nil
-- si Cargo no está montado. OJO: cuenta las DOS clases — los `unique` (el torniquete)
-- viven como entradas con `uid` y sin `count`, así que un conteo que solo mire stacks
-- da 0 y el botón sale deshabilitado con el torniquete en la mochila. Es exactamente
-- el bug G4 (2026-07-13), que allá se pagó en el server y acá volvería a morder.
local function ContarItem(id)
    local cargo = Corpus.GetModule("cargo")
    if cargo == nil then return nil end
    local snap = cargo.ClientState
    if snap == nil then return 0 end

    local n = 0
    for _, entry in ipairs(snap.items or {}) do
        if entry.id == id then
            n = n + (entry.uid ~= nil and 1 or (entry.count or 1))
        end
    end
    return n
end

-- Zona con la que abrir: la que más urge (sangrando y grave), si no la más dañada.
local function ZonaInicial()
    local mejor, mejorPeso = "torso", -1
    for _, z in ipairs(COAGULANT.Zones.LIST) do
        local peso = HUD.ZoneScore(z) + (HUD.ZoneBleeding(z) and 100 or 0)
        if peso > mejorPeso then mejor, mejorPeso = z, peso end
    end
    return mejor
end

local function MandarIntent(kind, zone)
    net.Start(MSG_TREAT)
    net.WriteString(kind)
    net.WriteString(zone or "")
    net.SendToServer()
end

-- Panel de la silueta: pinta la misma geometría que el HUD (Config.SILHOUETTE) y
-- resuelve el clic con Config.ZoneAt sobre la MISMA tabla — dibujo y área clickeable
-- no pueden divergir.
local function ConstruirSilueta(padre)
    local p = vgui.Create("DPanel", padre)
    p:SetSize(190, 330)
    p:Dock(LEFT)
    p:DockMargin(0, 0, 10, 0)

    p.Paint = function(_, w, h)
        surface.SetDrawColor(COL_PANEL)
        surface.DrawRect(0, 0, w, h)
        local ok, err = pcall(HUD.DrawSilhouette, 0, 0, w, h, 255, zonaSel)
        if not ok then Corpus.Log("coagulant", "error pintando la silueta: " .. tostring(err)) end
    end

    p.OnMousePressed = function(self)
        local mx, my = self:CursorPos()
        local w, h = self:GetSize()
        local z = Config.ZoneAt(mx / w, my / h)
        if z ~= nil then
            zonaSel = z
            surface.PlaySound("ui/buttonclick.wav")
        end
    end

    return p
end

-- Detalle de la zona seleccionada: se pinta desde el snapshot en cada frame, así que
-- una herida nueva (o una venda que cierra otra) aparece sola, sin reconstruir nada.
local function ConstruirDetalle(padre)
    local p = vgui.Create("DPanel", padre)
    p:Dock(FILL)

    p.Paint = function(_, w, h)
        surface.SetDrawColor(COL_PANEL)
        surface.DrawRect(0, 0, w, h)

        local zona = zonaSel or "torso"
        draw.SimpleText(COAGULANT.Zones.LABELS[zona] or zona, "DermaLarge", 12, 8, COL_TEXTO)

        local score = HUD.ZoneScore(zona)
        draw.SimpleText(string.format("Damage score: %.1f", score), "DermaDefault", 12, 42,
            score > 0 and COL_ALERTA or COL_TENUE)

        local y = 66
        local zd = HUD.ZoneData(zona)
        local heridas = zd.w or {}

        if #heridas == 0 then
            draw.SimpleText("No wounds.", "DermaDefault", 12, y, COL_TENUE)
            y = y + 20
        else
            for _, herida in ipairs(heridas) do
                local sangra = Config.BleedRate(Config.WoundFromSnap(herida)) > 0
                local txt = string.format("%s — %s%s",
                    SEV_LABEL[herida.s] or ("Sev " .. tostring(herida.s)),
                    TIPO_LABEL[herida.t] or tostring(herida.t),
                    herida.tr and " (bandaged)" or "")
                draw.SimpleText(txt, "DermaDefault", 12, y,
                    sangra and COL_ALERTA or COL_TENUE)
                if sangra then
                    draw.SimpleText("BLEEDING", "DermaDefaultBold", w - 12, y, COL_ALERTA,
                        TEXT_ALIGN_RIGHT)
                end
                y = y + 18
            end
        end

        y = y + 6
        if zd.tq then
            draw.SimpleText("Tourniquet applied", "DermaDefaultBold", 12, y, Color(60, 140, 220))
            y = y + 18
        end
        if zd.isq then
            draw.SimpleText("ISCHEMIA — the limb is dying", "DermaDefaultBold", 12, y,
                Color(150, 60, 200))
            y = y + 18
        end

        -- Solo el medkit borra la secuela (§7): decirlo donde se decide, no en un doc
        local tratadas = 0
        for _, herida in ipairs(heridas) do
            if herida.tr then tratadas = tratadas + 1 end
        end
        if tratadas > 0 then
            draw.SimpleText("A medkit closes bandaged wounds for good.", "DermaDefault",
                12, y, COL_TENUE)
        end

        -- Tratamiento en curso: la misma barra que el HUD, con su progreso
        local tr = HUD.Treatment()
        if tr ~= nil then
            local f = Config.TreatmentProgress(tr, CurTime())
            surface.SetDrawColor(15, 15, 15, 220)
            surface.DrawRect(12, h - 30, w - 24, 14)
            surface.SetDrawColor(50, 130, 60, 240)
            surface.DrawRect(12, h - 30, (w - 24) * f, 14)
            draw.SimpleText(string.format("%d%%", math.floor(f * 100)), "DermaDefault",
                w * 0.5, h - 29, COL_TEXTO, TEXT_ALIGN_CENTER)
        end
    end

    return p
end

-- Un botón por tratamiento. El texto lleva el conteo real del inventario de Cargo; sin
-- Cargo dice "field" (modo degradado: gratis, con cooldown que el server aplica — el
-- cooldown no viaja en el snapshot, así que el rechazo llega por chat, no gris acá).
local function ConstruirBoton(padre, kind, etiqueta)
    local b = vgui.Create("DButton", padre)
    b:Dock(LEFT)
    b:DockMargin(0, 0, 6, 0)
    b:SetWide(126)

    b.Think = function(self)
        local n = ContarItem(Config.TREATMENTS[kind].item)
        local zona = zonaSel or "torso"
        local puede = true

        if n == nil then
            self:SetText(etiqueta .. " (field)")
        else
            self:SetText(string.format("%s (%d)", etiqueta, n))
            puede = n > 0
        end

        -- Quitar un torniquete puesto no cuesta ítem (§7): el botón queda vivo aunque
        -- no lleve ninguno encima.
        if kind == "tourniquet" then
            if HUD.ZoneData(zona).tq then
                self:SetText("Remove tourniquet")
                puede = true
            elseif not Config.EXTREMITIES[zona] then
                puede = false -- solo extremidades
            end
        end

        if HUD.Treatment() ~= nil then puede = false end -- uno a la vez (§7)
        self:SetEnabled(puede)
    end

    b.DoClick = function()
        MandarIntent(kind, kind == "bloodbag" and "" or (zonaSel or "torso"))
    end

    return b
end

local function Abrir()
    if IsValid(frame) then frame:Remove() end
    if not Config.Enabled() then
        chat.AddText("Coagulant is disabled.")
        return
    end

    zonaSel = ZonaInicial()

    frame = vgui.Create("DFrame")
    frame:SetSize(600, 430)
    frame:Center()
    frame:SetTitle("Medical")
    frame:MakePopup()
    frame.Paint = function(_, w, h)
        surface.SetDrawColor(COL_FONDO)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(70, 70, 75)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- La sangre no es de ninguna zona: va en la cabecera del menú
        local sangre = HUD.Blood()
        local crit = sangre < Config.BLOOD_CRITICAL
        draw.SimpleText(string.format("Blood: %d%%", math.floor(sangre)), "DermaDefaultBold",
            w - 14, 6, crit and COL_ALERTA or COL_TENUE, TEXT_ALIGN_RIGHT)
    end

    local cuerpo = vgui.Create("DPanel", frame)
    cuerpo:Dock(FILL)
    cuerpo:DockMargin(8, 4, 8, 4)
    cuerpo.Paint = nil

    ConstruirSilueta(cuerpo)
    ConstruirDetalle(cuerpo)

    local pie = vgui.Create("DPanel", frame)
    pie:Dock(BOTTOM)
    pie:SetTall(30)
    pie:DockMargin(8, 0, 8, 8)
    pie.Paint = nil

    ConstruirBoton(pie, "bandage", "Bandage")
    ConstruirBoton(pie, "tourniquet", "Tourniquet")
    ConstruirBoton(pie, "medkit", "Medkit")
    ConstruirBoton(pie, "bloodbag", "Blood Bag")

    local cancelar = vgui.Create("DButton", pie)
    cancelar:Dock(FILL)
    cancelar:SetText("Cancel treatment")
    cancelar.Think = function(self) self:SetEnabled(HUD.Treatment() ~= nil) end
    cancelar.DoClick = function()
        net.Start(MSG_CANCEL)
        net.SendToServer()
    end
end

concommand.Add("coagulant_menu", Abrir, nil,
    "Open the medical menu (click a body zone, then a treatment)")

-- Tecla directa (§10: convar de cliente propia con su DBinder en el tab Q). El binder
-- del tab escribe esta convar; el default es la M porque no la usa ningún bind del
-- juego base.
COAGULANT.CV_KEY_MENU = CreateClientConVar("coagulant_key_menu", tostring(KEY_M), true, false,
    "Key that opens the medical menu (0 = unbound; bind it from the Q tab)")

-- Poleo de input.IsButtonDown en Think con detector de flanco, NO PlayerButtonDown:
-- ese hook no dispara client-side en singleplayer (quirk del engine), así que la
-- tecla parecía muerta con el juego local (ronda 7: el bind "no funcionó" — el
-- binder del tab escribía bien la convar; el que nunca corría era el lector).
-- Patrón ya pagado por Cargo con su tecla I (corpus_cargo_ui.lua). El guard de foco
-- (vgui.GetKeyboardFocus() == nil) evita robar la tecla mientras se escribe en el
-- chat; con el menú abierto el foco es del frame (MakePopup), así que la tecla solo
-- ABRE — el cierre sigue siendo la X del DFrame (pasarla a toggle es decisión de
-- diseño del autor, anotada en §10).
--
-- El guard de cursor (mini-ronda 8): al elegir tecla en el binder del tab Q, la tecla
-- recién elegida sigue físicamente abajo con el spawnmenu en pantalla — el binder la
-- captura por key-trapping pero la convar ya cambió, y sin este guard el poleo la
-- veía como flanco válido y desplegaba el menú ahí mismo. Vale JUSTAMENTE porque la
-- tecla solo abre: si algún día pasa a toggle, este guard se revisa (es el que volvía
-- inalcanzable el cierre en el slice 4).
local teclaAbajo = false
hook.Add("Think", "corpus_coagulant_medmenu_key", function()
    local tecla = COAGULANT.CV_KEY_MENU:GetInt()
    if tecla <= 0 then teclaAbajo = false return end

    local abajo = input.IsButtonDown(tecla)
    if abajo and not teclaAbajo
        and not gui.IsGameUIVisible()
        and not vgui.CursorVisible()
        and vgui.GetKeyboardFocus() == nil then
        Abrir()
    end
    teclaAbajo = abajo
end)

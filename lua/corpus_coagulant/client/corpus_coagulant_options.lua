-- corpus_coagulant_options.lua — tab único del menú Q (CLIENT)
-- Una sola entrada vía la primitiva de Corpus (Q → Utilities → Corpus →
-- Coagulant). Layout manual (DLabel apilados), patrón validado en ADS/Caliber.
-- SCAFFOLD: el tab solo declara el estado del módulo y la detección de
-- soft-deps; los ajustes reales llegan con Block 3.

local COAGULANT = Corpus.GetModule("coagulant")

Corpus.UI.RegisterTab("coagulant", "Coagulant", function(panel)
    -- Strings de cara al jugador en inglés (idioma del mod).
    local titulo = vgui.Create("DLabel", panel)
    titulo:SetText("Coagulant — player medical (scaffold)")
    titulo:SetFont("DermaDefaultBold")
    titulo:SetDark(true)
    titulo:Dock(TOP)
    titulo:DockMargin(8, 8, 8, 4)
    titulo:SizeToContents()

    local cuerpo = vgui.Create("DLabel", panel)
    cuerpo:SetText("Zone wounds, bleeding, vitals and treatment (ACE3-style).\nDomain design (Block 3) not landed yet: no gameplay effect.")
    cuerpo:SetDark(true)
    cuerpo:SetWrap(true)
    cuerpo:SetAutoStretchVertical(true)
    cuerpo:Dock(TOP)
    cuerpo:DockMargin(8, 0, 8, 8)

    -- Detección de soft-deps en el momento de construir el panel (lazy-check,
    -- CORPUS_Architecture.md §6.a) — el spawnmenu se abre bien después del boot.
    local deps = vgui.Create("DLabel", panel)
    deps:SetText(string.format(
        "Detected modules — Caliber: %s | Cargo: %s",
        Corpus.HasModule("caliber") and "yes" or "no",
        Corpus.HasModule("cargo") and "yes" or "no"
    ))
    deps:SetDark(true)
    deps:Dock(TOP)
    deps:DockMargin(8, 0, 8, 8)
    deps:SizeToContents()
end)

-- corpus_coagulant_options.lua — tab único del menú Q (CLIENT)
-- Coagulant_Architecture.md §10-§11. Una sola entrada vía la primitiva de Corpus
-- (Q → Utilities → Corpus → Coagulant), sobre el panel de formulario del spawnmenu
-- (p:Help/p:CheckBox/p:Button) — mismo patrón que el tab de Cargo.
--
-- Slice 4: el tab deja de ser el cartel del scaffold y pasa a ser el panel de ajustes
-- real (convars de cliente y de server, bind del menú médico, comandos de dev).

local COAGULANT = Corpus.GetModule("coagulant")

local function ConstruirTab(p)
    p:Help("Coagulant — player medical: zone wounds, bleeding, vitals and treatment.")

    p:Button("Open the medical menu").DoClick = function()
        RunConsoleCommand("coagulant_menu")
    end

    -- Binder: se hace clic y se aprieta la tecla deseada (escribe coagulant_key_menu).
    p:Help("Medical menu key:")
    local binder = vgui.Create("DBinder", p)
    binder:SetTall(30)
    local cvKey = GetConVar("coagulant_key_menu")
    if cvKey then binder:SetValue(cvKey:GetInt()) end
    binder.OnChange = function(_, num)
        RunConsoleCommand("coagulant_key_menu", tostring(num))
    end
    p:AddItem(binder)
    p:Help("Console alternative: bind <key> coagulant_menu")

    p:Help("Client")
    p:CheckBox("Wound silhouette HUD", "coagulant_hud")
    p:Help("The critical-blood overlay is never hidden: it is vital information, not decoration.")

    -- Las de server son REPLICADAS: el checkbox las escribe solo si el cliente tiene
    -- derechos (en un listen server, el host los tiene). Se muestran igual — que un
    -- ajuste exista y no se vea es peor que verlo y que el server lo rechace.
    p:Help("Server (replicated convars; changing them needs server rights)")
    p:CheckBox("Coagulant enabled", "coagulant_enabled")
    p:CheckBox("Leg wounds slow you down (limp)", "coagulant_debuff_legs")
    p:CheckBox("Arm wounds sway your aim", "coagulant_debuff_arms")
    p:CheckBox("Head wounds darken your vision", "coagulant_debuff_head")
    p:CheckBox("Log wounds and critical transitions to console", "coagulant_debug")
    p:Help("Balance multipliers: coagulant_bleed_scale, coagulant_regen_scale, coagulant_hpdrain_scale (1.0 = default).")

    -- Detección de soft-deps EN EL MOMENTO de construir el panel (lazy-check): el
    -- spawnmenu se abre mucho después del boot, así que acá el dato ya es real.
    p:Help("Detected modules")
    p:Help(string.format("Caliber: %s  |  Cargo: %s",
        Corpus.HasModule("caliber") and "yes — enriched hit location when its Block 3 lands"
            or "no — hit location falls back to the engine hitgroup",
        Corpus.HasModule("cargo") and "yes — medical items and the blood bar on its status panel"
            or "no — treatment runs in degraded mode (free, with a cooldown)"))

    p:Help("Verification")
    p:Help("coagulant_selftest — self-test in this realm. coagulant_status — blood, wounds, debuffs and tourniquet clocks. coagulant_dev_give — test medical kit (needs Cargo). coagulant_setblood <n> · coagulant_bandage — debug (admin).")
end

Corpus.UI.RegisterTab("coagulant", "Coagulant", ConstruirTab)

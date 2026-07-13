-- corpus_coagulant_items.lua — ítems médicos contra el framework de Cargo (SERVER)
-- Patrón del contrato de ítems generalizado (CORPUS_Architecture.md §5): Cargo
-- posee el contenedor (grid, peso, persistencia); Coagulant posee la semántica
-- (qué hace la venda al usarse). Cargo es SOFT-DEP: se detecta vía el registro,
-- nunca se asume — sin Cargo, el tratamiento cae a una vía mínima propia
-- (concommand de debug abajo; la vía real por world-entity es diseño de Block 3).

local COAGULANT = Corpus.GetModule("coagulant")

-- Se registra en la ready barrier: corre una vez, con todos los módulos presentes
-- ya registrados (CORPUS_Architecture.md §6.b). Lazy-check + degradación honesta.
Corpus.OnReady(function()
    local cargo = Corpus.GetModule("cargo")
    if cargo == nil then
        Corpus.Log("coagulant", "Cargo no presente: ítems médicos apagados (degradación honesta)")
        return
    end

    -- Strings de cara al jugador en inglés (idioma del mod). El peso viene del
    -- estándar del ecosistema (venda ~0.1 kg, §5 de la arquitectura de Corpus).
    cargo.Items.Register({
        id       = "corpus_coagulant_bandage",
        name     = "Bandage",
        weight   = 0.1,
        class    = "stackable",
        category = "medical",
        onUse    = function(ply)
            -- lógica de curación: dominio de Coagulant, no de Cargo
            return COAGULANT.ApplyBandage(ply)
        end,
    })

    Corpus.Log("coagulant", "ítems médicos registrados contra Cargo (1 def)")
end)

-- Vía mínima de debug sin inventario: aplica el tratamiento directo. Sirve para
-- verificar el slice aunque Cargo no esté montado. Solo admin.
concommand.Add("coagulant_bandage", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local objetivo = IsValid(ply) and ply or player.GetAll()[1]
    if not IsValid(objetivo) then
        Corpus.Log("coagulant", "coagulant_bandage: no hay jugador objetivo")
        return
    end
    COAGULANT.ApplyBandage(objetivo)
end)

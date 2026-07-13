-- corpus_coagulant_items.lua — ítems médicos contra el framework de Cargo (SHARED)
-- Patrón del contrato de ítems generalizado (CORPUS_Architecture.md §5): Cargo
-- posee el contenedor (grid, peso, persistencia); Coagulant posee la semántica
-- (qué hace la venda al usarse). Cargo es SOFT-DEP: se detecta vía el registro,
-- nunca se asume — sin Cargo, el tratamiento cae a la vía degradada (arquitectura
-- §7) y este archivo solo loguea.
--
-- REALM: SHARED a propósito — Cargo NO sincroniza defs por net: su grid cliente
-- renderiza desde las defs locales (igual que su dev kit, "both realms"). Con el
-- registro solo en server, el ítem existe en el inventario pero es invisible en
-- la UI (pagado en la verificación en juego del 2026-07-13, punto E). onUse corre
-- solo en server igual (lo invoca Cargo server-side).

local COAGULANT = Corpus.GetModule("coagulant")

-- Se registra en la ready barrier: corre una vez POR REALM, con todos los módulos
-- presentes ya registrados (CORPUS_Architecture.md §6.b). Lazy-check + degradación.
Corpus.OnReady(function()
    local cargo = Corpus.GetModule("cargo")
    if cargo == nil then
        Corpus.Log("coagulant", "Cargo no presente: ítems médicos apagados (degradación honesta)")
        return
    end

    -- Strings de cara al jugador en inglés (idioma del mod). El set completo de 4
    -- ítems (torniquete, kit, bolsa de sangre) llega con el slice 2 (§7).
    cargo.Items.Register({
        id       = "corpus_coagulant_bandage",
        name     = "Bandage",
        weight   = 0.1,
        class    = "stackable",
        category = "medical",
        onUse    = function(ply)
            -- lógica de curación: dominio de Coagulant, no de Cargo. Consumo
            -- instantáneo interim: el slice 2 lo vuelve tiempo de aplicación con
            -- consumo al completar (onUse -> false + TakeItem, arquitectura §7).
            return COAGULANT.ApplyBandage(ply)
        end,
    })

    Corpus.Log("coagulant", "ítems médicos registrados contra Cargo (1 def, "
        .. (SERVER and "server" or "client") .. ")")
end)

-- Vía mínima de debug sin inventario: aplica el tratamiento directo. Sirve para
-- verificar el slice aunque Cargo no esté montado. Solo admin, solo server.
if SERVER then
    concommand.Add("coagulant_bandage", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local objetivo = IsValid(ply) and ply or player.GetAll()[1]
        if not IsValid(objetivo) then
            Corpus.Log("coagulant", "coagulant_bandage: no hay jugador objetivo")
            return
        end
        COAGULANT.ApplyBandage(objetivo)
    end)
end

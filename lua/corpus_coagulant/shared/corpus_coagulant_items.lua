-- corpus_coagulant_items.lua — ítems médicos contra el framework de Cargo (SHARED)
-- Patrón del contrato de ítems generalizado (CORPUS_Architecture.md §5): Cargo
-- posee el contenedor (grid, peso, persistencia); Coagulant posee la semántica.
-- Cargo es SOFT-DEP: se detecta vía el registro, nunca se asume.
--
-- REALM: SHARED a propósito — Cargo NO sincroniza defs por net: su grid cliente
-- renderiza desde las defs locales (pagado en juego el 2026-07-13, punto E).
-- El onUse TAMBIÉN se registra en ambos realms: la UI de Cargo exige
-- isfunction(def.onUse) client-side para mostrar "Use" y el quick bind
-- (corpus_cargo_ui.lua) — un onUse solo-server deja el ítem visible pero
-- inusable. La closure es realm-safe: solo toca ApplyTreatment al INVOCARSE,
-- y Cargo únicamente la invoca en server.
--
-- CONSUMO AL COMPLETAR (arquitectura §7): el onUse devuelve SIEMPRE false (Cargo
-- no consume) y solo inicia el tratamiento; corpus_coagulant_treatment.lua hace
-- TakeItem al terminar la aplicación. onUse corre solo en server.

local COAGULANT = Corpus.GetModule("coagulant")

-- Fabrica el onUse de un tratamiento: inicia y avisa al jugador si no pudo.
local function UsarTratamiento(kind)
    return function(ply)
        local ok, err = COAGULANT.ApplyTreatment(ply, kind)
        if not ok and err ~= nil then ply:ChatPrint(err) end
        return false -- Cargo nunca consume acá: se consume al COMPLETAR
    end
end

-- Se registra en la ready barrier: corre una vez POR REALM, con todos los módulos
-- presentes ya registrados (CORPUS_Architecture.md §6.b). Strings de cara al
-- jugador en inglés (idioma del mod). Set v1 completo (arquitectura §7).
Corpus.OnReady(function()
    local cargo = Corpus.GetModule("cargo")
    if cargo == nil then
        Corpus.Log("coagulant", "Cargo no presente: ítems médicos apagados (degradación honesta)")
        return
    end

    -- MODELO POR DEFECTO propio (enmienda del autor 2026-08-05, revierte la
    -- decisión del 2026-07-23 que los dejaba sin `model`). Antes caían a la
    -- cajita de cartón del drop de Cargo; ahora traen su modelo.
    --
    -- La razón por la que NO lo tenían sigue siendo válida y sigue cubierta:
    -- que un addon de contenido pueda vestirlos a su setting. Eso NO se pierde
    -- al declarar un default, porque `Cargo.Items.SetModel` **pisa el modelo
    -- declarado y se re-aplica en cada registro** (corpus_cargo_items.lua, el
    -- bloque `_modelOverrides` de `Register`) — o sea que corpus-stalker les
    -- sigue poniendo los botiquines de la Zona sin tocar una línea de acá.
    -- Lo que cambia es solo qué se ve cuando NADIE sustituye: antes una caja
    -- de cartón, ahora el ítem.
    --
    -- Los .mdl son ports propios de assets CC BY 4.0 de Sketchfab
    -- (`Medical Supplies Collection` de Miguel Adão / @theauditor). El crédito
    -- es obligación de la licencia y vive en docs/CREDITOS.md; hay 18 modelos
    -- en `models/corpus_coagulant/` y estas defs usan tres.

    cargo.Items.Register({
        id       = "corpus_coagulant_bandage",
        name     = "Bandage",
        model    = "models/corpus_coagulant/bandage.mdl",
        weight   = 0.1,
        class    = "stackable",
        category = "medical",
        trivia   = "Stops light and medium bleeding. Applies over 4 seconds.",
        onUse    = UsarTratamiento("bandage"),
    })

    cargo.Items.Register({
        id       = "corpus_coagulant_tourniquet",
        -- SIN modelo, y no por olvido: en los 18 portados NO HAY un torniquete.
        -- El candidato que parecía serlo (`Lines`) resultó, al renderizarlo,
        -- ser dos carretes de sutura con aguja. corpus-stalker llegó a la misma
        -- conclusión con sus propios packs el 2026-07-23 ("sin modelo coherente
        -- identificado"). Cae a la cajita hasta que aparezca uno.
        name     = "Tourniquet",
        weight   = 0.2,
        class    = "unique",
        category = "medical",
        trivia   = "Stops all bleeding on one limb while applied. Leaving it on too long damages the limb. Not consumed.",
        onUse    = UsarTratamiento("tourniquet"),
    })

    cargo.Items.Register({
        id       = "corpus_coagulant_medkit",
        name     = "Medkit",
        -- `firstaidkit` (16 cm) y no `medkit_large` (30 cm): este es un ítem
        -- que se lleva encima. El grande queda como prop de escenario.
        model    = "models/corpus_coagulant/firstaidkit.mdl",
        weight   = 0.5,
        class    = "stackable",
        category = "medical",
        trivia   = "Restores health over 10 seconds. Does not stop bleeding or restore blood.",
        onUse    = UsarTratamiento("medkit"),
    })

    cargo.Items.Register({
        id       = "corpus_coagulant_bloodbag",
        name     = "Blood Bag",
        model    = "models/corpus_coagulant/bloodbag.mdl",
        weight   = 0.3,
        class    = "stackable",
        category = "medical",
        trivia   = "Restores blood volume over 8 seconds. Stop the bleeding first.",
        onUse    = UsarTratamiento("bloodbag"),
    })

    Corpus.Log("coagulant", "ítems médicos registrados contra Cargo (4 defs, "
        .. (SERVER and "server" or "client") .. ")")
end)

-- Vía mínima de debug sin inventario: efecto venda INSTANTÁNEO (no el flujo real
-- con tiempo — para eso está ApplyTreatment/el ítem). Solo admin, solo server.
if SERVER then
    concommand.Add("coagulant_bandage", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local objetivo = IsValid(ply) and ply or player.GetAll()[1]
        if not IsValid(objetivo) then
            Corpus.Log("coagulant", "coagulant_bandage: no hay jugador objetivo")
            return
        end
        -- Misma selección que el flujo real (COA-37): herida ABIERTA, sangre o no —
        -- si el debug siguiera mirando solo el sangrado, mentiría sobre lo que hace
        -- la venda de verdad.
        local zona = COAGULANT.WorstOpenZone(objetivo)
        if zona == nil then
            Corpus.Log("coagulant", "coagulant_bandage: sin heridas abiertas")
            return
        end
        COAGULANT.BandageEffect(objetivo, zona)
        Corpus.Log("coagulant", "venda (debug, instantánea) sobre " .. objetivo:Nick()
            .. " en " .. zona)
    end)
end

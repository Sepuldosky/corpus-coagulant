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
    -- Los .mdl son ports propios de assets CC BY 4.0 de Sketchfab, de tres
    -- packs: `Medical Supplies Collection` de Miguel Adão (@theauditor),
    -- `Medical First Aid Emergency Kit` de RayznGames y `Simple Pain Pills` de
    -- Blender3D. El crédito es obligación de la licencia y vive en
    -- docs/CREDITOS.md; hay 19 modelos en `models/corpus_coagulant/` y estas
    -- defs usan tres. Inventario completo en docs/ASSETS.md.

    -- PRECIO (`value`), 2026-08-18. SIN ÉL NO SE COMERCIAN: `Trade.IsTradeable`
    -- exige `isnumber(def.value) and def.value > 0`, y en Cargo la AUSENCIA de
    -- `value` significa "no está a la venta", NO "gratis" (contrato 13 de su
    -- CLAUDE.md). Las cuatro defs nacieron sin él, así que hasta hoy un trader
    -- las LISTABA y el server se negaba a moverlas — el mismo agujero que se
    -- midió en las 15 defs de comida de Craving, que nadie había mirado de este
    -- lado. Salió al escribir los dos traders de corpus-stalker (su roadmap [1]).
    --
    -- MÉTODO, el mismo que se usó para la comida: anclar en el precio real del
    -- objeto que el ítem representa, en USD de EE.UU. Y la etiqueta importa —
    -- **los cuatro son ESTIMACIONES (est.)**, no series publicadas: son precios
    -- de retail/adquisición típicos, no un índice citable como el FRED que
    -- respalda al pan y a la leche. Presentar un número estimado como medido es
    -- exactamente lo que este proyecto persigue en todos lados.
    --
    --   venda      8   rollo de gasa compresiva de trauma, ~5-8 USD  (est.)
    --   torniquete 35  CAT genuino, ~32-35 USD; REUSABLE (unique, no se
    --                  consume), y eso es la mitad de por qué es el más caro
    --                  de los tres baratos                            (est.)
    --   medkit     50  botiquín grande equipado, ~45-60 USD          (est.)
    --   bolsa de   220 una unidad de glóbulos rojos: costo de adquisición
    --   sangre         hospitalario en EE.UU., ~215-250 USD          (est.)
    --   analgésico 10  frasco de venta libre, ~8-12 USD; alta del
    --                  2026-08-25 con el tramo del dolor            (est.)

    --
    -- LO QUE HAY QUE SABER ANTES DE LEERLOS COMO "BARATOS": quedan POR DEBAJO
    -- de los suministros HL2 del propio Cargo (`cargo_hl2_healthkit` 150,
    -- `cargo_hl2_healthvial` 60), que no salen de un precio real sino de la
    -- banda de sus ítems dev. Es la MISMA asimetría que la comida tiene contra
    -- la munición (2-12 contra 8-900), y tiene la misma salida ya escrita y
    -- pendiente de ratificar: el multiplicador de precio por categoría de Cargo
    -- (su roadmap 61, `cargo_value_mult_<id>` replicada). Estos números entran
    -- igual y ese multiplicador los escala después; NO se compensa acá
    -- inflándolos, porque entonces el multiplicador escalaría una mentira.
    --
    -- El spread se comporta en los cuatro: con el piso de 1 de `UnitPrice`, un
    -- `value` de 2 ya vende a 2 y recompra a 1, y el más barato de acá es 8.

    cargo.Items.Register({
        id       = "corpus_coagulant_bandage",
        name     = "Bandage",
        -- UN rollo de gasa, no tres (enmienda del autor, 2026-08-08). La rama
        -- `Bandages` del pack son tres rollos sueltos y el primer port se los
        -- llevó los tres: el ítem se veía como «tres vendas juntas». El .qc
        -- ahora corta con `--object Bandage2` y normaliza a 9 cm — el porte que
        -- ocupaban los tres, así que en pantalla no se achicó nada.
        model    = "models/corpus_coagulant/bandage.mdl",
        weight   = 0.1,
        value    = 8,     -- rollo de gasa de trauma (est.)
        class    = "stackable",
        category = "medical",
        trivia   = "Stops light and medium bleeding. Applies over 4 seconds.",
        onUse    = UsarTratamiento("bandage"),
    })

    cargo.Items.Register({
        id       = "corpus_coagulant_tourniquet",
        -- SIN modelo, y no por olvido: en los 19 portados NO HAY un torniquete.
        -- El candidato que parecía serlo (`Lines`) resultó, al renderizarlo,
        -- ser dos carretes de sutura con aguja. corpus-stalker llegó a la misma
        -- conclusión con sus propios packs el 2026-07-23 ("sin modelo coherente
        -- identificado"). Cae a la cajita hasta que aparezca uno.
        name     = "Tourniquet",
        weight   = 0.2,
        value    = 35,    -- CAT genuino, y no se consume (est.)
        class    = "unique",
        category = "medical",
        trivia   = "Stops all bleeding on one limb while applied. Leaving it on too long damages the limb. Not consumed.",
        onUse    = UsarTratamiento("tourniquet"),
    })

    cargo.Items.Register({
        id       = "corpus_coagulant_medkit",
        name     = "Medkit",
        -- `medkit_large_closed` y no `firstaidkit` (enmienda del autor,
        -- 2026-08-08: «first_aid_kit es muy feo»). El blanco se descartó por
        -- estética, pero de paso se va con él un problema anotado: lleva la
        -- CRUZ ROJA, emblema protegido por los Convenios de Ginebra, y su pack
        -- no traía variante — era una decisión pendiente si esto se publica al
        -- Workshop. El naranja sí tenía variante y este .mdl usa la segura.
        --
        -- El CERRADO y no `medkit_large` (el abierto): es un ítem que se lleva
        -- encima, así que se ve cerrado, y además el abierto son 48.278 tris
        -- contra 3.590 — 13×, el 35 % de todo el set de 19 modelos. El abierto
        -- queda como prop de escenario, que es para lo que se portó.
        model    = "models/corpus_coagulant/medkit_large_closed.mdl",
        weight   = 0.5,
        value    = 50,    -- botiquín grande equipado (est.)
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
        value    = 220,   -- una unidad de glóbulos rojos (est.)
        class    = "stackable",
        category = "medical",
        trivia   = "Restores blood volume over 8 seconds. Stop the bleeding first.",
        onUse    = UsarTratamiento("bloodbag"),
    })

    -- ANALGÉSICO ORAL (§17, COA-52 — bajada del 2026-08-25). Quinta def del set, y
    -- la primera desde el v1. Es el primer CONSUMIDOR EN JUEGO del dolor: sin él el
    -- stat existe y nadie lo puede mover, así que su pasada en juego sería por
    -- consola y el tramo quedaría acreditado sólo offline.
    --
    -- Los cinco campos que un ítem necesita y que COA-52 NO especificaba están
    -- votados aparte y anotados como tales — son diseño, no detalle (COA-28):
    --   clase   `stackable`, no `unique`. El único `unique` del set es el torniquete
    --           y su razón no aplica acá: el torniquete se OCUPA mientras está
    --           puesto y vuelve al quitarlo; un frasco se consume.
    --   peso    0.1, el mismo de la venda — el escalón más liviano del set.
    --   tiempo  3 s, entre el torniquete (2) y la venda (4): tragarse unas pastillas
    --           es el gesto más corto salvo apretar una banda.
    --   value   10 — frasco de venta libre, ~8-12 USD (est.), MISMO método y MISMA
    --           etiqueta que los otros cuatro: es una estimación, no una serie.
    --   can()   la puerta `pain > PAIN_ANALGESIC_AT`, que NO es un número nuevo: es
    --           el `pain > 10` que el spec v5 ya tenía escrito para la morfina. Vive
    --           en el motor de tratamiento (ApplyTreatment), como los otros cuatro.
    --
    -- MODELO: `pain_pills` (frasco de analgésicos, 732 tris). Ya estaba portado y sin
    -- def desde el 2026-08-05 — ASSETS.md lo listaba justamente como el candidato
    -- para el día que el analgésico se abriera. Que el modelo exista no creó el ítem
    -- (COA-28): lo creó el voto; el modelo sólo evitó tener que buscar uno.
    --
    -- NO ENTRA LA MORFINA, y no es un olvido: PAIN_SUPPRESS.morphine = 80 está en la
    -- tabla porque COA-52 la votó, pero su ítem arrastra la sobredosis y la naloxona,
    -- que son del tramo del catálogo (COA-50). Acá entra la forma mínima.
    cargo.Items.Register({
        id       = "corpus_coagulant_painkillers",
        name     = "Painkillers",
        model    = "models/corpus_coagulant/pain_pills.mdl",
        weight   = 0.1,
        value    = 10,    -- frasco de venta libre (est.)
        class    = "stackable",
        category = "medical",
        trivia   = "Dulls pain for a few minutes. Does not close wounds or stop bleeding.",
        onUse    = UsarTratamiento("painkillers"),
    })


    Corpus.Log("coagulant", "ítems médicos registrados contra Cargo (5 defs, "

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

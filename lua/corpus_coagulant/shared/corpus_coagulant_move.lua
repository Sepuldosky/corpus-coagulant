-- corpus_coagulant_move.lua — aplicación de la cojera en el pipeline de movimiento (SHARED)
-- Coagulant_Architecture.md §6 (piernas → cojera). Contrato #6 del CLAUDE.md:
-- Coagulant NUNCA pisa SetWalkSpeed/SetRunSpeed.
--
-- POR QUÉ UN HOOK Move Y NO SetWalkSpeed: Cargo re-aplica su penalización de peso
-- sobre walk/run en SU propio hook Move cada tick (corpus_cargo_movecompat.lua,
-- nacido de que "better movement v2" re-estampa las velocidades cada tick). Dos
-- módulos escribiendo las mismas propiedades se pisan y el último gana. Escalando
-- el MaxSpeed del move data, en cambio, ambos COMPONEN multiplicativamente sobre lo
-- que haya dejado el gamemode/los mods: final = base × cargo_speed_mult × coagulant_speed_mult.
--
-- SHARED porque Move es PREDICHO: si el cliente no escala el mismo número que el
-- server, el jugador hace rubber-band. Por eso el multiplicador viaja en un NW2Float
-- (el server lo publica en corpus_coagulant_debuffs.lua; acá solo se lee) y las
-- convars que lo gobiernan son replicadas — ambos realms calculan idéntico.

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

hook.Add("Move", "corpus_coagulant_limp", function(ply, mv)
    if not Config.Enabled() or not Config.cv_debuff_legs:GetBool() then return end

    local mult = ply:GetNW2Float("coagulant_speed_mult", 1)
    if mult >= 1 then return end -- sano: ni tocamos el move data

    -- Piso absoluto: componiendo con el multiplicador de peso de Cargo, el producto
    -- puede acercarse a cero. math.min(base, ...) para no SUBIR la velocidad de un
    -- jugador que otro mod dejó por debajo del piso a propósito (freeze, agarre).
    local base = mv:GetMaxSpeed()
    mv:SetMaxSpeed(math.max(base * mult, math.min(base, Config.LIMP_SPEED_FLOOR)))
end)

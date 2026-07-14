-- corpus_coagulant_debuffs.lua — debuffs zonales: scores y cojera (SERVER)
-- Coagulant_Architecture.md §6. El server es la autoridad de los scores y publica el
-- multiplicador de cojera por NW2 (lo APLICA el hook Move compartido, shared/
-- corpus_coagulant_move.lua).
--
-- Los otros dos debuffs son de CLIENTE (client/corpus_coagulant_hud.lua), y no por
-- comodidad:
--   · Sway de brazos (§6, reescrito tras la ronda 5): es una deriva CONTINUA de la
--     mira. Mover la puntería sin jitter obliga a tocar el usercmd antes de que
--     salga (hook CreateMove, cliente); hacerlo desde el server pelearía contra el
--     mouse del jugador. El score de brazos viaja en el snapshot, con la isquemia
--     incluida, así que el cliente calcula el MISMO número que este archivo.
--   · Visión de cabeza: es pintado puro.
--
-- Tick propio de 0.5 s, separado del de sangrado (1 s): la isquemia entra y sale SOLA
-- por paso del tiempo (§7), así que los scores no se pueden refrescar solo desde los
-- eventos de herida/tratamiento.

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

-- Score sumado de un par de zonas (§6: piernas juntas, brazos juntos).
-- GetZoneScore ya incorpora las tratadas a la mitad y el piso de isquemia (§7).
local function ScorePar(ply, zonaA, zonaB)
    return COAGULANT.GetZoneScore(ply, zonaA) + COAGULANT.GetZoneScore(ply, zonaB)
end

function COAGULANT.GetLegScore(ply)  return ScorePar(ply, "left_leg", "right_leg") end
function COAGULANT.GetArmScore(ply)  return ScorePar(ply, "left_arm", "right_arm") end

-- Recalcula y publica el multiplicador de cojera. Off-contract: la llaman el tick,
-- el spawn y el selftest (que no puede esperar medio segundo). Solo escribe el NW2
-- cuando el valor cambió — un NW2 se replica a TODOS los clientes en cada escritura.
function COAGULANT.RefreshSpeed(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return 1 end

    local mult = 1
    if Config.Enabled() and Config.cv_debuff_legs:GetBool() then
        mult = Config.LimpMult(COAGULANT.GetLegScore(ply))
    end

    if st._speedMult ~= mult then
        st._speedMult = mult
        ply:SetNW2Float("coagulant_speed_mult", mult)
    end
    return mult
end

timer.Create("corpus_coagulant_debuffs_tick", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            -- la cojera se refresca SIEMPRE, incluso deshabilitada: apagar la convar
            -- tiene que devolver el multiplicador a 1, no congelarlo
            COAGULANT.RefreshSpeed(ply)
        end
    end
end)

-- Spawn = cuerpo nuevo (§2): el NW2 de la cojera se limpia YA, sin esperar al tick
-- (medio segundo de cojera heredada al reaparecer se siente como un bug).
hook.Add("PlayerSpawn", "corpus_coagulant_debuffs_spawn", function(ply)
    ply:SetNW2Float("coagulant_speed_mult", 1)
end)

-- corpus_coagulant_debuffs.lua — debuffs zonales: cojera y sway (SERVER)
-- Coagulant_Architecture.md §6. El server es la autoridad de los scores; publica el
-- multiplicador de cojera por NW2 (lo APLICA el hook Move compartido, shared/
-- corpus_coagulant_move.lua) y produce el sway de brazos con ViewPunch.
--
-- El tercer debuff (cabeza → visión) es puramente CLIENTE: se pinta desde el
-- snapshot + el NW2 de sangre (client/corpus_coagulant_hud.lua). No hay nada que
-- calcular acá para él.
--
-- Tick propio de 0.5 s, separado del de sangrado (1 s): la isquemia entra y sale
-- SOLA por paso del tiempo (§7), así que los scores no se pueden refrescar solo
-- desde los eventos de herida/tratamiento. Medio segundo también le da al sway
-- resolución suficiente sobre su intervalo de 1.5-3 s.

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

-- Sway de brazos (§6): ViewPunch periódico, agnóstico al arma — funciona con
-- cualquier SWEP sin tocar su API (la integración fina con ARC9 queda diferida).
local function TickSway(ply, st)
    if not Config.cv_debuff_arms:GetBool() then
        st._nextSway = nil
        return
    end

    local score = COAGULANT.GetArmScore(ply)
    if score <= 0 then
        st._nextSway = nil -- sano: el próximo punch se reprograma al herirse
        return
    end

    if st._nextSway == nil then
        st._nextSway = CurTime() + math.Rand(Config.SWAY_MIN_S, Config.SWAY_MAX_S)
        return
    end
    if CurTime() < st._nextSway then return end

    -- Dirección aleatoria: el pulso no debe ser corregible por costumbre
    local amp = Config.SwayAmplitude(score)
    local ang = math.Rand(0, math.pi * 2)
    ply:ViewPunch(Angle(math.cos(ang) * amp, math.sin(ang) * amp, 0))

    st._nextSway = CurTime() + math.Rand(Config.SWAY_MIN_S, Config.SWAY_MAX_S)
end

timer.Create("corpus_coagulant_debuffs_tick", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local st = COAGULANT.GetState(ply)
            if st ~= nil then
                -- la cojera se refresca SIEMPRE, incluso deshabilitada: apagar la
                -- convar tiene que devolver el multiplicador a 1, no congelarlo
                COAGULANT.RefreshSpeed(ply)
                if Config.Enabled() then TickSway(ply, st) end
            end
        end
    end
end)

-- Spawn = cuerpo nuevo (§2): el NW2 de la cojera se limpia YA, sin esperar al tick
-- (medio segundo de cojera heredada al reaparecer se siente como un bug).
hook.Add("PlayerSpawn", "corpus_coagulant_debuffs_spawn", function(ply)
    ply:SetNW2Float("coagulant_speed_mult", 1)
end)

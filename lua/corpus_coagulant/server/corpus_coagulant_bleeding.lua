-- corpus_coagulant_bleeding.lua — timer de sangrado, regen y HP crítico (SERVER)
-- Coagulant_Architecture.md §4-§5, §9. Un solo timer de 1 s para todos los
-- jugadores (nunca Think). También publica el NW2 de sangre y despacha el
-- snapshot on-change al dueño.

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

local MSG_STATE = Corpus.Net.Register("coagulant", "state")

-- Snapshot compacto del estado clínico para el dueño (§9): se manda solo cuando
-- st.dirty (on-change), nunca por tick. El cliente lo consume desde el slice 4.
local function EnviarSnapshot(ply, st)
    local zonas = {}
    for zona, zdata in pairs(st.zones) do
        -- la isquemia entra en el snapshot porque el CLIENTE calcula con ella: el
        -- sway (§6) lee el score de brazos de acá, y sin este dato daría un número
        -- distinto al del server justo cuando el torniquete lleva rato puesto
        local isq = COAGULANT.IsIschemic(ply, zona)
        if #zdata.wounds > 0 or zdata.tourniquet or isq then
            local ws = {}
            for i, w in ipairs(zdata.wounds) do
                ws[i] = { t = w.type, s = w.severity, tr = w.treated or nil }
            end
            zonas[zona] = { w = ws, tq = zdata.tourniquet or nil, isq = isq or nil }
        end
    end
    local blob = util.Compress(util.TableToJSON({
        blood = math.Round(st.blood, 1),
        zones = zonas,
        treatment = st.treatment,
    }))
    net.Start(MSG_STATE)
    net.WriteUInt(#blob, 16)
    net.WriteData(blob, #blob)
    net.Send(ply)
end

-- Drenaje total de sangre del jugador en unidades/s (§4): suma de heridas no
-- tratadas de zonas sin torniquete, escalada por convar.
local function DrenajeTotal(st)
    local total = 0
    for _, zdata in pairs(st.zones) do
        if not zdata.tourniquet then
            for _, w in ipairs(zdata.wounds) do
                total = total + Config.BleedRate(w)
            end
        end
    end
    return total * Config.cv_bleed_scale:GetFloat()
end

local function TickJugador(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return end

    -- Sangre: drenaje o regeneración natural (§4)
    local drenaje = DrenajeTotal(st)
    if drenaje > 0 then
        st.blood = math.max(0, st.blood - drenaje)
        st.dirty = true
    elseif st.blood < Config.BLOOD_MAX then
        st.blood = math.min(Config.BLOOD_MAX,
            st.blood + Config.REGEN_PER_S * Config.cv_regen_scale:GetFloat())
        st.dirty = true
    end

    -- Cruce del umbral crítico, en ambas direcciones (§5, §8)
    local critica = st.blood < Config.BLOOD_CRITICAL
    if critica ~= st.critical then
        st.critical = critica
        hook.Run("Coagulant_BloodCritical", ply, critica)
        if Config.cv_debug:GetBool() then
            Corpus.Log("coagulant", "sangre " .. (critica and "CRÍTICA" or "estable")
                .. " en " .. ply:Nick() .. " (" .. math.Round(st.blood) .. ")")
        end
    end

    -- Drenaje de HP en crítico (§5): DMG_GENERIC del mundo, pasa por el pipeline
    -- normal del engine. _selfDrain evita que el core lo lea como herida nueva.
    local hpDrain = Config.HPDrainRate(st.blood) * Config.cv_hpdrain_scale:GetFloat()
    if hpDrain > 0 and ply:Alive() then
        st._selfDrain = true
        local dmg = DamageInfo()
        dmg:SetDamage(hpDrain)
        dmg:SetDamageType(DMG_GENERIC)
        dmg:SetAttacker(game.GetWorld())
        dmg:SetInflictor(game.GetWorld())
        ply:TakeDamageInfo(dmg)
        st._selfDrain = false
        if not ply:Alive() then
            ply:ChatPrint("You bled out.")
        end
    end

    ply:SetNW2Float("coagulant_blood", st.blood)

    if st.dirty then
        st.dirty = false
        EnviarSnapshot(ply, st)
    end
end

timer.Create("corpus_coagulant_tick", 1, 0, function()
    if not Config.Enabled() then return end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then TickJugador(ply) end
    end
end)

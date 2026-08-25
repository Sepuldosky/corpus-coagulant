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
        -- El dolor de la zona lo calcula EL SERVER y viaja como número (§17,
        -- COA-52, sexta colisión): el cliente NUNCA lo deriva. Bajo niebla (COA-44)
        -- la lista de heridas no va a poder viajar y el número sí, así que si el
        -- cliente lo dedujera habría DOS implementaciones de la misma magnitud, y
        -- divergirían justo al cambiar la convar.
        local p = COAGULANT.ZonePain(ply, zona)
        -- El predicado de COA-52: «aporta dolor ≠ 0, torniquete o isquemia». Una
        -- zona puede doler SIN herida activa —el caso de COA-49, y el de una zona
        -- cuyo único contenido sea una fractura— y con la condición vieja
        -- (`#wounds > 0`) no viajaría, dejando a la niebla sin qué pintar.
        --
        -- ⚠ HOY LAS DOS CONDICIONES SON EQUIVALENTES y hay que decirlo en vez de
        -- acreditarlo: toda herida de los cinco tipos vivos produce dolor > 0, así
        -- que ninguna zona con heridas deja de viajar por este cambio. Deja de ser
        -- equivalente el día que exista `frac`. Lo que sostiene la equivalencia es
        -- el check de FORMA del harness (PAIN_TYPE cubre todo WOUND_TYPES): sin él,
        -- un tipo nuevo sin fila de dolor sacaría su zona del snapshot en silencio.
        if p ~= 0 or zdata.tourniquet or isq then
            local ws = {}
            for i, w in ipairs(zdata.wounds) do
                ws[i] = { t = w.type, s = w.severity, tr = w.treated or nil }
            end
            zonas[zona] = { w = ws, tq = zdata.tourniquet or nil, isq = isq or nil,
                            p = math.Round(p) }
        end
    end
    local blob = util.Compress(util.TableToJSON({
        blood = math.Round(st.blood, 1),
        -- el PERCIBIDO, no el crudo (COA-52 D5): el síntoma es lo que el paciente
        -- sufre. La supresión vigente NO viaja — es capa de diagnóstico y este
        -- tramo no abre canales que la niebla todavía no sabe filtrar; se lee por
        -- consola con coagulant_status, que corre en el server.
        pain = math.Round(COAGULANT.GetPain(ply)),
        zones = zonas,
        treatment = st.treatment,
    }))

    net.Start(MSG_STATE)
    net.WriteUInt(#blob, 16)
    net.WriteData(blob, #blob)
    net.Send(ply)
end

-- Drenaje total de sangre del jugador en unidades/s (§4): suma de heridas no
-- tratadas de zonas sin torniquete, escalada por convar. La zona se pasa a
-- BleedRate: es donde el mult de zona (ZONE_BLEED_MULT) muerde de verdad.
local function DrenajeTotal(st)
    local total = 0
    for zona, zdata in pairs(st.zones) do
        if not zdata.tourniquet then
            for _, w in ipairs(zdata.wounds) do
                total = total + Config.BleedRate(w, zona)
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


    -- Supresión de dolor: decae sola en el MISMO tick de 1 s (§17, COA-52 D5). El
    -- decaimiento es lo que explica «se pasó el efecto», que una resta no explica —
    -- y es la única razón por la que la supresión se almacena: a un valor derivado
    -- no se le resta de forma persistente sin guardar la resta.
    --
    -- ⚠ SE ENSUCIA SÓLO SI EL NÚMERO SE MOVIÓ DE VERDAD, y las dos direcciones
    -- importan. El percibido cambia cuando la supresión decae aunque nadie toque una
    -- herida, así que sin ensuciar el cliente mostraría el dolor de hace minutos;
    -- pero ensuciar SIEMPRE convierte el emisor on-change de COA-16 en un emisor por
    -- segundo, y eso no da ningún error — da tráfico, multiplicado por jugador.
    if (st.painSuppress or 0) > 0 then
        local resto = math.max(0, st.painSuppress - Config.PAIN_SUPPRESS_DECAY_PER_S)
        if resto ~= st.painSuppress then
            st.painSuppress = resto
            st.dirty = true
        end
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

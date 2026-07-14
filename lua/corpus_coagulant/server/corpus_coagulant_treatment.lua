-- corpus_coagulant_treatment.lua — tratamiento con tiempo de aplicación (SERVER)
-- Coagulant_Architecture.md §7, §9. Server-authoritative: un tratamiento a la vez,
-- barra client-side desde el snapshot ({kind, endsAt, duration}), cancelación por
-- daño/salto/velocidad. CLAVE del contrato con Cargo: el consumo ocurre AL
-- COMPLETAR (el onUse de los ítems devuelve false y acá se hace TakeItem al
-- terminar, re-validando). Sin Cargo: modo degradado — tratamiento gratis con
-- cooldown (§7/§14).

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

local MSG_TREAT  = Corpus.Net.Register("coagulant", "treat")
local MSG_CANCEL = Corpus.Net.Register("coagulant", "cancel")

-- Zona automática según el tipo (§7): la peor herida sangrante compatible.
local function ZonaAuto(ply, kind)
    if kind == "medkit" or kind == "bloodbag" then return "torso" end -- no usa zona
    if kind == "tourniquet" then
        local st = COAGULANT.GetState(ply)
        local mejor, mejorSev = nil, 0
        for zona in pairs(Config.EXTREMITIES) do
            for _, w in ipairs(st.zones[zona].wounds) do
                if Config.BleedRate(w) > 0 and w.severity > mejorSev then
                    mejor, mejorSev = zona, w.severity
                end
            end
        end
        return mejor
    end
    return COAGULANT.WorstBleedingZone(ply)
end

-- Valida y arranca un tratamiento. zone nil = automática. -> ok, err
-- (err: string corta en inglés — llega al jugador vía ChatPrint desde onUse/net)
function COAGULANT.ApplyTreatment(ply, kind, zone)
    if not Config.Enabled() then return false, "Coagulant is disabled" end
    local st = COAGULANT.GetState(ply)
    if st == nil or not ply:Alive() then return false, "Invalid patient" end

    local t = Config.TREATMENTS[kind]
    if t == nil then return false, "Unknown treatment" end
    if st.treatment ~= nil then return false, "Already applying a treatment" end

    zone = zone or ZonaAuto(ply, kind)
    local removing = false

    if kind == "bandage" then
        if zone == nil or st.zones[zone] == nil then return false, "Nothing to bandage" end
        local sangra = false
        for _, w in ipairs(st.zones[zone].wounds) do
            if Config.BleedRate(w) > 0 then sangra = true break end
        end
        if not sangra then return false, "Nothing to bandage there" end
    elseif kind == "tourniquet" then
        if zone == nil or not Config.EXTREMITIES[zone] then
            return false, "Tourniquets only work on limbs"
        end
        removing = st.zones[zone].tourniquet -- ya puesto: este tratamiento lo QUITA
    elseif kind == "medkit" then
        if ply:Health() >= ply:GetMaxHealth() then return false, "Health is already full" end
    elseif kind == "bloodbag" then
        if st.blood >= Config.BLOOD_MAX then return false, "Blood is already full" end
    end

    -- Ítems: con Cargo presente el tratamiento requiere la unidad (el torniquete
    -- no se consume, pero sí debe estar en el inventario para ponerlo; quitarlo
    -- no pide nada). Presencia vía HasItem, NUNCA CountItem: los `unique` (el
    -- torniquete) se guardan como {id, uid} y CountItem solo cuenta stacks —
    -- pagado en juego en la ronda 3 (G4). Sin Cargo: modo degradado con cooldown.
    local cargo = Corpus.GetModule("cargo")
    if cargo ~= nil then
        if not removing and not cargo.Inventory.HasItem(ply, t.item) then
            return false, "No " .. kind .. " in inventory"
        end
    else
        if CurTime() < st.freeCooldownAt then
            return false, string.format("Field treatment on cooldown (%ds)",
                math.ceil(st.freeCooldownAt - CurTime()))
        end
    end

    -- Brazo herido: aplicar cuesta +25 % de tiempo (§6)
    local dur = t.time
    if COAGULANT.GetZoneScore(ply, "left_arm") + COAGULANT.GetZoneScore(ply, "right_arm") > 0 then
        dur = dur * Config.ARM_TIME_MULT
    end

    st.treatment = { kind = kind, zone = zone, endsAt = CurTime() + dur,
                     duration = dur, removing = removing or nil }
    st.dirty = true
    hook.Run("Coagulant_TreatmentStart", ply, kind, zone)
    return true
end

-- Azúcar congelada desde el scaffold (§8): venda con zona automática.
-- true = el tratamiento ARRANCÓ (no que terminó).
function COAGULANT.ApplyBandage(ply)
    return (COAGULANT.ApplyTreatment(ply, "bandage"))
end

function COAGULANT.CancelTreatment(ply, reason)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.treatment == nil then return end
    local tr = st.treatment
    st.treatment = nil
    st.dirty = true
    hook.Run("Coagulant_TreatmentCancel", ply, tr.kind, tr.zone, reason or "cancelled")
end

-- Aplica el efecto al completar y consume la unidad si corresponde (§7).
local function Completar(ply, st)
    local tr = st.treatment
    st.treatment = nil
    st.dirty = true
    local t = Config.TREATMENTS[tr.kind]

    -- Consumo AL COMPLETAR: re-validar que la unidad siga ahí (pudo dropearse
    -- durante la aplicación). El torniquete nunca se consume.
    local cargo = Corpus.GetModule("cargo")
    if cargo ~= nil then
        if tr.kind ~= "tourniquet" then
            if cargo.Inventory.CountItem(ply, t.item) < 1 then
                hook.Run("Coagulant_TreatmentCancel", ply, tr.kind, tr.zone, "item_gone")
                return
            end
            cargo.Inventory.TakeItem(ply, t.item, 1)
        end
    else
        st.freeCooldownAt = CurTime() + Config.DEGRADED_COOLDOWN_S
    end

    local zdata = st.zones[tr.zone]
    if tr.kind == "bandage" then
        COAGULANT.BandageEffect(ply, tr.zone)
    elseif tr.kind == "tourniquet" then
        if tr.removing then
            -- quitar: si estuvo puesto de más, la isquemia persiste un rato (§7)
            if zdata.tourniquetAt ~= nil
                and CurTime() - zdata.tourniquetAt > Config.TOURNIQUET_ISCHEMIA_S then
                zdata.ischemiaUntil = CurTime() + Config.ISCHEMIA_LINGER_S
            end
            zdata.tourniquet = false
            zdata.tourniquetAt = nil
        else
            zdata.tourniquet = true
            zdata.tourniquetAt = CurTime()
        end
    elseif tr.kind == "medkit" then
        ply:SetHealth(math.min(ply:Health() + t.heal, ply:GetMaxHealth()))
    elseif tr.kind == "bloodbag" then
        st.blood = math.min(Config.BLOOD_MAX, st.blood + t.blood)
    end

    hook.Run("Coagulant_TreatmentComplete", ply, tr.kind, tr.zone)
end

-- Tick fino (0.25 s): completar a término y cancelar por velocidad. Separado del
-- timer de sangrado (1 s) para que la cancelación/completado no se sientan a saltos.
timer.Create("corpus_coagulant_treatment_tick", 0.25, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local st = COAGULANT.State[ply:SteamID64() or "singleplayer"]
        if st ~= nil and st.treatment ~= nil then
            if not ply:Alive() then
                COAGULANT.CancelTreatment(ply, "died")
            elseif ply:GetVelocity():Length2D() > ply:GetWalkSpeed() * Config.CANCEL_SPEED_MULT then
                COAGULANT.CancelTreatment(ply, "moving")
            elseif CurTime() >= st.treatment.endsAt then
                Completar(ply, st)
            end
        end
    end
end)

-- Cancelación por daño real (el drenaje propio del crítico NO cancela: si lo
-- hiciera, sería imposible tratarse justo cuando más hace falta).
hook.Add("PostEntityTakeDamage", "corpus_coagulant_treatcancel", function(ent, dmginfo, took)
    if not took or not (IsValid(ent) and ent:IsPlayer()) then return end
    local st = COAGULANT.GetState(ent)
    if st == nil or st._selfDrain or st.treatment == nil then return end
    COAGULANT.CancelTreatment(ent, "damage")
end)

-- Cancelación por salto
hook.Add("KeyPress", "corpus_coagulant_treatjump", function(ply, key)
    if key ~= IN_JUMP then return end
    local st = COAGULANT.GetState(ply)
    if st ~= nil and st.treatment ~= nil then
        COAGULANT.CancelTreatment(ply, "jumped")
    end
end)

-- Intents del cliente (§9): el menú médico del slice 4 manda estos; el server
-- valida todo de nuevo — el cliente nunca es autoridad.
net.Receive(MSG_TREAT, function(_, ply)
    local kind = net.ReadString()
    local zone = net.ReadString()
    if zone == "" then zone = nil end
    if zone ~= nil and not COAGULANT.Zones.IsValid(zone) then return end
    local ok, err = COAGULANT.ApplyTreatment(ply, kind, zone)
    if not ok and err ~= nil then ply:ChatPrint(err) end
end)

net.Receive(MSG_CANCEL, function(_, ply)
    COAGULANT.CancelTreatment(ply, "player")
end)

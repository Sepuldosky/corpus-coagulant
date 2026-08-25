-- corpus_coagulant_core.lua — estado clínico por jugador + creación de heridas (SERVER)
-- Coagulant_Architecture.md §2-§3, §8. La herida se crea en PostEntityTakeDamage
-- con el daño FINAL (post-mitigación de cualquier mod, y de Caliber Block 3 cuando
-- exista): ScalePlayerDamage solo captura el hitgroup del evento. Coagulant nunca
-- re-escala daño — solo observa.

local COAGULANT = Corpus.GetModule("coagulant")
local Config = COAGULANT.Config

-- Estado clínico en memoria, por SteamID64 (§2). Sin persistencia a disco (spawn =
-- cuerpo nuevo, decisión F de la semilla).
COAGULANT.State = COAGULANT.State or {}

local function NuevoEstado()
    local st = {
        blood          = Config.BLOOD_MAX,
        zones          = {},
        treatment      = nil, -- { kind, zone, endsAt, duration, removing } (§7)
        freeCooldownAt = 0,   -- modo degradado sin Cargo: próximo tratamiento gratis
        encumbrance    = 0,   -- último fraction reportado por Cargo (§12), sin efecto v1
        painSuppress   = 0,   -- techo de analgésico vigente (§17, COA-52 D5). Es lo ÚNICO
                              -- que el dolor almacena: el dolor mismo se DERIVA de las
                              -- heridas y no tiene reloj propio

        critical       = false, -- para detectar el cruce del umbral (§5)
        dirty          = true,  -- snapshot pendiente de enviar (§9)
        lastHit        = nil,   -- debug
    }
    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        st.zones[zona] = { wounds = {}, tourniquet = false }
    end
    return st
end

-- Devuelve (creando si hace falta) el estado clínico del jugador.
function COAGULANT.GetState(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return nil end
    local sid = ply:SteamID64() or "singleplayer"
    COAGULANT.State[sid] = COAGULANT.State[sid] or NuevoEstado()
    return COAGULANT.State[sid]
end

-- Resetea el estado clínico del jugador (spawn = cuerpo nuevo).
function COAGULANT.ResetState(ply)
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    local sid = ply:SteamID64() or "singleplayer"
    COAGULANT.State[sid] = NuevoEstado()
    ply:SetNW2Float("coagulant_blood", Config.BLOOD_MAX)
    -- También el NW2 de cojera, acá mismo: el selftest resetea SIN pasar por
    -- PlayerSpawn y dejaba publicado el multiplicador viejo hasta el siguiente tick
    -- (ronda 7: "piernas: score 0.0 → velocidad ×0.64" en coagulant_status).
    ply:SetNW2Float("coagulant_speed_mult", 1)
end

-- ============================================================
-- CONTRATO PÚBLICO (lectura) — §8
-- ============================================================

function COAGULANT.GetBlood(ply)
    local st = COAGULANT.GetState(ply)
    return st and st.blood or Config.BLOOD_MAX
end

function COAGULANT.IsBleeding(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return false end
    for zona, zdata in pairs(st.zones) do
        if not zdata.tourniquet then
            for _, w in ipairs(zdata.wounds) do
                if Config.BleedRate(w, zona) > 0 then return true end
            end
        end
    end
    return false
end

-- ¿La zona está isquémica? (§7: torniquete puesto más de 90 s, o hasta 60 s tras
-- quitarlo). Off-contract, pero la consultan el score, el snapshot al cliente y
-- coagulant_status — vive en un solo lugar para que los tres digan lo mismo.
function COAGULANT.IsIschemic(ply, zone)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return false end
    local zdata = st.zones[zone]
    return (zdata.tourniquet and zdata.tourniquetAt ~= nil
            and CurTime() - zdata.tourniquetAt > Config.TOURNIQUET_ISCHEMIA_S)
        or (zdata.ischemiaUntil ~= nil and CurTime() < zdata.ischemiaUntil)
end

-- Score de debuff de la zona (§6): Σ severidades; las tratadas cuentan la mitad.
-- La isquemia impone un piso de score alto — el costo de dejar el torniquete puesto.
function COAGULANT.GetZoneScore(ply, zone)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return 0 end
    local score = 0
    for _, w in ipairs(st.zones[zone].wounds) do
        score = score + (w.treated and w.severity * 0.5 or w.severity)
    end

    if COAGULANT.IsIschemic(ply, zone) then
        score = math.max(score, Config.ISCHEMIA_SCORE)
    end
    return score
end


-- ============================================================
-- DOLOR (§17, COA-52) — derivado por zona + agregado global saturado
-- ============================================================
-- El dolor NO se almacena y NO tiene reloj propio: se deriva del estado de las
-- heridas con la misma forma que GetZoneScore de acá arriba. De eso salen tres
-- cosas gratis y son la razón por la que se eligió esta forma: vendar baja el dolor
-- en el acto, una tratada limpia lo pierde con el reloj de curación de COA-49, y
-- una infectada lo recupera entero. Cero timers, cero acumuladores nuevos.

-- Dolor 0..100 de UNA zona, con los pisos de condición aplicados (D4 + D6).
function COAGULANT.ZonePain(ply, zone)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return 0 end
    local zdata = st.zones[zone]

    local pain = 0
    for _, w in ipairs(zdata.wounds) do
        -- Reparto por ESTADO de la herida: activa 1.00 · tratada 0.35 · infectada
        -- 1.00 entera. ⚠ El 0.35 NO es el 0.5 con el que GetZoneScore (arriba, en
        -- este mismo archivo) reparte las tratadas: son dos números distintos A
        -- PROPÓSITO —uno es debuff, el otro nocicepción— y copiar el de al lado no
        -- da ningún síntoma.
        --
        -- El tercer estado es de COA-49 y COA-49 NO BAJÓ: con la forma de LISTA de
        -- hoy ninguna herida lleva ese campo, así que esta rama es INALCANZABLE y el
        -- término lee 0 — exactamente neutro, que es lo que COA-52 predijo. El día
        -- que aterrice `w[tipo] = {a,t,i,s}`, lo que cambia es el RECORRIDO (pasa a
        -- ser por contadores de tipo), no estos tres multiplicadores.
        local mult
        if w.infected then
            mult = Config.PAIN_INFECTED_MULT
        elseif w.treated then
            mult = Config.PAIN_TREATED_MULT
        else
            mult = 1.0
        end
        pain = pain + Config.PainFromWound(w.type, w.severity) * mult
    end

    -- Pisos por condición (D6), con la MISMA forma max() que usa el score con la
    -- isquemia: un piso nunca BAJA el dolor de una zona que ya duele más.
    --
    -- El TORNIQUETE no está acá y no es un olvido: a los 90 s ya se convirtió en
    -- isquemia (TOURNIQUET_ISCHEMIA_S), que es el mismo reloj con otro nombre. Un
    -- reloj, no dos — y lo que duele nunca fue la banda apretada sino el miembro
    -- muriéndose.
    if COAGULANT.IsIschemic(ply, zone) then
        pain = math.max(pain, Config.PAIN_ISCHEMIA)
    end
    -- La fractura sigue diferida por §1: NADA en este árbol escribe `zdata.frac`
    -- (medido: 0 hits de `frac`/`splint` en el lua/). El término se escribe igual
    -- para que el día que exista no haya que volver acá, y hasta entonces lee 0.
    if zdata.frac == "fx" then
        pain = math.max(pain, Config.PAIN_FRAC)
    elseif zdata.frac == "splint" then
        pain = math.max(pain, Config.PAIN_SPLINT)
    end

    return math.Clamp(pain, 0, Config.PAIN_MAX)
end

-- Dolor global CRUDO (sin supresión): Σ de las siete zonas por su peso, SATURADO
-- (D1). El clamp no es cosmético — es lo que salva a las cuatro fórmulas del spec
-- v5 que ya consumen dolor con coeficientes calibrados contra un 0..100: con suma
-- cruda el rango sería 0..700 y el bpm sumaría +154 en vez de +22.
--
-- Es la capa de DIAGNÓSTICO (lo que el cuerpo tiene). Quién puede leerla bajo
-- niebla lo decide COA-44 cuando baje; que exista no dice que sea pública.
function COAGULANT.GetRawPain(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return 0 end
    local total = 0
    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        total = total + COAGULANT.ZonePain(ply, zona) * (Config.ZONE_PAIN_WEIGHT[zona] or 1.0)
    end
    return math.Clamp(total, 0, Config.PAIN_MAX)
end

-- Dolor PERCIBIDO = crudo − supresión (D5). Es lo que leen los consumidores y lo
-- que viaja al cliente: el síntoma es lo que el paciente SUFRE, no lo que tiene.
-- De ahí sale el efecto que le da sentido al analgésico bajo niebla — suprimir el
-- dolor apaga el único canal que la niebla deja gratis, así que la morfina será un
-- costo de información y no un buff.
function COAGULANT.GetPain(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return 0 end
    return math.Clamp(COAGULANT.GetRawPain(ply) - (st.painSuppress or 0), 0, Config.PAIN_MAX)
end

-- Suma puntos de supresión y devuelve el total vigente. Reemplaza al inexistente
-- `CoaAddDrug("morphine", 10)` del prototipo — cuyo 10 eran MILIGRAMOS y no puntos
-- de dolor; los miligramos se quedan donde eran ciertos, en el nombre del ítem.
--
-- Ensucia el snapshot: el percibido acaba de cambiar y el emisor es on-change
-- (COA-16), así que sin esto el cliente seguiría mostrando el dolor de antes hasta
-- que otra cosa moviera el estado.
function COAGULANT.AddPainSuppression(ply, puntos)
    local st = COAGULANT.GetState(ply)
    if st == nil or not isnumber(puntos) then return 0 end
    st.painSuppress = math.Clamp((st.painSuppress or 0) + puntos, 0, Config.PAIN_SUPPRESS_MAX)
    st.dirty = true
    return st.painSuppress
end

-- Contrato YA congelado por Cargo (corpus_cargo_movement.lua nos llama con pcall
-- en cada cambio de peso). v1: almacenar; la stamina/fatiga es bloque futuro (§1).
function COAGULANT.OnEncumbrance(ply, fraction)
    local st = COAGULANT.GetState(ply)
    if st == nil then return end
    st.encumbrance = fraction or 0
end

-- ============================================================
-- Heridas (§3)
-- ============================================================

-- Agrega una herida a la zona, respetando el tope por zona: al exceder, se agrava
-- la herida más leve (preferentemente no tratada) en vez de apilar sin límite.
-- Off-contract: la usan PostEntityTakeDamage y el selftest.
function COAGULANT.AddWound(ply, zone, wtype, severity)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return nil end
    local wounds = st.zones[zone].wounds

    local wound
    if #wounds >= Config.MAX_WOUNDS_PER_ZONE then
        local candidata
        for _, w in ipairs(wounds) do
            if candidata == nil
                or (not w.treated and candidata.treated)
                or (w.treated == candidata.treated and w.severity < candidata.severity) then
                candidata = w
            end
        end
        candidata.severity = math.min(Config.SEVERITY_MAX, candidata.severity + 1)
        candidata.treated = false
        wound = candidata
    else
        wound = { type = wtype, severity = severity, treated = false }
        wounds[#wounds + 1] = wound
    end

    st.dirty = true
    hook.Run("Coagulant_WoundAdded", ply, zone, wound)
    if Config.cv_debug:GetBool() then
        Corpus.Log("coagulant", string.format("herida: %s sev %d en %s (%s)",
            wound.type, wound.severity, zone, ply:Nick()))
    end
    return wound
end

-- ============================================================
-- Efecto puro de la venda (§7). La mecánica de tiempo/consumo/intents vive en
-- corpus_coagulant_treatment.lua (que también define ApplyBandage/ApplyTreatment);
-- este efecto lo usan el motor de tratamiento y el debug coagulant_bandage.
-- ============================================================

-- Efecto venda sobre una zona: cierra la peor herida ABIERTA leve/media; una grave
-- la reduce a media sin cerrarla (una grave cuesta 2 vendas). COA-37: "abierta" es
-- `not treated`, NO "sangrante" — la contusión (mult 0.0) también se venda, como en
-- ACE3. El criterio de "peor" (sangrantes primero, la más grave dentro de cada grupo)
-- vive en Config.BandagePriority, que comparten esta función y la zona automática.
function COAGULANT.BandageEffect(ply, zone)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return false end

    local objetivo, mejorPrio = nil, 0
    for _, w in ipairs(st.zones[zone].wounds) do
        local prio = Config.BandagePriority(w, zone)
        if prio > mejorPrio then objetivo, mejorPrio = w, prio end
    end
    if objetivo == nil then return false end

    if objetivo.severity >= 3 then
        objetivo.severity = 2
    else
        objetivo.treated = true
        hook.Run("Coagulant_WoundClosed", ply, zone, objetivo)
    end
    st.dirty = true
    return true
end

-- Cierra definitivamente las heridas ya TRATADAS de una zona; devuelve cuántas.
-- Es la ÚNICA cura de la secuela (§7, decisión del autor tras la ronda 5): vendar
-- corta el sangrado pero deja media severidad pesando en el debuff PARA SIEMPRE —
-- el Medkit es lo que borra eso. Las heridas sin tratar no se tocan: primero se
-- vendan. La usa el motor de tratamiento al completar un medkit.
function COAGULANT.HealTreatedWounds(ply, zone)
    local st = COAGULANT.GetState(ply)
    if st == nil or st.zones[zone] == nil then return 0 end
    local wounds = st.zones[zone].wounds
    local n = 0
    for i = #wounds, 1, -1 do
        if wounds[i].treated then
            table.remove(wounds, i)
            n = n + 1
        end
    end
    if n > 0 then st.dirty = true end
    return n
end

-- Zona con más secuela tratada (destino automático del medkit, §7). nil si no hay
-- ninguna herida tratada en el cuerpo.
function COAGULANT.WorstTreatedZone(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return nil end
    local mejorZona, mejorScore = nil, 0
    for zona, zdata in pairs(st.zones) do
        local score = 0
        for _, w in ipairs(zdata.wounds) do
            if w.treated then score = score + w.severity * 0.5 end
        end
        if score > mejorScore then mejorZona, mejorScore = zona, score end
    end
    return mejorZona
end

-- Zona con la herida ABIERTA más grave — destino automático de la VENDA (COA-37).
-- nil si no hay ninguna herida sin tratar. Reemplaza a WorstBleedingZone en ese rol:
-- aquella es ciega a la contusión (no sangra), así que con solo un moretón encima el
-- uso rápido no encontraba zona y el tratamiento se rechazaba con "Nothing to bandage".
function COAGULANT.WorstOpenZone(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return nil end
    local mejorZona, mejorPrio = nil, 0
    for zona, zdata in pairs(st.zones) do
        for _, w in ipairs(zdata.wounds) do
            local prio = Config.BandagePriority(w, zona)
            if prio > mejorPrio then mejorZona, mejorPrio = zona, prio end
        end
    end
    return mejorZona
end

-- Zona con la herida sangrante más grave. nil si no hay sangrado. Responde la
-- pregunta de URGENCIA (qué está drenando), no la de la venda: desde COA-37 la venda
-- va por WorstOpenZone. Off-contract; hoy la ejercita el selftest.
function COAGULANT.WorstBleedingZone(ply)
    local st = COAGULANT.GetState(ply)
    if st == nil then return nil end
    local mejorZona, mejorSev = nil, 0
    for zona, zdata in pairs(st.zones) do
        for _, w in ipairs(zdata.wounds) do
            if Config.BleedRate(w, zona) > 0 and w.severity > mejorSev then
                mejorZona, mejorSev = zona, w.severity
            end
        end
    end
    return mejorZona
end

-- ============================================================
-- Hooks del pipeline (§3)
-- ============================================================

-- Captura el hitgroup del evento; la herida se crea después, con el daño final.
hook.Add("ScalePlayerDamage", "corpus_coagulant_hit", function(ply, hitgroup, dmginfo)
    if not Config.Enabled() then return end
    ply.m_coagHitgroup = hitgroup
    ply.m_coagHitTime = CurTime()
end)

-- Crea la herida con el daño realmente aplicado. st._selfDrain evita el bucle:
-- el drenaje de HP crítico (bleeding, §5) también dispara este hook.
hook.Add("PostEntityTakeDamage", "corpus_coagulant_wound", function(ent, dmginfo, took)
    if not took or not Config.Enabled() then return end
    if not (IsValid(ent) and ent:IsPlayer()) then return end
    local st = COAGULANT.GetState(ent)
    if st == nil or st._selfDrain then return end

    local wtype = Config.WoundTypeFromDMG(dmginfo:GetDamageType())
    if wtype == nil then return end

    -- Zona: hitgroup capturado en este mismo evento (ventana corta); las caídas
    -- no pasan por ScalePlayerDamage → pierna al azar; resto sin dato → chest
    -- (COA-7: el fallback sin ubicación es chest, enmienda 2026-07-21).
    local zona
    if ent.m_coagHitTime ~= nil and CurTime() - ent.m_coagHitTime < 0.1 then
        zona = COAGULANT.Zones.FromHitgroup(ent.m_coagHitgroup)
    elseif bit.band(dmginfo:GetDamageType(), DMG_FALL) ~= 0 then
        zona = math.random(2) == 1 and "left_leg" or "right_leg"
    else
        zona = "chest"
    end

    local dano = dmginfo:GetDamage()
    COAGULANT.AddWound(ent, zona, wtype, Config.SeverityFromDamage(dano))
    st.lastHit = { zone = zona, damage = dano, time = CurTime() }
end)

hook.Add("PlayerSpawn", "corpus_coagulant_spawn", function(ply)
    COAGULANT.ResetState(ply)
end)

hook.Add("PlayerDisconnected", "corpus_coagulant_disconnect", function(ply)
    local sid = ply:SteamID64()
    if sid ~= nil then COAGULANT.State[sid] = nil end
end)

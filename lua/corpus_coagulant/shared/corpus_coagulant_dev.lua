-- corpus_coagulant_dev.lua — auto-test de consola + comandos de verificación (SHARED)
-- Mismo patrón que corpus_selftest / cargo_selftest: checks deterministas de la
-- superficie pura, en el realm donde se invoca. En listen server, realm server:
--   lua_run Corpus.GetModule("coagulant")._SelfTest()
-- No reemplaza la verificación en juego (flujo §1 PASO 4): la complementa.
-- Comandos de verificación (admin): coagulant_status, coagulant_setblood <n>.

local COAGULANT = Corpus.GetModule("coagulant")

function COAGULANT._SelfTest()
    local Config = COAGULANT.Config
    local pasan, fallan = 0, 0
    local function check(cond, msg)
        if cond then
            pasan = pasan + 1
        else
            fallan = fallan + 1
            Corpus.Log("coagulant", "SELFTEST FALLO: " .. msg)
        end
    end

    -- Registro: invariante by-ref del framework
    check(Corpus.GetModule("coagulant") == COAGULANT, "GetModule no devuelve la misma tabla by-ref")
    check(Corpus.HasModule("coagulant") == true, "HasModule('coagulant') no es true")

    -- Contrato de zonas: lista/labels consistentes y mapa total sobre hitgroups
    check(#COAGULANT.Zones.LIST == 6, "Zones.LIST no tiene 6 zonas")
    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        check(COAGULANT.Zones.IsValid(zona), "zona de LIST sin label: " .. tostring(zona))
    end
    local hitgroups = {
        HITGROUP_GENERIC, HITGROUP_HEAD, HITGROUP_CHEST, HITGROUP_STOMACH,
        HITGROUP_LEFTARM, HITGROUP_RIGHTARM, HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG,
        HITGROUP_GEAR,
    }
    for _, hg in ipairs(hitgroups) do
        check(COAGULANT.Zones.IsValid(COAGULANT.Zones.FromHitgroup(hg)),
            "FromHitgroup devuelve zona inválida para hitgroup " .. tostring(hg))
    end
    check(COAGULANT.Zones.FromHitgroup(999) == "torso", "FromHitgroup sin fallback a torso")

    -- Config pura (slice 1, arquitectura §3-§5)
    check(Config.WoundTypeFromDMG(DMG_BULLET) == "bala", "DMG_BULLET no mapea a bala")
    check(Config.WoundTypeFromDMG(bit.bor(DMG_BULLET, DMG_BURN)) == "bala",
        "bala incendiaria no prioriza bala")
    check(Config.WoundTypeFromDMG(DMG_BLAST) == "metralla", "DMG_BLAST no mapea a metralla")
    check(Config.WoundTypeFromDMG(DMG_SLASH) == "corte", "DMG_SLASH no mapea a corte")
    check(Config.WoundTypeFromDMG(DMG_BURN) == "quemadura", "DMG_BURN no mapea a quemadura")
    check(Config.WoundTypeFromDMG(DMG_FALL) == "contusion", "DMG_FALL no mapea a contusion")
    check(Config.WoundTypeFromDMG(DMG_POISON) == nil, "DMG_POISON debería ignorarse")
    check(Config.SeverityFromDamage(10) == 1, "daño 10 no es severidad 1")
    check(Config.SeverityFromDamage(20) == 2, "daño 20 no es severidad 2")
    check(Config.SeverityFromDamage(50) == 3, "daño 50 no es severidad 3")
    check(Config.BleedRate({ type = "bala", severity = 3, treated = false }) == 1.0,
        "bala grave no drena 1.0/s")
    check(Config.BleedRate({ type = "bala", severity = 3, treated = true }) == 0,
        "herida tratada sigue drenando")
    check(Config.BleedRate({ type = "contusion", severity = 3, treated = false }) == 0,
        "contusión drena sangre")
    check(Config.HPDrainRate(Config.BLOOD_CRITICAL) == 0, "HP drena con sangre no crítica")
    check(Config.HPDrainRate(0) == Config.HP_DRAIN_BASE + Config.HP_DRAIN_EXTRA,
        "HP drain con sangre 0 no es el máximo")

    -- Tratamiento (slice 2, §7): tabla completa y consistente
    for _, kind in ipairs({ "bandage", "tourniquet", "medkit", "bloodbag" }) do
        local t = Config.TREATMENTS[kind]
        check(istable(t) and isnumber(t.time) and t.time > 0 and isstring(t.item),
            "TREATMENTS." .. kind .. " incompleto")
    end
    local nExt = 0
    for _ in pairs(Config.EXTREMITIES) do nExt = nExt + 1 end
    check(nExt == 4, "EXTREMITIES no tiene 4 zonas")

    -- Contrato público congelado (server): existe con la firma esperada
    if SERVER then
        check(isfunction(COAGULANT.ApplyBandage), "ApplyBandage no es función")
        check(isfunction(COAGULANT.ApplyTreatment), "ApplyTreatment no es función")
        check(isfunction(COAGULANT.CancelTreatment), "CancelTreatment no es función")
        check(isfunction(COAGULANT.GetBlood), "GetBlood no es función")
        check(isfunction(COAGULANT.IsBleeding), "IsBleeding no es función")
        check(isfunction(COAGULANT.GetZoneScore), "GetZoneScore no es función")
        check(isfunction(COAGULANT.OnEncumbrance), "OnEncumbrance no es función (contrato de Cargo)")

        -- Round-trip de estado con un jugador real, si hay alguno conectado
        local ply = player.GetAll()[1]
        if IsValid(ply) then
            COAGULANT.ResetState(ply)
            local st = COAGULANT.GetState(ply)
            check(istable(st) and istable(st.zones), "GetState no devuelve estado con zonas")
            check(st.blood == Config.BLOOD_MAX, "sangre inicial incorrecta")
            check(COAGULANT.IsBleeding(ply) == false, "sangra sin heridas")

            COAGULANT.AddWound(ply, "left_arm", "bala", 2)
            check(COAGULANT.IsBleeding(ply) == true, "herida de bala no sangra")
            check(COAGULANT.GetZoneScore(ply, "left_arm") == 2, "score de zona incorrecto")
            check(COAGULANT.WorstBleedingZone(ply) == "left_arm", "WorstBleedingZone incorrecta")

            -- efecto venda puro: cierra leve/media; una grave cuesta 2 (§7)
            check(COAGULANT.BandageEffect(ply, "left_arm") == true, "BandageEffect sin efecto")
            check(COAGULANT.IsBleeding(ply) == false, "la venda no cortó el sangrado")
            check(COAGULANT.GetZoneScore(ply, "left_arm") == 1, "herida tratada no cuenta la mitad")
            COAGULANT.AddWound(ply, "torso", "bala", 3)
            COAGULANT.BandageEffect(ply, "torso")
            check(COAGULANT.IsBleeding(ply) == true, "una sola venda cerró una grave")
            COAGULANT.BandageEffect(ply, "torso")
            check(COAGULANT.IsBleeding(ply) == false, "dos vendas no cerraron la grave")

            -- motor de tratamiento (slice 2): arranca (brazo herido → +25%) y cancela
            COAGULANT.AddWound(ply, "right_leg", "bala", 2)
            local ok = COAGULANT.ApplyTreatment(ply, "bandage")
            check(ok == true, "ApplyTreatment bandage no arrancó")
            check(istable(st.treatment) and st.treatment.kind == "bandage",
                "st.treatment no quedó seteado")
            check(st.treatment.duration > Config.TREATMENTS.bandage.time,
                "brazo herido no encarece el tiempo (+25%)")
            local ok2, err2 = COAGULANT.ApplyTreatment(ply, "bandage")
            check(ok2 == false and isstring(err2), "permitió dos tratamientos a la vez")
            COAGULANT.CancelTreatment(ply, "selftest")
            check(st.treatment == nil, "CancelTreatment no limpió")
            check(COAGULANT.ApplyTreatment(ply, "tourniquet", "torso") == false,
                "torniquete aceptó una zona no-extremidad")

            COAGULANT.ResetState(ply) -- dejar limpio
        else
            Corpus.Log("coagulant", "selftest: sin jugadores — round-trip de estado omitido")
        end
    end

    -- Soft-deps: reporte informativo, nunca un fallo (degradación honesta)
    Corpus.Log("coagulant", string.format("soft-deps — caliber: %s | cargo: %s",
        Corpus.HasModule("caliber") and "presente" or "ausente",
        Corpus.HasModule("cargo") and "presente" or "ausente"))
    if Corpus.HasModule("cargo") then
        local cargo = Corpus.GetModule("cargo")
        for _, t in pairs(COAGULANT.Config.TREATMENTS) do
            local def = cargo.Items.Get and cargo.Items.Get(t.item) or nil
            check(def ~= nil, "Cargo presente pero falta la def " .. t.item .. " (¿corrió OnReady?)")
        end
    end

    Corpus.Log("coagulant", string.format("selftest (%s): %d OK, %d fallos",
        SERVER and "server" or "client", pasan, fallan))
    return fallan == 0
end

concommand.Add("coagulant_selftest", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    COAGULANT._SelfTest()
end)

-- ============================================================
-- Comandos de verificación en juego (server, admin) — sin UI hasta el slice 4
-- ============================================================
if SERVER then
    -- Vuelca sangre + heridas por zona a la consola del que lo invoca
    concommand.Add("coagulant_status", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local objetivo = IsValid(ply) and ply or player.GetAll()[1]
        if not IsValid(objetivo) then return end
        local st = COAGULANT.GetState(objetivo)

        Corpus.Log("coagulant", string.format("%s — sangre %.1f/%d%s | HP %d",
            objetivo:Nick(), st.blood, COAGULANT.Config.BLOOD_MAX,
            st.critical and " (CRÍTICA)" or "", objetivo:Health()))
        for _, zona in ipairs(COAGULANT.Zones.LIST) do
            local zdata = st.zones[zona]
            if #zdata.wounds > 0 or zdata.tourniquet then
                local partes = {}
                for _, w in ipairs(zdata.wounds) do
                    partes[#partes + 1] = string.format("%s sev%d%s",
                        w.type, w.severity, w.treated and " (tratada)" or "")
                end
                Corpus.Log("coagulant", "  " .. zona .. ": " .. table.concat(partes, ", ")
                    .. (zdata.tourniquet and " [torniquete]" or ""))
            end
        end
        if not COAGULANT.IsBleeding(objetivo) then
            Corpus.Log("coagulant", "  sin sangrado activo")
        end
        if st.treatment ~= nil then
            Corpus.Log("coagulant", string.format("  tratamiento en curso: %s en %s (%.1fs restantes)",
                st.treatment.kind, tostring(st.treatment.zone),
                math.max(0, st.treatment.endsAt - CurTime())))
        end
    end)

    -- Kit médico de prueba vía Cargo (mismo rol que cargo_dev_give). Existe porque
    -- un lua_run largo se TRUNCA en la consola de GMod (pagado en la ronda 3 de
    -- verificación): los comandos de checklist deben ser cortos.
    concommand.Add("coagulant_dev_give", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local objetivo = IsValid(ply) and ply or player.GetAll()[1]
        if not IsValid(objetivo) then return end
        local cargo = Corpus.GetModule("cargo")
        if cargo == nil then
            Corpus.Log("coagulant", "coagulant_dev_give: Cargo no está montado")
            return
        end
        cargo.Inventory.GiveItem(objetivo, "corpus_coagulant_bandage", 3)
        cargo.Inventory.GiveItem(objetivo, "corpus_coagulant_tourniquet")
        cargo.Inventory.GiveItem(objetivo, "corpus_coagulant_medkit", 2)
        cargo.Inventory.GiveItem(objetivo, "corpus_coagulant_bloodbag", 2)
        Corpus.Log("coagulant", "kit médico de prueba entregado a " .. objetivo:Nick()
            .. " (3 vendas, 1 torniquete, 2 medkits, 2 bolsas)")
    end)

    -- Fuerza el nivel de sangre (para probar el crítico sin desangrarse de verdad)
    concommand.Add("coagulant_setblood", function(ply, _, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local objetivo = IsValid(ply) and ply or player.GetAll()[1]
        if not IsValid(objetivo) then return end
        local n = tonumber(args[1])
        if n == nil then
            Corpus.Log("coagulant", "uso: coagulant_setblood <0-" .. COAGULANT.Config.BLOOD_MAX .. ">")
            return
        end
        local st = COAGULANT.GetState(objetivo)
        st.blood = math.Clamp(n, 0, COAGULANT.Config.BLOOD_MAX)
        st.dirty = true
        Corpus.Log("coagulant", "sangre de " .. objetivo:Nick() .. " → " .. st.blood)
    end)
end

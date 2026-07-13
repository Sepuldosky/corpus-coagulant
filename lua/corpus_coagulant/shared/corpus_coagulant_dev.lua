-- corpus_coagulant_dev.lua — auto-test de consola del scaffold (SHARED)
-- Mismo patrón que corpus_selftest / cargo_selftest: checks deterministas de la
-- superficie pura, en el realm donde se invoca. En listen server, realm server:
--   lua_run Corpus.GetModule("coagulant")._SelfTest()
-- No reemplaza la verificación en juego (flujo §1 PASO 4): la complementa.

local COAGULANT = Corpus.GetModule("coagulant")

function COAGULANT._SelfTest()
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
    check(COAGULANT.Zones.IsValid("bazo") == false, "IsValid acepta una zona inexistente")

    -- Contrato público congelado (server): existe con la firma esperada
    if SERVER then
        check(isfunction(COAGULANT.ApplyBandage), "ApplyBandage no es función")
        check(isfunction(COAGULANT.GetState), "GetState no es función")
        check(isfunction(COAGULANT.ResetState), "ResetState no es función")

        -- Round-trip de estado con un jugador real, si hay alguno conectado
        local ply = player.GetAll()[1]
        if IsValid(ply) then
            COAGULANT.ResetState(ply)
            local st = COAGULANT.GetState(ply)
            check(istable(st) and istable(st.zones), "GetState no devuelve estado con zonas")
            check(st.zones.torso ~= nil and st.zones.torso.bleeding == 0, "estado inicial de torso incorrecto")
            check(COAGULANT.ApplyBandage(ply) == true, "ApplyBandage (stub) no devuelve true")
        else
            Corpus.Log("coagulant", "selftest: sin jugadores — round-trip de estado omitido")
        end
    end

    -- Soft-deps: reporte informativo, nunca un fallo (degradación honesta)
    Corpus.Log("coagulant", string.format("soft-deps — caliber: %s | cargo: %s",
        Corpus.HasModule("caliber") and "presente" or "ausente",
        Corpus.HasModule("cargo") and "presente" or "ausente"))
    if SERVER and Corpus.HasModule("cargo") then
        local cargo = Corpus.GetModule("cargo")
        local def = cargo.Items.Get and cargo.Items.Get("corpus_coagulant_bandage") or nil
        check(def ~= nil, "Cargo presente pero la venda no está registrada (¿corrió OnReady?)")
    end

    Corpus.Log("coagulant", string.format("selftest (%s): %d OK, %d fallos",
        SERVER and "server" or "client", pasan, fallan))
    return fallan == 0
end

concommand.Add("coagulant_selftest", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    COAGULANT._SelfTest()
end)

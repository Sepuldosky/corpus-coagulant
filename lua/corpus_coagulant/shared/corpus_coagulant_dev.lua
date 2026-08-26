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

    -- Contrato de zonas (COA-8, enmienda 2026-07-21): 7 zonas, lista/labels
    -- consistentes y mapa total sobre hitgroups
    check(#COAGULANT.Zones.LIST == 7, "Zones.LIST no tiene 7 zonas")
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
    check(COAGULANT.Zones.FromHitgroup(HITGROUP_CHEST) == "chest"
        and COAGULANT.Zones.FromHitgroup(HITGROUP_STOMACH) == "stomach",
        "CHEST y STOMACH no mapean a zonas distintas (COA-8)")
    check(COAGULANT.Zones.FromHitgroup(HITGROUP_GENERIC) == "chest"
        and COAGULANT.Zones.FromHitgroup(HITGROUP_GEAR) == "chest",
        "GENERIC/GEAR no caen a chest (COA-7)")
    check(COAGULANT.Zones.FromHitgroup(999) == "chest", "FromHitgroup sin fallback a chest")
    check(COAGULANT.Zones.IsValid("torso") == false,
        "torso sigue siendo zona válida (murió sin alias, COA-8)")

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

    -- ZONE_BLEED_MULT (§4, enmienda 2026-07-21): cubre las 7 zonas exactas y
    -- BleedRate lo aplica. Todo derivado de la config, jamás del literal (COA-35):
    -- si el autor tunea el mult de stomach, este check sigue validando.
    local nMults = 0
    for _ in pairs(Config.ZONE_BLEED_MULT) do nMults = nMults + 1 end
    check(nMults == #COAGULANT.Zones.LIST, "ZONE_BLEED_MULT no cubre exactamente las zonas de LIST")
    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        check(isnumber(Config.ZONE_BLEED_MULT[zona]),
            "ZONE_BLEED_MULT sin la zona " .. tostring(zona))
        local wZona = { type = "bala", severity = 3, treated = false }
        local esperado = Config.BLEED_BASE[3] * Config.WOUND_TYPES.bala.mult
            * Config.ZONE_BLEED_MULT[zona]
        check(math.abs(Config.BleedRate(wZona, zona) - esperado) < 0.001,
            "BleedRate no aplica el mult de zona de " .. zona)
    end
    check(Config.BleedRate({ type = "bala", severity = 3, treated = false }, nil)
        == Config.BLEED_BASE[3] * Config.WOUND_TYPES.bala.mult,
        "BleedRate sin zona no es nil-safe (×1.0)")
    check(Config.HPDrainRate(Config.BLOOD_CRITICAL) == 0, "HP drena con sangre no crítica")
    check(Config.HPDrainRate(0) == Config.HP_DRAIN_BASE + Config.HP_DRAIN_EXTRA,
        "HP drain con sangre 0 no es el máximo")

    -- La venda pregunta "¿está ABIERTA?", no "¿sangra?" (COA-37, §7): con el criterio
    -- viejo la contusión era invendable y —como el medkit solo borra lo ya tratado—
    -- incurable hasta morir. Todo derivado de la config, nunca de un literal (COA-35).
    local moreton = { type = "contusion", severity = 2, treated = false }
    check(Config.BleedRate(moreton) == 0, "la contusión de prueba sangra")
    check(Config.BandagePriority(moreton) > 0,
        "una contusión abierta no se puede vendar (volvería a ser incurable)")
    check(Config.BandagePriority({ type = "contusion", severity = 2, treated = true }) == 0,
        "una herida ya tratada se puede volver a vendar")
    -- El SANGRADO domina, la severidad ordena DENTRO de cada grupo (corregido tras la
    -- pasada del autor, check 4 ✗). El caso que lo destapó: balazo LEVE + moretón MEDIO
    -- en la misma zona — la venda tiene que ir al balazo. Un moretón nunca mata.
    check(Config.BandagePriority({ type = "bala", severity = 1, treated = false })
        > Config.BandagePriority({ type = "contusion", severity = 2, treated = false }),
        "la venda antepone un moretón medio a un balazo leve: la urgencia es el sangrado")
    check(Config.BandagePriority({ type = "bala", severity = 1, treated = false })
        > Config.BandagePriority({ type = "contusion", severity = Config.SEVERITY_MAX,
            treated = false }),
        "una contusión al máximo de severidad le gana a un sangrado (el peso no domina)")
    check(Config.BandagePriority({ type = "bala", severity = 2, treated = false })
        > Config.BandagePriority(moreton),
        "a igual severidad la venda no prioriza la herida que sangra")
    -- ...pero dentro de cada grupo la severidad sigue ordenando
    check(Config.BandagePriority({ type = "bala", severity = 3, treated = false })
        > Config.BandagePriority({ type = "bala", severity = 1, treated = false }),
        "entre dos sangrantes la venda no prioriza la más grave")
    check(Config.BandagePriority({ type = "contusion", severity = 3, treated = false })
        > Config.BandagePriority(moreton),
        "entre dos contusiones la venda no prioriza la más grave")
    -- El peso del sangrado sale de SEVERITY_MAX (COA-35) y ese techo es el que aplica
    -- AddWound al agravar: si BLEED_BASE creciera sin que crezca el techo, una herida
    -- muy grave podría empatarle a un sangrado
    local nSev = 0
    for _ in pairs(Config.BLEED_BASE) do nSev = nSev + 1 end
    check(nSev == Config.SEVERITY_MAX, "BLEED_BASE no cubre exactamente SEVERITY_MAX niveles")
    check(Config.BLEED_BASE[Config.SEVERITY_MAX] ~= nil, "BLEED_BASE sin el nivel máximo")


    -- Dolor (§17, COA-52) — la parte PURA, que corre en los dos realms. Lo que se
    -- puede mirar desde adentro del juego con `coagulant_selftest`; el resto (la
    -- agregación, la supresión, el snapshot) vive en el harness offline.
    check(isfunction(Config.PainFromWound) and isfunction(Config.PainFrac),
        "faltan las funciones puras del dolor (COA-52)")
    check(math.abs(Config.PainFromWound("bala", 1)
            - Config.PAIN_PER_WOUND * Config.PAIN_TYPE.bala * Config.PAIN_SEVERITY[1]) < 0.001,
        "PainFromWound no es PAIN_PER_WOUND × PAIN_TYPE × PAIN_SEVERITY (COA-52 D3)")
    check(Config.PainFromWound("tipo_inexistente", 1) == 0,
        "PainFromWound no es nil-safe con un tipo sin fila (COA-52)")
    -- Todo tipo de herida VIVO tiene que producir dolor: el emisor del snapshot
    -- pregunta «¿aporta dolor?» en vez de «¿tiene heridas?» (COA-52), y sin esta
    -- cobertura un tipo nuevo sacaría su zona de la red en silencio.
    for tipo in pairs(Config.WOUND_TYPES) do
        check(isnumber(Config.PAIN_TYPE[tipo]) and Config.PAIN_TYPE[tipo] > 0,
            "el tipo de herida " .. tipo .. " no tiene fila en PAIN_TYPE (COA-52)")
    end
    for _, zona in ipairs(COAGULANT.Zones.LIST) do
        check(isnumber(Config.ZONE_PAIN_WEIGHT[zona]),
            "ZONE_PAIN_WEIGHT sin la zona " .. tostring(zona) .. " (COA-52 D1)")
    end
    -- La rampa satura en PAIN_FULL_AT y NO en PAIN_MAX (COA-52 D2): con 100 la mitad
    -- de arriba estaría muerta y una zona con dolor 7 pintaría casi roja.
    check(Config.PainFrac(Config.PAIN_FULL_AT) == 1 and Config.PainFrac(0) == 0,
        "PainFrac no satura en PAIN_FULL_AT (COA-52 D2)")
    check(Config.PainFrac(7) < 0.2, "una zona con dolor 7 se pinta casi roja (COA-52 D2)")

    -- Tratamiento (slice 2, §7): tabla completa y consistente. La lista sale de la
    -- PROPIA tabla, no de un enum escrito a mano: el quinto tratamiento (el
    -- analgésico, 2026-08-25) entró sin tocar esta línea, y el sexto también.
    for kind, t in pairs(Config.TREATMENTS) do
        check(istable(t) and isnumber(t.time) and t.time > 0 and isstring(t.item),
            "TREATMENTS." .. kind .. " incompleto")
    end

    local nExt = 0
    for _ in pairs(Config.EXTREMITIES) do nExt = nExt + 1 end
    check(nExt == 4, "EXTREMITIES no tiene 4 zonas")

    -- Debuffs (slice 3, §6): curvas puras — el server publica con ellas y el
    -- cliente pinta con ellas, así que un desvío acá desincroniza los dos realms
    check(Config.LimpMult(0) == 1, "sin heridas de pierna la cojera no es 1.0")
    check(math.abs(Config.LimpMult(2) - 0.76) < 0.001, "cojera con score 2 incorrecta")
    check(Config.LimpMult(100) == Config.LIMP_MIN_MULT, "la cojera no respeta su piso")
    check(Config.SwayAmplitude(0) == 0, "sway sin heridas de brazo")
    check(math.abs(Config.SwayAmplitude(2) - Config.SWAY_PER_SCORE * 2) < 0.001,
        "amplitud de sway incorrecta")

    -- Sway en dos capas (§6): apuntar tiene que doler mucho más que estar idle
    local ampBase = Config.SwayAmplitude(2)
    check(Config.SwayFor(2, true) > Config.SwayFor(2, false),
        "apuntar no agrava el sway (la capa ADS no muerde)")
    check(math.abs(Config.SwayFor(2, true) - ampBase * Config.SWAY_ADS_MULT) < 0.001,
        "la capa ADS del sway no aplica su multiplicador")
    check(math.abs(Config.SwayFor(2, false) - ampBase * Config.SWAY_IDLE_MULT) < 0.001,
        "la capa idle del sway no aplica su multiplicador")
    check(Config.SwayFor(0, true) == 0, "sway con los brazos sanos")

    -- La transición entre capas es una CURVA, no un escalón (ronda 6): smoothstep con
    -- extremos exactos y monótona en el medio — si no, la mira daría el tirón que el
    -- autor reportó como "tosco".
    check(Config.SwayEase(0) == 0 and Config.SwayEase(1) == 1,
        "la curva del sway no respeta sus extremos")
    check(math.abs(Config.SwayEase(0.5) - 0.5) < 0.001, "la curva del sway no es simétrica")
    check(Config.SwayEase(-5) == 0 and Config.SwayEase(5) == 1, "la curva del sway no clampea")

    local prevAmp, monotona = -1, true
    for i = 0, 10 do
        local a = Config.SwayFor(2, i / 10)
        if a < prevAmp - 0.0001 then monotona = false end
        prevAmp = a
    end
    check(monotona, "la rampa del sway no crece de idle a ADS")
    check(Config.SwayFor(2, 0.5) > Config.SwayFor(2, 0)
        and Config.SwayFor(2, 0.5) < Config.SwayFor(2, 1),
        "la mitad de la rampa del sway no cae entre las dos capas")

    -- La deriva es acotada y sobre todo HORIZONTAL (pedido del autor, ronda 5)
    local maxYaw, maxPitch = 0, 0
    for i = 0, 300 do
        local y, p = Config.SwayOffset(i * 0.13, 1)
        maxYaw, maxPitch = math.max(maxYaw, math.abs(y)), math.max(maxPitch, math.abs(p))
    end
    check(maxYaw <= 1.001, "la deriva del sway se escapa de su amplitud")
    check(maxPitch < maxYaw, "el sway no es principalmente horizontal")
    check(maxPitch <= Config.SWAY_VERTICAL + 0.001, "el cabeceo del sway excede su fracción")
    check(Config.VisionIntensity(0) == 0, "visión afectada sin heridas de cabeza")
    check(Config.VisionIntensity(Config.VISION_FULL_AT) == 1, "la visión no satura en VISION_FULL_AT")
    check(Config.VisionIntensity(999) == 1, "la visión pasa de 1 (falta clamp)")
    check(Config.CriticalIntensity(Config.BLOOD_MAX) == 0, "capa crítica con sangre llena")
    check(Config.CriticalIntensity(Config.BLOOD_CRITICAL) == 0, "capa crítica justo en el umbral")
    check(Config.CriticalIntensity(0) == 1, "la capa crítica no satura con sangre 0")

    -- UI (slice 4, §10): las puras que comparten el HUD y el menú médico. El dibujo y
    -- el área clickeable salen de la MISMA tabla — un desvío acá y el jugador le erra
    -- a la zona que quería vendar.
    check(#Config.SILHOUETTE == #COAGULANT.Zones.LIST, "la silueta no cubre las 7 zonas")
    local vistas = {}
    for _, p in ipairs(Config.SILHOUETTE) do
        check(COAGULANT.Zones.IsValid(p.zone), "la silueta nombra una zona inexistente: " .. tostring(p.zone))
        check(not vistas[p.zone], "la silueta repite una zona: " .. tostring(p.zone))
        vistas[p.zone] = true
        check(p.x >= 0 and p.y >= 0 and p.x + p.w <= 1 and p.y + p.h <= 1,
            "la zona " .. p.zone .. " se sale de la caja de la silueta")
        -- el centro de cada rect tiene que resolver a SU zona: es el contrato entre
        -- lo que se pinta y lo que se clickea
        check(Config.ZoneAt(p.x + p.w * 0.5, p.y + p.h * 0.5) == p.zone,
            "ZoneAt no resuelve el centro de " .. p.zone)
    end
    check(Config.ZoneAt(-0.5, -0.5) == nil, "ZoneAt inventa una zona fuera de la caja")

    check(Config.ZoneDamageFrac(0) == 0, "zona sana con color de herida")
    check(Config.ZoneDamageFrac(Config.ZONE_FULL_AT) == 1, "el color de zona no satura")
    check(Config.ZoneDamageFrac(999) == 1, "el color de zona pasa de 1 (falta clamp)")

    -- Barra de tratamiento: se calcula client-side desde {endsAt, duration} (§9)
    check(Config.TreatmentProgress(nil, 0) == 0, "progreso sin tratamiento")
    local trFake = { endsAt = 100, duration = 4 }
    check(Config.TreatmentProgress(trFake, 96) == 0, "la barra no arranca en 0")
    check(math.abs(Config.TreatmentProgress(trFake, 98) - 0.5) < 0.001, "la barra no va por la mitad")
    check(Config.TreatmentProgress(trFake, 100) == 1, "la barra no llega a 1 al terminar")
    check(Config.TreatmentProgress(trFake, 200) == 1, "la barra pasa de 1 (falta clamp)")

    -- El snapshot viaja con claves de una letra; las curvas esperan la herida entera
    local wSnap = Config.WoundFromSnap({ t = "bala", s = 3, tr = nil })
    check(wSnap.type == "bala" and wSnap.severity == 3 and wSnap.treated == nil,
        "WoundFromSnap no traduce la herida del snapshot")
    check(Config.BleedRate(wSnap) > 0, "una herida grave del snapshot no sangra")
    check(Config.BleedRate(Config.WoundFromSnap({ t = "bala", s = 3, tr = true })) == 0,
        "una herida tratada del snapshot sigue sangrando")

    if CLIENT then
        check(istable(COAGULANT.HUD), "el cliente no expone la superficie HUD")
        check(isfunction(COAGULANT.HUD.DrawSilhouette), "falta DrawSilhouette (la usan HUD y menú)")
        check(isfunction(COAGULANT.HUD.ZoneScore), "falta ZoneScore en la superficie HUD")
        check(isfunction(COAGULANT.HUD.ZoneBleeding), "falta ZoneBleeding en la superficie HUD")
        check(Config.cv_hud ~= nil, "falta la convar de cliente coagulant_hud")
    end

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

            -- efecto venda puro: cierra leve/media; una grave cuesta 2 (§7).
            -- La grave va a stomach: ejercita una de las dos zonas nuevas (COA-8)
            check(COAGULANT.BandageEffect(ply, "left_arm") == true, "BandageEffect sin efecto")
            check(COAGULANT.IsBleeding(ply) == false, "la venda no cortó el sangrado")
            check(COAGULANT.GetZoneScore(ply, "left_arm") == 1, "herida tratada no cuenta la mitad")
            COAGULANT.AddWound(ply, "stomach", "bala", 3)
            COAGULANT.BandageEffect(ply, "stomach")
            check(COAGULANT.IsBleeding(ply) == true, "una sola venda cerró una grave")
            COAGULANT.BandageEffect(ply, "stomach")
            check(COAGULANT.IsBleeding(ply) == false, "dos vendas no cerraron la grave")

            -- Motor de tratamiento (slice 2): arranca (brazo herido → +25%) y cancela.
            -- Con Cargo montado el motor EXIGE la unidad en el inventario (§7): el
            -- selftest se auto-abastece y DEVUELVE lo que pidió prestado. Sin esto, un
            -- jugador sin vendas vería fallos que no son del código (falso negativo que
            -- el harness destapó: en juego solo pasaba porque Cargo persiste el
            -- inventario entre sesiones).
            COAGULANT.AddWound(ply, "right_leg", "bala", 2)
            local cargoInv = Corpus.HasModule("cargo") and Corpus.GetModule("cargo").Inventory or nil
            local itemVenda = Config.TREATMENTS.bandage.item
            local prestada = false
            if cargoInv ~= nil and not cargoInv.HasItem(ply, itemVenda) then
                prestada = cargoInv.GiveItem(ply, itemVenda, 1) == true
            end

            if cargoInv == nil or cargoInv.HasItem(ply, itemVenda) then
                local ok, err = COAGULANT.ApplyTreatment(ply, "bandage")
                check(ok == true, "ApplyTreatment bandage no arrancó: " .. tostring(err))
                check(istable(st.treatment) and st.treatment.kind == "bandage",
                    "st.treatment no quedó seteado")
                check(istable(st.treatment)
                    and st.treatment.duration > Config.TREATMENTS.bandage.time,
                    "brazo herido no encarece el tiempo (+25%)")
                local ok2, err2 = COAGULANT.ApplyTreatment(ply, "bandage")
                check(ok2 == false and isstring(err2), "permitió dos tratamientos a la vez")
                COAGULANT.CancelTreatment(ply, "selftest")
                check(st.treatment == nil, "CancelTreatment no limpió")
            else
                Corpus.Log("coagulant", "selftest: no se pudo conseguir una venda "
                    .. "(¿inventario lleno?) — arranque de tratamiento omitido")
            end
            if prestada then cargoInv.TakeItem(ply, itemVenda, 1) end

            -- la zona se valida ANTES que el ítem: esto rechaza aunque no haya
            -- torniquete (chest es válida como zona pero no es extremidad)
            check(COAGULANT.ApplyTreatment(ply, "tourniquet", "chest") == false,
                "torniquete aceptó una zona no-extremidad")

            -- Debuffs (slice 3): scores por par de zonas y publicación de la cojera.
            -- El Move hook (shared) solo LEE el NW2 — si no se publica, no hay cojera.
            COAGULANT.ResetState(ply)
            check(COAGULANT.GetLegScore(ply) == 0 and COAGULANT.GetArmScore(ply) == 0,
                "los scores de extremidades no arrancan en cero")
            check(COAGULANT.RefreshSpeed(ply) == 1, "la cojera sin heridas no es 1.0")

            COAGULANT.AddWound(ply, "left_leg", "bala", 2)
            COAGULANT.AddWound(ply, "right_leg", "bala", 1)
            check(COAGULANT.GetLegScore(ply) == 3, "GetLegScore no suma las dos piernas")
            local mult = COAGULANT.RefreshSpeed(ply)
            check(math.abs(mult - Config.LimpMult(3)) < 0.001, "RefreshSpeed no aplica la curva")
            check(math.abs(ply:GetNW2Float("coagulant_speed_mult", 1) - mult) < 0.001,
                "la cojera no viajó por NW2 (el Move hook la leería como 1)")

            COAGULANT.AddWound(ply, "right_arm", "bala", 2)
            check(COAGULANT.GetArmScore(ply) == 2, "GetArmScore incorrecto")
            check(COAGULANT.GetLegScore(ply) == 3, "una herida de brazo movió el score de piernas")

            -- El medkit borra la secuela TRATADA (§7): es la única cura del debuff
            -- permanente. Sin esto, una pierna vendada te deja cojo hasta morir
            -- (reportado en juego, ronda 5, H3).
            COAGULANT.ResetState(ply)
            COAGULANT.AddWound(ply, "left_leg", "bala", 2)
            COAGULANT.BandageEffect(ply, "left_leg")
            check(COAGULANT.GetZoneScore(ply, "left_leg") == 1,
                "la herida tratada no cuenta la mitad")
            check(COAGULANT.WorstTreatedZone(ply) == "left_leg",
                "WorstTreatedZone no encuentra la secuela (el medkit iría a la zona equivocada)")
            check(COAGULANT.HealTreatedWounds(ply, "left_leg") == 1,
                "el medkit no cierra la herida tratada")
            check(COAGULANT.GetZoneScore(ply, "left_leg") == 0,
                "la secuela sobrevive al medkit: el debuff seguiría para siempre")
            check(COAGULANT.WorstTreatedZone(ply) == nil, "quedó secuela tratada tras curarla")

            -- ...pero NO toca las heridas sin vendar: primero se cierra el sangrado
            COAGULANT.AddWound(ply, "left_leg", "bala", 2)
            check(COAGULANT.HealTreatedWounds(ply, "left_leg") == 0,
                "el medkit cerró una herida SIN vendar")
            check(COAGULANT.IsBleeding(ply) == true,
                "el medkit cortó un sangrado que nadie había tratado")

            -- COA-37 — El circuito COMPLETO de una contusión, de punta a punta. Es el
            -- invariante que compra la enmienda: NINGUNA herida es incurable en vida.
            -- Antes, un moretón de caída pesaba entero en la cojera hasta morir.
            COAGULANT.ResetState(ply)
            COAGULANT.AddWound(ply, "left_leg", "contusion", 2)
            check(COAGULANT.IsBleeding(ply) == false, "la contusión sangra")
            check(COAGULANT.GetZoneScore(ply, "left_leg") == 2,
                "la contusión no pesa entero en el score de zona")
            check(COAGULANT.WorstOpenZone(ply) == "left_leg",
                "la zona automática de la venda no ve una contusión (uso rápido roto)")
            check(COAGULANT.BandageEffect(ply, "left_leg") == true,
                "la venda no cierra una contusión")
            check(COAGULANT.GetZoneScore(ply, "left_leg") == 1,
                "la contusión vendada no cuenta la mitad")
            check(COAGULANT.HealTreatedWounds(ply, "left_leg") == 1,
                "el medkit no cierra la contusión ya vendada")
            check(COAGULANT.GetZoneScore(ply, "left_leg") == 0,
                "la contusión sobrevive al circuito venda→medkit: cojera permanente")
            check(COAGULANT.BandageEffect(ply, "left_leg") == false,
                "la venda se gasta en una zona sin heridas abiertas")

            -- ...y el orden, en vivo, con EL CASO que el autor reportó en juego (check 4
            -- ✗, 2026-07-29): balazo LEVE + moretón MEDIO en la misma zona. La venda
            -- tiene que ir al balazo aunque el moretón sea más grave y entre primero en
            -- la lista — la urgencia es la hemorragia, no la severidad.
            COAGULANT.ResetState(ply)
            COAGULANT.AddWound(ply, "chest", "contusion", 2)
            COAGULANT.AddWound(ply, "chest", "bala", 1)
            COAGULANT.BandageEffect(ply, "chest")
            check(COAGULANT.IsBleeding(ply) == false,
                "la venda se fue al moretón medio y dejó el balazo leve drenando")
            check(COAGULANT.GetZoneScore(ply, "chest") == 2.5,
                "la venda no cerró el balazo (score esperado: moretón 2 + balazo tratado 0.5)")

            -- ...y la segunda venda ya sí va al moretón: cuando no queda nada sangrando,
            -- la contusión es lo que sigue (sin esto volvería a ser incurable)
            COAGULANT.BandageEffect(ply, "chest")
            check(COAGULANT.GetZoneScore(ply, "chest") == 1.5,
                "la segunda venda no atendió el moretón una vez cortado el sangrado")

            -- El torniquete se puede QUITAR aunque la zona ya no sangre. La zona
            -- automática solo miraba extremidades SANGRANTES, así que en cuanto
            -- vendabas la zona el torniquete quedaba clavado para siempre (bug
            -- reportado en juego, ronda 5, H4). Quitarlo no consume ni exige ítem.
            COAGULANT.ResetState(ply)
            local stTq = COAGULANT.GetState(ply)
            stTq.zones.right_leg.tourniquet = true
            stTq.zones.right_leg.tourniquetAt = CurTime()
            COAGULANT.AddWound(ply, "right_leg", "bala", 2)
            COAGULANT.BandageEffect(ply, "right_leg") -- la zona deja de sangrar
            local okQuitar, errQuitar = COAGULANT.ApplyTreatment(ply, "tourniquet")
            check(okQuitar == true, "no se puede quitar el torniquete de una zona que ya "
                .. "no sangra: " .. tostring(errQuitar))
            check(istable(stTq.treatment) and stTq.treatment.removing == true,
                "el toggle no detectó que había que QUITAR el torniquete")
            check(isfunction(COAGULANT.IsIschemic), "IsIschemic no es función")
            COAGULANT.CancelTreatment(ply, "selftest")

            -- DOLOR (§17, COA-52), round-trip con un cuerpo de verdad. No se usa
            -- ApplyTreatment del analgésico acá a propósito: eso exige la unidad en
            -- el inventario y el selftest tiene que correr igual sin Cargo (§14).
            COAGULANT.ResetState(ply)
            check(COAGULANT.ZonePain(ply, "chest") == 0, "una zona sana duele")
            -- Severidad 2 y no 3 a propósito: sobre una GRAVE la venda baja la
            -- severidad sin cerrar (§7), así que el reparto de tratada no llegaría a
            -- ejercitarse y la fila mediría otra cosa.
            COAGULANT.AddWound(ply, "chest", "metralla", 2)
            local dolorAct = COAGULANT.ZonePain(ply, "chest")
            check(math.abs(dolorAct - Config.PainFromWound("metralla", 2)) < 0.001,
                "una herida activa no pesa entera en el dolor de la zona (COA-52 D4)")
            COAGULANT.BandageEffect(ply, "chest")
            -- vendar tiene que ALIVIAR. La comparación es contra el dolor de ANTES y
            -- no contra PAIN_TREATED_MULT: un check derivado de la constante sigue
            -- verde con la constante puesta en 1.0, o sea que no la puede auditar.
            check(COAGULANT.ZonePain(ply, "chest") < dolorAct,
                "vendar no alivia el dolor de la zona (COA-52 D4)")
            check(COAGULANT.GetZoneScore(ply, "chest") == 1,
                "el dolor movió el score de debuff: son dos ejes distintos (COA-52)")


            -- La supresión: lo ÚNICO que el dolor almacena. Con supresión PUESTA —sin
            -- ella, GetPain y GetRawPain devuelven lo mismo y el check pasaría con las
            -- dos funciones intercambiadas.
            COAGULANT.ResetState(ply)
            COAGULANT.AddWound(ply, "chest", "metralla", 3)
            local crudoSt = COAGULANT.GetRawPain(ply)
            check(crudoSt > Config.PAIN_ANALGESIC_AT,
                "el dolor de prueba no llega a la puerta del analgésico (COA-52)")
            COAGULANT.AddPainSuppression(ply, Config.PAIN_SUPPRESS.oral)
            check(math.abs(COAGULANT.GetPain(ply) - (crudoSt - Config.PAIN_SUPPRESS.oral)) < 0.001,
                "el percibido no es crudo − supresión (COA-52 D5)")
            check(math.abs(COAGULANT.GetRawPain(ply) - crudoSt) < 0.001,
                "la supresión tocó el dolor CRUDO: enmascara, no cura (COA-52 D5)")
            check(COAGULANT.GetPain(ply) <= Config.PAIN_ANALGESIC_AT,
                "tras la dosis el percibido no cayó bajo la puerta: la 2.ª dosis no se desgatilla sola (COA-52 D5)")
            COAGULANT.AddPainSuppression(ply, Config.PAIN_SUPPRESS_MAX * 2)
            check(math.abs(COAGULANT.GetState(ply).painSuppress - Config.PAIN_SUPPRESS_MAX) < 0.001,
                "AddPainSuppression no clampea en PAIN_SUPPRESS_MAX (COA-52 D5)")
            check(COAGULANT.GetPain(ply) == 0,
                "el percibido bajó de 0 con la supresión por encima del crudo (COA-52 D5)")


            -- ============================================================
            -- Condiciones externas y palancas (§8, COA-38/39/40)
            -- ============================================================
            COAGULANT.ResetState(ply)

            -- La PUERTA: un id que Coagulant no implementa se rechaza. Es lo que le
            -- avisa al emisor que ese daño sigue siendo suyo, en vez de tragárselo.
            check(COAGULANT.ApplyExternalCondition(ply, "starvation", 0.5) == true,
                "ApplyExternalCondition rechazó un id que SÍ implementa (COA-39)")
            check(COAGULANT.ApplyExternalCondition(ply, "radiation", 1) == false,
                "ApplyExternalCondition ACEPTÓ un id que no implementa: el emisor creería que ese daño ya es de Coagulant (COA-39/43)")
            -- ⚠ Y el que más importa: el STAT del emisor no es un id clínico. Si esto
            -- pasara, switchear sobre el stat compilaría y la inanición quedaría
            -- inofensiva en silencio — el modo de falla que §8 nombra por escrito.
            check(COAGULANT.ApplyExternalCondition(ply, "hunger", 1) == false,
                "ApplyExternalCondition aceptó el STAT del emisor como id clínico (§8): hunger no es starvation")

            check(math.abs(COAGULANT.GetExternalCondition(ply, "starvation") - 0.5) < 0.001,
                "GetExternalCondition no devuelve la severity vigente")
            -- severity 0 LIMPIA, no guarda un cero (contrato congelado por Craving)
            COAGULANT.ApplyExternalCondition(ply, "starvation", 0)
            check(COAGULANT.GetState(ply).conditions.starvation == nil,
                "severity 0 no LIMPIÓ la condición: quedó un cero guardado (COA-39)")

            -- La regeneración se anula con starvation en 1 — literal de la tabla de §8
            check(math.abs(COAGULANT.RegenFactor(ply) - 1) < 0.001,
                "sin condiciones el factor de regeneración no es 1 (COA-40)")
            COAGULANT.ApplyExternalCondition(ply, "starvation", 1)
            check(COAGULANT.RegenFactor(ply) == 0,
                "starvation en 1 no ANULA la regeneración (§8)")
            -- ...y es PROPORCIONAL, no un interruptor: con la mitad, la mitad.
            COAGULANT.ApplyExternalCondition(ply, "starvation", 0.5)
            check(math.abs(COAGULANT.RegenFactor(ply) - 0.5) < 0.001,
                "la supresión de regeneración no es proporcional a severity (§8)")

            -- El techo: dehydration lo baja, starvation NO. Son dos ids distintos y
            -- la tabla dice que sólo uno toca el plasma.
            COAGULANT.ResetState(ply)
            check(math.abs(COAGULANT.BloodCap(ply) - Config.BLOOD_MAX) < 0.001,
                "sin condiciones el techo de sangre no es BLOOD_MAX")
            COAGULANT.ApplyExternalCondition(ply, "starvation", 1)
            check(math.abs(COAGULANT.BloodCap(ply) - Config.BLOOD_MAX) < 0.001,
                "starvation bajó el techo de sangre: eso es de dehydration (§8)")
            -- ⚠ Se LIMPIA starvation antes de seguir. Sin esto, el check de abajo
            -- daba verde por la condición equivocada: la regeneración estaba en 0 por
            -- el hambre, no por la sed, y borrarle el `regen` a dehydration no movía
            -- nada. Lo cazó la verificación en negativo (#7), no la lectura.
            COAGULANT.ApplyExternalCondition(ply, "starvation", 0)
            COAGULANT.ApplyExternalCondition(ply, "dehydration", 1)
            check(COAGULANT.BloodCap(ply) < Config.BLOOD_MAX,
                "dehydration en 1 no bajó el techo de sangre (§8)")
            -- El «ADEMÁS de lo anterior» de la tabla ratificada es literal: deshidratarse
            -- hace todo lo que hace pasar hambre, MÁS el plasma. Sin esta fila, una
            -- dehydration que sólo baja el techo pasa el auto-test entera.
            check(COAGULANT.RegenFactor(ply) == 0,
                "dehydration no heredó el freno de regeneración de starvation: el «además de lo anterior» de §8 es literal")

            -- La rampa del déficit, que es lo que traduce un crudo de Craving a un
            -- número de Coagulant. El umbral es NUESTRO (contraparte de CRV-24).
            check(Config.MetabolicDeficit(Config.METABOLIC_DEFICIT_AT) == 0,
                "en el umbral de déficit ya hay déficit: la rampa arranca donde no debe")
            check(math.abs(Config.MetabolicDeficit(0) - 1) < 0.001,
                "con el crudo en 0 el déficit no es total")
            check(math.abs(Config.MetabolicDeficit(Config.METABOLIC_DEFICIT_AT / 2) - 0.5) < 0.001,
                "la rampa de déficit no es lineal a mitad de umbral")

            -- Lo que SÍ se puede afirmar desde acá: la lectura del techo es PURA —
            -- consultarlo no mueve la sangre. Es poco, y por eso está dicho: la
            -- propiedad que de verdad importa («techa y FRENA, nunca mata») vive en el
            -- TICK, y un selftest que no corre el tick no puede tocarla. Esa la mide
            -- el harness (familia MET-*), que sí lo hace correr. Escribir acá un
            -- `blood == blood` con dos líneas de por medio habría dado VERDE siempre y
            -- habría acreditado la propiedad sin ejercerla nunca.
            local sangreAntes = COAGULANT.GetState(ply).blood
            check(sangreAntes > COAGULANT.BloodCap(ply),
                "precondición: la sangre de prueba no quedó por ENCIMA del techo")
            COAGULANT.BloodCap(ply); COAGULANT.RegenFactor(ply); COAGULANT.BleedFactor(ply)
            check(COAGULANT.GetState(ply).blood == sangreAntes,
                "leer las palancas movió la sangre: son consultas, no efectos")

            COAGULANT.ResetState(ply) -- dejar limpio
            -- ...y limpio DE VERDAD: el reset tiene que despublicar la cojera de las
            -- heridas de prueba, no dejarla hasta el próximo tick (ronda 7, ×0.64)
            check(ply:GetNW2Float("coagulant_speed_mult", 1) == 1,
                "ResetState dejó publicada la cojera vieja en el NW2")
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
        -- El torniquete (unique) exige Inventory.HasItem — un Cargo sin esa
        -- superficie reproduce el fallo G4 de la ronda 3 (CountItem no ve uniques)
        if SERVER then
            check(istable(cargo.Inventory) and isfunction(cargo.Inventory.HasItem),
                "Cargo montado sin Inventory.HasItem (desactualizado: el torniquete lo requiere)")
            check(isfunction(cargo.Inventory.TakeUnique),
                "Cargo montado sin Inventory.TakeUnique (desactualizado: ocupar el torniquete lo exige)")
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
            local isq = COAGULANT.IsIschemic(objetivo, zona)
            local dolor = COAGULANT.ZonePain(objetivo, zona)
            -- Mismo predicado que el emisor del snapshot (§9, COA-52): «aporta
            -- dolor, torniquete o isquemia». Si la consola y la red no se hicieran
            -- la misma pregunta, una zona podría viajar y no imprimirse.
            if dolor ~= 0 or zdata.tourniquet or isq then

                local partes = {}
                for _, w in ipairs(zdata.wounds) do
                    partes[#partes + 1] = string.format("%s sev%d%s",
                        w.type, w.severity, w.treated and " (tratada)" or "")
                end

                -- El torniquete y la isquemia se imprimen con SUS RELOJES: sin esto,
                -- el ciclo de isquemia es invisible en juego (ronda 5, H4)
                local marcas = ""
                if zdata.tourniquet then
                    local puesto = zdata.tourniquetAt and (CurTime() - zdata.tourniquetAt) or 0
                    marcas = marcas .. string.format(" [torniquete %.0fs/%ds]",
                        puesto, COAGULANT.Config.TOURNIQUET_ISCHEMIA_S)
                end
                if isq then
                    local resto = zdata.ischemiaUntil and (zdata.ischemiaUntil - CurTime()) or nil
                    marcas = marcas .. (resto ~= nil
                        and string.format(" [ISQUEMIA — %.0fs restantes]", math.max(0, resto))
                        or " [ISQUEMIA activa]")
                end

                Corpus.Log("coagulant", string.format("  %s (score %.1f · dolor %.0f): %s%s",
                    zona, COAGULANT.GetZoneScore(objetivo, zona), dolor,
                    #partes > 0 and table.concat(partes, ", ") or "sin heridas", marcas))
            end
        end

        -- DOLOR, en sus DOS formas, y eso no es adorno (§17, COA-52): el crudo es lo
        -- que el cuerpo tiene y el percibido es lo que el paciente sufre. Imprimir
        -- sólo uno deja «no duele» y «está tapado» indistinguibles, que es
        -- exactamente el estado que el analgésico fabrica. Renglón propio y corto: la
        -- consola de GMod trunca en 255 caracteres.
        Corpus.Log("coagulant", string.format(
            "  dolor — crudo %.0f | percibido %.0f | supresión %.1f/%d (−%.2f/s)",
            COAGULANT.GetRawPain(objetivo), COAGULANT.GetPain(objetivo),
            st.painSuppress or 0, COAGULANT.Config.PAIN_SUPPRESS_MAX,
            COAGULANT.Config.PAIN_SUPPRESS_DECAY_PER_S))

        if not COAGULANT.IsBleeding(objetivo) then
            Corpus.Log("coagulant", "  sin sangrado activo")
        end

        -- METABOLISMO Y CONDICIONES EXTERNAS (§8, COA-38/39/40). Se imprimen las tres
        -- capas por separado porque contestan preguntas distintas y confundirlas es
        -- justo el modo de falla del tramo: qué te EMPUJARON (condición), qué LEÍSTE
        -- de Craving (déficit) y qué EFECTO quedó vigente (las palancas). Con sólo el
        -- efecto, «Craving no está montado» y «Craving dice que estás bien» se leen
        -- igual — y son el bug y el sano.
        local condiciones = {}
        for id, sev in pairs(st.conditions or {}) do
            condiciones[#condiciones + 1] = string.format("%s %.2f", id, sev)
        end
        Corpus.Log("coagulant", "  condiciones externas — " .. (#condiciones > 0
            and table.concat(condiciones, ", ") or "ninguna"))

        local deficits = COAGULANT.Config.MetabolicDeficits(objetivo)
        if deficits == nil then
            -- NO es lo mismo que «sin déficit», y por eso tiene renglón propio.
            Corpus.Log("coagulant", "  metabolismo — Craving AUSENTE (palancas neutras)")
        else
            local partesMeta = {}
            for _, fila in ipairs(COAGULANT.Config.METABOLIC) do
                partesMeta[#partesMeta + 1] = string.format("%s %.0f%%%s", fila.id,
                    (deficits[fila.id] or 0) * 100, fila.live and "" or " (sin palanca)")
            end
            Corpus.Log("coagulant", "  metabolismo — déficit: " .. table.concat(partesMeta, ", "))
        end

        Corpus.Log("coagulant", string.format(
            "  palancas — techo sangre %.1f/%d | regen ×%.2f | sangrado ×%.2f",
            COAGULANT.BloodCap(objetivo), COAGULANT.Config.BLOOD_MAX,
            COAGULANT.RegenFactor(objetivo), COAGULANT.BleedFactor(objetivo)))

        -- Debuffs (§6). La velocidad se lee del NW2 REAL — es el número que el hook
        -- Move aplica de verdad; la curva teórica no dice si la convar está apagada.
        local cfg = COAGULANT.Config
        local piernas = COAGULANT.GetLegScore(objetivo)
        local brazos  = COAGULANT.GetArmScore(objetivo)
        local cabeza  = COAGULANT.GetZoneScore(objetivo, "head")
        Corpus.Log("coagulant", string.format(
            "  debuffs — piernas: score %.1f → velocidad ×%.2f | brazos: score %.1f → sway %.2f° idle / %.2f° apuntando | cabeza: score %.1f → visión %d%%",
            piernas, objetivo:GetNW2Float("coagulant_speed_mult", 1),
            brazos, cfg.SwayFor(brazos, false), cfg.SwayFor(brazos, true),
            cabeza, math.Round(cfg.VisionIntensity(cabeza) * 100)))

        -- La secuela tratada solo la borra el medkit (§7): decir DÓNDE iría el próximo
        local secuela = COAGULANT.WorstTreatedZone(objetivo)
        if secuela ~= nil then
            Corpus.Log("coagulant", "  secuela tratada (la cierra un Medkit): " .. secuela)
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
        cargo.Inventory.GiveItem(objetivo, "corpus_coagulant_painkillers", 2)
        Corpus.Log("coagulant", "kit médico de prueba entregado a " .. objetivo:Nick()
            .. " (3 vendas, 1 torniquete, 2 medkits, 2 bolsas, 2 analgésicos)")

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

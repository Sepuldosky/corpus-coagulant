-- corpus_coagulant_config.lua — convars + tablas de balance + funciones puras (SHARED)
-- Coagulant_Architecture.md §3-§5, §11. Los números viven acá como data: se tunean
-- editando este archivo o por convar, sin tocar lógica. Todo lo de este archivo es
-- puro (sin hooks, sin estado de jugador).

local COAGULANT = Corpus.GetModule("coagulant")

COAGULANT.Config = COAGULANT.Config or {}
local Config = COAGULANT.Config

-- ============================================================
-- Convars (§11). Replicadas para que el cliente (HUD, slice 4) lea los mismos
-- valores sin net propio.
-- ============================================================
local FLAGS = { FCVAR_ARCHIVE, FCVAR_REPLICATED }
Config.cv_enabled       = CreateConVar("coagulant_enabled", "1", FLAGS, "Enables/disables the whole Coagulant system")
Config.cv_bleed_scale   = CreateConVar("coagulant_bleed_scale", "1.0", FLAGS, "Global blood drain multiplier")
Config.cv_regen_scale   = CreateConVar("coagulant_regen_scale", "1.0", FLAGS, "Natural blood regeneration multiplier")
Config.cv_hpdrain_scale = CreateConVar("coagulant_hpdrain_scale", "1.0", FLAGS, "HP drain multiplier while blood is critical")
Config.cv_debug         = CreateConVar("coagulant_debug", "0", FLAGS, "Logs wounds/critical transitions to console")

-- Debuffs zonales (§6, §11). REPLICADAS por necesidad, no por comodidad: la
-- cojera se aplica en un hook Move PREDICHO (ambos realms) — si el cliente
-- leyera un valor distinto al del server, el jugador haría rubber-band.
Config.cv_debuff_legs = CreateConVar("coagulant_debuff_legs", "1", FLAGS, "Leg wounds slow you down (limp)")
Config.cv_debuff_arms = CreateConVar("coagulant_debuff_arms", "1", FLAGS, "Arm wounds sway your aim")
Config.cv_debuff_head = CreateConVar("coagulant_debuff_head", "1", FLAGS, "Head wounds blur and darken your vision")

-- Convar de CLIENTE (§11): apaga la silueta del HUD. El vignette de sangre crítica
-- NO cuelga de acá a propósito — es información vital, no decoración (§11).
if CLIENT then
    Config.cv_hud = CreateClientConVar("coagulant_hud", "1", true, false,
        "Show the wound silhouette HUD (the critical-blood overlay is never hidden)")
end

function Config.Enabled()
    return Config.cv_enabled:GetBool()
end

-- ============================================================
-- Balance (§2-§5) — propuesta inicial ratificada como tunable
-- ============================================================
Config.BLOOD_MAX      = 100
Config.BLOOD_CRITICAL = 40    -- por debajo: drenaje de HP (§5)
Config.REGEN_PER_S    = 0.10  -- unidades/s sin sangrado activo (~17 min 0→100)
Config.HP_DRAIN_BASE  = 1     -- HP/s al entrar en crítico...
Config.HP_DRAIN_EXTRA = 4     -- ...+ escala lineal hasta +4 con sangre 0

Config.SEVERITY_MEDIUM_AT = 15  -- daño final >= 15 → severidad 2
Config.SEVERITY_GRAVE_AT  = 40  -- daño final  > 40 → severidad 3
Config.SEVERITY_MAX       = 3   -- techo: lo aplica AddWound al agravar, y del él sale
                                -- el peso del sangrado en BandagePriority (COA-35)
Config.MAX_WOUNDS_PER_ZONE = 5  -- al exceder: se agrava la más leve (§3)

-- Drenaje base por severidad (unidades de sangre/s), × mult del tipo × mult de zona
Config.BLEED_BASE = { [1] = 0.15, [2] = 0.40, [3] = 1.00 }

-- Mult de sangrado por zona (§3-§4, enmienda 2026-07-21): nace NEUTRO a propósito —
-- la partición chest/stomach es anatómica, sin diferencia clínica en v1. Es el eje
-- donde un gut shot podrá sangrar distinto cuando el balance se tunee contra el
-- referente ACE y ritmos reales de exanguinación (cita COA-27); si algún día deja
-- de ser neutro, sube stomach, no chest (la base médica está en §3).
Config.ZONE_BLEED_MULT = {
    head      = 1.0,
    chest     = 1.0,
    stomach   = 1.0,
    left_arm  = 1.0,
    right_arm = 1.0,
    left_leg  = 1.0,
    right_leg = 1.0,
}

-- Tipos de herida (§3). label es de cara al jugador (idioma del mod: inglés).
Config.WOUND_TYPES = {
    bala      = { mult = 1.0, label = "Gunshot wound" },
    corte     = { mult = 0.8, label = "Laceration" },
    metralla  = { mult = 0.9, label = "Shrapnel wound" },
    quemadura = { mult = 0.2, label = "Burn" },
    contusion = { mult = 0.0, label = "Bruise" },
}

-- ============================================================
-- Dolor (§17, COA-52) — bajado del diseño votado el 2026-08-17
-- ============================================================
-- Vive ACÁ y no en el core por la misma razón que el sangrado: todo número es
-- balance (COA-27) y un check lo DERIVA, jamás lo hardcodea (COA-35). La tabla
-- es copia literal de la que §17 dejó escrita como PROPUESTA, comentarios
-- incluidos — los comentarios son la mitad que explica por qué PAIN_SEVERITY es
-- menos convexo que BLEED_BASE.
--
-- LO QUE NO ESTÁ ACÁ, y no es olvido: `coagulant_pain_scale`. COA-52 lo niega
-- explícitamente — nadie lo pidió y el tuning ya lo permite esta tabla.
Config.PAIN_MAX      = 100    -- misma escala que blood: la zona Y el global
Config.PAIN_FULL_AT  = 60     -- satura la RAMPA de la silueta, no el estado (espejo
                              -- de ZONE_FULL_AT = 6, que satura en dos heridas graves)

-- Producción (D3). PAIN_TYPE son los valores de ACE3 LITERALES —referente citado,
-- no fuente adoptada—: Avulsion 1.0, VelocityWound 0.9, ThermalBurn 0.7,
-- PunctureWound 0.4, Contusion 0.3, Laceration 0.2. El eje de SEVERIDAD es
-- NUESTRO: la tabla de ACE no tiene ninguno, así que no se podía copiar.
Config.PAIN_PER_WOUND = 40    -- la ÚNICA constante absoluta: la peor herida grave
Config.PAIN_TYPE = {
    metralla  = 1.00,  -- Avulsion — la esquirla arranca tejido (por eso COA-49 la llama sucia)
    bala      = 0.90,  -- VelocityWound
    quemadura = 0.70,  -- ThermalBurn — sangra 0.2 y duele 0.70: el dolor NO es proxy del sangrado
    punzante  = 0.40,  -- PunctureWound — el TIPO NO EXISTE todavía; la fila es inerte hasta que exista
    contusion = 0.30,  -- Contusion
    corte     = 0.20,  -- Laceration
}
-- Menos convexo que BLEED_BASE (1:1.9:2.9 contra 1:2.7:6.7) a propósito: la
-- nocicepción satura y la hemorragia no. Una herida leve duele; casi no sangra.
Config.PAIN_SEVERITY = { [1] = 0.35, [2] = 0.65, [3] = 1.00 }

-- Estado de la herida (D4): mismo reparto que el score de §6, con el tercer estado
-- de COA-49 pesando ENTERO. No hay tasa de decaimiento: el decaimiento del dolor ES
-- el reloj HEAL_S de COA-49.
--
-- ⚠ PAIN_TREATED_MULT es 0.35 y NO el 0.5 con el que GetZoneScore reparte las
-- tratadas. Son dos números distintos A PROPÓSITO —uno es debuff, el otro
-- nocicepción— y copiar el de al lado no da ningún síntoma.
Config.PAIN_TREATED_MULT  = 0.35
Config.PAIN_INFECTED_MULT = 1.00

-- Pisos por condición de zona (D6): espejo de las cláusulas max() de ZoneScore.
-- El TORNIQUETE no está acá a propósito: su reloj de 90 s ya es la isquemia — un
-- reloj, no dos. Lo interesante nunca fue la banda apretada, fue el miembro
-- muriéndose.
Config.PAIN_ISCHEMIA = 60     -- espejo de max(score, ISCHEMIA_SCORE = 6)
Config.PAIN_FRAC     = 30     -- espejo de max(score, 3) — lee 0 hasta que z.frac exista
Config.PAIN_SPLINT   = 12     -- ídem: la fractura con férula sigue diferida por §1

-- Agregación (D1): neutro en las siete, igual que ZONE_BLEED_MULT. Es un eje de
-- tuning, no una decisión clínica de v1.
Config.ZONE_PAIN_WEIGHT = {
    head = 1.0, chest = 1.0, stomach = 1.0,
    left_arm = 1.0, right_arm = 1.0, left_leg = 1.0, right_leg = 1.0,
}

-- Supresión (D5). Los DOS primeros son los painReduce de ACE3 ×100 (Morphine 0.8,
-- PainKillers 0.35). El decaimiento NO es de ACE —su fade es 1800 s— y la desviación
-- es deliberada: largo de sesión de sandbox, el mismo criterio con que este módulo
-- puso la isquemia en 90 s contra los 120 s de ACE.
Config.PAIN_SUPPRESS_MAX         = 100
Config.PAIN_SUPPRESS_DECAY_PER_S = 0.20   -- 80 puntos en ~6,7 min
Config.PAIN_SUPPRESS = { morphine = 80, oral = 35 }

-- La puerta del analgésico. NO es un número nuevo: es el `pain > 10` que el spec v5
-- ya tenía escrito para la morfina, y COA-52 lo deja donde está porque discrimina
-- bien con los números que salen de ACE — un balazo LEVE (12.6) la abre, un rasguño
-- (2.8) o un moretón medio (7.8) no. Vive como constante para que un check la
-- DERIVE (COA-35) en vez de escribir un 10.
--
-- Y lee el PERCIBIDO (D5), que es lo que hace que el apilamiento no necesite una
-- regla nueva: cada dosis acerca el percibido a 0 y la siguiente se desgatilla sola.
Config.PAIN_ANALGESIC_AT = 10


-- ============================================================
-- Tratamiento (§7) — tiempos en segundos, efectos por tipo
-- ============================================================
-- El Medkit es la ÚNICA cura de la secuela (§7, decisión del autor 2026-07-14): una
-- herida vendada deja de sangrar pero su score sigue pesando a la mitad para siempre
-- — el Medkit cierra las heridas ya TRATADAS de una zona. Las no tratadas no: hay
-- que vendarlas primero.
Config.TREATMENTS = {
    bandage    = { time = 4,  item = "corpus_coagulant_bandage" },
    tourniquet = { time = 2,  item = "corpus_coagulant_tourniquet" }, -- aplicar Y quitar
    medkit     = { time = 10, item = "corpus_coagulant_medkit", heal = 50, healsWounds = true },
    bloodbag   = { time = 8,  item = "corpus_coagulant_bloodbag", blood = 40 },
    -- El analgésico ORAL (§17, COA-52 D5). NO cierra ninguna herida ni corta un
    -- sangrado: pone un TECHO al dolor por un rato. Es el otro circuito, no una
    -- segunda entrada del de la venda — por eso no aparece en BandagePriority.
    -- Los 35 puntos salen de PAIN_SUPPRESS.oral (el painReduce 0.35 de ACE ×100).
    painkillers = { time = 3,  item = "corpus_coagulant_painkillers",
                    suppress = Config.PAIN_SUPPRESS.oral },
}

-- Tratamientos que NO usan zona (§7): el ítem opera sobre el cuerpo entero. Vive
-- como tabla y no como una cadena de `or` para que el menú médico, la zona
-- automática y el selftest se hagan la MISMA pregunta — un `kind == "bloodbag"`
-- repetido en tres archivos es la forma en que el quinto tratamiento se olvida en
-- dos de ellos.
Config.TREATMENT_NO_ZONE = { bloodbag = true, painkillers = true }

Config.ARM_TIME_MULT       = 1.25 -- brazo herido: tratamientos más lentos (§6)
Config.TOURNIQUET_ISCHEMIA_S = 90 -- puesto más de esto: isquemia (§7)
Config.ISCHEMIA_LINGER_S   = 60   -- la isquemia persiste tras quitarlo
Config.ISCHEMIA_SCORE      = 6    -- score de debuff que impone la isquemia
Config.DEGRADED_COOLDOWN_S = 30   -- sin Cargo: tratamiento gratis con cooldown (§7)
Config.CANCEL_SPEED_MULT   = 1.15 -- cancelar si velocidad > walk × esto

Config.EXTREMITIES = {
    left_arm = true, right_arm = true, left_leg = true, right_leg = true,
}

-- ============================================================
-- Debuffs zonales (§6) — score de zona = Σ severidades (tratadas cuentan la mitad)
-- ============================================================
Config.LIMP_PER_SCORE  = 0.12  -- cada punto de score de pierna quita 12 % de velocidad
Config.LIMP_MIN_MULT   = 0.45  -- piso: cojo, nunca inmóvil
Config.LIMP_SPEED_FLOOR = 30   -- piso ABSOLUTO en el Move hook (mismo que el movecompat
                               -- de Cargo): componiendo dos multiplicadores, el producto
                               -- podría dejar al jugador clavado
-- Sway (§6, reescrito el 2026-07-14 tras la ronda 5): el ViewPunch periódico se
-- sentía débil y llegaba estando idle. Ahora es una DERIVA CONTINUA en dos capas
-- (temblor sutil con el arma en mano; deriva fuerte al apuntar), sobre todo
-- horizontal, estilo ARMA 3 — pedido del autor.
--
-- Tuning de la ronda 6 (pedido del autor: "un poco más de sway en ambos casos, y es
-- medio tosco: pasa muy fuerte al apuntar, hacé una curva para pasar de un estado al
-- otro"). Dos cambios: sube la amplitud de las dos capas, y el salto entre ellas deja
-- de ser instantáneo — las capas ya no son un if, son los extremos de una rampa.
Config.SWAY_PER_SCORE  = 0.45  -- grados de amplitud base por punto de score de brazo
Config.SWAY_IDLE_MULT  = 0.60  -- capa 1: arma en mano, sin apuntar (perceptible, no ciego)
Config.SWAY_ADS_MULT   = 4.5   -- capa 2: apuntando (incapacitante — el número a tunear)
Config.SWAY_ADS_RAMP_S = 0.45  -- segundos de la transición idle↔ADS (el "tosco" de la ronda 6)
Config.SWAY_VERTICAL   = 0.30  -- el cabeceo es una fracción del bamboleo: deriva HORIZONTAL

Config.VISION_FULL_AT  = 6     -- score de cabeza donde el oscurecimiento satura
Config.BLACKOUT_S      = 2     -- fade a negro al recibir una herida de cabeza...
Config.BLACKOUT_MIN_SEVERITY = 2 -- ...media o grave (§6: es visual, sin pérdida de control)
Config.PULSE_HZ        = 1.1   -- latido del vignette de sangre crítica (ciclos/s)

-- ============================================================
-- Funciones puras
-- ============================================================

-- Damage types que NO crean herida (no son trauma localizable, §3)
local DMG_IGNORAR = bit.bor(DMG_DROWN, DMG_POISON, DMG_NERVEGAS, DMG_RADIATION)
local DMG_BALA    = bit.bor(DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER, DMG_AIRBOAT)
local DMG_QUEMA   = bit.bor(DMG_BURN, DMG_SLOWBURN, DMG_ENERGYBEAM, DMG_SHOCK, DMG_PLASMA)
local DMG_GOLPE   = bit.bor(DMG_FALL, DMG_CRUSH, DMG_CLUB)

-- Resuelve el bitfield de damage type a tipo de herida, o nil si no corresponde
-- herida. El orden de chequeo es la prioridad de la tabla de §3 (un evento puede
-- combinar bits: bala incendiaria = BULLET|BURN → gana bala).
function Config.WoundTypeFromDMG(dmgtype)
    if bit.band(dmgtype, DMG_IGNORAR) ~= 0 then return nil end
    if bit.band(dmgtype, DMG_BALA) ~= 0 then return "bala" end
    if bit.band(dmgtype, DMG_BLAST) ~= 0 then return "metralla" end
    if bit.band(dmgtype, DMG_SLASH) ~= 0 then return "corte" end
    if bit.band(dmgtype, DMG_QUEMA) ~= 0 then return "quemadura" end
    if bit.band(dmgtype, DMG_GOLPE) ~= 0 then return "contusion" end
    return "contusion" -- default conservador (§3)
end

-- Severidad 1-3 según daño FINAL del evento (post-mitigación, §3)
function Config.SeverityFromDamage(dmg)
    if dmg > Config.SEVERITY_GRAVE_AT then return 3 end
    if dmg >= Config.SEVERITY_MEDIUM_AT then return 2 end
    return 1
end

-- Drenaje de una herida en unidades de sangre/s (0 si está tratada, §4):
-- base(sev) × mult(type) × mult(zone). El mult de zona vive ACÁ y no en el timer
-- de bleeding.lua para que la fórmula entera de §4 sea una sola función pura que
-- ambos realms comparten. `zone` es opcional y nil-safe (sin zona → ×1.0): un
-- llamador que solo pregunta "¿sangra?" no necesita conocerla.
function Config.BleedRate(wound, zone)
    if wound.treated then return 0 end
    local tipo = Config.WOUND_TYPES[wound.type]
    if tipo == nil then return 0 end
    local multZona = (zone ~= nil and Config.ZONE_BLEED_MULT[zone]) or 1.0
    return Config.BLEED_BASE[wound.severity] * tipo.mult * multZona
end

-- Prioridad de la VENDA sobre una herida (COA-37, §7). 0 = no se puede vendar (ya
-- está tratada). La pregunta es "¿está ABIERTA?", nunca "¿sangra?": una contusión
-- tiene mult 0.0 y con el criterio viejo era invendable — y como el medkit solo borra
-- lo ya tratado, quedaba incurable hasta morir. Es la salida (1) de ACE3 (§7).
--
-- El SANGRADO domina y la severidad ordena DENTRO de cada grupo: una herida que drena
-- va antes que cualquier contusión, por grave que sea la contusión. Corregido tras la
-- pasada del autor (2026-07-29, check 4 ✗): la primera versión hacía dominar la
-- severidad, y en una zona con un balazo leve y un moretón medio la venda se iba al
-- moretón mientras el balazo seguía drenando. Un moretón nunca mata; un sangrado sí —
-- la urgencia es la hemorragia.
--
-- El peso del sangrado sale de SEVERITY_MAX, no de un literal (COA-35): si algún día
-- hay severidad 4, el sangrado sigue dominando sin tocar esta función. Pura y
-- compartida: la usan el efecto venda, la zona automática y el selftest.
function Config.BandagePriority(wound, zone)
    if wound.treated then return 0 end
    local urgencia = Config.BleedRate(wound, zone) > 0 and (Config.SEVERITY_MAX + 1) or 0
    return urgencia + wound.severity
end

-- Dolor que abre UNA herida, por sus tres ejes (§17, COA-52 D3):
--   PAIN_PER_WOUND × PAIN_TYPE[tipo] × PAIN_SEVERITY[sev]
-- Una sola constante absoluta en vez de 15 celdas sueltas. Pura y compartida: la
-- usan ZonePain (server), el selftest y el harness — el CLIENTE no la llama, y eso
-- es norma y no casualidad (COA-52, sexta colisión: el dolor viaja en el snapshot y
-- el cliente nunca lo deriva).
--
-- Nil-safe en los dos ejes. Un tipo sin fila en PAIN_TYPE devuelve 0, y eso NO es
-- inocuo: el emisor del snapshot pregunta «¿aporta dolor?», así que una zona con una
-- herida de un tipo sin fila dejaría de viajar. Lo que sostiene esa equivalencia es
-- el check de FORMA del harness —PAIN_TYPE cubre todo WOUND_TYPES—, no esta línea.
function Config.PainFromWound(tipo, sev)
    local pt = Config.PAIN_TYPE[tipo]
    local ps = Config.PAIN_SEVERITY[sev]
    if pt == nil or ps == nil then return 0 end
    return Config.PAIN_PER_WOUND * pt * ps
end


-- Drenaje de HP por segundo dada la sangre actual (0 si no es crítica, §5)
function Config.HPDrainRate(blood)
    if blood >= Config.BLOOD_CRITICAL then return 0 end
    local falta = (Config.BLOOD_CRITICAL - blood) / Config.BLOOD_CRITICAL
    return Config.HP_DRAIN_BASE + Config.HP_DRAIN_EXTRA * falta
end

-- --- Debuffs (§6): puras, sin estado — el server las usa para publicar, el
-- --- cliente las usa para pintar. Misma fórmula en ambos realms.

-- Multiplicador de velocidad por heridas de pierna (score = suma de AMBAS piernas)
function Config.LimpMult(scorePiernas)
    return math.max(Config.LIMP_MIN_MULT, 1 - Config.LIMP_PER_SCORE * scorePiernas)
end

-- Amplitud base de la deriva en grados por heridas de brazo (score = ambos brazos)
function Config.SwayAmplitude(scoreBrazos)
    return Config.SWAY_PER_SCORE * scoreBrazos
end

-- Suavizado de la transición entre capas (smoothstep): sale y entra despacio, así el
-- cambio no se siente como un tirón. Es la "curva" que pidió el autor en la ronda 6 —
-- antes las dos capas eran un if, y pasar de no-apuntar a apuntar era un escalón.
function Config.SwayEase(t)
    t = math.Clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

-- Amplitud EFECTIVA según cuánto se esté apuntando (§6). `ads` es un factor CONTINUO
-- 0..1 (0 = arma en mano, 1 = apuntando del todo): el cliente lo rampa en el tiempo,
-- las capas son sus extremos. Acepta un booleano por comodidad del selftest/status.
function Config.SwayFor(scoreBrazos, ads)
    if ads == true then ads = 1 end
    if type(ads) ~= "number" then ads = 0 end

    local t = Config.SwayEase(ads)
    local mult = Config.SWAY_IDLE_MULT + (Config.SWAY_ADS_MULT - Config.SWAY_IDLE_MULT) * t
    return Config.SwayAmplitude(scoreBrazos) * mult
end

-- Offset de la deriva en el instante t (grados: bamboleo, cabeceo). Dos senos de
-- períodos inconmensurables: nunca repite un patrón legible, así que no se puede
-- "aprender" a compensar. Pura: el cliente la usa para mover la mira y el selftest
-- para verificarla.
function Config.SwayOffset(t, amp)
    local yaw = (math.sin(t * 1.13) * 0.7 + math.sin(t * 0.37) * 0.3) * amp
    local pitch = math.sin(t * 0.83) * amp * Config.SWAY_VERTICAL
    return yaw, pitch
end

-- Intensidad 0..1 del oscurecimiento de visión por heridas de cabeza
function Config.VisionIntensity(scoreCabeza)
    return math.Clamp(scoreCabeza / Config.VISION_FULL_AT, 0, 1)
end

-- Intensidad 0..1 de la capa visual de sangre crítica (§5-§6): 0 sobre el umbral,
-- 1 con sangre 0. Es información vital: no se apaga por convar (§11).
function Config.CriticalIntensity(blood)
    if blood >= Config.BLOOD_CRITICAL then return 0 end
    return math.Clamp((Config.BLOOD_CRITICAL - blood) / Config.BLOOD_CRITICAL, 0, 1)
end

-- --- UI (§10): puras, para que el HUD y el menú médico pinten LO MISMO. La silueta
-- --- se dibuja dos veces (chica en el HUD, grande y clickeable en el menú) y las dos
-- --- veces sale de esta tabla: una sola verdad sobre dónde está cada zona.

-- El snapshot viaja comprimido, así que sus claves son de una letra ({t,s,tr}) — las
-- funciones de balance esperan la herida entera ({type,severity,treated}). Traducir
-- acá y no en cada llamador: si el snapshot cambia de forma, cambia un solo lugar.
function Config.WoundFromSnap(w)
    return { type = w.t, severity = w.s, treated = w.tr }
end

-- Score de zona → 0..1 para colorear (sano → amarillo → rojo). Satura en ZONE_FULL_AT:
-- de ahí para arriba la zona ya está tan roja como puede.
Config.ZONE_FULL_AT = 6
function Config.ZoneDamageFrac(score)
    return math.Clamp(score / Config.ZONE_FULL_AT, 0, 1)
end

-- Dolor de zona → 0..1 para colorear, espejo LITERAL de ZoneDamageFrac (§17, D2).
-- Satura en PAIN_FULL_AT = 60 y NO en PAIN_MAX: con 100 la mitad de arriba de la
-- rampa estaría muerta en juego normal, y una zona con dolor 7 pintaría casi roja.
-- Con 60 pinta 0.12 — apenas teñida, que es lo que la enmienda quería.
--
-- HOY NO LA LLAMA NADIE QUE PINTE: la silueta se sigue pintando con el SCORE. La
-- rampa de dolor es de la niebla diagnóstica (COA-44) y baja con ella; cambiar lo
-- que el jugador ve antes de que la niebla exista sería diseño de UI sin votar.
function Config.PainFrac(pain)
    return math.Clamp(pain / Config.PAIN_FULL_AT, 0, 1)
end


-- Progreso 0..1 del tratamiento en curso, desde el {endsAt, duration} del snapshot
-- (§9: la barra se calcula client-side, sin tick de red). `now` se pasa para que sea
-- pura y el selftest la pueda ejercitar.
function Config.TreatmentProgress(tr, now)
    if tr == nil or not tr.duration or tr.duration <= 0 then return 0 end
    return math.Clamp(1 - (tr.endsAt - now) / tr.duration, 0, 1)
end

-- Silueta de 7 zonas en coordenadas normalizadas 0..1 dentro de su caja (§10). Se ve
-- desde la perspectiva del jugador (su brazo izquierdo, a la izquierda del dibujo):
-- la alternativa —espejarla como un espejo— confunde al vendar bajo presión.
-- El rect del viejo torso se partió 58/42 (proporción del browser de Caliber,
-- gap 0.01, mismo x/w — enmienda 2026-07-21, geometría ratificada en §10).
Config.SILHOUETTE = {
    { zone = "head",      x = 0.37, y = 0.00, w = 0.26, h = 0.16 },
    { zone = "chest",     x = 0.32, y = 0.18, w = 0.36, h = 0.21 },
    { zone = "stomach",   x = 0.32, y = 0.40, w = 0.36, h = 0.15 },
    { zone = "left_arm",  x = 0.10, y = 0.19, w = 0.19, h = 0.36 },
    { zone = "right_arm", x = 0.71, y = 0.19, w = 0.19, h = 0.36 },
    { zone = "left_leg",  x = 0.33, y = 0.57, w = 0.16, h = 0.43 },
    { zone = "right_leg", x = 0.51, y = 0.57, w = 0.16, h = 0.43 },
}

-- Zona bajo un punto (x,y ya normalizados a la caja de la silueta), o nil. La usa el
-- menú médico para el clic; vive acá porque el rectángulo que se pinta y el que se
-- clickea tienen que ser el MISMO.
function Config.ZoneAt(nx, ny)
    for _, p in ipairs(Config.SILHOUETTE) do
        if nx >= p.x and nx <= p.x + p.w and ny >= p.y and ny <= p.y + p.h then
            return p.zone
        end
    end
    return nil
end

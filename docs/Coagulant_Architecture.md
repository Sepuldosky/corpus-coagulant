# Coagulant — Documento de Arquitectura

> **Uso de este documento:** Referencia autocontenida para la bajada a código del Block 3 (sustrato v1 del médico de jugador). No se requiere el chat de diseño original.
>
> **Estado:** Block 3 del ecosistema (`CORPUS_Architecture.md` §9) — **ratificado por el autor el 2026-07-13**, y en bajada a código desde entonces. Las decisiones estructurales se resolvieron en tres rondas con el autor (registro en [`Coagulant_Block3_Semilla.md`](Coagulant_Block3_Semilla.md) §3); los **números de balance** de este doc son propuesta inicial, tunables por convar, y se ajustan en la verificación en juego — un número distinto no invalida el diseño. **El avance de la bajada (slices verificados / pendientes) vive en [`coagulant_estado.md`](coagulant_estado.md), no acá.**
>
> **Estado vigente (foto de HOY)** → [`coagulant_estado.md`](coagulant_estado.md) — léelo antes que este documento. **Metodología** → `corpus_flujo_trabajo.txt` (compartido). Índice operativo → `CLAUDE.md` de este repo.

---

## Índice

1. [Alcance de este bloque](#1-alcance-de-este-bloque)
2. [Modelo de vitales — sangre en paralelo](#2-modelo-de-vitales--sangre-en-paralelo)
3. [Heridas — tipos por damage type](#3-heridas--tipos-por-damage-type)
4. [Sangrado y regeneración](#4-sangrado-y-regeneración)
5. [Sangre ↔ HP — el drenaje crítico](#5-sangre--hp--el-drenaje-crítico)
6. [Debuffs zonales](#6-debuffs-zonales)
7. [Tratamiento](#7-tratamiento)
8. [Contrato público y eventos de estado clínico](#8-contrato-público-y-eventos-de-estado-clínico)
9. [Net y estado replicado](#9-net-y-estado-replicado)
10. [UI](#10-ui)
11. [Convars](#11-convars)
12. [Soft-deps — superficies consumidas y expuestas](#12-soft-deps--superficies-consumidas-y-expuestas)
13. [Mapa de archivos objetivo](#13-mapa-de-archivos-objetivo)
14. [Degradación honesta](#14-degradación-honesta)
15. [Orden de bajada a código — vertical slices](#15-orden-de-bajada-a-código--vertical-slices)
16. [Checklist de cierre de bloque](#16-checklist-de-cierre-de-bloque)

---

## 1. Alcance de este bloque

**Es.** El sustrato v1 del médico de jugador estilo ACE3: volumen de sangre propio, heridas tipadas por damage type en lista por zona, sangrado con drenaje de HP bajo umbral crítico, tres debuffs zonales, cuatro ítems de tratamiento contra Cargo con tiempo de aplicación, HUD de silueta + menú médico propio. Solo **jugador**, solo **auto-tratamiento**.

**No es.**
- Incapacitación/revive (muerte directa en v1; bloque futuro).
- Tratar a otros jugadores (bloque futuro; el diseño de tratamiento deja el hueco — `ApplyTreatment` recibe el paciente como primer argumento).
- Dolor como stat, analgésicos, fracturas con férula (diferidos).
- Stamina/fatiga — **pese a que el contrato `OnEncumbrance` ya existe** (§12): v1 lo acepta y almacena, sin efecto.
- Medicina de NPCs (frontera: jugador; limbs NPC es de Caliber).
- Persistencia a disco (spawn = cuerpo nuevo; estado en memoria del server).
- Integración fina con ARC9 para la precisión (v1 usa un mecanismo agnóstico, §6).

---

## 2. Modelo de vitales — sangre en paralelo

Cada jugador tiene un **volumen de sangre** propio de Coagulant, además del HP nativo:

- `blood ∈ [0, 100]` (unidades abstractas; el HUD lo muestra como %). Spawn: 100.
- El HP nativo sigue siendo el **trauma directo** del engine y lo que leen/escriben los demás mods. Coagulant **nunca** re-escala daño (eso será de Caliber): solo observa impactos y drena/recupera.
- La sangre **no mata por sí misma**: mata a través del drenaje de HP (§5). La muerte es siempre por HP 0 — compatible con killfeed, respawn y mods que setean HP.
- Los medkits HL2 curan HP pero no sangre: con sangre crítica el HP curado se vuelve a drenar. El tratamiento real pasa por Coagulant — consecuencia deliberada, no bug.

Estado por jugador (crece sobre la forma del scaffold; sigue en memoria, keyed por SteamID64):

```lua
st = {
    blood       = 100,
    zones       = { [zona] = { wounds = {w1, w2, ...}, tourniquet = false } },
    treatment   = nil,   -- { kind, zone, endsAt } mientras hay uno en curso
    encumbrance = 0,     -- último fraction reportado por Cargo (§12); sin efecto en v1
    lastHit     = ...,   -- debug, como en el scaffold
}
```

---

## 3. Heridas — tipos por damage type

**COA-9 —** Una herida se crea **con el daño ya aplicado**, no con el daño entrante: `ScalePlayerDamage` captura el hitgroup del evento (ya lo hace el scaffold) y `PostEntityTakeDamage(ply, dmg, took)` crea la herida con el daño **final**. Esto deja gratis el punto de integración con Caliber Block 3 (la mitigación de armadura ocurre antes, la herida nace del daño post-armadura) y evita contar daño que un mod canceló.

### Tabla damage type → tipo de herida

| `DMG_*` del evento | Tipo | Mult. de sangrado | Nota |
|---|---|---|---|
| `BULLET`, `BUCKSHOT`, `SNIPER`, `AIRBOAT` | `bala` | 1.0 | |
| `SLASH` | `corte` | 0.8 | |
| `BLAST` | `metralla` | 0.9 | una herida, no N fragmentos (v1) |
| `BURN`, `SLOWBURN`, `ENERGYBEAM`, `SHOCK`, `PLASMA` | `quemadura` | 0.2 | sangra poco; la venda aplica igual (apósito) |
| `FALL`, `CRUSH`, `CLUB` | `contusion` | 0.0 | no sangra; **sí** cuenta para el debuff zonal |
| `DROWN`, `POISON`, `NERVEGAS`, `RADIATION` | — | — | **no crean herida** (no son trauma localizable) |
| resto / sin clasificar | `contusion` | 0.0 | default conservador |

### Severidad

Por daño final del evento: `< 15` → **1 (leve)** · `15–40` → **2 (media)** · `> 40` → **3 (grave)**.

### Apilado

Lista de heridas por zona: `wound = { type, severity, treated = false }`. Tope de **5 heridas por zona**: al exceder, en vez de agregar se sube 1 nivel de severidad a la herida más leve no tratada (cap 3) — el estado no crece sin límite y el castigo se conserva.

---

## 4. Sangrado y regeneración

**COA-15 —** Un **timer único de 1 s** (`timer.Create("corpus_coagulant_tick")`, no Think) recorre los jugadores vivos:

- **Drenaje por herida** (unidades de sangre/s): `base(severity) × mult(type)`, con `base = { [1]=0.15, [2]=0.40, [3]=1.00 }`. Heridas `treated` no drenan. Zona con torniquete puesto: sus heridas no drenan mientras esté puesto.
- **Drenaje total** = Σ de todas las zonas × `coagulant_bleed_scale`.
- **Regeneración natural**: si el drenaje total es 0 y `blood < 100`: `+0.10/s × coagulant_regen_scale` (~17 min de 0 a 100 — la bolsa de sangre es el atajo, §7).

Referencias de letalidad con los números propuestos: una herida de bala grave sin tratar = 1.0/s → de 100 a sangre crítica (40) en ~1 minuto; una leve de corte (0.12/s) tarda ~8 min — molestia, no sentencia.

---

## 5. Sangre ↔ HP — el drenaje crítico

- `blood ≥ 40`: sin efecto sobre HP.
- `blood < 40` (**crítico**): el mismo tick drena HP: `hpDrain = (1 + 4 × (40 − blood) / 40) × coagulant_hpdrain_scale` HP/s — de 1 HP/s al entrar en crítico a 5 HP/s con sangre 0.
- **COA-11 —** El drenaje se aplica como `DMG_GENERIC` sin atacante (mundo), así la muerte pasa por el pipeline normal del engine. Feedback de "bled out": mensaje propio en el chat/consola del jugador al morir con sangre crítica (el killfeed queda genérico — aceptado en v1).
- Cruce de umbral (en ambas direcciones) dispara `Coagulant_BloodCritical` (§8) y el feedback visual de cabeza/vignette (§10) se intensifica.

---

## 6. Debuffs zonales

Score de zona = Σ severidades de sus heridas; las `treated` cuentan **la mitad**. Los tres debuffs entran en v1, cada uno con su convar de apagado (§11).

> **COA-21 — Enmienda 2026-07-14 (ronda 5 en juego).** La media severidad de una herida tratada pesaba **para siempre**: vendarse las piernas dejaba al jugador cojo (×0.76) hasta morir, porque nada borraba la herida. El autor resolvió que la cura de esa secuela es el **Medkit** (§7): cierra las heridas ya tratadas de una zona. Vendar corta el sangrado; el Medkit borra la marca. Una herida sin vendar no se toca (primero hay que cerrarla).

### Piernas → cojera

- `speedMult = max(0.45, 1 − 0.12 × (score_left_leg + score_right_leg))`.
- **Aplicación composable, nunca `SetWalkSpeed`:** Cargo (movecompat) escala su propio multiplicador sobre `mv:SetMaxSpeed` del move data cada tick — **nunca** re-estampa walk/run: eso es el antipatrón de terceros («better movement v2») que CRG-12 existe para evitar. Si Coagulant escribiera `SetWalkSpeed`/`SetRunSpeed` se pisaría con cualquier mod que haga lo mismo. Coagulant publica `NW2Float("coagulant_speed_mult")` y lo aplica en un hook `Move` compartido propio escalando `mv:SetMaxSpeed(mv:GetMaxSpeed() × mult)` (ambos realms leen el mismo NW2 → predicción consistente). Componen multiplicativamente: `final = (lo que sea que dejaron gamemode/Cargo/mods) × coagulant_speed_mult`.
- **COA-6 — Piso absoluto con `math.min(base, piso)`.** Componiendo dos multiplicadores el producto puede acercarse a cero, así que el hook aplica `max(base × mult, min(base, LIMP_SPEED_FLOOR))` — el mismo piso de 30 que usa el movecompat de Cargo. El `math.min` es la mitad que importa y es fácil de perder al releer: sin él, un jugador que **otro** mod dejó a propósito por debajo del piso (freeze, agarre, un guion) vería su velocidad **subida** por una norma médica. Un piso nunca acelera a nadie: solo evita que la cojera clave a quien ya caminaba normal.
- **COA-17 — El NW2 de cojera se publica solo cuando el valor CAMBIÓ.** Cada escritura de un NW2 se replica a **todos** los clientes, no solo al dueño: reescribir el mismo número en cada tick de 0,5 s es tráfico multiplicado por la cantidad de jugadores, a cambio de nada. El tick refresca el cálculo siempre —incluso con la convar apagada, para que apagarla devuelva el multiplicador a 1 en vez de congelarlo— pero la escritura va detrás de una comparación con el último valor publicado.

### Brazos → precisión

- **Deriva continua de la mira, en dos capas** (reescrito el 2026-07-14 tras la ronda 5; el `ViewPunch` periódico original se sentía débil y llegaba estando idle. **Tuneado tras la ronda 6**: el autor pidió más amplitud en ambas capas y una **curva** entre ellas — el salto instantáneo se sentía tosco):
  - **Capa 1 — arma en mano:** temblor perceptible pero manejable (`amp × 0.60`).
  - **Capa 2 — apuntando:** deriva incapacitante (`amp × 4.5`), estilo ARMA 3. "Apuntando" se detecta por el **clic derecho** (`IN_ATTACK2`): es el ADS de ARC9/TFA/MW y no depende de la API de ningún arma.
  - **Las capas son los extremos de una rampa, no un `if`:** un factor continuo 0..1 va del idle al ADS en `SWAY_ADS_RAMP_S` (0.45 s) por **smoothstep** (`SwayEase`). **COA-23:** solo se rampa la **amplitud** — la fase del bamboleo nunca se corta, así que la mira se abre y se cierra en vez de dar un tirón.
  - `amp = 0.45° × (score_left_arm + score_right_arm)`. La deriva es **sobre todo horizontal** (el cabeceo es una fracción, `SWAY_VERTICAL`), y **(COA-24)** se compone de dos senos de períodos inconmensurables: nunca repite un patrón que se pueda aprender a compensar.
- **COA-22 — Se aplica en el CLIENTE** (hook `CreateMove`), sumando el **delta** del offset al usercmd — no el offset absoluto, o la vista derivaría sin control en vez de oscilar. Es la única forma de mover la puntería de forma continua sin pelear contra el mouse del jugador. El score de brazos llega en el snapshot **con la isquemia incluida**, así que el cliente calcula el mismo número que el server.
- Penalidad cruzada: brazo con score > 0 suma **+25 % al tiempo de aplicación** de tratamientos (§7).
- Integración fina con ARC9 (spread/recoil por su API): **diferida**; cuando se haga, los nombres se verifican contra `dev/other/`, nunca de memoria (lección pagada por Cargo).

### Cabeza → visión

- Overlay cliente (vignette/oscurecimiento de bordes) con intensidad `f(score_head)`, renderizado en `RenderScreenspaceEffects` a partir del snapshot propio.
- **El vignette es elíptico** (anillos concéntricos triangulados con `surface.DrawPoly`), no un marco de bandas rectangulares — la primera versión daba esquinas duras y el autor la rechazó en la ronda 5. Geometría propia, **sin materiales externos**: no depende de ningún asset ni de la licencia de nadie. Los mods de referencia del género (Screen Blood Remaster, CoD) son **COMPAT-RUNTIME, no reciclables** — licencia silenciosa = all-rights-reserved (`dev/mods_workshop_mapa.md`).
- Al recibir una herida de cabeza media/grave: fade a negro breve (~2 s) sin pérdida de control ("desmayo" v1 es solo visual).
- La sangre crítica (§5) suma su propia capa de desaturación/vignette progresiva — el jugador *siente* que se desangra antes de mirar el HUD.

Torso no tiene debuff propio en v1: su castigo es que concentra los impactos (dos hitgroups mapean a él).

---

## 7. Tratamiento

### Set de ítems v1 (defs contra Cargo, categoría `medical`)

| id | Nombre | Clase | Peso | Tiempo | Efecto |
|---|---|---|---|---|---|
| `corpus_coagulant_bandage` | Bandage | stackable | 0.1 | 4 s | Cierra (`treated = true`) **una** herida sangrante leve/media de la zona. Sobre una grave: la baja a media sin cerrarla (una grave cuesta 2 vendas). |
| `corpus_coagulant_tourniquet` | Tourniquet | unique | 0.2 | 2 s | Detiene todo el sangrado de **una extremidad** mientras esté puesto. A los 90 s puesto: isquemia — la zona pasa a score máximo de debuff hasta 60 s después de quitarlo. Quitar (2 s) reanuda el sangrado de lo no cerrado. **COA-20 — No se consume, y quitarlo no exige ni consume ítem** (el toggle opera sobre el torniquete ya puesto). |
| `corpus_coagulant_medkit` | Medkit | stackable | 0.5 | 10 s | +50 HP (cap MaxHealth) **y cierra las heridas ya TRATADAS de una zona** — la única cura de la secuela (§6, enmienda 2026-07-14). No toca sangre ni heridas sin vendar. |
| `corpus_coagulant_bloodbag` | Blood Bag | stackable | 0.3 | 8 s | +40 sangre (cap 100). |

### Mecánica de aplicación

- **COA-19 — Server-authoritative**: `st.treatment = { kind, zone, endsAt }`. Un solo tratamiento a la vez.
- **COA-34 — Cancelación**: recibir daño, saltar, o superar velocidad de caminata → cancela sin efecto y **sin consumir**.
- **COA-3 — El consumo ocurre al completar, no al iniciar.** Consecuencia de contrato con Cargo: el `onUse` de un ítem médico **devuelve `false`** (Cargo no consume) e inicia el tratamiento; al completarse, Coagulant consume explícitamente vía `CARGO.Inventory.TakeItem(ply, id, 1)` (re-validando que la unidad siga ahí). El tooltip del ítem lo dice ("applies over N seconds").
- **Selección de zona**: desde el menú médico (§10), la zona la elige el jugador; desde el uso rápido (quick slot / onUse de Cargo), automática — la zona con la herida más grave **compatible con el ítem**:
  - venda → la zona sangrante más grave.
  - torniquete → **(1)** la extremidad sangrante más grave **sin** torniquete (ponerlo); **(2)** si no hay ninguna, la extremidad que **ya lo tiene puesto** (quitarlo). *Sin la rama (2) el torniquete es imposible de sacar en cuanto vendás la zona: la herida deja de sangrar y la búsqueda no encuentra nada — bug reportado en juego, ronda 5.*
  - medkit → la zona con más secuela **tratada** (la que va a curar); torso si no hay ninguna (sigue sirviendo como cura de HP pura).
  - bloodbag → no usa zona.
- Brazos heridos: +25 % de tiempo (§6).

### Vía sin Cargo (degradación honesta)

Sin Cargo montado, el menú médico ofrece los mismos tratamientos **sin consumir ítems**, con cooldown de 30 s por tratamiento y rotulados "field treatment". El concommand `coagulant_bandage` del scaffold queda como debug/admin. La interacción con world-entities (botiquín de pared) queda diferida.

---

## 8. Contrato público y eventos de estado clínico

Superficie pública (bloque CONTRATO del init — todo lo demás es off-contract por convención):

```lua
COAGULANT.ApplyTreatment(ply, kind, zone) -- inicia tratamiento; kind: "bandage"|
                                          -- "tourniquet"|"medkit"|"bloodbag";
                                          -- zone nil = auto. -> ok, err
COAGULANT.ApplyBandage(ply)               -- azúcar congelada del scaffold
                                          -- (= ApplyTreatment(ply, "bandage")).
                                          -- true si el tratamiento ARRANCÓ.
COAGULANT.GetBlood(ply)      -- 0..100
COAGULANT.IsBleeding(ply)    -- bool (algún drenaje activo)
COAGULANT.GetZoneScore(ply, zone) -- score de debuff de la zona (0 = sana)
COAGULANT.OnEncumbrance(ply, fraction) -- contrato YA congelado por Cargo
                                       -- (corpus_cargo_movement.lua): v1 lo
                                       -- acepta y guarda; stamina es bloque futuro
COAGULANT.Zones.*            -- como en el scaffold (mapa de degradación)
```

### Eventos de estado clínico (la superficie que pide `CORPUS_Architecture.md` §4)

`hook.Run` en server, prefijo `Coagulant_` — los consumen Craving (efectos de salud), la UI propia y cualquier mod externo:

| Evento | Args | Cuándo |
|---|---|---|
| `Coagulant_WoundAdded` | `ply, zone, wound` | al crearse una herida |
| `Coagulant_WoundClosed` | `ply, zone, wound` | al cerrarse por tratamiento |
| `Coagulant_BloodCritical` | `ply, isCritical` | al cruzar el umbral de 40, ambas direcciones |
| `Coagulant_TreatmentStart` | `ply, kind, zone` | al iniciar |
| `Coagulant_TreatmentComplete` | `ply, kind, zone` | al completar |
| `Coagulant_TreatmentCancel` | `ply, kind, zone, reason` | al cancelar |

**COA-32 —** No hay evento por cada punto de sangre (spam); el estado continuo se lee por `GetBlood`/NW2.

---

## 9. Net y estado replicado

Todo net string vía `Corpus.Net.Register("coagulant", msg)` → `corpus_coagulant_<msg>`. El server posee el estado; el cliente manda intents y renderiza.

| Canal | Dirección | Contenido |
|---|---|---|
| `NW2Float "coagulant_blood"` | S→todos | sangre 0..100 (para StatusPanel/HUD, barato) |
| `NW2Float "coagulant_speed_mult"` | S→todos | multiplicador de cojera (Move hook en ambos realms) — **COA-17: se escribe solo si cambió** (§6); un NW2 se replica a todos los clientes en cada escritura |
| `corpus_coagulant_state` | S→C (owner) | snapshot de heridas/torniquetes/tratamiento en curso — **COA-16: on-change**, no por tick |
| `corpus_coagulant_treat` | C→S | intent `{ kind, zone }` — server valida (ítem presente vía Cargo o modo degradado, zona válida, sin tratamiento en curso) |
| `corpus_coagulant_cancel` | C→S | cancela el tratamiento propio en curso |

**COA-33 —** La barra de progreso se calcula client-side desde `{ kind, endsAt, duration }` del snapshot — sin tick de red.

---

## 10. UI

Tres piezas cliente, todas leyendo el snapshot + NW2 (nunca estado propio inventado):

1. **HUD silueta** (`HUDPaint`): silueta de 6 zonas coloreadas por score (sano→amarillo→rojo), pulso en zonas sangrando, icono de torniquete. Se desvanece cuando todo está sano y la sangre es 100. Barra de progreso de tratamiento centrada abajo cuando hay uno en curso. Capa de vignette de cabeza/sangre crítica en `RenderScreenspaceEffects` (§6).
2. **Menú médico**: concommand `coagulant_menu` + **tecla propia** (convar de cliente `coagulant_key_menu`, default `KEY_M`, con su DBinder en el tab Q; un hook `PlayerButtonDown` la ABRE). **La tecla no cierra**: el guard que evita robarle la tecla al chat o a otro menú (`gui.IsGameUIVisible()` / `vgui.CursorVisible()`) corre ANTES del toggle, y el frame se abre con `MakePopup()` → con el menú abierto el cursor siempre está visible y la rama de cierre queda inalcanzable. El menú se cierra con la **X de su `DFrame`** (`SetDeleteOnClose`, comportamiento default). Es deuda del slice 4, anotada para la ronda 7 —y el patrón ya está pago en Cargo: `PlayerButtonDown` **ni siquiera dispara client-side en singleplayer** (quirk del engine, `corpus_cargo_ui.lua`), que por eso poletea `input.IsButtonDown` en `Think` con detector de flanco y guards de foco (`vgui.GetKeyboardFocus() == nil`, que **no** es lo mismo que `CursorVisible`). Silueta clickeable → lista de heridas de la zona (tipo, severidad, tratada) → botones de tratamiento habilitados según disponibilidad: conteo de ítems si Cargo está; **sin Cargo se rotulan *field* y no se grisan por cooldown** — el cooldown del modo degradado **no viaja en el snapshot (§9)**, así que el rechazo llega por chat desde el server. Se grisan igual mientras hay un tratamiento en curso (uno a la vez, §7), y el torniquete cuando la zona seleccionada no es una extremidad. Al hacer clic manda el intent y **queda abierto** mostrando el progreso: no se cierra solo.
3. **StatusPanel de Cargo** (lazy-check en el archivo de HUD): `CARGO.StatusPanel.RegisterBar("coagulant", { id = "blood", label = "Blood", getValue = ply → NW2Float × 1, color = rojo })` — firma real verificada contra `corpus_cargo_statuspanel.lua`. Sin Cargo, la sangre se muestra como mini-barra en el HUD propio.

**COA-14 — Todo el pintado va en `pcall` + `Corpus.Log` ruidoso (avisando una sola vez):** GMod **desengancha** un hook de `HUDPaint` que erra — un error de pintado mata la capa entera en silencio por el resto de la sesión. La trampa la pagó Cargo (cita CRG-25) y acá rige para la silueta, la capa de visión y las barras.

El tab Q existente crece: convars de server (admin) + cliente, y el **binder** de la tecla del menú médico (`coagulant_key_menu`).

---

## 11. Convars

| Convar | Realm | Default | Efecto |
|---|---|---|---|
| `coagulant_enabled` | sv | 1 | apaga todo el sistema (hooks quedan inertes) |
| `coagulant_bleed_scale` | sv | 1.0 | multiplicador global de drenaje de sangre |
| `coagulant_regen_scale` | sv | 1.0 | multiplicador de la regeneración natural |
| `coagulant_hpdrain_scale` | sv | 1.0 | multiplicador del drenaje de HP en crítico |
| `coagulant_debug` | sv | 0 | loguea heridas y cruces del umbral crítico a consola |
| `coagulant_debuff_legs` | sv | 1 | on/off cojera |
| `coagulant_debuff_arms` | sv | 1 | on/off sway de brazos |
| `coagulant_debuff_head` | sv | 1 | on/off efectos de visión |
| `coagulant_hud` | cl | 1 | on/off HUD silueta (**COA-25**: el crítico visual no se apaga: es información vital) |
| `coagulant_key_menu` | cl | `KEY_M` | tecla que abre el menú médico (0 = sin bind; se ajusta desde el tab Q) |

**COA-27 —** Los números internos de balance (tabla §3, curvas §4-§6, tiempos §7) viven en `corpus_coagulant_config.lua` como tablas — tunables editando data, sin tocar lógica.

**COA-35 —** Un check (selftest/harness) jamás hardcodea un número tunable: se deriva de la config. Si el check congelara el número, retunear **rompería** el selftest en vez de validarlo — los checks de amplitud del sway se derivan de `SWAY_PER_SCORE`, no de un `0.70` literal.

---

## 12. Soft-deps — superficies consumidas y expuestas

### Cargo (presente hoy — nombres verificados contra el código real)

- **Consume:** `Items.Register(def)` (4 defs §7); `Inventory.HasItem(ply, id)` (**presencia al validar el arranque de un tratamiento — la única superficie que ve los `unique`**: `CountItem` cuenta solo stacks, así que el torniquete siempre daba 0 — pagado en juego el 2026-07-13, fallo G4; Cargo la agregó como su entry 18); `Inventory.CountItem(ply, id)` + `Inventory.TakeItem(ply, id, 1)` (**server, al completar**: re-validar y consumir la unidad stackable); `StatusPanel.RegisterBar` (client); y **`CARGO.ClientState.items` (client, superficie OFF-CONTRACT de Cargo)** — el menú médico cuenta con ella las DOS clases de ítem (los stacks por `count`, los `unique` por `uid`) porque `CountItem` no existe en el cliente. **Deuda asumida:** si Cargo cambia la forma de su snapshot, el conteo de los botones se rompe **en silencio**; el candidato natural es que Cargo exponga un contador de cliente en su contrato.
- **Expone hacia Cargo:** `OnEncumbrance(ply, fraction)` — Cargo ya lo llama con pcall en cada cambio de peso (`corpus_cargo_movement.lua`). v1: almacenar en `st.encumbrance`, cero efecto. `Inventory.GetWeightFraction(ply)` queda disponible para cuando la stamina exista.

### Caliber (mock-first — su pipeline de jugador no existe)

- Punto único de integración: la creación de herida (§3) ocurre en `PostEntityTakeDamage` con el daño final — cuando Caliber Block 3 mitigue daño de jugador, las heridas nacerán automáticamente post-armadura, **sin tocar código de Coagulant**. Si Caliber además expone hit-location enriquecido (placa golpeada, penetración), el enriquecimiento entra como refinamiento del `wound.type/severity` en ese único punto, con lazy-check.
- La rama vacía del scaffold en `ScalePlayerDamage` se reduce a capturar hitgroup (ya no necesita más).

### Craving (futuro consumidor)

- Consume los eventos de §8 y `GetBlood`/`IsBleeding`. **COA-31 —** Coagulant **no** detecta a Craving (dirección única de la soft-dep).

---

## 13. Mapa de archivos objetivo

El manifest del init crece a (orden de carga determinista; regla de siempre: nunca invocar hacia adelante en file-scope):

| Archivo | Realm | Rol | Estado |
|---|---|---|---|
| `shared/corpus_coagulant_zones.lua` | shared | zonas + hitgroup→zona | existe (scaffold) |
| `shared/corpus_coagulant_config.lua` | shared | convars + tablas de balance (§3-§7) | **nuevo** |
| `shared/corpus_coagulant_move.lua` | shared | hook `Move`: aplica `coagulant_speed_mult` | **nuevo** |
| `shared/corpus_coagulant_dev.lua` | shared | selftest (crece: heridas/sangrado puros) | existe |
| `server/corpus_coagulant_core.lua` | server | estado + captura hitgroup + creación de heridas | existe, crece |
| `server/corpus_coagulant_bleeding.lua` | server | timer 1 s: drenaje, regen, HP crítico | **nuevo** |
| `server/corpus_coagulant_treatment.lua` | server | ApplyTreatment, progreso, consumo Cargo, torniquetes, net intents | **nuevo** |
| `server/corpus_coagulant_debuffs.lua` | server | scores de zona, tick 0.5 s (la isquemia entra y sale sola), speed mult por NW2 | **nuevo** |
| `shared/corpus_coagulant_items.lua` | shared | 4 defs contra Cargo — **shared obligatorio (cita COR-12)**: Cargo no sincroniza defs por net, su grid cliente lee `Items.Get` local (lección del punto E, 2026-07-13) | existe, crece |
| `client/corpus_coagulant_hud.lua` | client | snapshot replicado + **sway de la mira (`CreateMove`)** + vignettes + silueta + barra progreso + StatusPanel | **nuevo** |
| `client/corpus_coagulant_medmenu.lua` | client | panel médico (`coagulant_menu`) | **nuevo** |
| `client/corpus_coagulant_options.lua` | client | tab Q (crece: convars de cliente y server + el **DBinder** de `coagulant_key_menu`, §10) | existe |

Trampas de VGUI heredadas del ecosistema aplican al medmenu (ver CLAUDE.md de Cargo: nada de `DNumSlider` en scroll, overlays por `PaintOver`, `Theme.FitText`-equivalente para nombres largos).

---

## 14. Degradación honesta

| Montado | Comportamiento |
|---|---|
| Solo Corpus + Coagulant | Sistema completo con hitgroup crudo; tratamiento en modo degradado (menú sin ítems, cooldown 30 s); sangre en mini-barra del HUD propio (**COA-25**) |
| + Cargo | Ítems reales (4 defs), consumo al completar, barra de sangre en StatusPanel, uso rápido por quick slots |
| + Caliber (hoy, Block 2) | Sin cambio (Caliber aún no toca daño de jugador) |
| + Caliber Block 3 (futuro) | Heridas nacen del daño post-armadura automáticamente (§12); hit-location enriquecido como refinamiento opcional |
| `coagulant_enabled 0` | **COA-26 —** Módulo inerte: hooks registrados pero de retorno temprano; el registro y el contrato siguen vivos (otros módulos no crashean) |

---

## 15. Orden de bajada a código — vertical slices

Cada slice cruza de punta a punta y se verifica en juego antes del siguiente (flujo §3):

1. **Sangre + heridas + sangrado** — config, crecimiento de core (heridas en `PostEntityTakeDamage`), bleeding (timer, drenaje, regen, HP crítico), NW2 de sangre, snapshot on-change, selftest de la matemática pura. Verificable ya: recibir un tiro, ver drenar sangre y morir desangrado; `coagulant_bandage` (debug) corta el sangrado.
2. **Tratamiento vía Cargo** — treatment (progreso, cancelación, consumo al completar, torniquete con isquemia), las 4 defs, intents de net. Verificable: vendarse desde el quick slot de Cargo.
3. **Debuffs** — debuffs server (scores, NW2 speed mult), move hook compartido, y en cliente el sway de la mira (`CreateMove`, §6) + los vignettes. Verificable: cojera/sway/visión con heridas en cada zona; sin pelearse con el multiplicador de peso de Cargo.
4. **UI** — HUD silueta, menú médico, StatusPanel, tab Q con convars. Verificable: flujo completo sin consola.

Al cerrar cada slice: CHANGELOG (`[PENDIENTE]` → verificación del autor) y `coagulant_estado.md` en sitio.

---

## 16. Checklist de cierre de bloque

1. Los 4 slices verificados en juego por el autor (CHANGELOG todo `[APLICADO]`).
2. Sección resumen + link a este doc en `CORPUS_Architecture.md` (§9: Block 3 → Cerrado).
3. `coagulant_estado.md` y `coagulant_roadmap.txt` refrescados; la semilla queda como registro histórico.
4. CLAUDE.md de este repo: mapa de archivos y contratos al día con el árbol real. **Hecho durante la bajada por slices**: los contratos del scaffold ya fueron reemplazados por los de este doc (el CLAUDE.md de hoy lleva los 9 contratos del módulo real, ninguno es el viejo "sin gameplay antes del diseño"). Al cerrar solo queda el repaso final de que el mapa siga coincidiendo con el árbol.
5. Anotar en `corpus/docs/corpus_estado.md` que Coagulant tiene módulo real (deja de ser scaffold).

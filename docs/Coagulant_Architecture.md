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
17. [Perfusión, oxígeno y daño ambiental](#17-perfusión-oxígeno-y-daño-ambiental-enmienda-2026-08-08b)

---

## 1. Alcance de este bloque

**Es.** El sustrato v1 del médico de jugador estilo ACE3: volumen de sangre propio, heridas tipadas por damage type en lista por zona, sangrado con drenaje de HP bajo umbral crítico, tres debuffs zonales, cuatro ítems de tratamiento contra Cargo con tiempo de aplicación, HUD de silueta + menú médico propio. Solo **jugador**, solo **auto-tratamiento**.

**No es.**
- Incapacitación/revive (muerte directa en v1; bloque futuro).
- Tratar a otros jugadores (bloque futuro; el diseño de tratamiento deja el hueco — `ApplyTreatment` recibe el paciente como primer argumento).
- ~~Dolor como stat, analgésicos~~, **fracturas con férula** (sigue diferida) — las otras dos salidas que ACE3 le da al trauma cerrado. Mientras la fractura no exista, la **venda** cubre el trauma cerrado: aplica a toda herida abierta, sangre o no (**COA-37**, §7). **Enmendado el 2026-08-08 (COA-44, §17):** el dolor dejó de ser diferido y pasó a ser **requisito** de la niebla diagnóstica — es el único canal que la niebla no tapa, así que sin él la niebla apaga la pantalla en vez de complicarla. **ESPECIFICADO el 2026-08-17 y BAJADO A CÓDIGO el 2026-08-25 (COA-52, §17):** el dolor y los analgésicos **salen de esta lista**, y ahora existen: el stat por zona, el agregado global saturado, la supresión con su decaimiento, el `p` en el snapshot y el **analgésico oral** como quinto ítem médico. La **morfina** no entra —arrastra la sobredosis y la naloxona, que son del tramo del catálogo (COA-50)—, y la **fractura con férula** sigue diferida, con su término de dolor escrito y leyendo 0.
- Stamina/fatiga — **pese a que el contrato `OnEncumbrance` ya existe** (§12): v1 lo acepta y almacena, sin efecto. Su relación con el oxígeno la fija **COA-42** (§17): son vitales distintos, se encuentran en el techo y no se fusionan.
- Medicina de NPCs (frontera: jugador; limbs NPC es de Caliber).
- Persistencia a disco (spawn = cuerpo nuevo; estado en memoria del server).
- Integración fina con ARC9 para la precisión (v1 usa un mecanismo agnóstico, §6).

---

## 2. Modelo de vitales — sangre en paralelo

Cada jugador tiene un **volumen de sangre** propio de Coagulant, además del HP nativo:

- `blood ∈ [0, 100]` (unidades abstractas; el HUD lo muestra como %). Spawn: 100.
- El HP nativo sigue siendo el **trauma directo** del engine y lo que leen/escriben los demás mods. Coagulant **nunca** re-escala daño (eso será de Caliber): solo observa impactos y drena/recupera.
- La sangre **no mata por sí misma**: mata a través del drenaje de HP (§5). La muerte es siempre por HP 0 — compatible con killfeed, respawn y mods que setean HP. **Enmienda 2026-08-08 (COA-41, §17):** lo que alimenta ese drenaje pasa a ser la **perfusión** (`blood × sat/100`), no el volumen solo. El dueño de la muerte no cambia — cambia su insumo.
- Los medkits HL2 curan HP pero no sangre: con sangre crítica el HP curado se vuelve a drenar. El tratamiento real pasa por Coagulant — consecuencia deliberada, no bug.

Estado por jugador (crece sobre la forma del scaffold; sigue en memoria, keyed por SteamID64):

```lua
st = {
    blood       = 100,
    zones       = { [zona] = { wounds = {w1, w2, ...}, tourniquet = false } },
    treatment   = nil,   -- { kind, zone, endsAt } mientras hay uno en curso
    encumbrance = 0,     -- último fraction reportado por Cargo (§12); sin efecto en v1
    lastHit     = ...,   -- debug, como en el scaffold

    -- COA-52 (§17, enmienda 2026-08-17). El DOLOR no está acá a propósito: se
    -- DERIVA de las heridas, así que no puede desincronizarse del estado que lo
    -- causa. Lo único que se almacena es cuánto lo enmascara una droga.
    painSuppress = 0,    -- 0..PAIN_SUPPRESS_MAX; decae en el tick de 1 s de §4
}
```

---

## 3. Heridas — tipos por damage type

> **COA-8 y COA-7 — Enmienda 2026-07-21 (ratificada por el autor): `torso` se parte en
> `chest` y `stomach`.** El Source siempre separó `HITGROUP_CHEST` de `HITGROUP_STOMACH`
> y Caliber los trata como zonas distintas de cara al usuario (placas 2 y 3 de su
> armadura, silueta del browser, toolgun) — Coagulant los fundía en `torso` y tiraba
> información que ya llegaba separada. Las zonas clínicas pasan de 6 a **7**: `head`,
> `chest`, `stomach`, `left_arm`, `right_arm`, `left_leg`, `right_leg` (la definición
> canónica del contrato sigue en su sede: CLAUDE.md, contrato 4). Decisiones de la ronda
> de diseño:
>
> 1. **Sin diferencia clínica en v1** — la separación es anatómica. Nace el eje de tuning
>    `ZONE_BLEED_MULT` (§4) **neutro** (todas las zonas ×1.0); el número se decide en
>    juego. **El balanceo se calibrará contra el referente ACE (Arma 3 / Arma Reforger) y
>    ritmos reales de exanguinación** — expectativa del autor que el doc no tenía escrita
>    y desde esta enmienda sí (es data tunable, cita COA-27). Base médica anotada en la
>    ronda: la catástrofe del pecho (corazón/grandes vasos) ya viaja en daño→severidad;
>    lo que un mult de zona expresaría es el sangrado sostenido y no compresible del
>    abdomen (hígado/bazo) — si algún día deja de ser neutro, sube `stomach`, no `chest`.
> 2. **Fallback → `chest`** (re-enuncia COA-7): `HITGROUP_GENERIC`, `HITGROUP_GEAR` y
>    todo hitgroup desconocido caen a `chest` — alineado con Caliber, que manda GENERIC a
>    chest tanto en su mult de zona como en el fallback de placas (chest antes que
>    stomach).
> 3. **Sin alias `torso`, se rompe ahora**: barrido del 2026-07-21 — ningún repo del
>    ecosistema consume los IDs de zona (los `condition_zones` de Cargo son de su ropa,
>    otro namespace). `Zones.IsValid("torso")` pasa a false; sin persistencia a disco
>    (decisión F) no hay migración de datos.
> 4. **Tope de heridas 5+5, aceptado**: el tope es cota de ESTADO (la lista no crece sin
>    límite; la 6.ª herida agrava a la más leve), no número de balance — más zonas son
>    más fuentes de drenaje simultáneas, no menos castigo.
> **Nota 2026-08-09 — el 58/42 describe el RECTÁNGULO, y la tabla de polígonos del v5 no lo conserva.** Medido: los polígonos del spec v5 dan chest 0.15→0.35 y stomach 0.35→0.555, o sea **49,4/50,6** contra el 58,3/41,7 que hoy produce `Config.SILHOUETTE` (`config.lua:293-294`). **Parte de esa diferencia no es que el pecho crezca**: la partición del v5 es CONTIGUA (0 → 0.15 → 0.35 → 0.555 → 1) y absorbe las tres bandas que hoy no son de ninguna zona —0.16→0.18, el gap deliberado 0.39→0.40, y 0.55→0.57—. Se anota como hecho, **no como enmienda**: el 58/42 sigue siendo lo que el código hace y lo que esta enmienda ratificó, y moverlo es voto del autor, pendiente al 2026-08-09 (`dev/PROMPT_coagulant_menu_v5.txt` §2/V2). Y ojo con lo que el cambio de forma trae gratis: donde el rect tenía un hueco de 0.01, el polígono tiene un **solape** de 0.01 en la costura de las piernas (`left_leg` llega a 0.505, `right_leg` arranca en 0.495, en los dos sexos) — un hueco no tiene dueño y un solape tiene dos, así que el ORDEN de evaluación pasa a ser contrato.
>
> 5. **Silueta 58/42** — el rect del torso se parte en la proporción del browser de
>    Caliber; geometría en §10.
>
> **Bajada a código aplicada y VERIFICADA EN JUEGO el 2026-07-21** (sesión «Bajada de
> zonas a código» del CHANGELOG, la siguiente a la de diseño): las 7 zonas viven en el
> árbol, la verificación offline cerró ALL GREEN (selftest 170 OK server / 132 client)
> y la ronda **O** de la planilla pasó **6/6** — chest/stomach por disparo real,
> fallback, medmenu, medkit automático y debuffs sin regresión.

**COA-9 —** Una herida se crea **con el daño ya aplicado**, no con el daño entrante: `ScalePlayerDamage` captura el hitgroup del evento (ya lo hace el scaffold) y `PostEntityTakeDamage(ply, dmg, took)` crea la herida con el daño **final**. Esto deja gratis el punto de integración con Caliber Block 3 (la mitigación de armadura ocurre antes, la herida nace del daño post-armadura) y evita contar daño que un mod canceló.

### Tabla damage type → tipo de herida

| `DMG_*` del evento | Tipo | Mult. de sangrado | Nota |
|---|---|---|---|
| `BULLET`, `BUCKSHOT`, `SNIPER`, `AIRBOAT` | `bala` | 1.0 | |
| `SLASH` | `corte` | 0.8 | |
| `BLAST` | `metralla` | 0.9 | una herida, no N fragmentos (v1) |
| `BURN`, `SLOWBURN`, `ENERGYBEAM`, `SHOCK`, `PLASMA`, `ACID` | `quemadura` | 0.2 | sangra poco; la venda aplica igual (apósito). **`ACID` lo agrega COA-46 (§17)**: hoy no está en el bitfield y cae al default, o sea que una quemadura química produce una *contusión* |
| `FALL`, `CRUSH`, `CLUB` | `contusion` | 0.0 | no sangra; **sí** cuenta para el debuff zonal; **sí** se venda (COA-37, §7) |
| `DROWN`, `POISON`, `NERVEGAS`, `RADIATION` | — | — | **no crean herida** (no son trauma localizable). **Enmendado por COA-43 (§17):** siguen sin crear herida —tienen razón en no crearla— pero dejan de ser invisibles: entran como **condiciones sistémicas** |
| resto / sin clasificar | `contusion` | 0.0 | default conservador |

### Severidad

Por daño final del evento: `< 15` → **1 (leve)** · `15–40` → **2 (media)** · `> 40` → **3 (grave)**.

### Apilado

Lista de heridas por zona: `wound = { type, severity, treated = false }`. Tope de **5 heridas por zona**: al exceder, en vez de agregar se sube 1 nivel de severidad a la herida más leve no tratada (cap 3) — el estado no crece sin límite y el castigo se conserva.

---

## 4. Sangrado y regeneración

**COA-15 —** Un **timer único de 1 s** (`timer.Create("corpus_coagulant_tick")`, no Think) recorre los jugadores vivos:

- **Drenaje por herida** (unidades de sangre/s): `base(severity) × mult(type) × mult(zone)`, con `base = { [1]=0.15, [2]=0.40, [3]=1.00 }`. El mult de zona (`ZONE_BLEED_MULT`, enmienda 2026-07-21 en §3) nace **neutro** — todas las zonas ×1.0: es el eje donde un gut shot podrá sangrar distinto cuando el balance se tunee contra el referente ACE (cita COA-27). Heridas `treated` no drenan. Zona con torniquete puesto: sus heridas no drenan mientras esté puesto.
- **Drenaje total** = Σ de todas las zonas × `coagulant_bleed_scale`.
- **Regeneración natural**: si el drenaje total es 0 y `blood < 100`: `+0.10/s × coagulant_regen_scale` (~17 min de 0 a 100 — la bolsa de sangre es el atajo, §7).
- **Decaimiento de la supresión de dolor** (**COA-52**, §17, desde el 2026-08-25): `painSuppress -= PAIN_SUPPRESS_DECAY_PER_S` en este **mismo** tick — el dolor no tiene reloj propio y la supresión no necesitaba uno nuevo. **Ensucia el snapshot SÓLO si el número se movió**: el percibido cambia al decaer aunque nadie toque una herida, pero ensuciar siempre convertiría el emisor on-change de **COA-16** en un emisor por segundo, y eso no da ningún error — da tráfico.

Referencias de letalidad con los números propuestos: una herida de bala grave sin tratar = 1.0/s → de 100 a sangre crítica (40) en ~1 minuto; una leve de corte (0.12/s) tarda ~8 min — molestia, no sentencia.

---

## 5. Sangre ↔ HP — el drenaje crítico

> **Enmienda 2026-08-08 — COA-41 (§17).** Las dos líneas de abajo se leen con **perfusión** (`blood × sat/100`) donde dicen `blood`. Con `sat` sano = 100 la sustitución es exacta: ningún número de balance de §4-§6 se mueve, y **COA-11 queda intacto** — la muerte sigue saliendo por el mismo `DMG_GENERIC`.

- `blood ≥ 40`: sin efecto sobre HP.
- `blood < 40` (**crítico**): el mismo tick drena HP: `hpDrain = (1 + 4 × (40 − blood) / 40) × coagulant_hpdrain_scale` HP/s — de 1 HP/s al entrar en crítico a 5 HP/s con sangre 0.
- **COA-11 —** El drenaje se aplica como `DMG_GENERIC` sin atacante (mundo), así la muerte pasa por el pipeline normal del engine. Feedback de "bled out": mensaje propio en el chat/consola del jugador al morir con sangre crítica (el killfeed queda genérico — aceptado en v1).
- Cruce de umbral (en ambas direcciones) dispara `Coagulant_BloodCritical` (§8) y el feedback visual de cabeza/vignette (§10) se intensifica.

---

## 6. Debuffs zonales

Score de zona = Σ severidades de sus heridas; las `treated` cuentan **la mitad**. Los tres debuffs entran en v1, cada uno con su convar de apagado (§11).

> ⚠ **El DOLOR reparte las tratadas por `PAIN_TREATED_MULT = 0.35`, no por este `0.5`** (**COA-52**, §17). Son dos números distintos **a propósito** —uno es debuff mecánico, el otro nocicepción— y viven en funciones **vecinas** de `core.lua` (`GetZoneScore` y `ZonePain`). Copiar el de al lado no da ningún síntoma: el dolor seguiría bajando al vendar, sólo que por el número equivocado. El harness lo separa con dos filas y el sabotaje #4 lo ejercita.

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

Ni chest ni stomach tienen debuff propio en v1 (enmienda 2026-07-21, §3 — antes esta línea hablaba de `torso`). Chest sigue concentrando los impactos sin ubicación real: es el fallback de `GENERIC`/`GEAR`/hitgroup desconocido.

---

## 7. Tratamiento

> **COA-37 — Enmienda 2026-07-29 (ratificada por el autor): la venda aplica a TODA herida
> ABIERTA, sangre o no.** Hasta esta enmienda la venda estaba gateada por `BleedRate > 0`,
> en el motor (`ApplyTreatment`) *y* en el efecto (`BandageEffect`). Como `contusion` tiene
> mult **0.0** (§3), una contusión no podía vendarse; y como el Medkit solo cierra heridas
> ya `treated` (enmienda COA-21, §6), tampoco podía curarse. Resultado: entraba al score de
> zona con severidad **entera** y pesaba en cojera/sway/visión **hasta morir** — una caída
> dejaba cojera permanente, y el default conservador de §3 (`resto / sin clasificar` →
> `contusion`) convertía cualquier fuente de daño rara de un tercero en una marca incurable.
>
> **La causa fue un diferimiento a medias, no un olvido.** En ACE3 el trauma cerrado tiene
> **tres** salidas: (1) la venda aplica a toda herida abierta —una contusión es una entrada
> más de la lista de open wounds—, (2) el **dolor** es un stat que decae solo y que un
> analgésico acelera, y (3) el efecto estructural es una **fractura** con su férula. §1
> difirió (2) y (3) —correcto para v1—, pero `contusion` se quedó con la **entrada** al
> sistema (crea herida, suma al score) sin ninguna de las tres salidas. La semilla escribió
> media frase de ACE.
>
> **Resolución: se adopta (1), la única que no cuesta mecánica nueva.** La venda deja de
> preguntar *"¿sangra?"* y pregunta *"¿está abierta?"* (`not treated`). Con eso la contusión
> entra al circuito **venda → medkit** que ya existe y está verificado: vendarla la cierra
> (`treated`, media severidad) y el medkit borra la secuela. Nada más cambia — en particular
> **no** entra la tabla de efectividad por tipo de venda que ACE3 sí tiene (sería mecánica
> nueva, fuera de COA-28), y la regla de la grave (3 → 2, dos vendas) rige igual para todos
> los tipos.
>
> **Orden de selección — el SANGRADO manda, la severidad ordena dentro de cada grupo.**
> Con varias heridas abiertas la venda va **siempre** a una que sangre; solo cuando no queda
> ninguna sangrante pasa a las cerradas-pero-abiertas (la contusión). Dentro de cada grupo
> ordena la severidad. Vive como función pura (`Config.BandagePriority`) para que el efecto,
> la zona automática y el selftest usen el mismo criterio.
>
> > **Corregido el 2026-07-29 tras la pasada en juego del autor (check 4 ✗).** La primera
> > redacción de esta enmienda decía lo contrario —«la severidad domina, el sangrado
> > desempata»— y el autor lo desmintió con el caso exacto: *«la zona con disparo mínimo y un
> > moretón medio: se cura primero el moretón y luego los disparos sangrantes. La urgencia
> > está en los disparos.»* Tenía razón, y el error era de diseño, no de implementación: un
> > moretón **nunca** mata y un balazo leve drena hasta matar, así que ninguna severidad de
> > contusión debería ganarle a un sangrado. La jerarquía correcta es la de la doctrina de
> > trauma real —hemorragia primero—, y es la que rige desde esta corrección. El peso del
> > sangrado se deriva de `SEVERITY_MAX`, no de un literal (COA-35): si algún día hay
> > severidad 4, el sangrado sigue dominando solo.
>
> Dolor como stat, analgésicos y fracturas con férula **siguen diferidos** (§1): esta enmienda
> no los adelanta — solo deja de haber una lesión incurable mientras no existan.
>
> > **Actualización 2026-08-17 (COA-52, §17), y BAJADA el 2026-08-25.** Las dos primeras ya **no** están diferidas: tienen
> > diseño votado con tabla de balance propuesta. La **fractura con férula** sí sigue diferida, y
> > COA-52 le deja el hueco hecho —`PAIN_FRAC` / `PAIN_SPLINT` escritos y leyendo 0 hasta que
> > `z.frac` exista—. Lo que **no** cambia es esta enmienda: la venda sigue siendo la salida (1) y
> > sigue cubriendo la contusión, porque el dolor no cierra heridas. Y hay una consecuencia sobre
> > el orden que conviene tener a la vista: el analgésico **no** entra a competir con la venda en
> > `BandagePriority`, porque no trata una herida — enmascara un síntoma. Son dos circuitos, no
> > uno con dos entradas.

### Set de ítems v1 (defs contra Cargo, categoría `medical`)

| id | Nombre | Clase | Peso | Tiempo | Efecto |
|---|---|---|---|---|---|
| `corpus_coagulant_bandage` | Bandage | stackable | 0.1 | 4 s | Cierra (`treated = true`) **una** herida **abierta** leve/media de la zona — sangrante o no (**COA-37**: la contusión también se venda). Sobre una grave: la baja a media sin cerrarla (una grave cuesta 2 vendas). **Va siempre a una herida que SANGRE** mientras quede alguna; la severidad ordena dentro de cada grupo. |
| `corpus_coagulant_tourniquet` | Tourniquet | unique | 0.2 | 2 s | Detiene todo el sangrado de **una extremidad** mientras esté puesto. A los 90 s puesto: isquemia — la zona pasa a score máximo de debuff hasta 60 s después de quitarlo. Quitar (2 s) reanuda el sangrado de lo no cerrado. **COA-20 — No se DESTRUYE pero se OCUPA: sale del inventario mientras está puesto (un torniquete ata una sola extremidad) y vuelve al quitarlo (`Inventory.TakeUnique`/`GiveItem` de Cargo); quitarlo no exige ítem** (el toggle opera sobre el ya puesto). |
| `corpus_coagulant_medkit` | Medkit | stackable | 0.5 | 10 s | +50 HP (cap MaxHealth) **y cierra las heridas ya TRATADAS de una zona** — la única cura de la secuela (§6, enmienda 2026-07-14). No toca sangre ni heridas sin vendar. |
| `corpus_coagulant_bloodbag` | Blood Bag | stackable | 0.3 | 8 s | +40 sangre (cap 100). |
| `corpus_coagulant_painkillers` | Painkillers | stackable | 0.1 | 3 s | **Analgésico oral (COA-52, §17 — alta del 2026-08-25).** Suma `PAIN_SUPPRESS.oral = 35` de **supresión**: pone un TECHO al dolor percibido por unos minutos y **no cierra ninguna herida ni corta ningún sangrado**. Su `can()` es la puerta `pain > PAIN_ANALGESIC_AT` **leída sobre el PERCIBIDO**, y eso es lo que hace que la segunda dosis se **desgatille sola** — el apilamiento no necesita una regla propia. La **morfina** (`PAIN_SUPPRESS.morphine = 80`) tiene su constante votada pero **no tiene ítem**: arrastra la sobredosis y la naloxona, que son del tramo del catálogo (COA-50). |

> **Modelos (decisión del autor 2026-07-23; mecanismo en Cargo, su entry 34).** Las cuatro defs
> se registran **sin `model`** a propósito: dropean como la cajita de cartón de Cargo y su ícono
> cae a la letra. Coagulant es genérico y no conoce ningún setting — un addon de **contenido**
> las re-viste desde afuera vía `Cargo.Items.SetModel(id, model)` sin tocar este repo
> (corpus-stalker lo hizo hasta el 2026-08-06 —venda → `wick_bandage`, medkit → `medkit_low`— y lo
> RETIRÓ cuando este módulo trajo los suyos: sus botiquines de la Zona serán ítems propios, no una
> piel del genérico. La puerta de sustitución sigue abierta. Torniquete y blood
> bag siguen en la cajita, sin modelo coherente identificado). No es deuda: no se les agrega
> modelo acá.

### Mecánica de aplicación

- **COA-19 — Server-authoritative**: `st.treatment = { kind, zone, endsAt }`. Un solo tratamiento a la vez.
- **COA-34 — Cancelación**: recibir daño, saltar, o superar velocidad de caminata → cancela sin efecto y **sin consumir**.
- **COA-3 — El consumo ocurre al completar, no al iniciar.** Consecuencia de contrato con Cargo: el `onUse` de un ítem médico **devuelve `false`** (Cargo no consume) e inicia el tratamiento; al completarse, Coagulant consume explícitamente vía `CARGO.Inventory.TakeItem(ply, id, 1)` (re-validando que la unidad siga ahí). El tooltip del ítem lo dice ("applies over N seconds").
- **Selección de zona**: desde el menú médico (§10), la zona la elige el jugador; desde el uso rápido (quick slot / onUse de Cargo), automática — la zona con la herida más grave **compatible con el ítem**:
  - venda → la zona con la herida **abierta** de mayor prioridad: sangrantes antes que no-sangrantes, y la más grave dentro de cada grupo (**COA-37** — antes era "la zona sangrante más grave", ciega a la contusión: con solo un moretón encima el uso rápido no encontraba zona y rechazaba el tratamiento).
  - torniquete → **(1)** la extremidad sangrante más grave **sin** torniquete (ponerlo); **(2)** si no hay ninguna, la extremidad que **ya lo tiene puesto** (quitarlo). *Sin la rama (2) el torniquete es imposible de sacar en cuanto vendas la zona: la herida deja de sangrar y la búsqueda no encuentra nada — bug reportado en juego, ronda 5.*
  - medkit → la zona con más secuela **tratada** (la que va a curar); `chest` si no hay ninguna (sigue sirviendo como cura de HP pura; enmienda 2026-07-21 — era `torso`).
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
COAGULANT.Zones.*            -- mapa de degradación; 7 zonas (COA-8, enmienda 2026-07-21)
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

### Condiciones externas y estado metabólico (enmienda 2026-08-08)

> Votada por el autor en cinco puntos antes de escribir una línea (**COA-28**). La contraparte vive en `../../corpus-craving/docs/Craving_Architecture.md` §4 y §5.2.
>
> **BAJADA A CÓDIGO EL 2026-08-25**, y con eso COA-38/39/40 dejan `INTENCION`. Lo que la ejerce: `Config.EXTERNAL_CONDITIONS`, `Config.METABOLIC` y las dos funciones de déficit en `shared/corpus_coagulant_config.lua`; `ApplyExternalCondition`/`GetExternalCondition` y las tres palancas (`BloodCap`/`RegenFactor`/`BleedFactor`) en `server/corpus_coagulant_core.lua`; su aplicación en el tick de 1 s de `server/corpus_coagulant_bleeding.lua`; y la marca de techo + la fila `METABOLIC` en el cliente. Harness: **331 checks ALL GREEN** con la familia `MET-*`; verificación en negativo en `dev/sabotaje_coagulant_metabolismo.py` (21 sabotajes). **Falta la pasada en juego.**
>
> **⚠ Y LA BAJADA MIDIÓ QUE DOS DE LAS CINCO PALANCAS DE COA-40 NO EXISTEN.** La norma afirma que *«los cinco entran por palancas que ya existen — no se crea un sistema nuevo»*, y contra el árbol eso es **falso para `hunger` y `energy`**: las dos apuntan al **techo de stamina**, que **§1 de este mismo documento difiere** por escrito (*«v1 lo acepta y almacena, sin efecto»*). Lo mismo con media pata de `dehydration`: los **bpm** tienen 0 hits en el `lua/`. Nadie cruzó las dos secciones al votar. **Las tres con blanco real bajaron vivas; las otras dos quedan escritas y NEUTRAS**, declaradas con un campo `live = false` y sostenidas por dos filas de harness (`MET-C12` mide que no muevan nada; `MET-C14` fabrica la colisión de palancas que hoy no existe, porque sin ella el guard no sería auditable). Es el mismo precedente que COA-52 estrenó con `PAIN_FRAC`. **El día que la stamina exista, `live = true` y `MET-F5` se pone rojo para obligar a mirar.**

**COA-39 — `ApplyExternalCondition(ply, id, severity)` queda RATIFICADA, con la firma que Craving congeló desde el consumidor.** Cierra la deuda **D-5**: la firma llevaba un mes viva en un solo lado del pacto.

```lua
COAGULANT.ApplyExternalCondition(ply, id, severity)
-- id       : "starvation" | "dehydration"  (el namespace del emisor va implícito
--            en el id; Coagulant NO pregunta quién llama)
-- severity : 0..1, y 0 LIMPIA la condición
```

Lo que ratificar significa acá, que es lo que faltaba: **la semántica clínica de cada id**.

| id | Qué hace Coagulant | Quién mata |
|---|---|---|
| `starvation` | suprime la regeneración natural de sangre proporcionalmente a `severity`; con `severity == 1` la anula | **Coagulant.** La muerte por inanición pasa a ser un desangrado que no regenera, no un chip de HP |
| `dehydration` | además de lo anterior, baja el **techo** de sangre (volumen de plasma) y sube los bpm | **Coagulant**, por la misma vía |

**El canal es de UNA sola dirección y no lleva gauges.** `ApplyExternalCondition` existe para contestar *quién es dueño de la muerte* — Craving necesita esa respuesta para apagar su propio daño de HP, y solo empujando se sabe si hay quién reciba. Todo lo demás se lee (abajo). Un id nuevo se agrega solo si su condición **puede matar**; si solo modula, no es una condición, es un gauge.

**COA-38 — Coagulant PUEDE leer a Craving, read-only y por capacidad.** Es la enmienda del autor a la dirección única que este doc fijaba en §12, y **acá está su sede** (la mitad de Craving, CRV-13, solo la acepta):

```lua
-- lazy-check + capability check, nunca en file-scope, jamás asumido
local crav = Corpus.GetModule("craving")
if crav and isfunction(crav.GetMetabolic) then
    local m = crav.GetMetabolic(ply)   -- { hunger, hydration, energy, protein, micro }
end
```

*Alcance exacto, y no se estira:* Coagulant **lee**. No escribe estado de Craving, no le registra ítems, no le publica nada. Sin Craving montado —o con un Craving viejo sin `GetMetabolic`— la fila `METABOLIC` **no existe** y las cinco palancas de abajo quedan en su valor neutro: degradación honesta, **COA-7** aplicado a un peer nuevo.

*Por qué se relajó* (razón del autor, se anota para que la decisión sea falsable): Cargo puede ser autónomo, pero Coagulant ya depende de Cargo para almacenar los medicamentos y Craving ya depende de Coagulant para que la inanición sea clínica. La dirección única describía un desacople que en estos dos módulos ya no existía.

**COA-40 — El metabolismo TECHA y FRENA; nunca mata.** Ninguno de los cinco valores toca HP ni mata por sí solo. La muerte sigue teniendo **un solo dueño** y llega por la vía de siempre: sangre en 0. Es la misma regla que CRV-3 leída desde este lado, y es la que impide que "más realismo" se convierta en cinco causas de muerte compitiendo.

Los cinco entran por palancas que **ya existen** — no se crea un sistema nuevo:

| Valor leído | Palanca | Efecto con déficit máximo |
|---|---|---|
| `hunger` | techo de stamina | −20 |
| `hydration` | techo de sangre (plasma) · bpm | −25 % de techo · +12 bpm |
| `energy` | techo de stamina · velocidad de recuperación | −25 · ×0.5 |
| `protein` | `REGEN_PER_S` · curación de heridas tratadas | ×0.3 · más lenta |
| `micro` | `BleedRate` | ×1.6 — coagulas peor |

**El umbral de déficit es de Coagulant, no de Craving** (contraparte de CRV-24: Craving publica números crudos y no sabe qué es un déficit). Uno solo para los cinco, tunable como todo el balance de §11:

```lua
Config.METABOLIC_DEFICIT_AT = 40          -- rampa desde acá hacia abajo
-- deficit(v) = math.Clamp((40 - v) / 40, 0, 1)   -- 0 en 40 o más, 1 en 0
```

**En pantalla: la fila `METABOLIC`, y los cinco entran por el techo que ya se dibuja.** El menú médico **no** gana cinco barras de tamaño completo — los déficits mueven la *marca de techo* que ya existe sobre stamina, y la nueva sobre sangre. La fila existe para contestar **por qué** el techo está bajo: un techo caído sin causa visible es exactamente la señal muda que el sistema de color prohíbe.

**Son CINCO filas compactas, no tres.** La tentación es mostrar solo los nutrientes —"hambre y sed ya se ven en el inventario"—, pero acá no se muestra el *stat*: se muestra **la causa de un techo**, y hambre e hidratación son dos de las cinco causas. Un médico que ve el techo de sangre al 78 % y solo tres chips de nutriente no tiene cómo saber que el paciente está deshidratado. La barra de Cargo y esta fila responden preguntas distintas: *"¿me queda comida?"* contra *"¿por qué este cuerpo no se recupera?"*.

Regla de tinte, que sale del sistema de color sin excepción nueva: un valor **sin déficit es cromo** (se lee tenue, no compite), y solo el déficit enciende señal fija (`warn` → `urgent` → `critical`). Un cuerpo alimentado no es un aviso, igual que una silueta sana no lo es.

---

## 9. Net y estado replicado

Todo net string vía `Corpus.Net.Register("coagulant", msg)` → `corpus_coagulant_<msg>`. El server posee el estado; el cliente manda intents y renderiza.

| Canal | Dirección | Contenido |
|---|---|---|
| `NW2Float "coagulant_blood"` | S→todos | sangre 0..100 (para StatusPanel/HUD, barato) |
| `NW2Float "coagulant_speed_mult"` | S→todos | multiplicador de cojera (Move hook en ambos realms) — **COA-17: se escribe solo si cambió** (§6); un NW2 se replica a todos los clientes en cada escritura |
| `corpus_coagulant_state` | S→C (owner) | snapshot de heridas/torniquetes/tratamiento en curso — **COA-16: on-change**, no por tick. **COA-52 (§17), escrito el 2026-08-25:** lleva además el **dolor por zona** (`p`, redondeado) y el **percibido global** (`pain`), calculados en el server; el cliente **nunca** los deriva. La **supresión** NO viaja: es capa de diagnóstico y este tramo no abre canales que la niebla todavía no sabe filtrar — se lee por consola con `coagulant_status` |
| `corpus_coagulant_treat` | C→S | intent `{ kind, zone }` — server valida (ítem presente vía Cargo o modo degradado, zona válida, sin tratamiento en curso) |
| `corpus_coagulant_cancel` | C→S | cancela el tratamiento propio en curso |

**COA-33 —** La barra de progreso se calcula client-side desde `{ kind, endsAt, duration }` del snapshot — sin tick de red.

**COA-52 — Un vital que la niebla puede OCULTAR no puede viajar por NW2.** Un `NW2` se replica a **todos** los clientes en cada escritura (es la mitad de COA-17 que importa acá) y **no tiene filtro por observador**, así que un vital sujeto a la niebla de COA-44 tiene que ir en el snapshot, que es owner-only. Por eso el dolor **no** gana un `NW2Float` aunque la sangre tenga uno. La sede del razonamiento y la **deuda que destapa sobre `coagulant_blood`** están en §17 (COA-52), no acá.

**El emisor deja de preguntar «¿tiene heridas?».** Su condición (`bleeding.lua:20`) pasa a ser *«aporta dolor ≠ 0, torniquete o isquemia»*: una zona puede **doler sin herida activa** —el caso exacto de COA-49— y con la condición vieja no viajaría, dejando a la niebla sin qué pintar. Es cambio de **red**, no de dibujo. Ojo con el alcance real, medido: hoy una herida `treated` sigue en `zdata.wounds`, así que hoy esa zona **sí** viaja; el defecto muerde recién con la forma `w[tipo] = {a,t,i,s}` de COA-49.

---

## 10. UI

Tres piezas cliente, todas leyendo el snapshot + NW2 (nunca estado propio inventado):

1. **HUD silueta** (`HUDPaint`): silueta de **7 zonas** (enmienda 2026-07-21: el rect del torso se parte en `chest` y `stomach` en proporción **58/42** — la de la silueta del browser de Caliber — con gap de 0.01 y mismo x/w: chest `y=0.18 h=0.21`, stomach `y=0.40 h=0.15`) coloreadas por score (sano→amarillo→rojo), pulso en zonas sangrando, icono de torniquete. Se desvanece cuando todo está sano y la sangre es 100. Barra de progreso de tratamiento centrada abajo cuando hay uno en curso. Capa de vignette de cabeza/sangre crítica en `RenderScreenspaceEffects` (§6).
2. **Menú médico**: concommand `coagulant_menu` + **tecla propia** (convar de cliente `coagulant_key_menu`, default `KEY_M`, con su DBinder en el tab Q). La tecla la lee un **poleo de `input.IsButtonDown` en `Think`** con detector de flanco y guards (`gui.IsGameUIVisible()`, `vgui.GetKeyboardFocus() == nil`, y `vgui.CursorVisible()` — la tecla solo abre, así que con cualquier menú de cursor en pantalla no dispara; sin este último, elegir la tecla en el binder desplegaba el menú dentro del propio tab Q, mini-ronda 8) — **no** `PlayerButtonDown`, que **no dispara client-side en singleplayer** (quirk del engine): la trampa la pagó Cargo con su tecla I (`corpus_cargo_ui.lua`) y este módulo la volvió a pagar en la ronda 7 —la tecla parecía muerta y la culpa se la llevó el binder del tab, que escribía bien—; el fix es de la sesión «Fix ronda 7». **La tecla no cierra**: con el menú abierto (`MakePopup()`) el foco de teclado es del frame y el poleo no dispara; el menú se cierra con la **X de su `DFrame`** (`SetDeleteOnClose`, comportamiento default). Pasar la tecla a toggle (que también cierre) es **decisión de diseño del autor, abierta desde la ronda 7**. Silueta clickeable → lista de heridas de la zona (tipo, severidad, tratada) → botones de tratamiento habilitados según disponibilidad: conteo de ítems si Cargo está; **sin Cargo se rotulan *field* y no se grisan por cooldown** — el cooldown del modo degradado **no viaja en el snapshot (§9)**, así que el rechazo llega por chat desde el server. Se grisan igual mientras hay un tratamiento en curso (uno a la vez, §7), y el torniquete cuando la zona seleccionada no es una extremidad. Al hacer clic manda el intent y **queda abierto** mostrando el progreso: no se cierra solo.
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
| `coagulant_env_conditions` | sv | 1 | on/off de la capa sistémica: radiación, agente nervioso, toxina (**COA-43**, §17) |
| `coagulant_o2_scale` | sv | 1.0 | multiplicador de la caída de saturación (**COA-42**, §17) |
| `coagulant_rad_scale` | sv | 1.0 | multiplicador de acumulación de dosis de radiación |
| `coagulant_diagnostic_fog` | sv | **0** | niebla diagnóstica: lo no conocido deja de viajar en el snapshot (**COA-44**, §17). Nace apagada: le pega de frente al flujo de campo |
| `coagulant_hud` | cl | 1 | on/off HUD silueta (**COA-25**: el crítico visual no se apaga: es información vital) |
| `coagulant_key_menu` | cl | `KEY_M` | tecla que abre el menú médico (0 = sin bind; se ajusta desde el tab Q) |

**COA-27 —** Los números internos de balance (tabla §3, curvas §4-§6, tiempos §7) viven en `corpus_coagulant_config.lua` como tablas — tunables editando data, sin tocar lógica.

**COA-35 —** Un check (selftest/harness) jamás hardcodea un número tunable: se deriva de la config. Si el check congelara el número, retunear **rompería** el selftest en vez de validarlo — los checks de amplitud del sway se derivan de `SWAY_PER_SCORE`, no de un `0.70` literal.

---

## 12. Soft-deps — superficies consumidas y expuestas

### Cargo (presente hoy — nombres verificados contra el código real)

- **Consume:** `Items.Register(def)` (4 defs §7); `Inventory.HasItem(ply, id)` (**presencia al validar el arranque de un tratamiento — la única superficie que ve los `unique`**: `CountItem` cuenta solo stacks, así que el torniquete siempre daba 0 — pagado en juego el 2026-07-13, fallo G4; Cargo la agregó como su entry 18); `Inventory.CountItem(ply, id)` + `Inventory.TakeItem(ply, id, 1)` (**server, al completar**: re-validar y consumir la unidad stackable); `StatusPanel.RegisterBar` (client); y **`CARGO.ClientState.items` (client, superficie OFF-CONTRACT de Cargo)** — el menú médico cuenta con ella las DOS clases de ítem (los stacks por `count`, los `unique` por `uid`) porque `CountItem` no existe en el cliente. **Deuda asumida:** si Cargo cambia la forma de su snapshot, el conteo de los botones se rompe **en silencio**; el candidato natural es que Cargo exponga un contador de cliente en su contrato.
- **PEDIDO RATIFICADO Y ENTREGADO — enmienda 2026-08-25 (pedido del 2026-08-09, COA-51 en §17).** `Containers.AreaHas` / `AreaCount` / `AreaTake` para el área de suministro del hospital, **y una cuarta que este repo no había pedido: `AreaTakeUnique`**. Cargo las aceptó, las escribió y las commiteó el **2026-08-22** (su roadmap **#60**, CHANGELOG **80**, commit `63c784f`; `corpus_cargo_containers.lua:646-741`), **server-only**. La cuarta salió de que Cargo **midiera el `lua/` de este repo** y no de una preferencia: `treatment.lua:163` gatea con `HasItem` y `:170` consume con `TakeUnique` **porque el torniquete es `unique`** — con sólo las tres, el área **vería** un torniquete en un mueble y no tendría con qué consumirlo, que es el fallo **G4** movido del lado de la presencia al del **take**. Semántica y consecuencias, en §17. **Lo que esta línea decía hasta hoy —que Cargo no lo había ratificado y que hasta entonces el tramo no bajaba— quedó viejo el 2026-08-22 y se corrigió el 2026-08-25**: el bloqueante externo del área hospital está **CAÍDO**.
- **Expone hacia Cargo:** `OnEncumbrance(ply, fraction)` — Cargo ya lo llama con pcall en cada cambio de peso (`corpus_cargo_movement.lua`). v1: almacenar en `st.encumbrance`, cero efecto. `Inventory.GetWeightFraction(ply)` queda disponible para cuando la stamina exista.

### Caliber (mock-first — su pipeline de jugador no existe)

- Punto único de integración: la creación de herida (§3) ocurre en `PostEntityTakeDamage` con el daño final — cuando Caliber Block 3 mitigue daño de jugador, las heridas nacerán automáticamente post-armadura, **sin tocar código de Coagulant**. Si Caliber además expone hit-location enriquecido (placa golpeada, penetración), el enriquecimiento entra como refinamiento del `wound.type/severity` en ese único punto, con lazy-check.
- La rama vacía del scaffold en `ScalePlayerDamage` se reduce a capturar hitgroup (ya no necesita más).

### Craving (consumidor, y desde el 2026-08-08 también peer leído)

- Consume los eventos de §8 y `GetBlood`/`IsBleeding`, y empuja `ApplyExternalCondition` (§8, **COA-39**).
- **COA-31 — ENMENDADA el 2026-08-08 (voto del autor).** La dirección dejó de ser única en un solo sentido: Coagulant **sí** detecta a Craving, pero **solo para leer** los cinco valores metabólicos vía `GetMetabolic`. La sede del permiso, con su alcance exacto y la razón, es **COA-38** en §8. Lo que la enmienda **no** toca: Coagulant no escribe estado de Craving, y la detección sigue siendo por capacidad (`isfunction`), nunca por presencia.

### Stalker (emisor de condiciones ambientales — **COA-48**, §17)

- **Consume de Coagulant:** nada. Stalker **empuja** y no lee — no toca estado clínico, no registra acciones, no dibuja nada del menú.
- **Empuja:** `ApplyExternalCondition(ply, id, severity)` con los ids de **COA-43** (`radiation`, `nerve_agent`, `toxin`) desde zonas de radiación, artefactos equipados y anomalías químicas. Es la vía de lo que **no tiene evento de daño**; lo que llega como `DMG_*` lo mapea Coagulant solo, en el `PostEntityTakeDamage` donde ya nacen las heridas (**COA-9**).
- **Sin Stalker montado:** las condiciones ambientales no llegan y el daño de ese origen cae al HP nativo (§14). Detección por **capacidad**, nunca por presencia — la regla de siempre.
- La contraparte vive en [`../../corpus-stalker/docs/STALKER_Arquitectura.md`](../../corpus-stalker/docs/STALKER_Arquitectura.md) §2, que ya declaraba este pacto desde el otro lado mientras esta sección no lo listaba.

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

---

## 17. Perfusión, oxígeno y daño ambiental (enmienda 2026-08-08b)

> Votada por el autor en **tres puntos** antes de escribir una línea (**COA-28**), en la sesión de diseño siguiente a la que dejó el spec v4 del menú (`dev/coagulant-v4-spec.html`). **Nada de esto está en código**: entra al registro con evidencia `INTENCION`. Mientras no exista, el comportamiento de hoy —el daño ambiental cae al HP nativo— es el correcto y no un bug: es §14 aplicada a un dominio que todavía no nació.
>
> **El disparador no fue el daño ambiental sino una pregunta de alcance:** si el catálogo del menú alcanza para un jugador que hace roleplay de **médico de hospital** y no solo de médico de campo estilo ACE3. Las dos preguntas resultaron ser **una sola**, y esa es la única razón por la que esta enmienda es una y no dos.
>
> **La sección creció después, con las sesiones de diseño que fue destapando** — se listan acá porque el título de §17 ya no las nombra: **COA-49** (la herida tratada tiene tiempo, 2026-08-09), **COA-50/COA-51** (el área hospital y la superficie que hay que pedirle a Cargo, 2026-08-09) y **COA-52** (el dolor como stat, 2026-08-17). De las cuatro, **COA-52 bajó a código el 2026-08-25** y deja `INTENCION`; COA-49, COA-50 y COA-51 siguen ahí.

### El agujero, que ya estaba abierto y no se veía

Ningún ítem del catálogo v4 sobra: los 24 se usan en un ER real. Lo que faltaba no eran ítems, era **causa**.

- **Tres de los 24 tratan condiciones que nada en el simulador produce.** El `Needle thoracostomy` descomprime un neumotórax y no hay neumotórax en el modelo (§3 tiene seis tipos de herida; los estados de zona son `tq`, `isch` y `frac`). La `Cricothyrotomy` y la cánula nasofaríngea abren una vía aérea que nunca se obstruye. Su gate en el spec es puramente **geométrico** —*chest only*, *head only*— porque no había condición que gatear. La categoría AIRWAY entera es decorado.
- **`Atropine` está en el catálogo sin gate y sin razón de existir.** Es el antídoto del agente nervioso.
- **Los cuatro damage types de §3 marcados «no crean herida»** (`DROWN`, `POISON`, `NERVEGAS`, `RADIATION`) son, hoy, el único daño del juego que el médico **no puede ver ni tratar**.
- Y `../../corpus-stalker/docs/STALKER_Arquitectura.md` §2 ya le había **prometido** a Coagulant «los efectos clínicos de la radiación y de las anomalías químicas», por `ApplyExternalCondition` — mientras §12 de este doc ni siquiera listaba a Stalker como peer. Dos docs apuntaban al mismo hueco desde lados opuestos y ninguno lo llenaba.

La conclusión que ordena todo lo demás: **la capa sistémica no es contenido extra para el hospital, es el paciente que le falta a media UI que ya está escrita.**

---

### COA-41 — La muerte cambia de INSUMO, no de dueño: perfusión en vez de volumen

**El dueño de la muerte no se toca.** §2 ya lo fijó y sigue palabra por palabra: el HP nativo es el trauma directo del engine, la sangre no mata por sí misma, y **la muerte es siempre por HP 0** vía el drenaje de §5 con `DMG_GENERIC` sin atacante (**COA-11**). El voto del autor —*«health es el dato de HL2, podría traducirse como qué tan estresado y dañado está el cuerpo»*— es exactamente esa lectura, y esta enmienda la conserva entera.

Lo que cambia es **qué alimenta el drenaje**. Hoy lo alimenta el volumen de sangre solo; pasa a alimentarlo la **perfusión**, que es lo médicamente cierto: el tejido no muere por falta de litros, muere por falta de oxígeno entregado, y el volumen es *una* de las dos entradas.

```lua
-- 0..100, misma escala que blood, mismo umbral de 40 de §5
function COAGULANT.Perfusion(ply)
    return st.blood * (st.sat / 100)
end
```

§5 se reescribe sustituyendo `blood` por `Perfusion(ply)` en las dos líneas —el umbral y la curva— y **nada más**:

- `perf ≥ 40`: sin efecto sobre HP.
- `perf < 40`: `hpDrain = (1 + 4 × (40 − perf) / 40) × coagulant_hpdrain_scale`.

**Retro-compatibilidad exacta, y es deliberada:** `sat` sano vale **100**, no 97-99. Un humano real en reposo lee 97-99 y mostrar 100 es una simplificación votada, por la misma regla que el spec v4 aplica al metabolismo (*un cuerpo alimentado no es una alarma*): el estado sano tiene que ser **neutro**, no un número que invite a tratarlo. Con `sat = 100`, `Perfusion == blood` y **ningún número de balance de §4-§6 se mueve**. Esta enmienda no obliga a retunear nada.

**El evento `Coagulant_BloodCritical` conserva su nombre** aunque ahora cruce por perfusión. Renombrarlo rompería a Craving, que lo consume (§12), y el evento siempre significó *el paciente entró en la zona donde se muere* — el nombre es histórico, la semántica no cambió. Se anota acá para que nadie lo «arregle».

**Lo que esto habilita, y es todo el punto:** la asfixia, el agente nervioso, el neumotórax a tensión y el ahogo dejan de necesitar una segunda ruta de muerte. Convergen en el número que el jugador **ya está mirando** — la amplitud del trazado del ECG, que el spec v4 deriva de `blood` y pasa a derivar de la perfusión. La traza se aplana igual, por una causa nueva.

---

### COA-42 — `sat` es un vital de primera clase, y NO es la stamina

El autor preguntó si el oxígeno podía **ser** la stamina, para simplificar. La respuesta es no, y las tres razones importan porque cada una es un modo de falla concreto:

1. **Escala de tiempo y agencia opuestas.** La stamina es un presupuesto que el jugador gasta y recupera en segundos por decisión propia; la saturación solo baja cuando algo está roto y su recuperación no depende de él. Fusionadas, **correr = asfixiarse**.
2. **Destruye la única discriminación que la categoría AIRWAY existe para hacer.** Con un número solo, un jugador que acaba de esprintar y uno con neumotórax a tensión se le presentan **idénticos** al médico. Ese diagnóstico diferencial *es* el juego médico.
3. **Las superficies de tratamiento son disjuntas.** La stamina baja se trata descansando. Si son el mismo número, **descansar cura un neumotórax.**

Pero el acoplamiento que el autor estaba viendo es real, y ya hay dónde ponerlo: **se encuentran en el techo de stamina**, la fórmula del spec v4 que ya recibe sangre, dolor, torniquete, fractura, hambre y energía. Un término más:

```lua
-- dentro de COAGULANT.StaminaCap(ply), junto a los seis que ya están
-- MISMA FAMILIA DE CURVA que los dos términos metabólicos: umbral + rampa.
function COAGULANT.HypoxiaDeficit(sat)
    return math.Clamp((94 - sat) / 34, 0, 1)   -- 0 en 94 o más, 1 en 60
end

c = c - 30 * COAGULANT.HypoxiaDeficit(ply:CoaSat())   -- la hipoxia techa la stamina
```

> **Corrección 2026-08-09, y el defecto era de esta misma sección.** La primera redacción decía `c = c - 60 * (1 - sat/100)`, y estaba mal por dos motivos que aparecieron al bajarla al mock. **(1) Familia de curva equivocada:** era el **único término lineal crudo** de una fórmula donde todo lo demás es o una constante plana (12/15/6) o una rampa con umbral (`Deficit`, 20 y 25) — y «un valor que solo importa por debajo de un umbral» ya tenía forma en este doc. **(2) Resolución tirada:** repartida sobre 0..100, la rampa gastaba casi todo su rango en `sat < 80`, donde el paciente ya está inconsciente, y en la banda útil (100→90) aportaba entre −0 y −6, o sea nada; el coeficiente además era 2,4× el mayor término existente. Los dos números —**94** y **30**— son balance de **COA-27** y viven en `Config`. Lo que **no** es balance es la forma: umbral más rampa, como los otros dos.

**Y sale más barato que fusionarlas, no más caro.** `sat` no tiene lógica de drenaje por frame: nace en 100, se queda ahí el 99 % de la partida y solo se mueve cuando hay causa. Costo total: una variable, un término en una fórmula que ya tiene seis, y una multiplicación en la amplitud del ECG. Fusionarlas, en cambio, obligaría a desenredar toda la lógica de esfuerzo del `bpm` (`COAGULANT.Exertion`), que ya está escrita.

**En pantalla no gana barra.** Va como cifra al lado del pulso —el bloque tiene lugar— y su déficit mueve la **marca de techo que ya se dibuja** sobre stamina. **Un renglón por vital, y no dos vitales en un renglón** (resuelto 2026-08-09 contra el mock): el punto medio de `bpm · +13 ex` separa *un vital de su modificador*, y reusarlo para unir `SpO₂` con `RR` —que son dos vitales distintos— es un error de lenguaje, no un problema de ancho. La **frecuencia respiratoria no se inventa**: ya está calculada por el ondulado del ECG, `RR = round(60 × (0.22 + 0.42 × ex))` con `ex = 1 − stamina/100`, que da exactamente los 13 rpm en reposo y 38 agotado que este doc ya declaraba. **No entra en la escalera de etiquetas de ritmo del ECG**: la saturación no es un ritmo, y meterla ahí sería el mismo error de lenguaje que el spec v4 evitó a propósito con el metabolismo.

**Hallazgo lateral, y es un caso de las «señales mudas» que el propio spec prohíbe:** el ECG **ya calcula** una frecuencia respiratoria —el ondulado de línea de base, 13 rpm en reposo a 38 agotado— y no la imprime en ningún lado. Es un signo vital ya computado, sin lectura. Imprimirlo cuesta una línea, y con la saturación al lado convierte la respiración en un eje legible en vez de un adorno del trazado.

---

### COA-43 — Las condiciones sistémicas entran por el canal que ya existe

Ninguna de estas es trauma localizable —§3 tiene razón en no crearles herida—. Son **condiciones sistémicas**, y el canal ya está construido y ya prometido: `ApplyExternalCondition(ply, id, severity)` (**COA-39**). Su regla de admisión no cambia y no hace falta que cambie: *un id nuevo entra solo si su condición **puede matar***. Radiación, agente nervioso y toxina califican; por COA-41, matan por la vía de siempre.

**Quién empuja qué, que es donde se rompen estas cosas.** Dos vías, y la distinción es mecánica, no de gusto:

- Lo que llega como **evento de daño** (`DMG_*` del engine) lo mapea Coagulant **internamente**, en el mismo `PostEntityTakeDamage` donde ya nacen las heridas (**COA-9**). No necesita canal externo: Coagulant ya ve ese evento.
- Lo que **no tiene evento de daño** —una zona de radiación que solo emite dosis, un artefacto equipado, una anomalía química— entra por `ApplyExternalCondition`. Esa es la vía de Stalker (**COA-48**).

| id | Qué es | Palancas (todas ya existen) | Qué lo trata |
|---|---|---|---|
| `radiation` | dosis acumulada, no quemadura | `REGEN_PER_S ×0` · `BleedRate ×N` · vómito → hidratación (Craving) | antiemético, quelante, **transfusión**, tiempo |
| `nerve_agent` | crisis colinérgica | `bpm ↓` (bradicardia) · `sat ↓` · techo de stamina · consciencia | **atropina** (ya en catálogo) + pralidoxima |
| `toxin` | veneno/ponzoña | igual que arriba, más suave y reversible | antídoto |

**La radiación NO es una quemadura, y esa es la corrección de fondo.** La quemadura por radiación necesita una dosis local enorme; lo que mata en el síndrome agudo es la médula ósea — dejas de fabricar plaquetas y glóbulos. Traducido a palancas de Coagulant: **la regeneración se va a cero y el sangrado se multiplica**, que son exactamente las dos palancas que **COA-38** ya le había asignado a `protein` y `micro`. La radiación no necesita mecánica nueva: necesita un **acumulador de dosis** —sube con la exposición, baja lentísimo— que alimente multiplicadores que ya están escritos. Y como su único tratamiento verdadero es transfusión, antibiótico y tiempo, es **la condición que le da razón de existir al hospital**: es el paciente que no se arregla con una venda.

**El agente nervioso tampoco es una quemadura de pecho.** Es bradicardia, secreciones, parálisis respiratoria y convulsión: le pega a la vía aérea y a la saturación, no a la piel. Y le da su `can()` a la atropina que ya estaba escrita sin gate.

**`DROWN` no gana id de condición**: es una entrada directa a `sat`, y COA-41 hace el resto. Un id para él sería una condición que no agrega nada que la saturación no diga ya.

> **Sin verificar — no apoyarse en esto hasta medirlo en juego.** El veneno del headcrab venenoso de HL2, canónicamente, deja al jugador en 1 HP y después regenera: nunca mata. Si se sostiene al medirlo, es un caso donde el juego original ya implementó *techa y frena, nunca mata* y conviene copiarle en vez de inventar. **El engine también es un tercero** — la lección la pagó Cargo tres veces con APIs asumidas.

---

### COA-44 — Tres capas de conocimiento: síntoma, signo, diagnóstico

Voto del autor: **la niebla diagnóstica entra**, con su matiz — *«eso amerita a que el jugador deba diagnosticar; lo más obvio de que ocurre es dolor y efectos que sufre el jugador»*. Esa frase es la que define las capas, y hay que leerla como el límite de la niebla y no solo como su permiso: **el síntoma nunca se oculta**.

| Capa | Cuesta | Qué muestra |
|---|---|---|
| **Síntoma** | nada, siempre visible | lo que el cuerpo *hace*: dolor por zona, cojera, sway de la mira, vignette, disnea, el trazado del ECG. El paciente los **sufre** y el médico los **observa**; ninguna acción los revela porque ya están pasando |
| **Signo** | examen, segundos | qué tipo de herida, cuántas, si hay sangrado activo. `Examine zone`, palpación |
| **Diagnóstico** | instrumento | severidad exacta, fractura contra contusión, hemorragia interna, dosis de radiación, la cifra de saturación. Rayos X, ecografía, oxímetro, Geiger |

**Consecuencia sobre el paperdoll, y es la decisión concreta: bajo niebla la rampa de la silueta pinta DOLOR, no score.** El dolor es el síntoma; el score es el diagnóstico. Correlacionan, pero el dolor **no discrimina** —una zona a 6 puede ser tres balas o un fémur roto— y esa indeterminación es justamente el juego. Los glifos de tipo aparecen recién tras el examen; el zigzag de fractura, recién tras la imagen. La isquemia sí se ve sin instrumento: el frío y la palidez de un miembro ocluido son síntoma.

**La niebla es un filtro de RED, no de dibujo.** Si el server manda el estado completo y el cliente decide qué tapar, la niebla la derrota un cliente modificado y deja de ser una regla del mundo para ser una decoración. Lo que no se conoce **no viaja** en el snapshot de §9. Esto tiene un costo real —el snapshot deja de ser un volcado y pasa a filtrarse por observador— y se anota acá para que no se descubra a mitad de la bajada.

**Y promueve al dolor de diferido a REQUISITO.** §1 listaba el dolor como stat entre los diferidos (**ya no: COA-52 lo especificó el 2026-08-17** — sigue sin código, pero el diseño está y esta dependencia dejó de estar bloqueada). Bajo niebla, el dolor pasa a ser **el único canal gratis**: si no existe, la silueta no tiene qué pintar y la niebla apaga la pantalla en vez de complicarla. El spec v4 ya lo dibuja como barra y ya gatea la morfina con `CoaPain() > 10`; esta enmienda lo vuelve **bloqueante** para la niebla, no opcional.

**Va detrás de convar y nace apagada** (`coagulant_diagnostic_fog`, default `0`): le pega de frente al flujo de campo, donde ver el estado de un vistazo es la mecánica. Servidor de guerra apagado, servidor de hospital encendido. Es también lo que le da sentido a DIAGNOSTICS, que hoy son tres acciones que no consumen nada y no desbloquean nada.

---

### COA-45 — Los dispositivos persistentes siguen siendo casos especiales

Se propuso generalizar `z.tq` a un `z.dev = {}` que alojara vía IV, tubo torácico, tubo endotraqueal, sonda y mascarilla. **El autor votó que no:** cada dispositivo persistente sigue siendo un caso especial con su propio campo en la zona, como el torniquete.

**Lo que la decisión cuesta, escrito para que la cuenta esté a la vista y no aparezca como sorpresa tres rondas después.** Cada dispositivo nuevo paga tres veces: su campo en `st.zones[zona]`, su render propio sobre el eje de la zona (§10) y su línea en el snapshot (§9) — y ninguna de las tres se amortiza con la siguiente. `z.tq` es hoy la única instancia, y funciona; el precio se paga recién a partir de la segunda.

**Consecuencia sobre el catálogo, que reordena lo de abajo:** todo lo que necesita persistencia queda **diferido y nombrado**, no descartado — tubo torácico, ventilador, vía IV como prerequisito de fluidos. Y los fluidos **siguen siendo autocontenidos**: no ganan acceso venoso previo. Criterio para admitir un dispositivo nuevo el día que se pida: que su estado sea observable en el paperdoll y que su ausencia cambie la simulación, como el torniquete. Si solo decora, es un ítem consumible, no un dispositivo.

**Nota de assets (autor, 2026-08-08):** hay compra en curso de modelos de equipamiento médico e ítems médicos en FAB (marketplace de Unreal). Cuando lleguen, el orden sigue siendo el de COA-28 y el del roadmap §5: **que exista un modelo no crea un ítem**. `docs/ASSETS.md` es para mirar cuando un tramo ya decidido necesita con qué, no al revés.

---

### COA-46 — La tabla de §3 se corrige en tres filas

Hallazgos leyendo `corpus_coagulant_config.lua:139-155` contra la tabla de §3. Los tres son de código vivo, no de diseño:

1. **`DMG_ACID` no está en `DMG_QUEMA`.** Cae al default conservador y produce una **contusión**. Una quemadura química se venda igual pero sangra distinto (mult 0.2 contra 0.0) y, sobre todo, la contusión miente sobre qué pasó. Va a `DMG_QUEMA`.
2. **`DMG_SHOCK` está bien como quemadura** —el daño tisular es ese— pero **pierde la arritmia**, que es lo característico de la electrocución y lo único que el ECG podría dibujar y una acción podría revertir (COA-47).
3. **`DMG_BLAST` produce metralla y nada torácico.** La lesión pulmonar por onda expansiva es la causa clásica del neumotórax — o sea, **la fuente que le faltaba al `Needle thoracostomy`**. Entra como caída de `sat` acompañando a la herida de metralla del torso, no como herida nueva.

---

### COA-47 — Parada cardíaca: RCP y desfibrilador

**No hay RCP ni desfibrilador en un menú médico cuyo ECG puede decir `ASYSTOLE`.** La etiqueta existe en la escalera de ritmos del spec v4 y no hay una sola acción que responda a ella. Esto no es una carencia de hospital: ACE3 tiene RCP, y es la omisión más visible del catálogo tal como está. Con COA-41 además gana causa —la perfusión puede colapsar por saturación, no solo por sangrado— y con COA-46 gana la suya el desfibrilador.

Las dos entran por el registro abierto de acciones, sin cambio de UI, en `CIRCULATION`.

---

### COA-48 — Stalker entra a §12 como peer emisor

`../../corpus-stalker/docs/STALKER_Arquitectura.md` §2 ya declaraba a Coagulant como destino de «los efectos clínicos de la radiación y de las anomalías químicas» vía `ApplyExternalCondition` — la firma que **CRV-4** congeló y **COA-39** ratificó. §12 de este doc no lo listaba. Se agrega, con el mismo régimen que los otros tres: detección **por capacidad**, nunca por presencia, y degradación honesta si Stalker no está montado (las condiciones ambientales simplemente no llegan; el daño cae al HP nativo, §14).

Alcance exacto, y no se estira: Stalker **empuja** condiciones. No lee estado clínico, no registra acciones, no dibuja nada del menú.

---

---

### COA-49 — La herida tratada tiene TIEMPO: se cura sola, o se infecta

Voto del autor el **2026-08-09**, continuación de la sesión que dejó §17: es el primero de los dos ejes que la sección había anotado **sin votar**. Hasta acá `zone.w[tipo] = { a, t, s }` no tenía tiempo: una herida tratada era tratada **para siempre**, y el herido nunca se convertía en un paciente que *se queda*.

**Tres contadores y dos relojes, sobre la forma que ya existe.** Los estados NO son un enum por herida: son contadores por tipo, como `a` y `t`, porque el cupo ya es por tipo y por estado y romper esa forma obligaría a rehacer el reparto de glifos entero.

```
zone.w[tipo] = { a = <activas>, t = <tratadas>, i = <infectadas>, s = <severidad> }

  a  --tratar (limpia)-->  t  --reloj de curación-->  desaparece
     \--tratar (sucia)-->  i  --antibiótico-------->  t
                            \--reloj de sepsis----->  condición sistémica
```

- **`t` lleva reloj de curación.** Cada `HEAL_S` se resuelve **una** herida tratada de la zona (`t -= 1`). Es un acumulador por zona sobre el **tick de 1 s que ya existe** (§4), no una estructura nueva ni un timer por herida.
- **`i` no se cura sola** y su reloj corre en la dirección contraria.
- **`i` pesa entero en el score de zona**, no la mitad como `t`: no está resuelta.

**El Medkit no cambia una línea, y eso es el punto.** Hoy cierra las heridas ya `treated` de una zona (**COA-21**); con esta enmienda sigue haciendo exactamente eso — sólo que ahora es el **atajo** de una resolución que además ocurre sola. Es la comprobación que esta enmienda tenía que pasar: **COA-21 nació porque una herida tratada pesaba para siempre y dejaba cojera permanente**, y agregar tiempo sin resolución automática habría reintroducido ese bug con otro nombre. La curación automática es lo que lo impide; el Medkit es comodidad, no la única salida.

**Qué decide si una herida sale limpia o sucia**, en el momento de tratarla:

| Entrada | Efecto |
|---|---|
| tipo de herida | `punzante` y `metralla` son sucias por naturaleza (cuerpo extraño retenido); `quemadura` casi nunca; `contusion` nunca — no hay puerta de entrada |
| `Debridement` previo | limpia la herida: es **profilaxis**, no cura. Le da al ítem un motivo que hoy no tiene |
| déficit de `micro` | sube el riesgo — misma palanca que **COA-38** ya le había asignado |
| zona | `stomach` peor que un brazo |

**Y le da su `can()` al antibiótico**, que estaba en el catálogo v4 sin gate — el segundo caso del mismo hallazgo que ordenó §17 (acciones sin condición), después de la atropina.

**La sepsis mata por donde matan todos: la perfusión.** Cuando el reloj de `i` vence, la zona aporta severidad a una condición sistémica que baja el **techo de sangre**, suprime la regeneración y sube los bpm — las tres palancas que ya existen (la de techo la estrenó `dehydration` en **COA-38**). Si el techo cae por debajo del umbral de §5, el paciente muere por **COA-41** y por nada más: **un solo dueño**, sin ruta nueva. No es id del canal externo de **COA-39** porque no viene de afuera: nace dentro de Coagulant, del estado de sus propias heridas.

**Bajo niebla diagnóstica (COA-44) las tres capas caen solas, sin inventar señal:**

| Capa | Qué delata la infección |
|---|---|
| **Síntoma** (gratis) | el dolor de una zona tratada **deja de bajar, o vuelve a subir**. El jugador lo siente sin que nadie se lo diga |
| **Signo** (examen) | fiebre — y ahí el termómetro deja de ser adorno de hospital |
| **Diagnóstico** (instrumento) | cuál de las heridas tratadas es la infectada |

**Glifo:** el tercer estado que la ficha `foundations/wound-glyphs.html` del design system marcaba como *propuesto* queda **votado** — contorno en `--urgent` con núcleo, distinto por forma y no sólo por color, como manda §7.

Los tiempos (`HEAL_S`, el retardo de sepsis, los pesos de riesgo) son balance de **COA-27**: viven en `corpus_coagulant_config.lua` y se tunean sin tocar lógica.

---

### COA-50 — El área hospital es UNA entidad: la estación, con modelo opcional

Voto del autor el **2026-08-09**, cerrando el segundo de los dos ejes que §17 había anotado sin votar — y con él, la pregunta de si compran modelos de equipamiento. La respuesta salió de la forma del diseño y no de una lista de compras.

**Lo que la estación separa, y que la pregunta original juntaba:**

| Gate | Pregunta que contesta | De dónde sale |
|---|---|---|
| **suministro** | ¿tengo el consumible? | contenedores de Cargo dentro del radio |
| **capacidad** | ¿es posible *acá*? | la estación misma |

Son **independientes** en el `can()` de cada acción. Juntarlos hace que tener morfina en un armario te habilite una cirugía, y que un quirófano sin gasas no sirva para nada aunque el armario esté a un metro.

```lua
-- UNA entidad. El modelo es la PIEL, no la entidad.
COAGULANT.RegisterStation(ent, {
  caps   = { "imaging", "surgery" },   -- enum abierto, como el registro de acciones
  radius = 3 * 160,                    -- múltiplo declarado de CARGO USE_RANGE
})
```

**Dos pieles, un solo código:** la **camilla** —el único modelo que se compra— y `SetNoDraw` para los mapas de roleplay que ya traen un hospital construido, donde alcanza con colocar un punto invisible donde estaría cada cama. Que las dos sean la misma entidad es lo que hace la **compra opcional por construcción**: si el modelo no llega nunca, el sistema funciona igual.

**Por qué se compra la camilla y no el resto.** Es el único con papel **mecánico**: un paciente sobre una camilla es un *estado*, y es la superficie de «el paciente se queda», que es todo el sentido del hospital. Un escáner, un monitor y un pie de suero no cambian nada mecánicamente — un punto invisible en un rincón hace su trabajo hoy, a costo cero. Y hay una segunda razón que no es estética: **la camilla es la marca visible de un radio que de otro modo es invisible**, y un radio invisible es una trampa — el jugador ve cancelarse una acción sin saber por qué. Eso es función, no decoración.

**«El paciente se queda» no cuesta mecánica nueva.** Las acciones de hospital son de canalización larga (20-40 s) y exigen que paciente y médico estén dentro del radio; salirse **cancela**, por la vía que ya existe (`Coagulant_TreatmentCancel` con su `reason`, §8). Ocupar físicamente la camilla —animación, vista, entrar y salir— queda **diferido**: es la parte cara y no compra nada que el radio más la canalización no den ya.

**Capacidades al arranque: dos.** `imaging` (rayos X, ecografía — lo que revela el diagnóstico bajo **COA-44**) y `surgery` (cirugía con anestesia, reducción, hemostasia quirúrgica, amputación). El enum queda abierto como el registro de acciones, pero **arranca con dos a propósito**: cada capacidad nueva es una pregunta más en cada `can()`, y la lista larga es la que después nadie recuerda por qué existe.

**Coste, y dónde se paga.** El área **no se resuelve por `can()`**: se resuelve una vez al abrir el menú, más un refresco lento mientras está abierto, en el **server**, y el resultado viaja en el snapshot. Misma disciplina que la niebla de **COA-44** y por la misma razón — el cliente no escanea el mundo.

> **Consecuencia de permisos, declarada y no disimulada.** `CARGO.Containers.OpenFor` **no comprueba dueño**: hoy cualquier jugador a menos de `USE_RANGE` (160) abre cualquier contenedor. El área hospital **no crea** ese hecho, pero **le ensancha el radio** — de 160 unidades a lo que mida la sala. No se arregla acá: el dueño de los permisos de contenedor es Cargo (su roadmap #12 ya tiene los permisos de admin abiertos). Se escribe para que el día que aparezca el reporte «un tipo me vació el botiquín desde la puerta» nadie lo investigue como bug de Coagulant.

#### La superficie que hay que pedirle a Cargo — PEDIDO, no pacto

Coagulant necesita **contar y consumir contra un conjunto de contenedores cercanos**, y el contrato público de Cargo hoy expone **solo `CARGO.Containers.Attach(ent, opts)`**: el contenido vive en `_byId`/`Snapshot`, que es off-contract. Coagulant **ya carga una deuda de ese tipo** —cuenta los ítems de los botones con `CARGO.ClientState.items`, con la nota escrita de que si Cargo cambia su snapshot el conteo se rompe **en silencio** (§12)— y firmar la segunda por comodidad sería convertir un accidente en un método.

La forma pedida es el **espejo exacto de las tres que Coagulant ya usa**, para que no haya que aprender un modelo nuevo:

```lua
CARGO.Containers.AreaHas(pos, radius, id)        -> bool   -- espejo de Inventory.HasItem
CARGO.Containers.AreaCount(pos, radius, id)      -> n      -- espejo de Inventory.CountItem
CARGO.Containers.AreaTake(pos, radius, id, n)    -> ok     -- espejo de Inventory.TakeItem
```

**Las tres, no dos, y por una lección ya pagada:** `CountItem` cuenta **solo stacks** — los `unique` le son invisibles, que es por qué el torniquete daba siempre 0 (fallo **G4**, 2026-07-13) hasta que Cargo agregó `HasItem`. Un `AreaCount` sin su `AreaHas` reproduce el mismo defecto en el área, con el mismo síntoma: la acción existe, el ítem está, y el botón dice que no hay.

**Se anotó como PEDIDO, no como pacto**, y se escribió el mismo día en el roadmap de Cargo (#60), en los dos lados. Es la conducta que **D-5** dejó como lección: `ApplyExternalCondition` estuvo un mes congelada por el consumidor y sin ratificar por el dueño, y lo que faltaba no era la firma sino saber si el dueño la aceptaba. Hasta acá, cómo se pidió — lo de arriba se conserva como registro del pedido y **ya no describe el estado**.

> ### RATIFICADA Y ENTREGADA — enmienda 2026-08-25 (Cargo la escribió el 2026-08-22)
>
> **El bloqueante que COA-51 declaraba está CAÍDO.** Cargo aceptó el pedido, lo escribió en tanda con su #65 y lo dejó commiteado: su roadmap **#60**, CHANGELOG **80**, commit `63c784f`, `corpus_cargo_containers.lua:646-741`. Las cuatro son **server-only**, que es donde este diseño ya había puesto la resolución del área («el cliente no escanea el mundo»). Lo que cambia respecto de lo pedido:
>
> **1 · Son CUATRO, no tres — y la cuarta la encontró Cargo midiendo el `lua/` de ESTE repo.** `AreaTakeUnique(pos, radius, id)`, gemela de `Inventory.TakeUnique`. El camino de tratamiento usa cuatro superficies, no tres: `treatment.lua:163` gatea con `HasItem` y `:170` consume con `TakeUnique` **cuando el ítem es `unique` — el torniquete lo es**. Con las tres pedidas, el área habría **visto** un torniquete en un mueble y no habría tenido con qué consumirlo: **el fallo G4 exacto que este bloque invoca** —*«la acción existe, el ítem está, y el botón dice que no hay»*—, movido del lado de la **presencia** al del **take**. La lección se volvió a cobrar **en el bloque escrito para evitarla**, y no la cazó quien la escribió sino el dueño de la superficie, contando llamadores.
>
> **2 · La semántica entregada**, que es contra lo que hay que escribir el tramo (y no contra lo que se pidió):
>
> ```lua
> CARGO.Containers.AreaHas(pos, radius, id)          -> bool   -- ve las DOS clases (stacks y unique)
> CARGO.Containers.AreaCount(pos, radius, id)        -> n      -- SOLO stacks, igual que CountItem
> CARGO.Containers.AreaTake(pos, radius, id, count)  -> bool   -- todo o nada; drena ENTRE contenedores
> CARGO.Containers.AreaTakeUnique(pos, radius, id)   -> bool   -- una instancia; borra su blob
> ```
>
> - **`AreaTake` es todo o nada**: valida el total antes de mover, así que un `can()` que pasó no puede quedar seguido de un `do()` que consumió a medias.
> - **Drena entre contenedores** —dos vendas en un estante y tres en el siguiente son cinco, que era el pedido entero— y dentro de cada uno los stacks **de fábrica antes que los gastados** (CRG-7 de Cargo: un gastado no es intercambiable con uno fresco).
> - Cada contenedor tocado se **guarda** (`Containers.Save`) y se **re-sincroniza con sus espectadores**: una caja abierta mientras el médico la vacía seguiría dibujando stock que ya no está.
> - **`AreaCount` no ve los `unique`** — por eso `AreaHas` existe, y por eso un `can()` de este módulo nunca debe gatear un `unique` por conteo.
>
> **3 · Ya no hay que leer `_byId`.** La segunda deuda silenciosa que COA-51 se negaba a firmar **no se firma**: la superficie es pública. La primera —`CARGO.ClientState.items` para el conteo de los botones, §12— sigue igual y sigue siendo la única.
>
> **4 · La deuda se dio vuelta, y conviene tenerlo escrito antes de planificar el tramo.** Cargo dejó la **pasada en juego** de su #60 **diferida hasta que exista el área hospital**, por ser su **único consumidor**: una planilla sobre un llamador que no existe vuelve a medir el harness y no el juego. O sea que hoy **el que bloquea es este repo**, y cuando el área baje a código, esa planilla viaja con ella — las filas de Cargo se corren desde acá.

### Lo que el catálogo gana, por orden de costo

`C` = sirve también en campo · `H` = solo tiene sentido con hospital · **diferido** = necesita un dispositivo persistente, o sea COA-45.

| Categoría | Ítem | | Por qué entra |
|---|---|---|---|
| CIRCULATION | RCP (no consume) | C | COA-47 — hoy `ASYSTOLE` no tiene respuesta |
| CIRCULATION | Desfibrilador | C | COA-47, y le da destino a la arritmia de `DMG_SHOCK` |
| DIAGNOSTICS | Oxímetro | C | la cifra de `sat` bajo niebla (COA-42, COA-44) |
| DIAGNOSTICS | Contador Geiger | C | la dosis de `radiation`; Stalker ya lo tiene inventariado |
| PHARMACOLOGY | Antiemético | C | radiación y opioides |
| PHARMACOLOGY | Naloxona | C | revierte la morfina: sobredosificar pasa a costar |
| PHARMACOLOGY | Analgésico oral | C | ya tiene modelo — `pain_pills` en `ASSETS.md` |
| PHARMACOLOGY | Yoduro de potasio / quelante | C/H | profilaxis y decorporación de radiación |
| PHARMACOLOGY | Pralidoxima (2-PAM) | H | con la atropina, el par real del agente nervioso |
| PHARMACOLOGY | Antibiótico IV | H | el escalón de la infección |
| PHARMACOLOGY | Sedante / anestesia | H | habilita la cirugía que no es de campo |
| DIAGNOSTICS | Rayos X portátil | H | lo que revela `frac` bajo niebla |
| DIAGNOSTICS | Ecografía (FAST) | H | hemorragia interna |
| DIAGNOSTICS | Termómetro | H | señal temprana de infección |
| FIELD SURGERY | Reducción de fractura | H | paso previo al yeso |
| FIELD SURGERY | Amputación | H | la salida de una isquemia vencida |
| AIRWAY | Oxígeno (mascarilla) | C | **diferido** — palanca directa de `sat`, pero es dispositivo |
| AIRWAY | Intubación + ventilador | H | **diferido** — definitivo de la cricotirotomía |
| AIRWAY | Tubo torácico | H | **diferido** — definitivo de la aguja |
| CIRCULATION | Vía IV / intraósea | C | **diferido** — COA-45 dejó los fluidos autocontenidos |

**Dos ejes de hospital que §17 anotó SIN votar. Los DOS se votaron el 2026-08-09** y sus sedes son **COA-49** y **COA-50**, arriba. La lista queda tachada y se conserva por lo que dice el registro de decisiones: eran preguntas antes de ser normas.

1. ~~**Trayectoria de la herida tratada.**~~ **VOTADO 2026-08-09 → COA-49.** Era el eje más barato de los que faltaban y el que más cambia el juego; la sede es la subsección de arriba.
2. ~~**De dónde sale el stock.**~~ **VOTADO 2026-08-09 → COA-50.** No resultó ser «una línea en el `can()`»: son DOS gates independientes —suministro y capacidad— y una superficie nueva que hay que pedirle a Cargo. La estimación de esta línea estaba mal, y se deja escrita en vez de corregirla.

### Pares campo → hospital, para cuando los diferidos se descongelen

| Campo (ya está) | Hospital (falta) |
|---|---|
| CAT tourniquet | reparación vascular — **`z.isch` ya es su reloj** |
| Needle thoracostomy | tubo torácico + drenaje |
| Cricothyrotomy | intubación orotraqueal + ventilador |
| SAM splint / fijador externo | reducción → yeso |
| Wound packing | hemostasia quirúrgica |
| Suture | cirugía con anestesia |

El torniquete ya tiene el gancho puesto: `z.isch` a los 90 s con score mínimo 6, y hoy la única salida es sacarlo. **Un torniquete que solo un hospital puede convertir en algo definitivo es la mejor razón de diseño para que el hospital exista.**

---

### COA-52 — El dolor es estado POR ZONA derivado, más un agregado global saturado (enmienda 2026-08-17)

> Votada por el autor en **seis puntos** el 2026-08-17, antes de escribir una línea (**COA-28**). Es UNA norma con partes: el dolor no se parte en seis IDs porque ninguna de sus partes rige a otro módulo.
>
> **BAJADA A CÓDIGO EL 2026-08-25**, y con eso deja `INTENCION`. Lo que la ejerce: la tabla de balance vive en `shared/corpus_coagulant_config.lua` (bloque *Dolor (§17, COA-52)*, con `Config.PainFromWound` y `Config.PainFrac` como las dos funciones puras); `ZonePain`/`GetRawPain`/`GetPain`/`AddPainSuppression` en `server/corpus_coagulant_core.lua`; el decaimiento de `painSuppress` y el `p` por zona + el percibido global del snapshot en `server/corpus_coagulant_bleeding.lua`; `HUD.ZonePain`/`HUD.Pain` en `client/corpus_coagulant_hud.lua`, **que sólo leen**. El harness da **275 checks ALL GREEN** con **86 filas nuevas** (85 de ellas citando COA-52), y la verificación en negativo es `dev/sabotaje_coagulant_dolor.py`. **CERRÓ EN JUEGO EL 2026-08-25**, planilla `dev/checks/coagulant-dolor-r1.html`: **12/12**, cero defectos. Las dos filas que la norma necesitaba y el harness no podía dar: el reparto de la herida tratada medido **en juego** como `0.35` contra el `0.5` del score sobre la misma zona (`score 3.0 → 1.5`, `dolor 38 → 13`) —la trampa de COA-35 le prohíbe a un check derivado auditar su propia constante—, y la puerta del analgésico desgatillándose con el **percibido** en 4-6 teniendo el **crudo** en 24, que es la única medición que separa `GetPain` de `GetRawPain`. **La medición vieja queda como registro:** el día que se votó, el `lua/` tenía 0 apariciones de `pain` (control positivo de la misma corrida: `blood` daba 64).
>
> **El disparador es que el dolor ya se consume sin haberse escrito.** Cuatro fórmulas del spec v5 lo leen con número exacto —`bpm += pain × 0.22`, `StaminaCap -= pain × 0.35`, `pain > 80 → DAZED`, `pain > 85 → 0.10` de irregularidad del ECG— más la puerta de la morfina, `pain > 10`. Del lado de la **producción** no había un solo número. **COA-44** además lo promovió de diferido a requisito de la niebla. O sea: cinco consumidores y ningún productor.


#### La pregunta que ordena todo: es por zona **Y** global

Los cinco consumidores leen un **escalar global**; el `struct zone` del spec no tiene campo de dolor. Pero **COA-44** pinta la silueta con dolor **por zona** bajo niebla, y el síntoma gratis de **COA-49** es que el dolor **de una zona tratada** deje de bajar o vuelva a subir. Las dos cosas son requisito, así que el dolor es **estado por zona más un agregado**, y la función de agregación es la primera decisión porque de ella dependen todas las demás.

#### D1 — La agregación es **suma con saturación**, y es lo que salva las cuatro fórmulas

```
globalPain = clamp( Σ_zonas  zonePain(z) × ZONE_PAIN_WEIGHT[z],  0, PAIN_MAX )
```

`ZONE_PAIN_WEIGHT` nace **neutro (×1.0 en las siete)**, mismo precedente que `ZONE_BLEED_MULT` (§3-§4): es un eje de tuning, no una decisión clínica de v1.

**La cuenta que descarta a las otras tres, escrita porque es el punto entero de la decisión:**

| Agregación | Rango real | Qué le pasa a `pain × 0.22` y `pain × 0.35` |
|---|---|---|
| suma cruda | 0..700 | `bpm` **+154** y `StaminaCap` **−245**. Retunea las cuatro fórmulas y los umbrales 80 y 85 pierden sentido |
| máximo | 0..100 | nada acumula: tres balazos en tres zonas duelen igual que uno solo |
| promedio ponderado | 0..100 | una zona destrozada aporta ~14 al global ⇒ **`DAZED` es inalcanzable por trauma localizado**, que es justo el trauma que este módulo modela |
| **suma con clamp** | **0..100** | **`+22` / `−35` exactos: los cuatro coeficientes quedan donde están** |

El techo plano no es pérdida de información: en 100 el paciente ya está `DAZED` y con 35 puntos menos de techo de stamina, igual que la sangre se aplana en 0 y el dolor de ACE3 clampea en 1.

#### D2 — La zona vive en **0..100, la misma escala que el global**; `PAIN_FULL_AT` **no es 100**

Una escala sola, sin conversión entre niveles. Tres heridas graves de bala en un muslo suman 108 y clampean a 100: es literalmente el ejemplo con que **COA-44** justifica que el dolor no discrimine — *«una zona a 6 puede ser tres balas o un fémur roto»*.

La rampa de la silueta es **espejo de `ZoneDamageFrac`** (`config.lua:271-275`):

```lua
Config.PAIN_FULL_AT = 60          -- satura la RAMPA, no el ESTADO
Config.PainFrac(pain) = math.Clamp(pain / Config.PAIN_FULL_AT, 0, 1)
```

`ZONE_FULL_AT = 6` satura en «dos heridas graves», no en el máximo que el estado admite, y `PAIN_FULL_AT` copia ese criterio. Con 100 la mitad de arriba de la rampa estaría muerta en juego normal. Y contesta el temor concreto de esta enmienda: una zona con **dolor 7** pinta `t = 0.12` —apenas teñida—, no roja del todo.

#### D3 — La forma primero: **una constante absoluta × la tabla de ACE3 × un eje de severidad que es NUESTRO**

```
PainFromWound(tipo, sev) = PAIN_PER_WOUND × PAIN_TYPE[tipo] × PAIN_SEVERITY[sev]
```

Tres ejes y **un solo número absoluto**, en vez de 15 celdas sueltas. `PAIN_TYPE` son los valores de ACE3 **literales**, sin aritmética de por medio (`VelocityWound 0.9` · `Avulsion 1.0` · `ThermalBurn 0.7` · `PunctureWound 0.4` · `Contusion 0.3` · `Laceration 0.2`), citados **como referente** y no adoptados a ciegas: la tabla de ACE **no tiene eje de severidad**, así que `PAIN_SEVERITY` es una decisión nuestra y queda marcada como tal. Es la mitad de §1.4 que no se podía copiar.

**`PAIN_SEVERITY` es mucho menos convexo que `BLEED_BASE` a propósito** — `1 : 1.9 : 2.9` contra `1 : 2.7 : 6.7`: la nocicepción satura y la hemorragia no. Una herida leve **duele**; una herida leve casi no sangra.

**La matriz son 15 celdas hoy, no 18** — `Config.WOUND_TYPES` tiene **cinco** tipos. El sexto es `punzante`, que **COA-49 ya nombra** (*«`punzante` y `metralla` son sucias por naturaleza»*) y que **no existe en ninguna parte del árbol**. Su fila entra igual en `PAIN_TYPE` con el valor de ACE: el día que el tipo exista no hay que volver acá, y hasta entonces la fila es inerte porque nada la indexa. Es la razón por la que la **forma** se votó antes que los valores.

| tipo | ACE3 | leve ×0.35 | media ×0.65 | grave ×1.00 |
|---|---|---|---|---|
| `metralla` | 1.00 | 14.0 | 26.0 | **40.0** |
| `bala` | 0.90 | **12.6** | 23.4 | 36.0 |
| `quemadura` | 0.70 | 9.8 | 18.2 | 28.0 |
| `punzante` *(no existe)* | 0.40 | 5.6 | 10.4 | 16.0 |
| `contusion` | 0.30 | 4.2 | 7.8 | 12.0 |
| `corte` | 0.20 | 2.8 | 5.2 | 8.0 |

**El control es la única puerta que ya existía, y no se toca para que pase:** con `pain > 10` un balazo **leve** (12.6) habilita la morfina, y un rasguño (2.8) o un moretón medio (7.8) **no**. La puerta discrimina bien con los números que salen de ACE, sin recalibrarla.

**Lo que compra la tabla de ACE, y es el argumento de diseño y no de comodidad: el dolor NO es un proxy del sangrado.** La quemadura sangra 0.2 y duele 0.70; el corte sangra 0.8 y duele 0.20. Los dos ejes están casi invertidos, así que la silueta que la niebla repinta con dolor **dice algo que el score no dice** — que es la condición para que COA-44 sea un juego de diagnóstico y no un cambio de paleta.

#### D4 — El decaimiento **no necesita reloj propio: ya está escrito en COA-49**

**El dolor no se almacena: se deriva del estado de las heridas**, con la misma forma que el score de §6 y con el tercer estado de **COA-49** pesando entero:

```
zonePain(z) = clamp( Σ_tipo PainFromWound(tipo, s) × (a + 0.35·t + 1.00·i)
                     + pisos de condición (D6),  0, PAIN_MAX )
```

Lo que sale gratis de esa forma, y es por lo que se eligió:

- **vendar baja el dolor de esa herida a 35 % en el acto** — la recompensa es inmediata y legible, sin mecánica nueva;
- **una tratada limpia desaparece con el reloj `HEAL_S` de COA-49** ⇒ su dolor cae solo. **El decaimiento del dolor ES el reloj de curación**: cero constantes de tasa, cero timers, cero acumuladores nuevos;
- **una infectada pesa entero** (palabra por palabra de COA-49 sobre el score) ⇒ el síntoma gratis sale exacto **y en sus dos mitades**: al pasar `t → i` el dolor **vuelve a subir** (×0.35 → ×1.00) y además **deja de bajar** (ya no lo resuelve el reloj). No hay que inventar ninguna señal, que es lo que COA-49 prometió.

**Y da vuelta una dependencia que estaba escrita al revés.** `dev/PROMPT_coagulant_menu_v5.txt` §4.3 dice que COA-49 está bloqueada por el dolor; es al revés — **el dolor consume el reloj de COA-49**. Si la migración de `zone.wounds` a `w[tipo] = {a,t,i,s}` no entra en el mismo tramo, el término `i` lee 0 con la forma de lista de hoy y es **exactamente neutro** hasta que COA-49 aterrice. El dolor no espera a esa migración; la aprovecha cuando llegue.

**Lo que esta forma pierde, declarado y no disimulado:** el **fade de dolor de 900 s** de ACE3 para una herida **sin tratar**. Acá una bala sin vendar duele igual para siempre — igual que sangra para siempre hasta que te desangra. Es coherente con lo que el módulo ya hace, y el número de ACE queda citado **como no adoptado**, no omitido.

#### D5 — Los analgésicos ponen un **techo por un tiempo**; la variable de estado es la SUPRESIÓN, no el dolor

D4 lo obliga: a un valor derivado no se le puede restar de forma persistente sin **almacenar la resta**. Y esa resta ya tiene nombre en el referente — ACE3 lleva **dos** variables (`pain` y `painSuppress`, percibido = `clamp(pain − suppress)`), que es la recomendación de la D10 de `dev/Coagulant_ACE_Referencia.md`.

```lua
COAGULANT.GetRawPain(ply)   -- derivado de las heridas, sin supresión
COAGULANT.GetPain(ply)      -- PERCIBIDO = clamp(raw − st.painSuppress, 0, PAIN_MAX)
COAGULANT.AddPainSuppression(ply, puntos)   -- suma, clamp a PAIN_SUPPRESS_MAX
```

**`AddPainSuppression` es lo que reemplaza a `CoaAddDrug("morphine", 10)`, que no existe** — y el `10` de esa llamada eran **miligramos**, no puntos de dolor. Los miligramos se quedan donde eran ciertos: en el nombre del ítem (*«Morphine 10 mg»*), que es flavor y no estado.

Un solo término más en el **tick de 1 s que ya existe** (§4): `suppress -= PAIN_SUPPRESS_DECAY_PER_S`. El decaimiento es lo que explica *«se pasó el efecto»*, que una resta no explica.

**Los cinco consumidores leen el PERCIBIDO**, no el crudo — igual que el `dolorPercibido` que gobierna el HR en el controlador de ACE (§8.2 del referente). Con eso la morfina te mantiene consciente y te baja el pulso, sin cerrar una sola herida.

**Y de ahí sale el efecto de segundo orden más valioso del tramo: bajo niebla, la morfina te CIEGA EL DIAGNÓSTICO.** COA-44 define el síntoma como lo que el cuerpo *hace* y el paciente *sufre* — o sea el percibido —, así que la silueta bajo niebla pinta percibido. Suprimir el dolor **apaga el único canal gratis** que la niebla deja abierto: la morfina deja de ser un buff y pasa a ser un **costo de información**. Es lo que le da razón de existir a la **naloxona** que COA-50 ya listó en el catálogo, y es la traducción exacta de *«los supresores lo enmascaran sin curar la causa»* del referente.

**La puerta de la morfina se auto-limita, y eso resuelve el apilamiento sin una regla nueva.** Como `can()` lee el percibido, cada dosis acerca el percibido a 0 y la siguiente dosis se **desgatilla sola** en cuanto baja de 10. La sobredosis como mecánica (ventana de OD, naloxona como antídoto real) queda **diferida y nombrada**: es del tramo del catálogo, no de éste.

**Nota de nombres, para que el prototipo no gobierne el contrato:** la superficie de este módulo es `COAGULANT.GetX(ply)` (§8), no metamétodos de jugador. El `ply:CoaPain()` del `.dc.html` es azúcar del demostrador; si el registro de acciones lo quiere, es una envoltura fina que decide **ese** tramo. No se acuña acá.

#### D6 — Isquemia y fractura **sí**; el torniquete **no** — y por eso no hay doble cobro

Los dos entran con la **misma forma** que las cláusulas `max()` que la `ZoneScore` del spec ya usa, así que no se inventa un mecanismo:

```
si z.isch            →  zonePain = max(zonePain, PAIN_ISCHEMIA = 60)   -- espejo de max(score, 6)
si z.frac == "fx"    →  zonePain = max(zonePain, PAIN_FRAC     = 30)   -- espejo de max(score, 3)
si z.frac == "splint"→  zonePain = max(zonePain, PAIN_SPLINT    = 12)
```

- **El torniquete no genera dolor.** En ACE3 duele a los **120 s**; acá a los **90 s ya se convierte en isquemia** (`TOURNIQUET_ISCHEMIA_S`), que es el mismo reloj con otro nombre. El dolor se cuelga de la **isquemia**: **un reloj, no dos**. Y lo interesante nunca fue la banda apretada, fue el miembro muriéndose — que es además lo que COA-44 dice que se ve **sin instrumento**.
- **El torniquete conserva su −12 plano** en `StaminaCap`: es la oclusión **mecánica** de un miembro que dejó de funcionar, no dolor.
- **La fractura pierde los planos −15 / −6** el día que la fórmula exista: paga por **un solo canal**, el del dolor. Sin esto, una fractura cobraría −15 plano **y** otra vez `−0.35 × 30 = −10.5` en la misma fórmula.
- El término de `frac` se escribe ahora y **lee 0 hasta que la fractura exista** (§1 la sigue difiriendo), igual que el `i` de D4. Costo cero, compatible hacia adelante.
- **El par torniquete/isquemia queda separado por 90 s**, así que el jugador puede distinguir los dos cobros en vez de sentir uno arbitrario.

**Costo de migración de todo D6: cero, y está medido.** `StaminaCap`, `frac` y `splint` tienen **0 hits** en el `lua/` — los −12/−15/−6 viven **sólo en la fórmula del spec v5**, que no está implementada. Elegir hoy no toca un número vivo; elegir después sí.

#### Las cinco colisiones, contestadas

**1 · Los coeficientes 0.22 y 0.35 están calibrados contra un escalar `0..100`.** El clamp de D1 mantiene el rango ⇒ **no se retunea ninguna de las cuatro fórmulas**. La cuenta de la alternativa (`+154` bpm, `−245` de techo con suma cruda) queda escrita arriba como el motivo del clamp, no como una nota al pie.

**2 · COA-41 prometió que ningún número de balance se mueve, y esa promesa no cubría al dolor.** No se rompe, y hay que decir **por qué**, porque leído al revés parece que sí: la promesa de COA-41 era sobre la sustitución de `blood` por perfusión con `sat` sano = 100, y **el dolor no existía**. Que el dolor tampoco mueva nada es una **decisión de diseño aparte** —elegir una agregación que preserva el rango—, **no un corolario de COA-41**. Si algún día se vota suma cruda, el retuneo de 0.22, 0.35, `> 80` y `> 85` vuelve, y volvería por esta decisión y no por aquélla.

**3 · El torniquete y la fractura ya están cobrados en `StaminaCap`.** Resuelto por D6: torniquete sólo plano, fractura sólo dolor, isquemia dolor. Nada queda cobrado dos veces, y el doble cobro **no se acepta por escrito** porque no hace falta aceptarlo.

**4 · `ZONE_FULL_AT = 6` normaliza el score y el dolor no tenía equivalente.** Resuelto por D2: `PAIN_FULL_AT = 60` y `PainFrac` espejo de `ZoneDamageFrac`.
**Consecuencia que engancha con el voto V3 del menú v5, y hay que escribirla o las dos rampas se comportan distinto con y sin niebla:** el piso de la rampa que V3 propone subir a **2.0 está en unidades de SCORE**, y queda sin sentido cuando el insumo es dolor. El piso tiene que expresarse en el `t` **normalizado**, no en el insumo:

```
t = (insumo > 0) and math.max(T_FLOOR, insumo / FULL_AT_del_insumo) or 0
```

Con `T_FLOOR = 2/6 = 0.333` la regla es la misma que V3 quiere —*ileso contra herido es categórico*— y vale igual para score y para dolor. Cada insumo normaliza contra **su** `FULL_AT`; el piso es uno solo.

**5 · El snapshot omite hoy las zonas sanas, y una zona puede doler sin herida activa.** La condición del emisor (`bleeding.lua:20`) pasa de *«tiene heridas, torniquete o isquemia»* a *«aporta dolor ≠ 0, torniquete o isquemia»*. Un predicado.
**Corrección de alcance, medida sobre el código de hoy:** una herida `treated` **sigue en `zdata.wounds`** hasta que el Medkit la borra (`core.lua:185-192`) y su `tr` viaja en el snapshot, así que **hoy la zona tratada SÍ viaja**. La colisión es real y grave, pero **muerde recién con la forma `w[tipo] = {a,t,i,s}` de COA-49** —donde la condición natural se vuelve `a > 0`— y con una zona cuyo único contenido sea `frac`. Se anota así para que nadie la busque hoy y concluya que no existe.

#### La sexta colisión, que no estaba en la lista: **un vital que la niebla puede ocultar no puede viajar por NW2**

Bajo niebla la lista de heridas **no puede viajar** (COA-44: lo no conocido no viaja), así que el dolor por zona tiene que llegar como **número**. Si además el cliente lo derivara cuando la niebla está apagada, habría **dos implementaciones de la misma magnitud** — lo que la ley del spec prohíbe (*«una sola fuente por magnitud»*), y con el agravante de que las dos ramas divergirían justo al cambiar la convar.

**Resolución: el server manda `p` por zona SIEMPRE, y el cliente nunca lo deriva.** Un número por zona en el snapshot, con o sin niebla; la niebla pasa a ser una **resta** al snapshot en vez de un cálculo distinto. Y el percibido global viaja igual, en el mismo snapshot.

De ahí sale la regla dura, que es lo que la vuelve norma y no detalle de implementación: **un NW2 se replica a TODOS los clientes y no tiene filtro por observador**, así que cualquier vital que la niebla pueda ocultar **no puede viajar por NW2** — tiene que ir en el snapshot, que es owner-only. Por eso el dolor **no** gana un `NW2Float` a pesar de que la sangre tenga uno.

> **Deuda declarada que esto destapa y que esta sesión NO arregla.** `NW2Float "coagulant_blood"` (§9) ya viaja a todos los clientes, y la **cifra** de sangre es capa de **diagnóstico** en la tabla de COA-44. O sea que la niebla, tal como está escrita, tiene un agujero **anterior** al dolor: un cliente cualquiera puede leer el volumen de sangre de cualquier jugador. No se toca acá porque la niebla no baja en este tramo y porque mover ese NW2 rompe la barra del StatusPanel de Cargo (§10) y la mini-barra del modo degradado. Se escribe para que el día que la niebla baje, esto sea un ítem de su planilla y no un hallazgo.

#### La tabla de balance — ESCRITA en `config.lua` desde el 2026-08-25

Se copió **tal cual, con sus comentarios**, al bloque *Dolor (§17, COA-52)* de `shared/corpus_coagulant_config.lua` — entre `WOUND_TYPES` y el bloque de tratamiento, para que `PAIN_SUPPRESS` exista antes que `TREATMENTS`. Todo número de acá es balance (**COA-27**): se tunea editando esa tabla y **un check lo DERIVA, jamás lo hardcodea** (**COA-35**). Se conserva escrita acá porque ésta es la sede del razonamiento: el archivo dice *qué* vale, esta sección dice *por qué*.

> ⚠ **Y de la bajada salió una consecuencia de método sobre COA-35 que vale para todo este repo: un check que DERIVA su esperado de la constante no puede auditar esa constante.** `ZonePain(tratada) == base × PAIN_TREATED_MULT` sigue **verde** con el mult puesto en `1.0`, y el decaimiento medido como `inicial − N × DECAY` sigue **verde** con la tasa en `0` — el número se vuelve incomprobable justo por la disciplina que lo hace tuneable. Lo que los caza son las filas que miden la **propiedad**: *vendar ALIVIA* y *el efecto SE PASA*. Las dos están en el harness y las dos se vieron fallar (sabotajes #3 y #13 de `dev/sabotaje_coagulant_dolor.py`). La regla que queda: **por cada constante de balance, una fila derivada (qué vale) y una fila de propiedad (para qué está).**

```lua
-- ============================================================
-- Dolor (§17, COA-52) — PROPUESTA de la sesión de diseño 2026-08-17
-- ============================================================
Config.PAIN_MAX      = 100    -- misma escala que blood: la zona Y el global
Config.PAIN_FULL_AT  = 60     -- satura la RAMPA de la silueta, no el estado (espejo
                              -- de ZONE_FULL_AT = 6, que satura en dos heridas graves)

-- Producción (D3). PAIN_TYPE son los valores de ACE3 LITERALES —referente citado,
-- no fuente adoptada (§1.4)—: Avulsion 1.0, VelocityWound 0.9, ThermalBurn 0.7,
-- PunctureWound 0.4, Contusion 0.3, Laceration 0.2. El eje de SEVERIDAD es NUESTRO:
-- la tabla de ACE no tiene ninguno, así que no se podía copiar.
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
Config.PAIN_TREATED_MULT  = 0.35
Config.PAIN_INFECTED_MULT = 1.00

-- Pisos por condición de zona (D6): espejo de las cláusulas max() de ZoneScore.
-- El TORNIQUETE no está acá a propósito: su reloj de 90 s ya es la isquemia.
Config.PAIN_ISCHEMIA = 60     -- espejo de max(score, ISCHEMIA_SCORE = 6)
Config.PAIN_FRAC     = 30     -- espejo de max(score, 3) — lee 0 hasta que frac exista
Config.PAIN_SPLINT   = 12

-- Agregación (D1): neutro en las siete, igual que ZONE_BLEED_MULT
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
```

Funciones puras que el tramo tiene que crear, con la misma disciplina que §4-§6 (una fórmula = una función pura compartida por los dos realms):

```lua
Config.PainFromWound(tipo, sev)     -- PAIN_PER_WOUND × PAIN_TYPE × PAIN_SEVERITY
Config.PainFrac(pain)               -- 0..1 para la rampa (espejo de ZoneDamageFrac)
COAGULANT.ZonePain(ply, zone)       -- 0..100, derivado; con los pisos de D6 aplicados
COAGULANT.GetRawPain(ply)           -- agregado sin supresión (capa de diagnóstico)
COAGULANT.GetPain(ply)              -- PERCIBIDO — lo que leen los cinco consumidores
COAGULANT.AddPainSuppression(ply, puntos)
```

#### Lo que este tramo NO decide, nombrado para que no se dé por decidido

- **La sobredosis** y la naloxona como antídoto real: es del tramo del catálogo. La puerta `pain > 10` ya impide el apilamiento trivial.
- **La fractura con férula** sigue diferida por §1. Lo único que entra hoy es su **término de dolor**, que lee 0.
- **Un `coagulant_pain_scale`** por simetría con `bleed_scale`/`regen_scale`: no se acuña. Nadie lo pidió y una convar de más es una pregunta de más; el tuning ya lo permite la tabla (COA-27).
- **Qué revela la capa de instrumento** sobre el dolor crudo (que `GetRawPain` existe no dice quién puede leerlo): es de COA-44 cuando baje.

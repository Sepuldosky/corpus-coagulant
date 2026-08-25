# Coagulant — CHANGELOG de parches (repo: corpus-coagulant/)

> Registro de parches al código y a la documentación, por sesión de trabajo.
> **Disciplina (heredada de Kontrol vía ADS 2.0 y Corpus):**
> - Un parche nace `[PENDIENTE]` y pasa a `[APLICADO YYYY-MM-DD]` cuando se aplica y
>   verifica. Para código de addon GMod, "verificado" = confirmado en juego (ver
>   [`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt)).
> - **Nunca** se borra una entrada. **Nunca** se renumera un parche existente.
> - Cada sesión abre su **propia subsección**, con numeración independiente.
> - Estado vivo del proyecto → [`coagulant_estado.md`](coagulant_estado.md). Lo
>   `[PENDIENTE]` acá debe coincidir con lo pendiente allá.
> - Este CHANGELOG es de **este repo** (`corpus-coagulant/`). El framework tiene el
>   suyo en `corpus/docs/CHANGELOG.md`.

---

## PARCHES DE sesión Scaffold pre-Block 3 — 2026-07-13

Primera vez que este repo recibe contenido real. **No es el Block 3:** el diseño de
dominio (heridas, sangrado, vitales, tratamiento) sigue pendiente de su sesión de
diseño y aterrizará como `Coagulant_Architecture.md`. Esta sesión solo baja la
ESTRUCTURA del módulo sobre las 6 primitivas de Corpus (boot template de Caliber,
namespace, degradación de soft-deps, contrato mínimo congelado — patrón mock-first,
flujo §3), sin efecto de gameplay. Los parches de código nacen `[PENDIENTE]` hasta la
verificación en juego del autor (flujo §1 PASO 4). Verificación estática previa:
sintaxis Lua validada offline.

- PARCHE 1 — Bootstrap de docs: `CLAUDE.md` + `docs/{coagulant_estado.md,
  coagulant_roadmap.txt, CHANGELOG.md, coagulant_convenciones_commits.txt}` + refresh
  del `README.md`. Mismo template que caliber/cargo, apuntando al
  `corpus_flujo_trabajo.txt` compartido en vez de duplicarlo. `Coagulant_Architecture.md`
  NO se crea acá: llega con el Block 3 de diseño. **[APLICADO 2026-07-13]**

- PARCHE 2 — feat(init): manifest de carga `lua/autorun/corpus_coagulant_init.lua` —
  registro (`Corpus.RegisterModule("coagulant", {})`), bloque CONTRATO (`ApplyBandage`
  + `Zones.*` como única superficie pública), `include()` determinista, boot diferido a
  `Initialize` con sonda `CorpusListo()` (patrón template de Caliber), falla ruidoso
  sin framework. **[APLICADO 2026-07-13]** (verificado en juego por el autor)

- PARCHE 3 — feat(zones): `shared/corpus_coagulant_zones.lua` — 6 zonas clínicas
  estilo ACE3 (IDs ya contrato: `head/torso/left_arm/right_arm/left_leg/right_leg`) +
  mapa hitgroup nativo → zona con fallback a torso. Puro, sin hooks. Es la vía de
  degradación sin Caliber (§2 de la arquitectura de Corpus); nunca se borra.
  **[APLICADO 2026-07-13]** (verificado en juego por el autor)

- PARCHE 4 — feat(core): `server/corpus_coagulant_core.lua` — estado clínico por
  SteamID64 en memoria (forma sustrato `zones[zona]={wounds,bleeding}`), reset en
  `PlayerSpawn`, limpieza en `PlayerDisconnected`, hook `ScalePlayerDamage` que SOLO
  observa (registra `lastHit`, no toca daño) con rama mock-first para el hit-location
  de Caliber, y stub `ApplyBandage(ply)` (firma congelada del `onUse` de §5; loguea,
  limpia placeholder, devuelve `true`). Sin persistencia ni net a propósito.
  **[APLICADO 2026-07-13]** (verificado en juego por el autor; superado el mismo día
  por el slice 1, que lo reescribe)

- PARCHE 5 — feat(items): `server/corpus_coagulant_items.lua` — ítem semilla
  `corpus_coagulant_bandage` (Bandage, 0.1, stackable, categoría `medical`) registrado
  contra Cargo en `Corpus.OnReady` con lazy-check y apagado honesto si Cargo no está;
  `onUse` delega en `COAGULANT.ApplyBandage`. Concommand de debug `coagulant_bandage`
  (admin) como vía mínima sin inventario. **[APLICADO 2026-07-13]** — la primera
  ronda de verificación **falló en este punto** (punto E: def registrada solo en
  server, y el grid cliente de Cargo renderiza desde defs locales → ítem invisible).
  Tras el fix de la sesión "Fix punto E", el re-test del autor pasó (ronda 2, 14/14).

- PARCHE 6 — feat(options): `client/corpus_coagulant_options.lua` — tab único
  `Corpus.UI.RegisterTab("coagulant", "Coagulant", …)` (Q → Utilities → Corpus →
  Coagulant): estado del scaffold + detección de soft-deps en vivo. Strings de cara
  al jugador en inglés. **[APLICADO 2026-07-13]** (verificado en juego por el autor)

- PARCHE 7 — test(dev): `shared/corpus_coagulant_dev.lua` — `coagulant_selftest`
  (admin-gated): invariante by-ref del registro, consistencia de zonas y mapa total
  de hitgroups, contrato público en server, round-trip de estado si hay jugador,
  check de la venda registrada si Cargo está presente, reporte de soft-deps.
  **[APLICADO 2026-07-13]** (verificado en juego por el autor)

- PARCHE 8 — docs(docs): `Coagulant_Block3_Semilla.md` — semilla del Block 3 de
  diseño: marco fijo (contratos ya congelados), referente ACE3 adaptado a sandbox,
  decisiones abiertas A-F (vitales, incapacitación, heridas/sangrado, efectos por
  zona, tratamiento, presentación/config) y no-scope. Registra además la decisión
  del autor (2026-07-13): **el diseño de mods se hace en el repo con Claude Code**,
  no en Desktop (eso queda para Kontrol) — estado/roadmap/CLAUDE.md ajustados.
  **[APLICADO 2026-07-13]**

- PARCHE 9 — docs(docs): primera pasada de diseño del Block 3 cerrada con el autor
  (tres rondas de preguntas, mismo día): sangre propia en paralelo con drenaje de HP
  bajo umbral crítico (muerte siempre por HP 0, sin revive en v1), heridas por damage
  type en lista por zona, tres debuffs zonales (cojera/precisión/visión), set de 4
  ítems contra Cargo con tiempo de aplicación + barra, solo auto-tratamiento, HUD
  silueta + StatusPanel de Cargo, menú médico propio por zona, regen lenta natural,
  spawn = cuerpo nuevo sin disco. Resoluciones anotadas en
  `Coagulant_Block3_Semilla.md` §3; quedan PENDIENTE de arquitectura: tabla damage
  type → herida, curvas/números, vía sin Cargo, convars. **[APLICADO 2026-07-13]**

- PARCHE 10 — docs(docs): `Coagulant_Architecture.md` — baja las resoluciones de la
  semilla a spec autocontenida (16 secciones): tabla damage type → herida ×
  severidad, curvas de sangrado/regen/HP crítico, debuffs (cojera composable con el
  movecompat de Cargo vía Move hook + NW2, nunca SetWalkSpeed; sway por ViewPunch
  agnóstico; visión por overlay), 4 ítems con consumo AL COMPLETAR (onUse devuelve
  false y Coagulant hace TakeItem al terminar — clave del contrato con Cargo),
  eventos `Coagulant_*`, net (2 NW2 + 3 mensajes), UI, convars, mapa de archivos
  objetivo (7 nuevos), degradación, 4 vertical slices. Superficies de Cargo
  verificadas contra su código real (`OnEncumbrance` ya llamado por
  corpus_cargo_movement.lua — v1 lo acepta como stub, stamina diferida;
  `StatusPanel.RegisterBar` con su firma real). **Borrador: los números de balance
  quedan sujetos a ratificación del autor.** Estado/roadmap/CLAUDE.md apuntados al
  doc. **[APLICADO 2026-07-13]**

---

## PARCHES DE sesión Block 3 — slice 1: sangre + heridas + sangrado — 2026-07-13

El autor ratificó la arquitectura ordenando la bajada a código (los números de
balance siguen tunables en juego). Primer slice de los 4 de
`Coagulant_Architecture.md` §15. Verificación previa: sintaxis (luaparser) +
harness offline (lupa + framework real: herida por daño final → drenaje por tick →
crítico → drenaje de HP → muerte "You bled out." → venda ×2 sobre grave → regen;
selftest 49 OK). Los parches de código nacen `[PENDIENTE]` hasta la verificación en
juego del autor (checklist entregada como artefacto).

- PARCHE 1 — feat(config): `shared/corpus_coagulant_config.lua` — convars replicadas
  (`coagulant_enabled/bleed_scale/regen_scale/hpdrain_scale/debug`), tablas de
  balance (§2-§5: BLOOD_MAX 100, crítico 40, regen 0.10/s, bleed base por severidad,
  tipos con mult) y funciones puras (`WoundTypeFromDMG` con prioridad de bits,
  `SeverityFromDamage` 15/40, `BleedRate`, `HPDrainRate`). **[APLICADO 2026-07-13]**
  (verificado en juego por el autor — checklist A-D/F OK)

- PARCHE 2 — feat(core): reescritura de `server/corpus_coagulant_core.lua` — estado
  v1 (blood/zones con wounds+tourniquet/treatment/encumbrance), heridas creadas en
  `PostEntityTakeDamage` con el daño FINAL (hitgroup capturado en
  `ScalePlayerDamage`; caída → pierna al azar; guard `_selfDrain` contra el bucle
  del drenaje propio), tope de 5 heridas por zona (la 6.ª agrava la más leve),
  eventos `Coagulant_WoundAdded/WoundClosed`, contrato de lectura
  (`GetBlood`/`IsBleeding`/`GetZoneScore`), `OnEncumbrance` (stub del contrato de
  Cargo) y el efecto venda real (`BandageEffect`: cierra leve/media, grave 3→2;
  `ApplyBandage` con zona automática — instantáneo hasta el slice 2).
  **[APLICADO 2026-07-13]** (verificado en juego por el autor)

- PARCHE 3 — feat(bleeding): `server/corpus_coagulant_bleeding.lua` — timer único de
  1 s: drenaje total (zonas sin torniquete, × convar), regen natural, cruce del
  umbral crítico (`Coagulant_BloodCritical`), drenaje de HP en crítico vía
  `DMG_GENERIC` del mundo (muerte por HP 0 + "You bled out." en chat), NW2Float
  `coagulant_blood`, y snapshot comprimido on-change al dueño
  (`corpus_coagulant_state`). **[APLICADO 2026-07-13]** (verificado en juego por el autor)

- PARCHE 4 — test(dev): selftest crece a la matemática pura del slice (mapa DMG con
  prioridad, severidades, curvas, venda ×2 sobre grave, score con tratadas a la
  mitad) + comandos de verificación en juego `coagulant_status` (sangre/HP/heridas
  por zona) y `coagulant_setblood <n>` (probar el crítico sin desangrarse), ambos
  admin. **[APLICADO 2026-07-13]** (verificado en juego por el autor)

- PARCHE 5 — chore(init): manifest suma `config` y `bleeding` en orden (config antes
  que core: core usa las tablas en file-scope), sonda `CorpusListo` suma
  `Corpus.Net`, bloque CONTRATO actualizado a §8 (lectura + eventos + encumbrance).
  **[APLICADO 2026-07-13]** (verificado en juego por el autor)

---

## PARCHES DE sesión Fix punto E — defs de ítems en ambos realms — 2026-07-13

Resultado de la verificación en juego (checklist como artefacto): **todo OK salvo el
punto E** — la venda dada por `GiveItem` no aparecía/funcionaba en la UI de Cargo.
Causa raíz: `corpus_coagulant_items.lua` era un archivo SERVER-only, y **Cargo no
sincroniza defs por net** — su grid cliente renderiza desde `Items.Get` local (por
eso su propio dev kit registra en shared, "both realms"). La def existía en server
(GiveItem funcionaba) pero el cliente no la conocía. El fix es de Coagulant; Cargo
queda intacto.

- PARCHE 1 — fix(items): mueve `corpus_coagulant_items.lua` de `server/` a
  `shared/` (git mv + manifest): el registro contra Cargo corre ahora en ambos
  realms vía `Corpus.OnReady` (una vez por realm); el concommand de debug
  `coagulant_bandage` queda gated `if SERVER`. Header del archivo documenta la
  trampa. Harness offline gana una **pasada de realm CLIENT con Cargo fake** que
  asserta la def registrada en cliente — regresión directa del punto E (server 49
  OK + client 34 OK). **[APLICADO 2026-07-13]** (re-test en juego del autor: ronda 2
  de la checklist, 14/14 ✓ — la def registra en ambos realms y la venda funciona
  desde la UI de Cargo)

---

## PARCHES DE sesión Block 3 — slice 2: tratamiento con tiempo + 4 ítems — 2026-07-13

Segundo slice de `Coagulant_Architecture.md` §15, tras el 14/14 de la ronda 2.
Verificación previa: sintaxis + harness offline en tres pasadas (server degradado:
tiempo/cooldown/cancelaciones por daño-movimiento-salto/torniquete+isquemia; server
con Cargo fake: onUse→false y TakeItem al completar, torniquete nunca consumido;
client: 4 defs en realm cliente) — selftest 63/67/43 OK. Los parches nacen
`[PENDIENTE]` hasta la verificación en juego (artefacto, ronda 3, sección G).

- PARCHE 1 — feat(config): tabla `TREATMENTS` (venda 4s, torniquete 2s, medkit 10s
  +50 HP, bolsa 8s +40 sangre), `ARM_TIME_MULT` 1.25, isquemia (90 s puesto / 60 s
  de resaca / score 6), cooldown degradado 30 s, `EXTREMITIES`, umbral de velocidad
  de cancelación. **[APLICADO 2026-07-13]** (ronda 3 ✓ — tiempos, cancelación y
  consumo ejercitados en G2-G3/G5; los números de isquemia los cubre el re-test G4)

- PARCHE 2 — feat(treatment): `server/corpus_coagulant_treatment.lua` — motor
  server-authoritative (§7/§9): `ApplyTreatment(ply, kind, zone)` con zona
  automática por tipo y validaciones (ocupado, zona/extremidad, HP/sangre llenos,
  ítem presente con Cargo, cooldown sin Cargo), tick fino de 0.25 s (completar a
  término + cancelar por velocidad), cancelación por daño real (el drenaje propio
  NO cancela) y por salto, **consumo AL COMPLETAR** (`TakeItem` re-validado; el
  torniquete nunca se consume), torniquete toggle poner/quitar con isquemia
  persistente, eventos `Coagulant_TreatmentStart/Complete/Cancel`, intents de net
  `treat`/`cancel` (server re-valida todo), y `ApplyBandage` = azúcar del contrato.
  **[APLICADO 2026-07-13]** — ronda 3: G2/G3/G5 ✓ (venda con tiempo,
  cancelaciones, medkit/bolsa) pero **G4 ✗**: la validación de ítem usaba
  `CountItem` de Cargo, que es ciego a los `unique` → el torniquete nunca
  arrancaba. Corregido en la sesión "Fix G4" (abajo) y **re-confirmado en la
  ronda 4** (el torniquete arranca y se pone desde la UI).

- PARCHE 3 — feat(items): set v1 completo contra Cargo — Bandage (stackable 0.1),
  Tourniquet (unique 0.2, no consumible), Medkit (stackable 0.5), Blood Bag
  (stackable 0.3), categoría `medical`, trivia de cara al jugador en inglés;
  `onUse` fabricado que devuelve **false** e inicia el tratamiento (aviso por chat
  si no puede). El debug `coagulant_bandage` queda como efecto instantáneo
  explícitamente rotulado. **[APLICADO 2026-07-13]** (ronda 3 ✓ — G1: 4 defs en
  ambos realms y kit visible; venda/medkit/bolsa usados desde la UI; el `onUse`
  del torniquete también corrió — el fallo G4 está aguas abajo, en la validación
  del motor)

- PARCHE 4 — feat(core): `WorstBleedingZone` (zona automática), isquemia impone
  piso de score en `GetZoneScore` (§7), `freeCooldownAt` en el estado; el efecto
  puro `BandageEffect` queda como primitiva del motor. **[APLICADO 2026-07-13]**
  — `WorstBleedingZone` ✓ implícito en G2 (zona automática de la venda) y en el
  G4 de la ronda 4 (el torniquete eligió zona solo). El **piso de score por
  isquemia** (>90 s puesto → 6) queda cubierto **solo offline**: en la ronda 4 el
  autor puso el torniquete sobre una zona sin herida grave, así que vio score
  pero no el ciclo largo de isquemia. Deuda de verificación, no de código —
  anotada en `coagulant_estado.md`.

- PARCHE 5 — test(dev): selftest cubre `TREATMENTS`/`EXTREMITIES`, arranque con
  +25% por brazo herido, doble-tratamiento rechazado, cancelación, torniquete
  rechazando zonas no-extremidad, y las 4 defs si Cargo está (ambos realms);
  `coagulant_status` muestra el tratamiento en curso. **[APLICADO 2026-07-13]**
  (ronda 3 ✓ — A2: selftest 67 OK con Cargo; el status mostró el tratamiento en
  curso en G2)

- PARCHE 6 — chore(init): manifest suma `treatment` (después de bleeding), bloque
  CONTRATO gana `ApplyTreatment`; log de boot → "Block 3 slice 2". Convenciones de
  commits ganan los alcances `config` y `treatment` (el mapa de archivos creció).
  **[APLICADO 2026-07-13]** (ronda 3 ✓ — A1: log de boot "Block 3 slice 2" en
  ambos realms, sin errores Lua)

- PARCHE 7 — test(dev): `coagulant_dev_give` (admin, requiere Cargo) — entrega el
  kit médico de prueba (3 vendas, 1 torniquete, 2 medkits, 2 bolsas). Nace del
  primer intento de la ronda 3 (2026-07-13): el `lua_run` con los cuatro `GiveItem`
  **se trunca en la consola de GMod** (límite de largo del comando) y tira
  `')' expected near '<eof>'` — lección: los comandos de checklist deben ser
  concommands cortos, nunca lua_run largos. **[APLICADO 2026-07-13]** (ronda 3 ✓
  — G1: el kit llegó entero con el comando corto)

- PARCHE 8 — fix(items): el `onUse` de las 4 defs se registra en AMBOS realms
  (antes `SERVER and UsarTratamiento(...) or nil` → cliente con `onUse = nil`).
  **Encontrado desde la sesión de Craving** (ronda 2, 2026-07-13) al verificar el
  gate real de la UI de Cargo: `corpus_cargo_ui.lua` exige `isfunction(def.onUse)`
  **client-side** para mostrar la opción "Use" y el submenú de quick bind — con
  `onUse` nil en cliente, los ítems médicos se ven en el grid pero no se pueden
  usar (la ronda 3 de la sección G habría fallado). La closure es realm-safe:
  solo toca `ApplyTreatment` al invocarse, y Cargo la invoca únicamente en
  server (mismo patrón que los consumibles de Craving, su entry 10). Header del
  archivo documenta la trampa completa; sintaxis verificada offline.
  **[APLICADO 2026-07-13]** (ronda 3 ✓ — G2/G5: venda, medkit y bolsa usados
  desde la UI de Cargo, con "Use" visible en cliente)

Nota — ronda 3 interrumpida en G1 por lo anterior (el resto de la sección G quedó
sin correr); A-F re-confirmadas ✓ por el autor en la misma ronda. La ronda 3 se
repite con el comando nuevo (e incluye el PARCHE 8: "Use" y quick bind visibles
sobre los 4 ítems médicos). **Resultado de la repetición (2026-07-13): A-F ✓,
G1-G3/G5 ✓, G4 ✗ (torniquete: "No tourniquet in inventory" con el ítem en el
grid) → sesión "Fix G4" abajo; G6 (degradado, opcional) quedó sin correr.**

---

## PARCHES DE sesión Fix G4 — el torniquete `unique` es invisible para CountItem — 2026-07-13

Resultado de la ronda 3, sección G: **todo ✓ salvo G4**. Nota del autor: herida
en el brazo izquierdo y torniquete entregado por `coagulant_dev_give`, pero el
motor respondía "No tourniquet in inventory". Causa raíz: la validación de
arranque de `ApplyTreatment` preguntaba presencia con
`cargo.Inventory.CountItem`, que cuenta **solo stacks** (`entry.uid == nil` —
su resultado alimenta el drenaje de `TakeItem`, que también es de stacks); los
`unique` se guardan como `{id, uid}` → el torniquete, único `unique` del set,
siempre contaba 0. Bandage/Medkit/Blood Bag son `stackable`: por eso G2 y G5
pasaron. La zona NO era el problema (brazo = extremidad válida). El fix cruza
los dos repos: la pregunta "¿lleva al menos uno?" es del contenedor, así que
**Cargo gana `Inventory.HasItem(ply, id)`** (entry 18 de su CHANGELOG, lectura
pura sobre ambas clases, sin tocar CountItem/TakeItem) y Coagulant la consume.

Verificación previa: sintaxis limpia (luaparser, 4 archivos en ambos repos);
harness offline (lupa + framework real + **Cargo REAL** — items/weight/
instances/inventory, primera vez que el harness carga el inventario real en vez
del fake): 23 checks verdes (CountItem 0 vs HasItem true sobre el unique, guard
de TakeItem intacto, flujo G4 completo — arranque con +25 % por brazo herido,
completa a los 2.5 s, el torniquete no se consume, isquemia impone score 6 al
quitarlo tras 90 s — y la venda sigue consumiéndose al completar) + selftest
68 OK con Cargo / 63 sin Cargo + pasada degradada (gratis + cooldown 30 s).

- PARCHE 1 — fix(treatment): la validación de ítem de `ApplyTreatment` pregunta
  `cargo.Inventory.HasItem(ply, t.item)` en vez de `CountItem(...) < 1`; el
  comentario del bloque documenta la trampa. El consumo al completar sigue en
  `CountItem`/`TakeItem` (ahí solo llegan consumibles stackable; el torniquete
  nunca se consume). **[APLICADO 2026-07-13]** (ronda 4 ✓ — el autor pudo
  ponerse el torniquete desde la UI y vio el score de la zona)

- PARCHE 2 — test(dev): con Cargo montado y en realm server, el selftest exige
  `isfunction(cargo.Inventory.HasItem)` — un Cargo desactualizado reproduce el
  G4 en vez de fallar mudo. El conteo con Cargo pasa de 67 a **68 OK**.
  **[APLICADO 2026-07-13]** (ronda 4 ✓ — A2: selftest verde con Cargo montado)

Nota — ronda 4 (2026-07-13): **20/20 salvo G6** (modo degradado sin Cargo, que
el autor difiere a futuro; queda como la única deuda de verificación del slice,
cubierta offline). El G4 pasó con la observación de que la zona tratada no tenía
herida grave: el **fix** (arrancar y poner el torniquete) está confirmado en
juego; el **ciclo largo de isquemia** (>90 s → score 6, resaca de 60 s) sigue
respaldado solo por el harness.

---

## PARCHES DE sesión Block 3 — slice 3: debuffs zonales — 2026-07-13

Tercer slice de `Coagulant_Architecture.md` §15, tras el 20/20 de la ronda 4. Los
tres debuffs de §6 entran juntos porque comparten el mismo insumo (el score de
zona que ya calcula `GetZoneScore`) y ninguno tiene sentido a medias:

- **Piernas → cojera.** El punto delicado del slice: Cargo re-aplica su
  penalización de peso sobre walk/run **cada tick de movimiento** (su
  `movecompat`, nacido de "better movement v2"). Si Coagulant escribiera
  `SetWalkSpeed`, se pisarían y el último en correr ganaría. En vez de eso publica
  `NW2Float "coagulant_speed_mult"` y escala el **MaxSpeed del move data** en su
  propio hook `Move` — los dos módulos COMPONEN multiplicativamente sobre lo que
  dejó el gamemode. `Move` es predicho, así que el hook es **shared** y las convars
  replicadas: si el cliente escalara distinto al server, el jugador haría
  rubber-band.
- **Brazos → sway.** `ViewPunch` periódico (intervalo aleatorio 1.5-3 s, amplitud
  0.35° × score, dirección aleatoria): agnóstico al arma, funciona con cualquier
  SWEP sin tocar su API. La integración fina con ARC9 sigue diferida (§6).
- **Cabeza → visión.** Enteramente cliente, desde el snapshot que ya existía: sin
  canal de red nuevo (§9 queda intacto). El fade a negro por herida media/grave se
  detecta **comparando snapshots** (herida nueva o agravada), no con un mensaje.

Verificación previa: sintaxis (luaparser, 12 archivos) + harness offline en tres
pasadas (server con **Cargo real**, server degradado, client) — **selftest 86 OK
con Cargo / 81 sin Cargo / 50 client**, más 70 checks de harness: curva y piso de
la cojera, escalado del move data (incluida la composición con una penalización de
peso previa y el piso absoluto), apagado por convar, sway con su intervalo, la
isquemia moviendo la cojera, y en cliente el pipeline entero de la visión
(snapshot → vignette → blackout → desaturación crítica) más la **igualdad de
escalado entre realms** (la predicción). Los parches nacen `[PENDIENTE]` hasta la
verificación en juego (artefacto, ronda 5, sección H).

- PARCHE 1 — feat(config): convars `coagulant_debuff_legs/arms/head` (replicadas
  por necesidad: la cojera se predice) + tablas de §6 (`LIMP_PER_SCORE` 0.12,
  `LIMP_MIN_MULT` 0.45, `LIMP_SPEED_FLOOR` 30, `SWAY_PER_SCORE` 0.35°,
  `SWAY_MIN_S`/`MAX_S` 1.5-3, `VISION_FULL_AT` 6, `BLACKOUT_S` 2) + las cuatro
  funciones puras que server y cliente comparten (`LimpMult`, `SwayAmplitude`,
  `VisionIntensity`, `CriticalIntensity`). **[APLICADO 2026-07-14]** (ronda 6 ✓ —
  sección H completa; las constantes de sway las retunea la sesión de abajo)

- PARCHE 2 — feat(debuffs): `shared/corpus_coagulant_move.lua` — hook `Move` que
  escala `mv:SetMaxSpeed` por el NW2 de cojera. **Nunca `SetWalkSpeed`** (contrato
  #6). Piso absoluto de 30 u/s, pero con `math.min(base, piso)`: jamás SUBE la
  velocidad de un jugador que otro mod dejó frenado a propósito.
  **[APLICADO 2026-07-14]** (ronda 5/6 ✓ — H2: la cojera compone con el peso de
  Cargo sin rubber-band, el punto crítico del slice)

- PARCHE 3 — feat(debuffs): `server/corpus_coagulant_debuffs.lua` — tick propio de
  0.5 s (la isquemia entra y sale SOLA por tiempo: no alcanza con refrescar desde
  los eventos de herida), `GetLegScore`/`GetArmScore`/`RefreshSpeed` (publica el
  NW2 solo cuando el valor cambió — un NW2 se replica a todos los clientes en cada
  escritura) y el sway con su intervalo. La cojera se refresca aunque la convar
  esté apagada: apagarla tiene que devolver el multiplicador a 1, no congelarlo.
  El NW2 se limpia en `PlayerSpawn` sin esperar al tick (medio segundo de cojera
  heredada al reaparecer se siente como un bug). **[APLICADO 2026-07-14]** (ronda
  5/6 ✓ — H1/H8: la cojera muerde y las tres convars apagan. El sway de este parche
  ya no vive acá: la sesión "Fix ronda 5" lo movió al cliente)

- PARCHE 4 — feat(hud): `client/corpus_coagulant_hud.lua` — nace con el receptor
  del snapshot (`COAGULANT.ClientState`, la única fuente de verdad del cliente) y
  la capa de visión: vignette por score de cabeza, fade a negro por herida
  media/grave, y la capa de sangre crítica (desaturación en
  `RenderScreenspaceEffects` + vignette rojo) que **no se apaga por convar** — es
  información vital (§11). Vignette por bandas de rects, sin materiales externos
  (nada que pueda faltar en un cliente ni orientarse al revés). Todo el pintado va
  en `pcall`: GMod desengancha un `HUDPaint` que erra y la capa moriría en silencio
  el resto de la sesión (trampa pagada por Cargo). La silueta, la barra de
  tratamiento y el StatusPanel crecen sobre este archivo en el slice 4.
  **[APLICADO 2026-07-14]** (ronda 5/6 ✓ — H5/H6; el vignette de bandas que nació
  acá lo reemplazó el elíptico de la sesión "Fix ronda 5", confirmado en I4)

- PARCHE 5 — test(dev): el selftest cubre las cuatro curvas de §6 y el round-trip
  de scores (piernas suman ambas zonas, un brazo no mueve el score de piernas, la
  cojera viaja por NW2). Además **corrige un falso negativo que el harness
  destapó**: con Cargo montado el motor exige la venda en el inventario, así que el
  selftest fallaba 2 checks en un jugador sin vendas — en juego pasaba solo porque
  Cargo persiste el inventario entre sesiones. Ahora se auto-abastece y devuelve lo
  que pidió prestado. `coagulant_status` suma una línea de debuffs (score por par de
  zonas + el multiplicador **real** del NW2, no la curva teórica).
  **[APLICADO 2026-07-14]** (ronda 5/6 ✓ — A2 y el status leído en toda la sección H)

- PARCHE 6 — chore(init): manifest suma `move` (shared, tras config), `debuffs`
  (server, tras treatment) y `hud` (client, antes de options); el bloque CONTRATO
  documenta los dos NW2 de §9 y por qué la cojera se aplica en un hook `Move`; log
  de boot → "Block 3 slice 3". Las convenciones de commits ganan los alcances
  `debuffs` y `hud`. **[APLICADO 2026-07-14]** (ronda 5 ✓ — A1/A2 y los tres debuffs
  se vieron en juego)

Resultado de la **ronda 5** (2026-07-14): **H1, H2, H5, H6, H7, H8 ✓** — la cojera
muerde (score 6 → ×0.45), **compone con el peso de Cargo sin rubber-band** (el punto
crítico del slice), el sway y la visión funcionan y las tres convars apagan. **H3 y H4
✗** (ver la sesión de abajo) y el sway/vignette quedaron con pedidos de diseño del
autor. Los parches 1-4 quedaron `[PENDIENTE]` hasta el re-test de la ronda 6, porque el
fix los reescribe en parte.

**Cerrado por la ronda 6** (2026-07-14): el autor re-corrió las secciones A-H enteras y
la I (los 4 fixes) — **todo ✓**, sin una sola marca en contra. Los 5 parches pasan a
`[APLICADO]`. Única observación, sobre el sway: "dale un poco más en ambos casos,
también es medio tosco; pasa muy fuerte al apuntar" → la sesión de tuning de más abajo.

---

## PARCHES DE sesión Fix ronda 5 — secuela permanente, torniquete clavado, sway y vignette — 2026-07-14

La ronda 5 dejó **dos bugs** y **tres decisiones de diseño** (resueltas con el autor
antes de tocar código, como manda el CLAUDE.md — nada de esto se implementó por
iniciativa propia):

**Bugs.**
1. **La cojera no se curaba nunca.** Con las dos piernas vendadas el autor quedaba en
   score 2.0 → ×0.76 **para siempre** ("he esperado varios minutos y aún está el
   debuff"). No era un bug del código: §6 dice que las tratadas cuentan la mitad, y
   **nada en el diseño borraba una herida**. El propio checklist prometía "se recupera
   del todo al cerrarla" — eso estaba mal redactado.
2. **El torniquete era imposible de quitar.** La zona automática solo miraba
   extremidades **sangrantes**; en cuanto vendabas la zona, la búsqueda no encontraba
   nada y el toggle devolvía "Tourniquets only work on limbs". El autor lo reportó como
   "falta manera de sacarse el torniquete". Además `coagulant_status` no imprimía la
   isquemia, así que el ciclo de 90 s era **inobservable** — por eso el H4 no se pudo
   evaluar.

**Decisiones del autor.**
- **Curación de la secuela → el Medkit.** No hay cura pasiva por tiempo.
- **Sway → dos capas** (leve siempre, fuerte al apuntar), continuo y horizontal.
- **Vignette → propio, bien hecho.** Se descartó copiar *Screen Blood Remaster* / el mod
  de CoD: `dev/mods_workshop_mapa.md` los clasifica como **licencia silenciosa =
  all-rights-reserved → COMPAT-RUNTIME, sin permiso de copia**. Reciclarlos habría ido
  contra la política que el propio autor fijó.

Verificación previa: sintaxis (12 archivos) + harness offline en tres pasadas (server
con Cargo real, server degradado, client) — **selftest 102 OK con Cargo / 97 sin Cargo
/ 56 client**, más 94 checks de harness (incluidos: el medkit borrando la secuela por
el motor real, el torniquete quitándose sobre una zona ya vendada, la isquemia viajando
en el snapshot, y que el sway **oscila y no deriva** — se mide el recorrido de la mira
en 200 frames).

- PARCHE 1 — fix(treatment): la zona automática del torniquete gana su segunda rama —
  si no hay extremidad sangrante que atar, elige **la que ya lo tiene puesto**, o sea
  lo QUITA. Sin esto quedaba clavado de por vida. Quitarlo no exige ni consume ítem.
  **[APLICADO 2026-07-14]** (ronda 6 ✓ — I2: el torniquete se saca de una zona ya
  vendada)

- PARCHE 2 — feat(core): `HealTreatedWounds(ply, zone)` y `WorstTreatedZone(ply)` —
  el Medkit cierra las heridas ya **tratadas** de una zona (única cura de la secuela) y
  su zona automática es la que más secuela tiene. Las heridas sin vendar no se tocan.
  `IsIschemic(ply, zone)` sale de `GetZoneScore` a función propia: la consultan el
  score, el snapshot y el status — vive en un solo lugar para que los tres digan lo
  mismo. **[APLICADO 2026-07-14]** (ronda 6 ✓ — I1: el Medkit borra la secuela y la
  cojera se va; la única cura, como decidió el autor)

- PARCHE 3 — feat(hud): **el sway se reescribe como deriva continua en dos capas**
  (temblor con el arma en mano; deriva incapacitante al apuntar, ×4). Pasa de server
  (`ViewPunch` periódico) a **cliente** (`CreateMove`): es la única forma de mover la
  puntería de forma continua sin pelear contra el mouse. Se aplica el **delta** del
  offset, no el absoluto — si no, la mira derivaría sin control en vez de oscilar (el
  harness lo verifica midiendo el recorrido en 200 frames). El score de brazos llega en
  el snapshot **con la isquemia incluida**, así que cliente y server calculan igual.
  **[APLICADO 2026-07-14]** (ronda 6 ✓ — I3: la deriva se siente y las dos capas se
  distinguen; el autor pidió **más amplitud y una curva entre capas** → tuning abajo)

- PARCHE 4 — feat(hud): **el vignette pasa de bandas rectangulares a elipse** — anillos
  concéntricos triangulados (`surface.DrawPoly`), geometría propia cacheada por
  resolución. El marco cuadrado con esquinas duras era lo que se veía raro. El de sangre
  crítica además **late** (`PULSE_HZ`). Cero assets externos: sin dependencia de la
  licencia de nadie. **[APLICADO 2026-07-14]** (ronda 6 ✓ — I4, textual: "funcionó
  bien")

- PARCHE 5 — feat(config): `SWAY_IDLE_MULT`/`SWAY_ADS_MULT`/`SWAY_VERTICAL`,
  `SwayFor` y `SwayOffset` (puras, compartidas por cliente y selftest), `PULSE_HZ`, y
  `healsWounds` en la def del medkit. Se van `SWAY_MIN_S`/`SWAY_MAX_S` (ya no hay
  intervalo: la deriva es continua). **[APLICADO 2026-07-14]** (ronda 6 ✓ — I1/I3;
  los tres números de sway los retunea la sesión de abajo)

- PARCHE 6 — test(dev): `coagulant_status` imprime **el score de cada zona, el reloj
  del torniquete (`Xs/90s`) y la ISQUEMIA con sus segundos restantes** — sin esto el
  ciclo de isquemia es invisible en juego, que es exactamente por qué el H4 no se pudo
  evaluar. También dice dónde iría el próximo Medkit y muestra el sway en sus dos capas.
  El selftest cubre las curvas nuevas, el medkit borrando la secuela, el torniquete
  quitable y que la deriva sea acotada y horizontal. **[APLICADO 2026-07-14]** (ronda 6
  ✓ — I2b: la isquemia por fin se VE, que era lo que había dejado al H4 sin evaluar)

Resultado de la **ronda 6** (2026-07-14): **los 4 fixes ✓**, y con ellos las secciones
A-H re-corridas enteras sin una marca en contra. El slice 3 queda **verificado en
juego**. Sale una sola observación —el sway— que no es un bug sino tuning: abajo.

---

## PARCHES DE sesión Tuning del sway — ronda 6 — 2026-07-14

La ronda 6 pasó los 4 fixes, pero el autor dejó una nota sobre el sway (I3): *"Dale un
poco tanto más de sway en ambos casos, también es medio tosco. Pasa muy fuerte al
apuntar, creo que deberías hacer una curva para pasar de un estado al otro"*. Son dos
cosas distintas: **poco** (amplitud) y **tosco** (el salto entre capas era un escalón —
`SwayFor` elegía multiplicador con un `if apuntando`, así que la amplitud daba un tirón
de 3.5° en UN frame al tocar el clic derecho). La amplitud ya estaba anotada como deuda
tunable en `coagulant_estado.md`; la curva es lo que faltaba.

Verificación previa: sintaxis (luaparser, 3 archivos) + harness de la curva (lupa +
config real): smoothstep con extremos exactos y clamp, rampa monótona idle→ADS, la
transición reparte el escalón en 28 frames (0.47 s) con un salto máximo de 0.19°/frame
—18× menos que el tirón de la ronda 5— y la deriva sigue acotada y horizontal.

- PARCHE 1 — feat(config): sube la amplitud de las dos capas (`SWAY_PER_SCORE`
  0.35 → 0.45, `SWAY_IDLE_MULT` 0.35 → 0.60, `SWAY_ADS_MULT` 4.0 → 4.5) y **`SwayFor`
  deja de recibir un booleano**: toma un factor continuo `ads` 0..1 y las dos capas
  pasan a ser sus extremos, interpolados por `SwayEase` (smoothstep). Sigue aceptando
  `true`/`false` por comodidad del selftest y de `coagulant_status`. Nace
  `SWAY_ADS_RAMP_S` (0.45 s). Con score 2 la amplitud va de 0.25°/2.80° a
  **0.54°/4.05°** (idle/ADS). **[APLICADO 2026-07-20]** (ronda 7 ✓ — K1: la amplitud
  nueva se nota y se sigue pudiendo caminar y disparar; sin pedido de re-tuning)

- PARCHE 2 — feat(hud): el hook `CreateMove` rampa el factor de ADS con
  `math.Approach` en vez de leer el clic derecho como un booleano. Solo se rampa la
  **amplitud**: la fase del bamboleo nunca se corta, así que la mira se abre y se cierra
  en lugar de dar un tirón. El paso se clampea a 0.1 s de frame para que un tirón de FPS
  no teletransporte la rampa, y `CortarSway` la resetea junto con el offset.
  **[APLICADO 2026-07-20]** (ronda 7 ✓ — K2: el paso idle→ADS ya no da tirón; la
  transición se siente gradual en los dos sentidos)

- PARCHE 3 — test(dev): el selftest cubre la curva (extremos exactos, simetría en 0.5,
  clamp), que la rampa crezca monótona de idle a ADS y que su mitad caiga entre las dos
  capas; los checks de amplitud dejan de hardcodear 0.70 y se derivan de
  `SWAY_PER_SCORE` (si no, retunear el número rompía el selftest en vez de validarlo).
  **[APLICADO 2026-07-20]** (ronda 7 ✓ — J1: selftest 145 OK server / 108 client,
  0 fallos)

---

## PARCHES DE sesión Block 3 — slice 4: UI — 2026-07-14

Cuarto y último slice de `Coagulant_Architecture.md` §15, tras la ronda 6. Las tres
piezas de §10 (silueta, menú médico, StatusPanel) más el tab Q con sus convars. **Este
slice cierra el Block 3**: al verificarse, corre la checklist de cierre de §16.

Decisión de diseño del slice, y la única que importa: **el dibujo y el área clickeable
salen de la MISMA tabla** (`Config.SILHOUETTE` + `Config.ZoneAt`). La silueta se pinta
dos veces —chica en el HUD, grande en el menú— y si cada una tuviera su geometría, el
primer retoque las desincronizaría y el jugador terminaría vendando una zona que no
eligió. El selftest lo asserta zona por zona (el centro de cada rect pintado tiene que
resolver a su propia zona).

Verificación previa: sintaxis (luaparser, 13 archivos) + harness offline en los cuatro
cruces realm × Cargo — selftest **145 OK** (server+Cargo) / 140 (server) / **108**
(client+Cargo) / 104 (client), más **69 checks de harness**: el snapshot llegando al
cliente y sus scores coincidiendo con los del server (incluido el piso de isquemia), el
sangrado por zona, la saturación del color, el clic cayendo en la zona correcta en las
6, la barra de tratamiento a 0/50/100 %, el `HUDPaint` completo sin errar, el menú
abriendo y su intent viajando con `{kind, zone}`, y la barra de sangre registrada en el
StatusPanel de Cargo leyendo el NW2. Los parches nacen `[PENDIENTE]` hasta la
verificación en juego (artefacto, ronda 7).

- PARCHE 1 — feat(config): convar de CLIENTE `coagulant_hud` (§11) y las puras que
  comparten el HUD y el menú: `SILHOUETTE` (las 6 zonas en coordenadas normalizadas),
  `ZoneAt` (qué zona hay bajo el clic), `ZoneDamageFrac` (score → color, satura en
  `ZONE_FULL_AT` 6), `TreatmentProgress` (la barra se calcula client-side desde el
  `{endsAt, duration}` del snapshot — §9 no gana un canal de red) y `WoundFromSnap` (el
  snapshot viaja con claves de una letra `{t,s,tr}` y las curvas de balance esperan la
  herida entera: se traduce en UN lugar, no en cada llamador). **[APLICADO 2026-07-20]**
  (ronda 7 ✓ — sus puras se ejercitaron en J2-J5 y J9: silueta, `ZoneAt`, barra de
  tratamiento y convar de HUD)

- PARCHE 2 — feat(hud): la silueta de 6 zonas y la barra de tratamiento. Color por
  score en dos tramos (sano → amarillo → rojo: un lerp directo de verde a rojo se come
  el amarillo), **la zona sangrante LATE** —la única señal que hay que ver sin leer
  nada—, banda azul de torniquete que se pone morada con la isquemia, y **la silueta se
  desvanece sola** cuando el cuerpo está sano y la sangre llena (un corte seco se lee
  como un bug del HUD). Todo el pintado va en `pcall` con aviso una sola vez. La
  superficie `COAGULANT.HUD` (score/sangrado/datos de zona por snapshot) queda expuesta
  para que el menú médico lea **el mismo estado**, nunca uno propio. **[APLICADO
  2026-07-20]** (ronda 7 ✓ — J2: aparece sola al herirse, la zona sangrante late y con
  el cuerpo sano no hay silueta; J3: la barra de tratamiento se llena quieto y correr
  la cancela. La nota del autor en J9 —«no desaparece al curarme»—
  es el diseño vigente, no un bug: el fade exige TAMBIÉN la sangre llena, y la regen es
  lenta (0.10/s); su pedido de toggle queda ANOTADO como decisión de diseño abierta)

- PARCHE 3 — feat(hud): barra de sangre en el **StatusPanel de Cargo** (§10/§12) —
  `RegisterBar("coagulant", {id="blood", getValue=ply→NW2 0..100})`, con lazy-check en
  `Corpus.OnReady`, jamás en file-scope (el orden de mount no está garantizado). **Sin
  Cargo la sangre no desaparece:** el HUD propio pinta una mini-barra bajo la silueta —
  la información vital no puede depender de un soft-dep (§14). **[APLICADO 2026-07-20]**
  (ronda 7 ✓ — J8: barra Blood en el StatusPanel de Cargo, sin duplicado en el HUD;
  L1: sin Cargo la sangre aparece como mini-barra bajo la silueta)

- PARCHE 4 — feat(medmenu): `client/corpus_coagulant_medmenu.lua` (archivo nuevo) —
  comando `coagulant_menu`: silueta clickeable, lista de heridas de la zona (tipo,
  severidad, si está vendada, si sangra), estado de torniquete/isquemia, y los 4 botones
  de tratamiento con **el conteo real del inventario**. Ese conteo cuenta las DOS clases
  de ítem: los `unique` viven como entradas con `uid` y sin `count`, así que un conteo
  que solo mire stacks deja el botón del torniquete en gris con el torniquete en la
  mochila — es el bug **G4 otra vez**, que en el server se pagó el 2026-07-13 y acá
  volvería a morder desde el cliente. El botón sabe además que **quitar** un torniquete
  no cuesta ítem. Todo se pinta leyendo el snapshot en vivo desde los `Paint`, sin
  reconstruir el panel en callbacks (patrón del frame de Cargo). El cliente nunca es
  autoridad: manda el intent y el server re-valida. Suma bind propio
  (`coagulant_key_menu`, default M) que no le roba la tecla al chat ni a otro menú
  abierto. **[APLICADO 2026-07-20]** (ronda 7 ✓ — J4: el clic cae en la zona que se ve;
  J5: el flujo completo sin consola, el criterio de §15; J6: el torniquete `unique`
  contado y quitable gratis — el G4 del cliente NO volvió; J7: torniquete e isquemia
  visibles. La tecla configurable NO respondía: el lector era `PlayerButtonDown`, que
  no dispara client-side en singleplayer → sesión «Fix ronda 7», abajo)

- PARCHE 5 — feat(options): el tab Q deja de ser el cartel del scaffold — convars de
  cliente y de server, binder del menú médico, detección de soft-deps **con lo que
  implica cada ausencia** (sin Cargo: tratamiento degradado; sin Caliber: hit-location
  por hitgroup crudo) y la lista de comandos de verificación. **[APLICADO 2026-07-20]**
  (ronda 7 ✓ — J9: convars, soft-deps y comandos a la vista; la falla del binder que
  reportó el autor era en realidad del LECTOR de la tecla —el binder escribía bien la
  convar—, ver «Fix ronda 7»)

- PARCHE 6 — test(dev): el selftest cubre lo puro del slice — que la silueta cubra las
  6 zonas sin repetirlas ni salirse de su caja, que **el centro de cada rect pintado
  resuelva a su propia zona** (el contrato entre lo que se ve y lo que se clickea), la
  saturación del color, la barra de tratamiento en sus tres puntos y la traducción del
  snapshot; en realm cliente, que la superficie `COAGULANT.HUD` exista completa.
  **[APLICADO 2026-07-20]** (ronda 7 ✓ — J1: 145 OK server / 108 client con Cargo,
  0 fallos en ambos realms)

- PARCHE 7 — chore(init): el manifest suma `medmenu` (client, **después** de `hud`: lee
  su silueta), el header y el log de boot pasan a "Block 3 slice 4". Las convenciones de
  commits ganan el alcance `medmenu`. **[APLICADO 2026-07-20]** (ronda 7 ✓ — J1: log de
  boot «Block 3 slice 4» en ambos realms, sin errores Lua)

---

## PARCHES DE sesión Pasada de veracidad de docs — 2026-07-14

Auditoría de VERACIDAD cruzando cada afirmación de los docs contra el árbol real: los
docs de este repo habían quedado congelados en el momento en que el diseño se ratificó y
los tres primeros slices bajaron a código. La deriva es de dos clases: **estado viejo**
(la arquitectura y el CLAUDE.md seguían llamándose «borrador para ratificación», y el
roadmap tenía como INMEDIATO dos tramos ya cerrados) y **rot de la ronda 5**, cuando el
sway pasó de un `ViewPunch` de server a una deriva continua de cliente (`CreateMove`) y
los docs quedaron describiendo el mecanismo muerto en **cinco** sitios (dos en la
arquitectura, el `CLAUDE.md`, las convenciones de commit y un comentario del manifest).
La segunda pasada (PARCHES 7-8) sumó el quinto sitio y otras cuatro afirmaciones falsas
que la primera no había abierto. La **tercera** (PARCHES 9-12) abrió los dos docs que
ninguna de las dos anteriores había tocado: el `README.md` —el doc **público**, que seguía
entero en la era scaffold («sin gameplay», «ítem semilla», «diseño pendiente»)— y la
semilla del Block 3, que dejaba tres decisiones marcadas «PENDIENTE» estando cerradas y en
juego. La **cuarta** (PARCHES 13-15) cerró el último reducto: los **comentarios del código**,
donde sobrevivían el sexto sitio del rot de la tecla («abre y cierra»), una cita entre
comillas a una versión de §10 que ya no existe y un puntero al contrato #6 del `CLAUDE.md`
que hoy apunta a otra cosa. Sin superficie de runtime: solo docs y comentarios —ni una línea
ejecutable cambió, y el bug de la tecla queda **anotado, no arreglado**, para la ronda 7 del
autor— nacen `[APLICADO]`.

- PARCHE 1 — docs(docs): el encabezado de `Coagulant_Architecture.md` deja de decir
  «borrador para ratificación del autor» — la arquitectura está **ratificada desde el
  2026-07-13** y en bajada a código desde entonces. **No** se incrusta acá el avance por
  slice: el estado vivo es de `coagulant_estado.md` (duplicarlo garantiza que quede viejo
  el día que corra la ronda 7 — el pecado que esta pasada corrige). Mismo fix en el punto
  5 de la jerarquía de lectura del `CLAUDE.md`, que se contradecía con su propia línea 9.
  **[APLICADO 2026-07-14]**

- PARCHE 2 — docs(docs): §10 (pieza 2, menú médico) describe el comportamiento **real**
  de los botones: sin Cargo se rotulan *field* y **no se grisan por cooldown**, porque el
  cooldown del modo degradado **no viaja en el snapshot** (§9) — el rechazo llega por chat
  desde el server, que es la autoridad. Sí se grisan por tratamiento en curso y por
  torniquete en zona que no es extremidad (`ConstruirBoton`). Se documenta la realidad, no
  se cambia el runtime: honrar el diseño exigiría sumar `freeCooldownAt` al payload, y esa
  es una decisión de código que el autor deja para después. De paso, el «bind sugerido en
  el tab Q» pasa a lo implementado: convar de cliente propia (`coagulant_key_menu`, default
  `KEY_M`) con su DBinder en el tab y un `PlayerButtonDown` que abre el menú.
  **[APLICADO 2026-07-14]** — corregido en la segunda pasada (PARCHE 8): la tecla **no**
  cierra, la rama de cierre es inalcanzable.

- PARCHE 3 — docs(docs): la tabla de convars (§11) listaba **8** de las **10** que el
  código registra. Suman `coagulant_debug` (sv) y `coagulant_key_menu` (cl).
  **[APLICADO 2026-07-14]**

- PARCHE 4 — docs(docs): §12 (soft-deps, Cargo) atribuía los conteos del menú médico a
  `Inventory.CountItem` — **imposible**: `CountItem` es server y el menú es cliente. La
  realidad: `HasItem` valida el arranque (la única superficie que ve los `unique`),
  `CountItem` + `TakeItem` corren en server **al completar**, y el conteo de los botones
  sale de **`CARGO.ClientState.items`**, que es superficie **off-contract** de Cargo. Queda
  anotada como deuda asumida: si Cargo cambia la forma de su snapshot, los botones se
  rompen en silencio. **[APLICADO 2026-07-14]**

- PARCHE 5 — docs(docs): se mata el rot del `ViewPunch` en los **cinco** sitios donde
  seguía vivo — §13 (mapa de archivos: el `debuffs` de server ya no «hace sway punch»; el
  `hud` de cliente sí lleva el sway por `CreateMove`), **§15 (el slice 3 seguía
  atribuyendo el sway a los debuffs de server; se contó de más tarde, en la pasada de
  cierre — el «tres» original se quedaba corto)**, la fila de `debuffs` del mapa del
  `CLAUDE.md`, el comentario del manifest en `corpus_coagulant_init.lua`, y **el alcance
  `debuffs` de `coagulant_convenciones_commits.txt` §3** (quinto sitio, encontrado en la
  segunda pasada — PARCHE 7: se contradecía con el alcance `hud` del mismo archivo). La
  arquitectura ya decía en §6 que el sway se aplica en el cliente: el doc se contradecía a
  sí mismo. De paso, la fila de `options` de §13 («bind hint») se alinea con el cierre de
  §10: lo que hay es un **DBinder** de `coagulant_key_menu`. **[APLICADO 2026-07-14]**

- PARCHE 6 — docs(docs): `coagulant_roadmap.txt` se pone al día. §1 INMEDIATO tenía como
  próximos dos tramos ya cerrados (la verificación del scaffold y la ratificación de la
  arquitectura); pasa a la **ronda 7** (el slice 4 + el sway retuneado, con el flip de las
  10 entradas `[PENDIENTE]` del CHANGELOG) y al **checklist de cierre del Block 3**. §2 se
  retitula «después de **cerrar** el Block 3» —ratificar ya no es condición de nada—,
  pierde el ítem de la bajada por slices (los 4 están bajados) y concreta la superficie
  para Craving con la firma que ya se negocia: `ApplyExternalCondition(ply, stat,
  severity)`. **[APLICADO 2026-07-14]**

- PARCHE 7 — docs(docs): **segunda pasada** de la misma auditoría (ronda 3 del ecosistema),
  esta vez sobre los docs que la primera no abrió: convenciones de commit, CLAUDE.md y el
  checklist de cierre. Cuatro mentiras más, todas verificadas contra el código:
  **(a)** el alcance `debuffs` de `coagulant_convenciones_commits.txt` §3 le atribuía el
  sway al server (quinto sitio del rot del `ViewPunch`, y se contradecía con el alcance
  `hud` del mismo archivo) — el sway es de cliente (`CreateMove` en
  `corpus_coagulant_hud.lua`), `debuffs` es scores + cojera por NW2. **(b)** El flujo de
  verificación en juego del `CLAUDE.md` seguía siendo el del scaffold: «usarla loguea el
  stub y consume una unidad» — no existe ningún stub (el `onUse` llama a `ApplyTreatment`
  y arranca 4 s de venda) y la unidad **no** se consume al usar, sino al COMPLETAR
  (contrato #5 del propio archivo, que la frase contradecía). **(c)** La lista de alcances
  del `CLAUDE.md` tenía 6 de los 12 del doc canónico —faltaban `config`, `treatment`,
  `debuffs`, `hud` y `medmenu`— y listaba `chore`, que es un **tipo**, no un alcance.
  **(d)** El ítem 4 del checklist de cierre (§16) mandaba reemplazar un contrato #6 que ya
  no existe («sin gameplay antes del diseño»): el reemplazo ocurrió con la bajada por
  slices. **[APLICADO 2026-07-14]**

- PARCHE 8 — docs(docs): §10 (pieza 2) deja de afirmar que la tecla del menú médico «abre y
  cierra». **La rama de cierre es inalcanzable**: en `corpus_coagulant_medmenu.lua` el guard
  (`gui.IsGameUIVisible() or vgui.CursorVisible()`) corre ANTES del toggle y el frame se abre
  con `MakePopup()` → con el menú abierto el cursor siempre está visible → el `frame:Remove()`
  nunca corre. Hoy la tecla abre y el cierre es la **X del `DFrame`**. El doc pasa a decir eso
  y lo deja anotado como deuda del slice 4 para la **ronda 7**, con el precedente de Cargo
  (`corpus_cargo_ui.lua`: `PlayerButtonDown` **no dispara client-side en singleplayer** —
  quirk del engine—, por eso su bind poletea `input.IsButtonDown` en `Think` con detector de
  flanco y guard `vgui.GetKeyboardFocus() == nil`, que no es `CursorVisible`). **Sin tocar el
  runtime**: el fix del hook lo decide el autor. De paso, «manda el intent y cierra» pasa a la
  verdad — el menú queda abierto mostrando el progreso. **[APLICADO 2026-07-14]**

- PARCHE 9 — docs(docs): **el `README.md`** — el único doc del repo que seguía entero en la era
  scaffold, y el que ve cualquiera que entre por GitHub. Decía «**Estado: scaffold pre-diseño**
  … estado por jugador **sin gameplay**, **ítem semilla** … su bloque de diseño de dominio
  (heridas, sangrado, vitales, tratamiento) **sigue pendiente**»: falso en cada cláusula. El
  Block 3 se ratificó el 2026-07-13 y sus 4 slices están bajados a código (13 archivos `.lua`);
  hay gameplay (sangre 0-100, heridas por damage type con severidad, sangrado con drenaje de HP
  bajo el crítico, tres debuffs zonales) y **cuatro** defs reales contra Cargo, no una semilla
  (venda, torniquete, medkit, bolsa de sangre — categoría `medical`). El bloque de estado pasa a
  la verdad del árbol (Block 3, slice 4 de 4; slices 1-3 verificados en juego, el 4 esperando la
  ronda 7) y suma el link a la arquitectura del módulo, que no aparecía. La sección de deps deja
  de llamarse «previstas» (Corpus está cableado y Cargo consumido de verdad; solo Caliber sigue
  mock-first). **[APLICADO 2026-07-14]**

- PARCHE 10 — docs(docs): la degradación sin Cargo del `README` decía «tratamiento por
  **world-entity** o vía mínima propia» — la arquitectura §7 difiere explícitamente la
  interacción con world-entities (botiquín de pared). Lo que existe es el modo degradado: los
  mismos tratamientos **sin consumir ítems**, con cooldown de 30 s (`Config.DEGRADED_COOLDOWN_S`)
  y los botones rotulados «field». **[APLICADO 2026-07-14]**

- PARCHE 11 — docs(docs): `CLAUDE.md` §«El workspace multi-repo» decía «una de **seis** raíces».
  `corpus.code-workspace` declara **ocho** carpetas = **siete** repos git + `dev/` (que no es
  repo): faltaba entera la séptima raíz, `corpus-stalker`, el addon de **contenido** de la Zona
  — que este mismo repo ya citaba dos veces en `coagulant_estado.md` como si existiera. Se
  corrige la cardinalidad y se anota qué es (consumidor puro; nada de su contenido baja acá:
  Coagulant es genérico y no sabe nada de la Zona). **[APLICADO 2026-07-14]**

- PARCHE 12 — docs(docs): `Coagulant_Block3_Semilla.md` §3 — el preámbulo prometía que «lo que
  sigue abierto está marcado» y dejaba **tres** decisiones «PENDIENTE (arquitectura)» que la
  arquitectura ya resolvió y el código ya implementa. `CLAUDE.md` manda leer la semilla como «el
  registro de decisiones»: un lector se llevaba tres preguntas abiertas que están cerradas **y en
  juego**. Las tres pasan a `→ RESUELTO` con el puntero a dónde viven: **(a)** curva de drenaje y
  números de balance → §3-§4 (`base = {0.15, 0.40, 1.00}` × `mult` de tipo, severidad por daño
  final, `Config.BLEED_BASE`/`BleedRate`), incluida la cola olvidada de esa misma línea (la
  contusión no sangra pero **sí** cuenta para el debuff zonal — se verificó contra
  `GetZoneScore`, que suma toda herida sin mirar el tipo; fractura estructural fuera de v1).
  **(b)** La vía sin Cargo → §7, y la propuesta se validó tal cual (cooldown de 30 s, rótulo
  «field», `coagulant_bandage` como debug). **(c)** Set de convars y qué expone el tab Q → §11:
  las **10** convars (8 sv + 2 cl), todas registradas en el código. El preámbulo del doc suma que
  el volcado a la arquitectura **ya ocurrió** y que la semilla es registro histórico, no lista de
  trabajo. **[APLICADO 2026-07-14]**

- PARCHE 13 — docs(medmenu): **cuarta pasada** (ronda 5 del ecosistema), sobre el último reducto
  que ninguna de las tres anteriores abrió: los **comentarios del código**. El comentario del
  toggle de la tecla (`corpus_coagulant_medmenu.lua`) todavía decía «misma tecla: abre y cierra»
  — el **sexto** sitio del mismo rot que los PARCHES 8 y 5 mataron en los otros cinco (§10 de la
  arquitectura, el flujo de verificación del `CLAUDE.md`, la fila `options` de §13…), y el único
  que quedaba **dentro del árbol de código**. La rama es INALCANZABLE y el propio repo ya lo
  documenta: el guard de la línea de arriba (`gui.IsGameUIVisible() or vgui.CursorVisible()`)
  corre ANTES del toggle y el frame se abre con `MakePopup()` → con el menú abierto el cursor
  siempre está visible → el `frame:Remove()` nunca corre. El comentario pasa a decir la verdad
  (la tecla solo ABRE; el cierre es la X del `DFrame`) y deja la **deuda anotada para la ronda 7**
  con el patrón que sí funciona, ya pago en Cargo (`corpus_cargo_ui.lua`: poleo de
  `input.IsButtonDown` en `Think` con detector de flanco y guard `vgui.GetKeyboardFocus() == nil`,
  que **no** es `CursorVisible`). **Sin tocar el runtime**: la línea ejecutable queda byte a byte
  igual —solo se le saca el comentario de cola— y el fix del hook lo decide el autor.
  **[APLICADO 2026-07-14]**

- PARCHE 14 — docs(medmenu): el comentario de la convar de la tecla entrecomillaba una versión
  muerta del doc — «§10: "bind sugerido en el tab Q"». Esa frase ya **no existe** en §10: el
  PARCHE 2 la reemplazó por lo implementado (convar de cliente `coagulant_key_menu`, default
  `KEY_M`, con su DBinder en el tab Q y un `PlayerButtonDown` que abre el menú), y el PARCHE 5 ya
  había alineado la fila `options` de §13 por el mismo motivo. Citar entre comillas un doc que
  cambió es la peor clase de rot: el lector cree estar leyendo el texto vigente. El comentario
  pasa a describir el mecanismo real. **[APLICADO 2026-07-14]**

- PARCHE 15 — docs(move): `corpus_coagulant_move.lua` mandaba al lector al **contrato #6** del
  `CLAUDE.md` para la regla de no pisar `SetWalkSpeed`/`SetRunSpeed`. Puntero podrido: el
  contrato #6 de hoy es «la silueta se pinta y se clickea desde la MISMA tabla»; la regla que el
  archivo cita es el **#8** («Coagulant nunca re-escala daño ni pisa `SetWalkSpeed`»). Quien
  siguiera el puntero caía en la silueta. Se corrige el número y se completa el enunciado con la
  primera mitad del contrato (el daño es de Caliber), que el comentario recortaba.
  **[APLICADO 2026-07-14]**

---

## PARCHES DE sesión Etiquetado de IDs normativos (deuda D-7) — 2026-07-19

Tanda multi-repo del ecosistema, guiada por `dev/PROMPT_d7_etiquetado_ids.txt` (§8 del flujo).
Solo prosa: **ninguna norma cambió**. Cada sede que el registro
(`../corpus/docs/ids.yaml`) declara ahora lleva su ID visible, para que un lector que
aterriza en el doc vea de qué norma se trata sin abrir el registro, y para que el gate de
coherencia (§7.8) pueda contrastar el título del yaml contra la prosa de su sede.

- PARCHE 1 — **27 de 31 IDs de la familia `COA` etiquetados en su sede.**
  Los 4 restantes NO se etiquetaron a propósito: sus sedes viven en archivos `.lua`,
  en el CHANGELOG, en el estado o en el roadmap. Etiquetar ahí volvería **definitorio** un
  comentario, que es lo que **FLU-26** prohíbe, o tocaría un doc que no se reescribe
  (**FLU-14**). Son deuda **D-3** del registro y se cierran moviendo la sede a un doc —
  decisión de diseño, no mecánica. **[APLICADO 2026-07-19]**

- PARCHE 2 — **Contratos que eran copias, ahora CITAN por ID.** Los contratos 1, 2 y 9 del
  `CLAUDE.md` pasan a citar `COR-2`/`COR-7`, `COR-5` y `COR-6`; la regla cardinal
  cita `COR-10`/`COR-1`; el boot diferido cita `CAL-1` (su sede es Caliber); y la regla
  de defs en ambos realms cita **`COR-12`** en sus dos apariciones, en vez de re-enunciarla.
  Esto último es la reparación de la deuda **D-1**. **[APLICADO 2026-07-19]**

Verificación: `corpus/.claude/check-ids/corpus_check_ids.ps1` en verde (una etiqueta mal
tipeada habría salido como `HUERFANO_DOC`). Sin superficie de runtime: nada que cargar en
un mapa, y **ningún check de planilla nace de esta tanda** (FLU-37).

---

## PARCHES DE sesión Anti-drift: cierre de votos — 2026-07-19

Tanda multi-repo guiada por `dev/PROMPT_cierre_antidrift.txt`: el autor votó las deudas
abiertas del registro y acá se aplica lo que toca a este repo.

- PARCHE 1 — **Voto D-10 aplicado: la prosa sube a la sede.** §7 enuncia la mitad de
  **`COA-20`** que solo el registro afirmaba (quitar el torniquete **no exige ni consume
  ítem** — el toggle opera sobre el ya puesto), y §11 gana **`COA-35`** (un check jamás
  hardcodea un número tunable: se deriva de la config), partido de `COA-27`, que queda solo
  con «los números de balance viven en config». **[APLICADO 2026-07-19]**
- PARCHE 2 — **Curaduría de títulos fusionados:** la cancelación del tratamiento es ahora
  **`COA-34`** (§7, con su evidencia de planilla G3) y la barra de progreso client-side es
  **`COA-33`** (§9, a ratificar en juego en la ronda 7); `COA-16` y `COA-19` quedan con un
  solo enunciado y un solo ancla cada uno. **[APLICADO 2026-07-19]**
- PARCHE 3 — **D-3 recortada: `COA-14` sube a §10.** «Todo el pintado va en `pcall` +
  `Corpus.Log` ruidoso» — la norma real peor ubicada del ecosistema (su sede era un
  comentario de código; la trampa la pagó Cargo) vive ahora en el doc de diseño, y el
  comentario de `corpus_coagulant_hud.lua` pasa de definir a **citar** (FLU-26).
  **[APLICADO 2026-07-19]**

Verificación: `corpus/.claude/check-ids/corpus_check_ids.ps1` en verde sobre 197 IDs. Sin
superficie de runtime (el comentario de hud.lua no cambia lógica), y **ningún check de
planilla nace de esta tanda** (FLU-37).

---

## PARCHES DE sesión Anti-drift: reparación del COMPLETO — 2026-07-19

Aplica los hallazgos del acta `corpus/docs/auditorias/2026-07-19_coherencia_docs.md` que
tocan este repo.

- PARCHE 1 — **2.9:** la semilla anota como **DEROGADA** la identidad
  `onUse == ApplyBandage` (el slice 2 la reemplazó: `onUse` fabricado que devuelve
  SIEMPRE `false`, consumo al COMPLETAR — COA-3; `ApplyBandage` quedó como azúcar del
  contrato). La viñeta convivía con contratos vivos en la lista «Marco fijo» y se leía
  como vigente. **[APLICADO 2026-07-19]**
- PARCHE 2 — **2.12:** el estado y el roadmap dejan de escribir la firma pendiente como
  `ApplyExternalCondition(ply, stat, …)`: el 2.º argumento es el **id de condición
  clínica** `{starvation, dehydration}`, no el stat — implementar switcheando sobre el
  stat pasaría el gate de CAPACIDAD sin aplicar nada, y la inanición quedaría inofensiva
  **en silencio**. **[APLICADO 2026-07-19]**
- PARCHE 3 — **H4 (el hallazgo que el cruce dejó escapar, con árbitro en el Lua):** §6
  deja de atribuirle a Cargo el re-estampado de walk/run por tick — movecompat escala
  `mv:SetMaxSpeed` del move data, y re-estampar walk/run es el antipatrón de terceros
  que CRG-12 existe para evitar. **[APLICADO 2026-07-19]**

Del acta queda **para el autor** (deuda **D-12** del registro): `dev/harness_coagulant.py`
**no existe** como archivo, este CLAUDE.md aún declara el harness «de scratchpad», y hay
acreditaciones `tipo: harness` vivas en entradas COA. NO se tocó a propósito: primero
decidir (materializar el harness vs. re-acreditar la evidencia), después parchear.

Verificación: checker en verde + suite 12/12. Sin superficie de runtime.

---

## PARCHES DE sesión D-12: el harness de Coagulant se materializa — 2026-07-19

Cierra la deuda **D-12** que la tanda anterior dejó anotada arriba, por **voto del autor**
(opción (a): materializar, no re-acreditar). Guiada por `dev/PROMPT_d12_d13_segundo_completo.txt`.

**Lo que la derivación del árbol corrigió antes de votar (FLU-27):** el acta nombraba
`COA-2`, `COA-4`, `COA-5` y `COA-6`. El registro llevaba **dieciséis** entradas `COA` con
`tipo: harness` — el 47 % de la familia — más la de `COR-12`, que se apoyaba a medias en el
mismo archivo ausente. El costo real de re-acreditar era 17 adjudicaciones, no 4.

- PARCHE 1 — **`dev/harness_coagulant.py` existe** (tercero del patrón, detrás de
  `harness_cargo.py` y `harness_craving.py`): LuaJIT vía `lupa` + stubs de GMod, carga el
  framework real de `corpus/` y este módulo en **ambos realms**. Corre **173 checks propios**
  (124 server / 49 client) más el `_SelfTest` del módulo en los dos realms (145 + 108). Los
  checks se **re-derivaron** del CHANGELOG de este repo (rondas 1-6) y del código: ninguno se
  inventó. **[APLICADO 2026-07-19]**

- PARCHE 2 — **La igualdad de escalado entre realms (`COA-5`) se verifica de verdad.** El
  snapshot que produce el realm SERVER se **inyecta** en el CLIENT y ambos derivan el mismo
  score de zona y el mismo multiplicador de cojera. Un harness que fabricara el snapshot en
  el cliente probaría su propia aritmética, no la igualdad. **[APLICADO 2026-07-19]**

- PARCHE 3 — **`CLAUDE.md` §Verificación pasa al régimen permanente.** La línea que declaraba
  el harness «de scratchpad, se reconstruye por sesión» (el mismo régimen viejo que Cargo dejó
  atrás en el hallazgo 2.5) ahora nombra la ruta, el comando y por qué el archivo es
  versionado. **[APLICADO 2026-07-19]**

- PARCHE 4 — **Las 17 acreditaciones pasan a ser citables.** Las 16 refs `COA` con
  `tipo: harness` y la de `COR-12` dejan de describir un check suelto («el piso absoluto»,
  «snapshot llegando al cliente») y nombran la ruta del archivo más el escenario que corre.
  El checker cazó de paso que una ref con **dos** rutas no resuelve a ninguna: la de `COR-12`
  quedó partida en dos entradas, una por harness. **[APLICADO 2026-07-19]**

**Dos escenarios del primer borrador eran IRREALES y se corrigieron contra el código, no al
revés** — es la disciplina de FLU-22 (el código manda) aplicada al propio verificador:
**(a)** sin herida abierta el tick **regenera** antes de calcular el drenaje de HP (§4), así
que «sangre 0 → drenaje máximo» exigía una herida activa; el harness ahora prueba las dos
ramas por separado. **(b)** Comparar el multiplicador de cojera del cliente contra un estado
del server **posterior** al snapshot no probaba igualdad entre realms: probaba que dos
estados distintos dan números distintos. Los tres números del puente se toman ahora del mismo
estado que produjo el snapshot.

Efecto colateral en `corpus-craving/CLAUDE.md:70`: su «mismo patrón que verificó Corpus,
Cargo **y Coagulant**» era falso cuando el acta lo señaló (H3) y **pasó a ser verdadero** sin
tocar una línea de ese repo — el hueco no estaba en la afirmación sino en el árbol.

Verificación: harness en verde (`ALL GREEN`, exit 0) + checker en verde sobre 197 IDs + suite
12/12. Sin superficie de runtime: **ni una línea de Lua cambió** en esta tanda, y **ningún
check de planilla nace de ella** (FLU-37) — un harness es capa offline, no planilla.

---

## PARCHES DE sesión Fix ronda 7 — la tecla del menú y el residuo del selftest — 2026-07-20

La **ronda 7** (2026-07-20) pasó **13/13**: las secciones J y K enteras **y también la L1
opcional** — el modo degradado sin Cargo queda verificado EN JUEGO y la deuda G6 (diferida
dos veces) se salda. **Con J y K en verde, el Block 3 CIERRA**: la checklist de §16 corrió
en esta misma sesión (resumen en `CORPUS_Architecture.md` §9, estados y roadmaps de ambos
repos refrescados). El reporte dejó cuatro notas sobre checks ✓ — dos eran bugs mecánicos
(se fixean acá; nacen `[PENDIENTE]` hasta la **mini-ronda 8**, sección M de la planilla) y
dos son **decisiones de diseño que quedan con el autor** (toggle del paperdoll; que la
tecla del menú también cierre). Las «heridas de bala» que el autor vio en J1 no son un
bug: son las heridas de PRUEBA del round-trip del selftest sobre el primer jugador
conectado — se loguean porque `coagulant_debug` está activo y se limpian al final.

- PARCHE 1 — fix(medmenu): el lector de la tecla pasa de `PlayerButtonDown` a **poleo de
  `input.IsButtonDown` en `Think`** con detector de flanco y guard de foco
  (`vgui.GetKeyboardFocus() == nil`). `PlayerButtonDown` **no dispara client-side en
  singleplayer** (quirk del engine, pagado por Cargo con su tecla I) — por eso «no
  funcionó el cambiar el bind» (nota de J4/J9): el binder del tab escribía bien la
  convar; el que nunca corría era el lector. La tecla sigue SOLO abriendo (el cierre es
  la X del `DFrame`; pasarla a toggle es la decisión de diseño abierta).
  **[APLICADO 2026-07-21]** (mini-ronda 8 ✓ — M1: la tecla del binder abre sin `bind`
  de consola. Nota del autor: elegir la tecla en el binder desplegaba el menú dentro
  del tab Q → sesión «Fix mini-ronda 8», abajo)

- PARCHE 2 — fix(core): `ResetState` despublica también el NW2 de cojera
  (`coagulant_speed_mult` → 1), como ya hacía con el de sangre: el selftest resetea SIN
  pasar por `PlayerSpawn` y dejaba publicado el multiplicador de sus heridas de prueba
  hasta el siguiente tick — el «piernas: score 0.0 → velocidad ×0.64» que el autor pegó
  en J1. Era transitorio (el tick de 0.5 s lo normalizaba solo), pero un reset tiene que
  dejar limpio YA — el mismo criterio que ya rige en el spawn. **[APLICADO 2026-07-21]**
  (mini-ronda 8 ✓ — M2: `coagulant_status` tras el selftest muestra `score 0.0 →
  velocidad ×1.00`)

- PARCHE 3 — test(dev): el selftest verifica que su propio reset final despublique la
  cojera. El conteo server pasa de 145 a **146 OK**; el de cliente no cambia (108).
  **[APLICADO 2026-07-21]** (mini-ronda 8 ✓ — M2: selftest 146 OK, 0 fallos en juego)

Verificación previa: sintaxis (luaparser, 3 archivos) + harness offline
(`dev/harness_coagulant.py`): **ALL GREEN** — selftest 146 OK (server+Cargo) / 108
(client+Cargo), 0 fallos en ambos realms.

---

## PARCHES DE sesión Fix mini-ronda 8 — la tecla no dispara con un menú de cursor abierto — 2026-07-21

La mini-ronda 8 (2026-07-21) pasó **2/2** y los tres parches de «Fix ronda 7» flipean
arriba. Quedó UNA nota (M1): **al elegir la tecla en el binder del tab Q, el menú médico
se desplegaba ahí mismo**. Mecanismo: la tecla recién elegida sigue físicamente abajo con
el spawnmenu en pantalla — el binder la captura por key-trapping pero la convar ya cambió,
y el poleo de «Fix ronda 7» la veía como flanco válido (el spawnmenu no retiene foco de
teclado, así que el guard de foco no lo frenaba).

- PARCHE 1 — fix(medmenu): el poleo gana el guard `not vgui.CursorVisible()` — la tecla
  solo ABRE, así que con cualquier menú de cursor en pantalla (el Q, el propio medmenu)
  no debe disparar. OJO: el guard es válido JUSTAMENTE porque no hay rama de cierre; si
  la tecla pasa a toggle (decisión de diseño abierta), se revisa — es el mismo guard que
  volvía inalcanzable el cierre en el slice 4. **[APLICADO 2026-07-21]** (check N1 ✓ —
  reporte del autor por chat: «funciona el bind»; elegir la tecla en el binder ya no
  despliega el menú)

Verificación previa: sintaxis (luaparser) + harness offline: **ALL GREEN** — selftest
146 OK (server+Cargo) / 108 (client+Cargo), 0 fallos. En juego: check **N1** de la
planilla.

---

## PARCHES DE sesión Enmienda de zonas — `torso` → `chest` & `stomach` (diseño) — 2026-07-21

Sesión de DISEÑO del tramo que el autor pidió el 2026-07-21 (semilla:
`dev/HANDOFF_coagulant_zonas.md`): alinear las zonas clínicas con Caliber partiendo
`torso` en `chest` y `stomach` — el Source ya separa los hitgroups y Coagulant tiraba la
información. Es cambio del contrato COA-8, así que rige el orden de COA-28: **(1) ronda
de preguntas con el autor y enmienda en los docs — esta sesión —, (2) código, (3) ronda
en juego (sección O de la planilla)**. Las cinco preguntas de la semilla se resolvieron
con el autor: **sin diferencia clínica en v1** pero nace `ZONE_BLEED_MULT` **neutra**
(todas ×1.0) con el balanceo futuro calibrado contra el referente ACE (Arma 3 / Arma
Reforger) y ritmos reales de exanguinación — expectativa del autor que los docs no
tenían escrita y ahora sí; **fallback** `GENERIC`/`GEAR`/desconocido → `chest`; **sin
alias** `torso` (barrido: ningún repo del ecosistema consume los IDs — los
`condition_zones` de Cargo son de su ropa, otro namespace); **tope 5+5** aceptado (cota
de estado, no balance); **silueta 58/42** (proporción del browser de Caliber, gap 0.01).
Sin superficie de runtime — solo docs; los parches nacen `[APLICADO]`. La bajada a
código es la próxima sesión y abre sus propios parches `[PENDIENTE]`.

- PARCHE 1 — docs(docs): `Coagulant_Architecture.md` — bloque de enmienda en §3 (las
  cinco decisiones, con fecha, voto y la base médica de la ronda), la fórmula de §4 gana
  `× mult(zone)` neutro, §6 reescribe la línea «torso no tiene debuff» (su racional
  murió con la partición), §7 la zona automática del medkit cae a `chest`, §8 anota las
  7 zonas en `Zones.*`, §10 la silueta pasa a 7 rects con la geometría ratificada
  (chest `y=0.18 h=0.21`, stomach `y=0.40 h=0.15`). **[APLICADO 2026-07-21]**

- PARCHE 2 — docs(docs): re-enunciación de las normas en su sede e índice — `CLAUDE.md`
  contrato 4 (COA-8: los 7 IDs, con marca explícita de **bajada a código pendiente**:
  hasta que el código baje, el árbol dice `torso` y el código manda, flujo §7.1) y
  `corpus/docs/ids.yaml` con COA-8 **y COA-7** re-enunciados en el mismo parche (§7.4
  del flujo — COA-7 entra porque su título fijaba «torso como fallback» y el fallback
  nuevo es `chest`). **[APLICADO 2026-07-21]**

---

## PARCHES DE sesión Bajada de zonas a código — `torso` → `chest` & `stomach` — 2026-07-21

Fase 2 de las tres que fijó la sesión de diseño (orden COA-28): la enmienda ratificada
de §3 baja al árbol tal cual — nada se re-litigó. Los 13 archivos pasan sintaxis
(luaparser) y el harness versionado (`dev/harness_coagulant.py`) cierra **ALL GREEN**
con checks nuevos de la partición: selftest **170 OK server / 132 client** (antes
146/108; +24 por realm, todos shared — zonas 7, partición CHEST/STOMACH en el mapa Y
en el pipeline, `torso` inválido, `ZONE_BLEED_MULT` derivada de la config, silueta
58/42 con gap 0.01). La fase 3 es la ronda **O** de la planilla, en juego — estos
parches quedan `[PENDIENTE]` hasta su reporte.

- PARCHE 1 — feat(zones): `Zones.LIST`/`LABELS` pasan a **7 zonas** en orden estable de
  UI (head, chest, stomach, left_arm, right_arm, left_leg, right_leg); `HITGROUP_A_ZONA`
  parte CHEST→`chest` / STOMACH→`stomach` y GENERIC/GEAR caen a `chest`; el fallback de
  `FromHitgroup` pasa a `"chest"` (COA-7); `IsValid("torso")` pasa a false — murió sin
  alias (COA-8). Header del archivo re-escrito (decía «6 zonas»). **[APLICADO
  2026-07-21]** (ronda O ✓ — O2: chest/stomach por disparo real; O3: fallback chest y
  torso muerto)

- PARCHE 2 — feat(config): nace `Config.ZONE_BLEED_MULT` **neutra** (las 7 zonas ×1.0,
  eje de tuning contra el referente ACE, cita COA-27) y `SILHOUETTE` pasa a 7 rects —
  el rect del torso partido 58/42 (chest `y=0.18 h=0.21`, stomach `y=0.40 h=0.15`, gap
  0.01, mismo x/w); `ZoneAt` intacto, itera la tabla. Micro-decisión de implementación
  (documentada en el comentario): `BleedRate` gana el 2.º parámetro `zone`, **nil-safe**
  (sin zona → ×1.0) — la fórmula entera de §4 (`base × mult(type) × mult(zone)`) queda
  en UNA pura compartida por ambos realms, en vez de repartir el mult en el timer.
  **[APLICADO 2026-07-21]** (ronda O ✓ — O4: el clic de la silueta cae en chest y en
  stomach)

- PARCHE 3 — fix(core): el fallback de la herida sin hitgroup capturado pasa de
  `"torso"` a `"chest"` (COA-7); `IsBleeding`/`BandageEffect`/`WorstBleedingZone` y el
  `DrenajeTotal` del timer de bleeding pasan la zona a `BleedRate` — el timer es donde
  el mult de zona muerde de verdad. **[APLICADO 2026-07-21]** (ronda O ✓ — O2)

- PARCHE 4 — fix(treatment): los defaults de zona automática pasan a `"chest"` (§7
  enmendado): bloodbag (no usa zona) y medkit sin secuela tratada; la búsqueda del
  torniquete pasa la zona a `BleedRate`. **[APLICADO 2026-07-21]** (ronda O ✓ — O5:
  medkit automático → chest sin secuela)

- PARCHE 5 — fix(medmenu): barrido de los `or "torso"` → `"chest"` (zona con la que
  abre, título del detalle, botones, intent del clic) y el detalle pasa la zona a
  `BleedRate`. **[APLICADO 2026-07-21]** (ronda O ✓ — O4)

- PARCHE 6 — fix(hud): `HUD.ZoneBleeding` pasa la zona a `BleedRate` — misma pregunta,
  misma curva y ahora mismo eje de zona que el server (COA-5). `hud` y `debuffs` no
  necesitaron más: son genéricos sobre `Zones.LIST`/`SILHOUETTE` (revisado, no asumido);
  el bloque CONTRATO del init no enumera IDs de zona (confirmado). **[APLICADO
  2026-07-21]** (ronda O ✓ — O6: cojera, sway y visión sin regresión)

- PARCHE 7 — test(dev): el selftest exige 7 zonas, la partición explícita
  (CHEST→chest, STOMACH→stomach, GENERIC/GEAR→chest), el fallback
  `FromHitgroup(999) == "chest"` y `IsValid("torso") == false`; los checks de
  `ZONE_BLEED_MULT` cubren las 7 zonas y verifican que `BleedRate` la aplica,
  **derivando todo de la config, jamás del literal 1.0** (COA-35); las heridas de
  prueba sobre `"torso"` pasan a `chest`/`stomach` (la grave de la venda ejercita
  stomach) y el rechazo del torniquete usa `chest` como no-extremidad. **[APLICADO
  2026-07-21]** (ronda O ✓ — O1: selftest 170 OK server / 132 client EN JUEGO, 0 fallos)

- PARCHE 8 — docs(docs): transición de la enmienda cerrada en el mismo parche que el
  código (flujo §7.3): `CLAUDE.md` pierde la marca «bajada a código pendiente» del
  contrato 4 y los «6 zonas» del mapa (filas `zones` y `hud`) y actualiza los conteos
  del harness (170/132); la arquitectura §3 flipea su cierre a «bajada aplicada»;
  `corpus/docs/ids.yaml` COA-7/COA-8 pierden la marca en sus notas; el estado refleja
  la bajada y apunta a la ronda O. **[APLICADO 2026-07-21]** (ronda O ✓ 6/6 — con el
  reporte, COA-7/COA-8 ganan evidencia `planilla`: checks O2/O3/O4)

---

## PARCHES DE sesión Barrido de drifts de docs — post-zonas — 2026-07-21

Punto (1) de los tres que el autor acordó para después del tramo de zonas (semilla:
`dev/HANDOFF_coagulant_drift_docs.md`): barrer los docs vivos de Coagulant y los ecos
sobre Coagulant en las otras raíces buscando enunciados que el árbol ya desmiente, y
corregirlos EN SITIO. Es un ejercicio de flujo §7: jerarquía de autoridad (7.1 — el
código manda), barrido de ratificación (7.3 — por el VALOR, abriendo ambos lados de
cada cita) y conducta DETENTE (nada quedó sin árbitro, así que no hubo voto). Los
puntos (2) —las dos decisiones de diseño abiertas— y (3) —la mejora de UI que el autor
trae— NO son de esta sesión. **Tramo SOLO de docs** (comentarios de Lua incluidos, sin
lógica): sin superficie de runtime, los parches nacen `[APLICADO]` (precedente:
«Enmienda de zonas»). Sin planilla. **Ninguna norma tocada** → `ids.yaml` sin cambios
(COA-7/COA-8 ya quedaron al día en «Bajada de zonas a código»).

- PARCHE 1 — docs(docs): los docs de cabecera de Coagulant, reescritos contra el estado
  real. `CLAUDE.md` §Qué es dejaba la **mini-ronda 8** como «pendiente chico» estando
  2/2 con el check N1 ✓, y no mencionaba el tramo de zonas ya cerrado; el **`README.md`**
  se declaraba «Block 3 en bajada — slice 4 de 4» con «los slices 1-3 verificados; el 4
  espera su ronda». Ambos afirman ahora los fixes post-cierre confirmados, el Block 3
  CERRADO (4 slices en juego) y el tramo `torso`→`chest`&`stomach` COMPLETO (ronda O
  6/6, 7 zonas), dejando como único pendiente las dos decisiones de diseño abiertas.
  **[APLICADO 2026-07-21]**

- PARCHE 2 — docs(hud): barrido §7.3 de comentarios de Lua — `corpus_coagulant_hud.lua`
  decía «silueta de 6 zonas» en dos comentarios (cabecera del archivo y encabezado del
  bloque de silueta). El código ya pinta 7 (SILHOUETTE de 7 rects, verificado ronda O);
  la sesión de bajada barrió la lógica y las filas del mapa del `CLAUDE.md`, pero no
  estos dos comentarios. Solo texto de comentario — sin cambio de runtime, el conteo del
  selftest no se mueve. **[APLICADO 2026-07-21]**

- PARCHE 3 — docs(docs): ecos de estado de Coagulant en las otras raíces, corregidos en
  el mismo parche (§7.3a — el eco que el informe no lista es el que sobrevive):
  - `corpus/README.md` (tabla de módulos): la celda de Estado de Coagulant decía «la UI
    espera su ronda» estando cerrada; pasa a «En código, verificado», como los demás.
  - `corpus/docs/corpus_roadmap.txt` [3]: listaba la **mini-ronda 8** como pendiente
    («le quedan una mini-ronda 8…») estando cerrada; ahora la da por cerrada junto con
    el tramo de zonas.
  - `corpus/docs/corpus_estado.md` (Próximo paso 2): daba la **bajada a código** de las
    zonas como pendiente y apuntaba a la semilla ya consumida — contradecía su propia
    foto de «Qué existe hoy», que ya la daba completa (§7.1: el código manda, gana la
    línea alineada al árbol).
  - `corpus-cargo/docs/Cargo_Architecture.md`: «silueta de 6 zonas del HUD de Coagulant»
    → 7 (la cita misma remite a `Coagulant_Architecture.md §10`, que ya dice 7).
  - `corpus-craving/docs/Craving_Architecture.md` (tabla de peers **y** §4, el intro del
    puente) y `craving_estado.md` (remanentes): describían el Block 3 de Coagulant como
    «slices 1-3 verificados, UI pendiente / pendiente de la ronda 7». El Block cerró (4
    slices, ronda 7 13/13). Se **preserva** «todavía no expone condición externa»:
    `ApplyExternalCondition` sigue con 0 hits en el `lua/` de Coagulant (verificado) — es
    la deuda D-5, aún abierta.

  **[APLICADO 2026-07-21]**

- PARCHE 4 — chore(workspace): espejo Code→Desktop regenerado (`sync.ps1`, 7 repos, 44
  archivos; propósito: «barrido de drifts de docs de Coagulant (post-zonas)»). Estaba
  desactualizado desde antes del tramo de zonas; el autor pidió refrescarlo en esta
  pasada. Los snapshots están gitignoreados (§6) — la regeneración no produce cambio
  commiteable, solo este registro. **[APLICADO 2026-07-21]**

Verificación: sin superficie de runtime en ningún repo (solo docs y dos comentarios de
Lua) — el harness/selftest de Coagulant no cambia (170 OK server / 132 client). El
checker de IDs (§7.7) corre en cada commit que toca superficie normativa. **NO se
disparó el gate de coherencia LLM (§7.8)**: tramo de un solo módulo — el autor lo dispara
en un chat aparte. Espejo desktop-sync regenerado (PARCHE 4). Commiteado y pusheado con
autorización expresa del autor (2026-07-21).

---

## PARCHES DE sesión Reparación del gate de coherencia (acta 2026-07-22) — 2026-07-22

Tanda de reparación documental propuesta por el gate de coherencia en su corrida COMPLETO del
2026-07-22 (`../../corpus/docs/auditorias/2026-07-22_coherencia_docs.md`; el gate propone, el
autor dispone). Acá lo que toca a este repo. Los PARCHES 1-2 son solo prosa; el PARCHE 3 toca
Lua (voto expreso del autor). **Ninguna norma cambió de contenido.**

- PARCHE 1 — **Hallazgo 2.1 [ALTA] del acta:** `docs/Coagulant_Block3_Semilla.md` presentaba
  las 6 zonas con `torso` como contrato vigente bajo «Contratos ya congelados», sin la nota de
  derogación que sí lleva su bullet hermano (`onUse == ApplyBandage`). Se inserta la nota
  «> DEROGADO por la enmienda de zonas del 2026-07-21»: hoy son **7** zonas, `torso` murió sin
  alias (`Zones.IsValid("torso")` es false), sede **COA-8**. **[APLICADO 2026-07-22]**
- PARCHE 2 — **Hallazgos 2.5 y 2.6 del acta (pase de valor):** `docs/coagulant_roadmap.txt`
  bullet [1] afirmaba en presente que «Coagulant hoy los funde en el mapa de Zones» y que solo
  «la PRIMERA fase ya corrió… falta la bajada a código y la ronda O». El árbol dice que las
  TRES fases corrieron el 2026-07-21 (ronda O 6/6). Se pasa a pasado: la fusión valió «hasta el
  2026-07-21» y el tramo está **COMPLETO**. **[APLICADO 2026-07-22]**
- PARCHE 3 — fix(treatment): **Contrato-vs-árbol PARCIAL 2 del acta (COA-2)** — la re-validación
  de consumo AL COMPLETAR en `server/corpus_coagulant_treatment.lua:148` usaba `CountItem`, la
  función que COA-2 declara «nunca». No era bug (la rama está guardada por `tr.kind ~= "tourniquet"`,
  así que solo tocaba stackables), pero derivaba el absoluto del contrato en una rama. Por voto del
  autor se hace literal el «nunca»: `CountItem(ply, t.item) < 1` → `not HasItem(ply, t.item)`
  (equivalente para stackables; misma forma que ya usa el arranque en `:98`). COA-2 y su CLAUDE.md
  quedan **sin cambio**: el doc ya era correcto, se alinea el código. **[APLICADO 2026-07-23]**
  (pasada en juego del autor — planilla consolidada: V1 venda 3→2, V2 bloodbag 2→1, V3 el torniquete
  `unique` no se consume; los tres ✓)

Verificación: PARCHES 1-2 sin superficie de runtime (solo docs). PARCHE 3 toca `server/treatment`
(realm server) — **[APLICADO 2026-07-23]** tras la pasada en juego (venda 3→2, bloodbag 2→1,
torniquete no consumido); el selftest/harness estaban en verde por construcción (170 OK server /
132 client) y el «nunca CountItem» quedó confirmado con stackable en juego. Cambios trazables al
acta (§7.1: el código manda). Commiteado (`3ef6a46`) y pusheado a `origin/main` con autorización del
autor — la nota «no commiteado» de la redacción original quedó superada por el push.

---

## PARCHES DE sesión Cap del torniquete: se OCUPA, no se reutiliza sin costo (COA-20 enmendada) — 2026-07-23

Nota del check V3 de la pasada del 2026-07-23 (COA-2): el torniquete pasó ✓ (no se consume),
pero el autor observó que **un torniquete `unique` se ponía en varias extremidades** (tenía 2 y
ató las cuatro). Era la deuda de diseño anotada en el estado; por voto del autor se **capa**: el
torniquete deja de ser reutilizable sin costo y pasa a **OCUPARSE** — sale del inventario
mientras está puesto y vuelve al quitarlo —, así uno ata **una sola extremidad** (cap = los que
llevás). Es cross-repo (**Cargo primero**, FLU-04): Cargo estrena `Inventory.TakeUnique` para
consumir un `unique` (su CHANGELOG #29); Coagulant lo consume. **Enmienda COA-20** (sede en
`Coagulant_Architecture.md §7` + `ids.yaml`): «nunca se consume» → «no se destruye pero se
ocupa». Verificación offline: harness **171 OK server / 132 client, ALL GREEN** (checks nuevos:
ponerlo descuenta la unidad, una 2.ª extremidad sin torniquete libre se rechaza, quitarlo lo
devuelve).

- PARCHE 1 — fix(treatment): el bloque de consumo de `Completar` ocupa/devuelve el torniquete —
  al ponerlo (no `removing`) re-valida `HasItem` y hace `TakeUnique(ply, t.item)`; al quitarlo
  (`removing`) hace `GiveItem(ply, t.item)`. El cap sale solo: sin torniquete libre, el arranque
  ya falla por `HasItem` (:98). Comentarios de `:91-95` y del bloque actualizados. **[APLICADO
  2026-07-23]** (pasada 2026-07-23, TQ ✓: ponerlo descuenta la unidad, la 2.ª pierna no alcanza,
  quitarlo lo devuelve)
- PARCHE 2 — test(dev): el selftest exige `isfunction(cargo.Inventory.TakeUnique)` con Cargo
  montado (un Cargo sin la superficie reproduce el multi-extremidad en silencio) — server pasa de
  170 a **171 OK**. **[APLICADO 2026-07-23]** (offline; el check corre en cada carga)
- PARCHE 3 — docs(docs): **enmienda COA-20** en su sede (`Coagulant_Architecture.md §7`, fila del
  torniquete) y en `corpus/docs/ids.yaml` (título + evidencia harness); el estado refleja el cap.
  **[APLICADO 2026-07-23]**

Nota de diseño (para la pasada): un torniquete **puesto al morir** se pierde con el cuerpo (queda
ocupado y nunca vuelve). Aceptable v1, o deuda menor — lo decide el autor en juego.

Verificación: PARCHE 1 toca `server/treatment` (realm server) — **[APLICADO 2026-07-23]** (TQ ✓
en la pasada del autor). PARCHES 2-3 offline/docs. Harness 171/132 ALL GREEN. Cross-repo: Cargo
`TakeUnique` (#29) va primero (FLU-04). No commiteado ni pusheado (GIT-7).

---

## PARCHES DE sesión Modelos de los ítems médicos: la cajita es la decisión, no la deuda — 2026-07-23

Decisión del autor (2026-07-23, misma tanda que el entry **34** de Cargo): los ítems médicos se
quedan **sin `model`** — dropean como la cajita de cartón de Cargo y su ícono cae a la letra —,
y la sustitución es asunto de los addons de CONTENIDO vía el punto de extensión nuevo de Cargo,
`Items.SetModel(id, model)` (orden-independiente; los defs siguen siendo de Coagulant).
`corpus-stalker` ya re-viste venda (`wick_bandage`) y medkit (`medkit_low`); torniquete y blood
bag no tienen modelo coherente en los packs y quedan en la cajita. En este repo el cambio es
**solo prosa/comentario** — el código ya no declaraba modelos; lo que cambia es que la ausencia
pasa de accidente a contrato de diseño.

- PARCHE 1 — docs(items): comentario en el bloque de registro de
  `shared/corpus_coagulant_items.lua` («Sin `model` A PROPÓSITO… No agregues modelos acá») +
  nota en `Coagulant_Architecture.md` §7 bajo la tabla del set v1. **[APLICADO 2026-07-23]**

Verificación: sin superficie de runtime en este repo (harness/selftest intactos: 171 server /
132 client). La verificación en juego de la sustitución vive en el checklist del entry 34 de
Cargo — **confirmada por el autor el 2026-07-23** (venda → wick_bandage, medkit → medkit_low;
torniquete y blood bag en la cajita, como se decidió). Commiteado y pusheado con autorización
del autor.

---

## PARCHES DE sesión La venda cubre el trauma cerrado (COA-37, alineación con ACE3) — 2026-07-29

Sale de una pregunta del autor —«¿cómo se sana el daño Blunt/Trauma?»— cuya respuesta era **no se
sana**. Cadena verificada en el árbol: `contusion` tiene mult **0.0** (`config:77`) → `BleedRate`
siempre 0 → la venda, gateada por `BleedRate > 0` en el motor (`treatment:69-75`) *y* en el efecto
(`core:161-165`), nunca la podía marcar `treated` → y `HealTreatedWounds` (el medkit) solo borra lo
ya `treated` → la contusión pesaba **entera** en `GetZoneScore` hasta morir. Una caída dejaba
cojera permanente, y el default conservador de §3 (`resto / sin clasificar` → `contusion`) convertía
cualquier fuente de daño rara de un tercero en una marca incurable.

**La causa fue un diferimiento a medias, no un olvido.** Segunda pregunta del autor: si el
referente es ACE3/ACE-Reforger, ¿cómo lo atacan ellos? Con **tres** salidas — la venda aplica a
toda herida abierta, el **dolor** decae solo y lo acelera un analgésico, y el efecto estructural es
una **fractura** con su férula. §1 difirió las dos últimas (correcto para v1), pero `contusion` se
quedó con la **entrada** al sistema y sin ninguna de las tres salidas. Por voto expreso del autor
se adopta la primera, la única que **no cuesta mecánica nueva**: la venda deja de preguntar
«¿sangra?» y pregunta «¿está abierta?». Con eso la contusión entra al circuito **venda → medkit**
que ya existe y está verificado. **No** entra la tabla de efectividad por tipo de venda de ACE3
(sería mecánica nueva, COA-28), y dolor/fractura **siguen diferidos**.

- PARCHE 1 — docs(docs): **enmienda COA-37** en su sede (`Coagulant_Architecture.md §7`, bloque
  nuevo al abrir la sección) + fila de la venda, fila `contusion` de la tabla de §3, la línea de
  §1 que difiere dolor/férula y el bullet de zona automática de §7. Alta de **COA-37** en
  `corpus/docs/ids.yaml` (INVARIANTE, evidencia `harness`). Va **antes** que el código (COA-28).
  **[APLICADO 2026-07-29]**
- PARCHE 2 — feat(config): nace `Config.BandagePriority(wound, zone)` — pura y compartida: 0 si
  la herida ya está tratada, si no `severity × 2 + (sangra and 1 or 0)`. La severidad **domina** y
  el sangrado **desempata**: sin eso, en una zona con un moretón y un balazo de la misma severidad
  la venda podía irse al moretón mientras el balazo drena. Un solo criterio para el efecto, la
  zona automática y el selftest — no tres. **[APLICADO 2026-07-29]** — pero **la jerarquía de esta
  fórmula quedó REFUTADA por el check 4** de la misma pasada: el autor reportó que con un balazo
  leve y un moretón medio la venda atendía el moretón. Se invierte en la sesión siguiente
  («Hemorragia primero»); la función y su rol siguen en pie, cambia el orden.
- PARCHE 3 — fix(core): `BandageEffect` selecciona por `BandagePriority` en vez de por
  `BleedRate > 0` (la contusión ya se venda); nace `WorstOpenZone(ply)` como destino automático de
  la venda. `WorstBleedingZone` **se conserva** —responde la pregunta de URGENCIA, no la de la
  venda— con el comentario corregido: hoy solo la ejercita el selftest. **[APLICADO 2026-07-29]**
  (pasada del autor: checks 1-3 ✓ — la contusión de caída se venda y el medkit la borra)
- PARCHE 4 — fix(treatment): el gate de arranque de la venda pasa de «¿hay algo sangrando?» a
  «¿hay una herida abierta?» (mismo `BandagePriority`), y la zona automática pasa a
  `WorstOpenZone` — antes, con solo un moretón encima, el uso rápido no encontraba zona y
  rechazaba con *"Nothing to bandage"*. **[APLICADO 2026-07-29]** (checks 1-3 y 5 ✓)
- PARCHE 5 — fix(items): el debug `coagulant_bandage` usa la misma selección que el flujo real
  (`WorstOpenZone`); si mirara solo el sangrado mentiría sobre lo que hace la venda de verdad.
  **[APLICADO 2026-07-29]**
- PARCHE 6 — test(dev): 14 checks nuevos. **5 puros** (ambos realms): la contusión no sangra pero
  **sí** se venda, una tratada no se re-venda, el desempate a igual severidad va a la que sangra, y
  la severidad domina sobre el sangrado. **9 de server**: el circuito completo de una contusión de
  punta a punta (score entero → la venda la cierra → media → el medkit la borra → score 0), que
  `WorstOpenZone` la ve, que una zona sin heridas abiertas no gasta venda, y el desempate en vivo
  con balazo y moretón de la misma severidad en la misma zona. Server **171 → 185**, client
  **132 → 137**. **[APLICADO 2026-07-29]** (offline; corren en cada carga)
- PARCHE 7 — docs(docs): `CLAUDE.md` §Verificación decía **170 OK server** — quedó desactualizado
  cuando el PARCHE 2 de la sesión «Cap del torniquete» lo subió a 171 (el `coagulant_estado.md` sí
  lo tenía bien). Se corrige y se pasa a los conteos de hoy. **[APLICADO 2026-07-29]**

Verificación: harness offline **ALL GREEN — 185 OK server / 137 client, 0 fallos** (línea base
medida contra HEAD con `git stash`: 171/132, así que el delta son exactamente los 14 checks del
PARCHE 6). Los PARCHES 2-5 tocan runtime (config shared, core/treatment server, items shared) y
nacieron `[PENDIENTE]` hasta la pasada en juego del autor (flujo §1 PASO 4).

**Resultado de la pasada (2026-07-29): 4/5.** ✓ **(1)** caer, herirse y vendarse la pierna — antes
rechazaba, ahora entra y la cojera baja a la mitad; ✓ **(2)** medkit sobre esa pierna → cojera en
cero; ✓ **(3)** golpe de melé vendable igual; ✗ **(4)** una zona con balazo y moretón: *«la zona
con disparo mínimo y un moretón medio, se cura primero el moretón y luego los disparos sangrantes.
La urgencia es en los disparos»* — el ORDEN de `BandagePriority` estaba al revés; se corrige en la
sesión siguiente; ✓ **(5)** sin heridas abiertas la venda sigue rechazando y no se consume. La
enmienda en sí (que la contusión se cure) queda **confirmada**: lo refutado es a cuál de dos
heridas abiertas va la venda. No commiteado ni pusheado (GIT-7).

---

## PARCHES DE sesión Hemorragia primero: el orden de la venda, corregido (COA-37) — 2026-07-29

Sale del **check 4 ✗** de la pasada anterior, en el mismo día. Yo había especificado —y el autor
había aprobado sobre esa redacción— que en `BandagePriority` **la severidad domina y el sangrado
desempata**. El caso del autor en juego lo desmiente: *balazo mínimo + moretón medio → se curaba
el moretón*. Tiene razón y el error era **de diseño, no de implementación**: un moretón no mata
nunca y un balazo leve drena hasta matar, así que ninguna severidad de contusión debería ganarle a
un sangrado. La jerarquía correcta es la de la doctrina de trauma real —hemorragia primero— y es
la que rige desde acá. Alcance mínimo: **cambia el orden, no la enmienda** — que la contusión se
cure (lo que COA-37 compra) quedó confirmado en la pasada.

- PARCHE 1 — docs(docs): el bloque COA-37 de `Coagulant_Architecture.md` §7 cambia su párrafo de
  orden por **«el SANGRADO manda, la severidad ordena dentro de cada grupo»**, con la nota de por
  qué se corrigió y el caso del autor citado textual; se alinean la fila de la venda del set v1 y
  el bullet de zona automática. `ids.yaml` COA-37: título, evidencia y nota. **[APLICADO
  2026-07-29]**
- PARCHE 2 — fix(config): `BandagePriority` pasa a `urgencia + severity`, con
  `urgencia = sangra and (SEVERITY_MAX + 1) or 0` — el sangrado domina y la severidad ordena
  dentro de cada grupo. El peso sale de **`SEVERITY_MAX`, no de un literal** (COA-35): con una
  severidad 4 futura el sangrado seguiría dominando sin tocar la función. **[APLICADO 2026-07-29]**
  (re-pasada del autor: el check 4 ✓ — la venda va al balazo y la segunda al moretón)
- PARCHE 3 — feat(config): nace `Config.SEVERITY_MAX = 3`, el techo que ya aplicaba `AddWound`
  como literal. `core:131` pasa a `math.min(Config.SEVERITY_MAX, …)`: el 3 estaba escrito en dos
  lugares y ahora en uno. **[APLICADO 2026-07-29]**
- PARCHE 4 — test(dev): el check que afirmaba lo contrario (*«la severidad no domina sobre el
  sangrado»*) se **invierte**, y entran los que faltaban: el caso exacto del autor (balazo sev 1 >
  moretón sev 2), que ni una contusión en `SEVERITY_MAX` le gana a un sangrado, que dentro de cada
  grupo la severidad sigue ordenando (dos sangrantes / dos contusiones), y que `BLEED_BASE` cubre
  exactamente `SEVERITY_MAX` niveles — si creciera sin que crezca el techo, una herida muy grave
  podría empatarle a un sangrado. En vivo, el caso del autor de punta a punta: balazo leve +
  moretón medio → la 1.ª venda corta el sangrado (score 2.5) y la 2.ª atiende el moretón (1.5).
  Server **185 → 192**, client **137 → 142**. **[APLICADO 2026-07-29]** (offline)

Verificación: harness **ALL GREEN — 192 OK server / 142 client, 0 fallos**. Los PARCHES 2-3 tocan
runtime (config shared) y nacieron `[PENDIENTE]`; la **re-pasada del autor (2026-07-29) cerró el
check 4 ✓** — con balazo leve y moretón medio la venda va al balazo y la segunda al moretón. Con
eso **COA-37 queda 5/5 verificado en juego** y el tramo cerrado: el trauma cerrado ya tiene cura y
el orden es el correcto. Commiteado y pusheado con autorización expresa del autor (2026-07-29),
junto con el alta de COA-37 en `corpus/docs/ids.yaml`.

---

## PARCHES DE sesión Los ítems médicos traen su modelo (enmienda a la sesión del 2026-07-23) — 2026-08-05

**Enmienda del autor** a la decisión del 2026-07-23 (entry 34 de Cargo). Aquella dejaba los ítems
médicos **sin `model`** para que un addon de contenido pudiera vestirlos; el motivo era bueno pero
el efecto no: sin nadie que sustituya, el mod se ve con cajitas de cartón. Textual del autor: *"mi
idea de no agregar directamente era para que otros usuarios pudieran sustituir sus propios modelos,
pero para mí, prefiero que se vea lindo el mod con sus respectivos modelos por defecto"*.

**La razón por la que no los tenían NO se pierde.** `Cargo.Items.SetModel` pisa el modelo declarado
**y se re-aplica en cada `Register`** (bloque `_modelOverrides`, verificado en el código de Cargo,
no asumido): declarar un default no cierra la puerta a la sustitución, sólo cambia qué se ve
cuando nadie sustituye. `corpus-stalker` sigue vistiendo venda y medkit con los de la Zona sin
tocar una línea de este repo.

**18 modelos nuevos**, portados de tres packs de Sketchfab **CC BY 4.0** con el pipeline de
`dev/phastools/`. Créditos y obligaciones de la licencia en [`CREDITOS.md`](CREDITOS.md).

- PARCHE 1 — feat(items): `models/corpus_coagulant/` (18 `.mdl`, 10,5 MB) +
  `materials/models/corpus_coagulant/` (18 VMT + 31 VTF, 16,5 MB). Los `.qc` con el comando exacto
  que los regenera viven en `dev/phastools/compile/src/`. **[PENDIENTE]**

- PARCHE 2 — feat(items): `model` en tres de las cuatro defs de
  `shared/corpus_coagulant_items.lua` — `bandage` → `bandage.mdl`, `medkit` → `firstaidkit.mdl`
  (el de 16 cm; `medkit_large` de 30 cm queda como prop de escenario), `bloodbag` →
  `bloodbag.mdl`. **[PENDIENTE]**

- PARCHE 3 — docs(items): el comentario «No agregues modelos acá» se reemplaza por el que ahora es
  cierto, **conservando la razón original** y explicando por qué sigue cubierta. El torniquete
  lleva su propio comentario de por qué queda sin modelo. **[PENDIENTE]**

- PARCHE 4 — docs: alta de [`CREDITOS.md`](CREDITOS.md) — autores, licencia CC BY 4.0, enlace a la
  licencia y declaración de que los modelos están modificados (las tres cosas son **obligación**
  de CC BY, no cortesía). **[APLICADO 2026-08-05]**

**El torniquete queda sin modelo, y no por olvido: en los tres packs no hay ninguno.** El candidato
que lo parecía (`Lines`) resultó, al renderizarlo, ser dos carretes de sutura con aguja —
`corpus-stalker` había llegado a la misma conclusión con sus propios packs el 2026-07-23. Cae a la
cajita hasta que aparezca uno.

- PARCHE 5 — docs: alta de [`ASSETS.md`](ASSETS.md) — catálogo de los 18 `.mdl` con qué es cada uno,
  tris, tamaño, cuáles son translúcidos y **cuáles no tienen def (quince)**. Enlazado desde el
  `CLAUDE.md` (jerarquía de lectura + mapa de archivos) y desde el roadmap (tramo [5]).
  **Lo motivó una pregunta del autor:** el inventario existía sólo dentro de `CREDITOS.md`, que es
  una página de licencias — nadie la abre buscando un asset — y ni el `CLAUDE.md` ni el roadmap la
  nombraban. Un inventario guardado donde nadie lo busca no existe para la sesión siguiente.
  El tramo [5] del roadmap además deja escrito el orden correcto: **que exista el modelo no crea el
  ítem** (COA-28); el catálogo sirve cuando un tramo YA decidido necesita un modelo.
  **[APLICADO 2026-08-05]**

Verificación offline: harness **ALL GREEN — 192 OK server / 142 client, 0 fallos** (idéntico a la
línea base: los defs sumaron un campo, no lógica). Los 18 `.mdl` pasan `verify_model.py` con
controles conocidos-buenos, **17 con 7/7**; el 18.º (`sutures`) falla C1 con 1,97 unidades contra
un umbral de 2 — es un carrete de sutura de 5 cm y **el tamaño es el correcto**: el check marca
props chicos, y se deja constar en vez de forzarle una escala que rompería la del resto del set.
Los PARCHES 1-3 tocan runtime y nacen `[PENDIENTE]`: falta la pasada en juego del autor.

---

## PARCHES DE sesión El botiquín grande abre, se vacía y se cierra (bodygroup) — 2026-08-05

Pedido del autor tras confirmar Coagulant en juego: que el botiquín pueda estar **cerrado** y
**vacío**, tipo bodygroup. El modelo se prestaba: los 43 objetos separan solo en **carcasa** (8
piezas, 3.590 tris) y **contenido** (35 piezas, 44.688 tris), así que «vacío» es un bodygroup
literal y quita el **92,6 %** de los triángulos.

«Cerrado» no lo es —hay que **rotar** la tapa, no ocultarla—, y ahí el nombre volvió a mentir: el
modelo trae dos objetos llamados `Spinle` que parecían los pasadores de la bisagra y **no lo son**
(centros sin relación, uno adentro de la caja, vector diagonal). La bisagra salió de la geometría:
`MetalBox` es una bandeja plana cuyo borde está en z=+0,0073 y `MetalCover` una losa parada de
0,113 de espesor apoyada contra el fondo — un giro de **+90° sobre X** por la esquina superior
trasera. La separación tapa/caja tampoco es por nombre: hay un **hueco medido de 3,3 cm** entre el
objeto más alto de la caja (y=0,2215) y el más bajo de la tapa (y=0,2542), y el umbral va en el
medio.

- PARCHE 1 — feat(items): `dev/phastools/medkit_states.py` — genera los tres SMD. Comprueba el
  cierre **antes** de escribir, y no contra un rango escrito a mano (el primer intento falló por un
  rango mal derivado, sacado de `MetalCover` solo e ignorando los herrajes) sino contra dos
  propiedades medidas de la caja: que la tapa **apoye** (su cara inferior al ras del borde, da 1,55
  cm de solape) y que **cubra** la huella. **[APLICADO 2026-08-05]**

- PARCHE 2 — feat(items): `medkit_large.qc` pasa a `$bodygroup state` con tres opciones
  (`open_full` / `open_empty` / `closed`). Un bodygroup de tres y no dos de dos: dos darían cuatro
  combinaciones y una no existe físicamente. **[PENDIENTE]**

- PARCHE 3 — fix(items): `$illumposition 0 0 0` explícito en `medkit_large.qc`. **Lo destapó C2 de
  `verify_model.py`, no la vista.** Los otros 17 modelos no lo declaran y sale (0,0,0) solo porque
  su geometría está centrada; acá también lo está, pero studiomdl mide la **unión** de las tres
  opciones —que no es simétrica, porque el cerrado ocupa sólo la mitad inferior— y le aplica
  `$scale` otra vez. Quedaba en (11.33, 0, 0) sobre un bbox que llega a 5.85: **el error 15 de la
  referencia de ripping**, o sea un prop que se va a negro según el ángulo. Sin la batería esto se
  ve recién en juego y parece un problema de material. **[PENDIENTE]**

**Lo que NO se hizo y hay que saber:** la colisión es **una sola para los tres estados** (Source
tiene un `$collisionmodel` por modelo, no por bodygroup). Se usa la del estado 0 porque contiene a
los tres. Medido: con `closed` quedan **8,29 u (~21 cm) de colisión invisible arriba** de la caja.
La base coincide en los tres, así que apoya bien en el piso; lo que molesta es no poder pasar por
encima. Y **`firstaidkit` sigue sin estados**: el trabajo de bisagra hay que rehacerlo para él.

Verificación offline: compila con **0 errores y 0 warnings**; `verify_model.py` da **7/7** con dos
controles que discriminan (spiritbox sigue fallando C7). El bodygroup se comprobó **leyendo el
binario instalado**, no la salida de studiomdl: 1 bodypart `state` con 3 opciones de 39.224 / 3.809
/ 3.809 vértices. Harness sin tocar (no hay cambio de Lua). Los PARCHES 2-3 nacen `[PENDIENTE]`:
falta la pasada en juego.

---

## PARCHES DE sesión El botiquín cerrado se va a su propio modelo — 2026-08-06

Decisión del autor tras ver los bodygroups en juego: *"deberíamos separar el closed con su propia
colisión y sacar ese bodygroup"*. Es exactamente la salida que el comentario del `.qc` de ayer
anotaba como única — **Source tiene un `$collisionmodel` por modelo, no por bodygroup**, así que
mientras el cerrado fue la tercera opción tuvo que usar el casco del abierto: 8,29 unidades
(~21 cm) de colisión invisible por encima de la caja.

- PARCHE 1 — feat(items): `medkit_large_closed.mdl`, modelo aparte con **casco propio**. Alto del
  casco **11,81 u → 3,52 u**, y ajusta a su malla con **0,000 u de holgura**. De paso pesa lo que
  dibuja: `.vvd` de 244 KB contra 2,75 MB. Comparte el VMT con el abierto — es el mismo objeto.
  **[PENDIENTE]**

- PARCHE 2 — refactor(items): `medkit_large.qc` baja a `$bodygroup state` de **dos** opciones
  (`open_full` / `open_empty`). Las dos que quedan **sí** comparten casco legítimamente:
  `open_empty` es un subconjunto de `open_full`. **[PENDIENTE]**

- PARCHE 3 — refactor: `dev/phastools/medkit_states.py` genera los cuatro SMD de los dos modelos y
  **también los dos cascos**, con el mismo offset y factor que su malla visible cada uno. El header
  de `bl_collision.py` pide que el centrado de la malla y el de la colisión coincidan; acá no pueden
  divergir porque se pasan el mismo valor. **La escala se HEREDA y el centrado NO**: el factor sale
  del modelo abierto (30 cm) y el cerrado lo toma prestado — si se normalizara a 30 cm por su cuenta
  saldría ~3,4× más grande, porque cerrado es mucho más bajo. El script lo comprueba comparando el
  ancho de la caja en los dos modelos y **aborta** si no coincide. **[APLICADO 2026-08-06]**

- PARCHE 4 — fix(items): **se SACA** el `$illumposition 0 0 0` que el parche de ayer había puesto en
  `medkit_large.qc`, y se sacó **midiendo, no por prolijidad**. Hacía falta cuando la unión de las
  tres opciones era asimétrica (el cerrado ocupaba sólo la mitad inferior); con el cerrado afuera,
  `open_empty` es subconjunto de `open_full`, la unión vuelve a estar centrada y C2 pasa con
  (0,0,0) sin la línea — C7 además pasó de 2,5 % de desvío a 0,0 %. Arrastrarla «por las dudas»
  habría dejado una línea cuya razón ya no existía. **[APLICADO 2026-08-06]**

- PARCHE 5 — chore: se borra `medkit_large_closed.smd`, el SMD huérfano de la versión de tres
  estados. Lo reemplaza `medkit_large_closed_ref.smd`. **[APLICADO 2026-08-06]**

Verificación offline: los dos `.qc` compilan con **0 errores y 0 warnings**, y **los dos dan 7/7**
en `verify_model.py` contra control. Comprobado leyendo el binario instalado y no la salida de
studiomdl: `medkit_large` tiene el bodygroup `state` con **2** opciones (39.224 / 3.809 vértices) y
`medkit_large_closed` tiene **1** bodypart. Harness sin tocar (no hay cambio de Lua). Los PARCHES
1-2 tocan runtime y nacen `[PENDIENTE]`: falta la pasada en juego.

---

## PARCHES DE sesión La venda es UNA y el Medkit es el naranja — 2026-08-08

Reporte del autor mirando los modelos ya cableados: *«medkit_large debería cambiar el
first_aid_kit que está actual como modelo de medikit porque first_aid_kit (modelo chiquito de una
caja blanca) es muy feo. Las vendas también se ven feas, son 3 vendas juntas cuando debería ser un
solo modelo de una venda grande, la bolsa de sangre se ve bien.»* Los dos son cambios de **asset**,
no de mecánica: ninguna def cambia de peso, de clase, de `onUse` ni de categoría.

**La venda eran tres porque la rama del pack son tres.** Medido con Blender sobre el FBX de origen:
`Bandages` tiene **tres objetos separados** de 642 tris cada uno (un rollo de 302 caras + su punta
de gasa de 3), que se cortan limpio. `fbx2smd.py` sólo sabía filtrar por **rama**, y una rama puede
ser un conjunto y no una pieza — por eso el port se llevó los tres.

**Y un rollo solo NO es «una venda grande»: es más chico que `sutures`.** Con el factor 2.0 que
comparte el set, un rollo mide **3,0 cm = 1,18 u**, y C1 de `verify_model.py` pide 2..40 u:
reprobaba. Se normaliza a **9 cm con factor propio**, que es el porte que ocupaban los tres juntos
— o sea que en pantalla el ítem **no se achicó**, dejó de ser tres cosas. La excepción al factor
único del pack está votada por el autor y escrita en tres lugares para que nadie la «arregle»
(`bandage.qc`, `ASSETS.md`, `CREDITOS.md`).

**De los tres rollos se elige `Bandage2` por medida y no por nombre:** su rollo es 3,00 × 3,67 ×
3,68 cm contra 3,00 × 3,00 × 3,09 de los otros dos, o sea el más grande, y al normalizar se estira
menos — eso conserva densidad de textura.

- PARCHE 1 — feat: `fbx2smd.py` gana `--object <malla>`, que se queda con UNA malla de la rama por
  nombre exacto. Falla ruidoso si el nombre no existe, por la misma razón que `--mat`: un filtro
  que no filtra produce un `.mdl` que compila, pasa los checks y se ve bien — sólo que no es el que
  se pidió, y **no tiene síntoma propio**. Vive en `dev/`, fuera de los repos.
  **[APLICADO 2026-08-08]**

- PARCHE 2 — feat(items): `bandage.mdl` regenerado de UN rollo a 9 cm. 1.926 → **642 tris**,
  `.vvd` 71.488 → **23.872 B**, dims 3,33 × 8,95 × 5,16 → **7,87 × 8,99 × 9,00 cm**. El `.qc` lleva
  el comando exacto y el porqué de la excepción de escala. **[APLICADO 2026-08-08]**

- PARCHE 3 — feat(items): la def `corpus_coagulant_medkit` pasa de `firstaidkit.mdl` a
  `medkit_large_closed.mdl`. 8.860 → **3.590 tris**. El **cerrado** y no el abierto: es un ítem que
  se lleva encima, y el abierto son 48.278 tris (el 35 % de todo el set). **[APLICADO 2026-08-08]**

- PARCHE 4 — docs(items): comentarios de `corpus_coagulant_items.lua` — el del medkit justificaba
  el `firstaidkit` y quedó falso; se reescribe con las dos razones. De paso el bloque decía «18
  modelos» y «`Medical Supplies Collection`» como único pack: son **19** y son **tres** packs, y
  ahora una def usa uno de los otros dos. **[APLICADO 2026-08-08]**

- PARCHE 5 — docs: `ASSETS.md` (tabla, total de tris 140.056 → **138.772**, sección nueva *La venda
  es UN rollo*) y `CREDITOS.md` (*Qué usa cada def* + la excepción de escala). **[APLICADO
  2026-08-08]**

**LO QUE HAY QUE HACER ANTES DE MIRAR ESTO EN JUEGO, o la pasada informa lo contrario de lo que
pasó.** El grid de Cargo no dibuja el modelo: dibuja un **ícono cacheado en disco** cuyo nombre ES
la clave de invalidación — `<defid>_<CRC(recipe|modelo|cámara|footprint)>.png`
(`corpus_cargo_icons.lua:396-410`). Consecuencia asimétrica, y medida leyendo ese código:

- el **Medkit** cambió de RUTA de modelo, así que el CRC cambia, el nombre cambia y **se
  re-renderiza solo**;
- la **venda** conserva la ruta `bandage.mdl` y sólo cambió la malla de adentro → **mismo CRC,
  mismo archivo, y el ícono viejo de tres rollos sobrevive**. Además `mesh_bounds.json` cachea las
  medidas **por ruta de modelo** («computed once per model path EVER»), así que el encuadre también
  saldría del bbox viejo.

O sea que sin borrar la caché, el ítem en el mundo se vería con la venda nueva y el ícono del
inventario seguiría mostrando tres — y el reporte natural sería «el modelo no cambió». **Borrar
`garrysmod/data/corpus/cargo/icons/` antes de la pasada** (es caché pura: se reconstruye sola).

Verificación offline: `bandage.qc` compila con **0 errores y 0 warnings**; `verify_model.py` da
**7/7** sobre el `.mdl` instalado (C1 = 3,54 u, C2 illumposition en (0,0,0), C7 desvío 0,0 %).
Harness **192 OK server / 142 client, 0 fallos, ALL GREEN** y `glua_check.py` OK sobre el archivo
tocado.

**Sobre el control de `verify_model.py`, que esta vez hubo que fabricar.** Los conocidos-buenos que
había a mano —`bloodbag`, `medkit_large_closed` y los tres `spiritbox`— **pasan los siete checks**,
así que una corrida donde nada falla no probaba que la batería pudiera fallar; el control que la
sesión del 2026-08-06 citaba como discriminante («spiritbox sigue fallando C7») **ya no falla**, se
arregló en el medio y la nota envejeció sin que nadie la tocara. Se compiló un control negativo
—la misma venda con `$scale` DESPUÉS de `$body`, el defecto que C1 existe para atajar— y **reprobó
C1 con 0,09 u** mientras el sujeto pasaba con 3,54. Recién ahí el 7/7 dice algo. El control se
borró después de medir.

**Pasada del autor: CONFIRMADA el mismo 2026-08-08, los dos ítems.** Textual: *«ya revisé ambas
ingame, está bien ahora. Tanto medkit como venda.»* Los PARCHES 2-3 pasan a `[APLICADO]`. Es el
único veredicto que importa acá: los siete checks de `verify_model.py` dicen que el `.mdl` está
sano, no que el modelo se vea bien — eso no lo puede decir ninguna batería.

**Y lo que esta pasada NO cubre, para que nadie lea «assets cerrados».** El autor miró los dos
ítems que cambiaron. Siguen pendientes de la sesión del 2026-08-05/06: los **cuatro
`$translucent`** (`bloodbag`, `pill_bottles`, `test_tubes`, `vials`) y sus artefactos de
ordenamiento, si `sutures` —1,97 u, el único que marca C1— se agarra con la physgun, y el
**bodygroup del `medkit_large` ABIERTO** (el autor vio el cerrado, que es el que quedó cableado a
la def; el abierto sigue siendo prop de escenario y nadie lo miró).

---

## PARCHES DE sesión El dolor como stat (COA-52) — DISEÑO, cero código — 2026-08-17

**Sesión de diseño. No se escribió una línea de Lua** — el no-negociable de su prompt
(`dev/PROMPT_coagulant_dolor.txt` §0, citando **COA-28**). El harness queda en **192 OK server /
142 client, ALL GREEN**, idéntico, porque no había nada que pudiera moverlo.

> **Por qué esta entrada existe y las dos anteriores no.** Las sesiones de diseño del 2026-08-08b
> (§17, COA-41…COA-48) y del 2026-08-09 (COA-49, COA-50/COA-51) **no dejaron entrada acá**:
> quedaron sólo en la arquitectura, en `ids.yaml` y en el estado. Pero el estado es **volátil y se
> reescribe en sitio**, así que el único rastro durable de esas dos es git más las subsecciones
> fechadas de §17. Pedido del autor el 2026-08-17: que las sesiones de diseño dejen rastro acá
> también. **Esta entrada abre esa práctica; no se retro-escriben las dos anteriores** (nunca se
> inventa un parche con fecha vieja) — se nombran en este recuadro, que es lo que se puede hacer
> sin falsear el registro.

**El disparador: el dolor ya se consumía sin haberse escrito.** Cinco consumidores con número
exacto —`bpm += pain × 0.22`, `StaminaCap -= pain × 0.35`, `pain > 80 → DAZED`, `pain > 85 → 0.10`
de irregularidad del ECG, y la puerta de la morfina `pain > 10`— y **cero productores**. Medido en
la sesión: **0 apariciones de `pain`** en los 13 archivos del `lua/`, con `blood` en **64** como
control positivo de la misma corrida. Y **COA-44** lo había promovido de diferido a **requisito**
de la niebla, así que el tramo no era opcional.

- PARCHE 1 — docs(arquitectura): subsección **COA-52** en `Coagulant_Architecture.md` §17 — la
  **sede**. Las seis decisiones votadas por el autor con la cuenta hecha, las **seis** colisiones
  contestadas, la **tabla de balance propuesta** (no escrita en `config.lua`, lista para que el
  tramo de código la copie) y lo que el tramo explícitamente **no** decide. **[APLICADO
  2026-08-17]**

  **Lo votado, en una línea cada uno:**
  1. **Agregación = suma con clamp** a `0..100`, peso de zona neutro ×1.0. Es lo que **salva las
     cuatro fórmulas**: la suma cruda da rango `0..700` ⇒ `bpm +154` y `StaminaCap −245`, y los
     umbrales 80 y 85 pierden sentido. El máximo no acumula (tres balazos en tres zonas duelen
     igual que uno) y el promedio ponderado vuelve `DAZED` **inalcanzable por trauma localizado**,
     que es el único trauma que este módulo modela.
  2. **La zona vive en la misma escala `0..100`** que el global; `PAIN_FULL_AT = 60` satura la
     **rampa** y no el estado (espejo de `ZONE_FULL_AT = 6`, que satura en dos heridas graves).
     Con eso una zona con dolor 7 pinta `t = 0.12`, no roja del todo.
  3. **Producción de tres ejes con UNA constante absoluta:** `PAIN_PER_WOUND 40 × PAIN_TYPE ×
     PAIN_SEVERITY`. `PAIN_TYPE` son los valores de **ACE3 literales** (Avulsion 1.0, VelocityWound
     0.9, ThermalBurn 0.7, Puncture 0.4, Contusion 0.3, Laceration 0.2), **citados como referente**;
     el eje de **severidad es NUESTRO** porque la tabla de ACE **no tiene ninguno** — ésa es la
     mitad que §1.4 del prompt advertía que no se podía copiar. Menos convexo que `BLEED_BASE`
     (1 : 1.9 : 2.9 contra 1 : 2.7 : 6.7) a propósito: la nocicepción satura y la hemorragia no.
  4. **El dolor NO se almacena y NO tiene reloj propio:** se deriva de las heridas con el mismo
     reparto que el score de §6 (activa 1.00 · tratada 0.35 · infectada **entera**). **El
     decaimiento del dolor ES el reloj `HEAL_S` de COA-49** — cero constantes de tasa, cero
     timers, cero acumuladores— y el síntoma gratis de COA-49 sale exacto **en sus dos mitades**:
     al pasar `t → i` el dolor **vuelve a subir** (0.35 → 1.00) y además **deja de bajar**.
  5. **Los analgésicos ponen techo, no restan**, y el modelo lo obliga: a un derivado no se le
     resta sin **almacenar la resta**. La única variable de estado nueva es `painSuppress` (el par
     `pain`/`painSuppress` de ACE3, recomendación de su D10); los cinco consumidores leen el
     **percibido**. `AddPainSuppression(ply, puntos)` reemplaza al inexistente
     `CoaAddDrug("morphine", 10)` — cuyo `10` eran **miligramos**, no puntos de dolor.
     Efecto de segundo orden que justifica la elección: **bajo niebla la morfina te CIEGA el
     diagnóstico**, porque el síntoma de COA-44 es el percibido ⇒ deja de ser un buff y pasa a ser
     un **costo de información**, y le da razón de existir a la naloxona de COA-50. La puerta
     `pain > 10` **se auto-limita** porque lee el percibido: el apilamiento no necesita regla nueva.
  6. **Isquemia y fractura generan dolor (como PISO); el torniquete NO.** Los dos con la misma
     forma que las cláusulas `max()` de `ZoneScore` (isquemia 60, espejo de `max(score, 6)`; `fx`
     30 y férula 12, espejo de `max(score, 3)`). El torniquete no duele porque **a los 90 s ya se
     vuelve isquemia**: un reloj, no dos. Conserva su −12 plano (oclusión mecánica) y la fractura
     **pierde** sus −15/−6 cuando la fórmula exista: un canal por causa, cero doble cobro.

  **La SEXTA colisión, que la sesión encontró y no estaba en la lista del prompt:** un `NW2` se
  replica a **todos** los clientes y **no tiene filtro por observador**, así que **un vital que la
  niebla puede ocultar no puede viajar por NW2**. Por eso el dolor va en el snapshot (owner-only) y
  no gana `NW2Float`, y por eso el server manda `p` por zona **siempre** y el cliente **nunca** lo
  deriva — dos ramas de la misma magnitud divergirían justo al cambiar la convar.

- PARCHE 2 — docs(arquitectura): §1 **deja de listar el dolor y los analgésicos entre los
  diferidos** (la **fractura con férula** se queda). Más §2 (`painSuppress` en el `st`, con el
  comentario de por qué el dolor **no** está ahí), §7 (nota sobre COA-37: el analgésico **no**
  entra a competir en `BandagePriority` porque no trata una herida, enmascara un síntoma), §9 (el
  dolor en el snapshot + la regla del NW2 + el cambio de predicado del emisor) y el preámbulo de
  §17, que ya no nombraba las cuatro enmiendas que la sección fue acumulando. **[APLICADO
  2026-08-17]**

- PARCHE 3 — docs: alta de **COA-52** en `corpus/docs/ids.yaml` con evidencia **`INTENCION`** — es
  diseño y no hay código que lo ejerza. **UNA norma con partes y no seis IDs** (§5 del prompt):
  ninguna de sus partes rige a otro módulo. Bloque `salud` **copiado de la corrida del checker**,
  no escrito a mano: **244 IDs / 76 INTENCION (31 %)**. `check-ids OK`. **[APLICADO 2026-08-17]**

- PARCHE 4 — docs: `coagulant_estado.md` (en sitio) y `coagulant_roadmap.txt`. En el estado se
  corrigió además la línea del «Próximo paso» §3, que **esta sesión volvió falsa** («la niebla
  depende del dolor como stat, que hoy sigue diferido por §1»). En el roadmap, la **trampa de orden**
  de [6] se reescribe: el orden obligado sigue vigente para la **bajada** (dolor → niebla) pero ya
  no bloquea el **diseño**. **[APLICADO 2026-08-17]**

- PARCHE 5 — docs: barrido de drift con `rg --no-ignore` sobre **3.473 archivos** de las siete
  raíces más `dev/`, buscando los ecos de «el dolor sigue diferido». Corregidos los **dos vivos**:
  `CLAUDE.md` (el «Estado actual») y `Coagulant_Architecture.md:650` (el cuerpo de COA-44, que
  decía «§1 lista el dolor entre los diferidos»). **Los del CHANGELOG y de
  `Coagulant_Block3_Semilla.md` NO se tocaron**: son registro histórico y eran ciertos cuando se
  escribieron — la semilla es explícitamente registro por §16.3. **[APLICADO 2026-08-17]**

**TRES CORRECCIONES AL PROPIO PROMPT, medidas antes de apoyarse en ellas.** Se escriben porque las
tres cambiaban el alcance del tramo, no porque sean anécdotas:

1. **La matriz son 15 celdas, no 18.** El prompt dice «6 tipos × 3 severidades = **15** celdas» y
   las dos cifras no cierran. Las 15 son las reales: `Config.WOUND_TYPES` tiene **CINCO** tipos. El
   sexto es **`punzante`**, que **COA-49 ya nombra** (*«`punzante` y `metralla` son sucias por
   naturaleza»*) y que **no existe en ninguna parte del árbol**. Su fila entra igual en `PAIN_TYPE`
   con el valor de ACE y queda **inerte** hasta que el tipo exista. Es por esto que la **forma** se
   votó antes que los valores.
2. **El doble cobro de §4.3 cuesta CERO migrar.** `StaminaCap`, `frac` y `splint` tienen **0 hits**
   en el `lua/`: los −12/−15/−6 viven **sólo en la fórmula del spec v5**, que no está implementada.
   Elegir hoy no toca un número vivo; elegir en tres rondas sí.
3. **§4.5 está sobredimensionada para el código de HOY.** Una herida `treated` **sigue en
   `zdata.wounds`** hasta que el Medkit la borra (`core.lua:185-192`) y su `tr` viaja en el
   snapshot, así que **hoy la zona tratada SÍ viaja**. La colisión es real y grave, pero **muerde
   recién con la forma `w[tipo] = {a,t,i,s}` de COA-49**. Anotado así para que nadie la busque hoy,
   no la encuentre, y concluya que no existe.

**Y UNA DEPENDENCIA QUE ESTABA ESCRITA AL REVÉS.** `dev/PROMPT_coagulant_menu_v5.txt` §4.3 dice que
COA-49 está bloqueada por el dolor. Es al revés: **el dolor CONSUME el reloj de COA-49**. Con la
forma de lista de hoy su término `i` lee 0 y es **exactamente neutro**, así que el dolor puede bajar
antes o junto con COA-49 — pero nunca la espera.

**DEUDA DECLARADA que esta sesión destapó y NO arregló**, para que el día que la niebla baje sea una
fila de su planilla y no un hallazgo: `NW2Float "coagulant_blood"` **ya** viaja a todos los clientes
y la **cifra** de sangre es capa de **diagnóstico** en la tabla de COA-44 — o sea que la niebla, tal
como está escrita, tiene un agujero **anterior** al dolor. No se toca acá porque mover ese NW2 rompe
la barra del StatusPanel de Cargo (§10) y la mini-barra del modo degradado.

**Lo que NO entró, y no es olvido:** una convar `coagulant_pain_scale` por simetría con
`bleed_scale`/`regen_scale` — nadie la pidió y el tuning ya lo permite la tabla (**COA-27**). Y la
**sobredosis** con naloxona como antídoto real, que es del tramo del catálogo; la puerta `pain > 10`
ya impide el apilamiento trivial.

**Verificación de esta sesión** (es de docs, así que no hay pasada en juego que correr): harness
**192 OK server / 142 client, ALL GREEN** —sin cambio, y tenía que no cambiar— y `check-ids OK: el
registro está limpio` sobre 244 IDs. **Nada commiteado ni pusheado.**

---

## PARCHES DE sesión Las cuatro médicas tienen precio — 2026-08-18

**El agujero es tan viejo como las defs, y no lo podía encontrar nadie usando este módulo.**
`Trade.IsTradeable` de Cargo exige `isnumber(def.value) and def.value > 0`, y en Cargo la
**ausencia** de `value` significa *«no está a la venta»*, **no** *«gratis»* (contrato 13 de su
CLAUDE.md). Las cuatro defs médicas nacieron sin `value`: un trader las **listaba** y el server se
negaba a moverlas. Coagulant **nunca vende nada**, así que ninguna pasada de este repo podía
notarlo — salió al escribir los dos traders de `corpus-stalker`, o sea **desde afuera**, y es el
mismo agujero que el handoff de ese tramo ya había medido en las 15 defs de comida de Craving.
Del lado médico no lo había mirado nadie.

- PARCHE 1 — `shared/corpus_coagulant_items.lua`: `value` en las cuatro. **Es data (COA-28 no se
  toca: no se implementa nada que la arquitectura no especifique, y un precio no es diseño
  clínico).** **[PENDIENTE]**

| ítem | `value` | de dónde sale |
|---|---:|---|
| Bandage | **8** | rollo de gasa compresiva de trauma, ~5-8 USD **(est.)** |
| Tourniquet | **35** | CAT genuino, ~32-35 USD **(est.)** — y es `unique` y **no se consume** |
| Medkit | **50** | botiquín grande equipado, ~45-60 USD **(est.)** |
| Blood Bag | **220** | una unidad de glóbulos rojos, costo de adquisición hospitalario ~215-250 USD **(est.)** |

**Los cuatro son estimaciones y así están etiquetados.** El método es el mismo que se usó para la
comida —anclar en el precio real del objeto que el ítem representa, en USD de EE.UU.—, pero **sin
serie publicada detrás**: la tabla de comida tenía anclas del FRED para el pan, la leche y la
gaseosa, y acá no hay equivalente. *Un número estimado presentado como medido es exactamente lo que
este proyecto persigue en todos lados,* así que la etiqueta va en el código, no sólo acá.

**Quedan POR DEBAJO de los suministros HL2 del propio Cargo** (`cargo_hl2_healthkit` 150,
`cargo_hl2_healthvial` 60), que no salen de un precio real sino de la banda de sus ítems dev. Es la
**misma asimetría** que la comida tiene contra la munición (2-12 contra 8-900) y tiene la misma
salida ya escrita: el multiplicador de precio por categoría de Cargo (su roadmap **61**,
`cargo_value_mult_<id>` replicada, **PEDIDO sin ratificar**). Estos números entran igual y ese
multiplicador los escala después. **No se compensa acá inflándolos**, porque entonces el
multiplicador escalaría una mentira.

- PARCHE 2 — `dev/harness_coagulant.py`: el control que habría cazado esto, en los **dos** realms.
  **No es una lista de cuatro**: recorre **todo lo que este módulo registre contra Cargo**, así que
  la def número cinco que alguien agregue mañana queda cubierta sin tocar la línea. *Una lista de N
  sólo encuentra los N que alguien ya sabía* — que es exactamente cómo estas cuatro se pasaron.
  Va con un **segundo** check que exige el valor **derivado** y no un positivo cualquiera: el
  primero pasa igual con un `1` puesto para callarlo. **[PENDIENTE]**

Se **restate** el criterio en vez de llamarlo, y hay que decirlo: el Cargo de este harness es un
**fake** (`MakeFakeCargo`), así que `Trade.IsTradeable` no existe de este lado y la copia puede
envejecer si Cargo cambia la regla. El que la corre de verdad, contra la función real, es
`harness_cargo.py`.

**Verificación:** harness **185 → 189 checks**, selftest **192 OK server / 142 client**, ALL GREEN,
exit 0. **Verificado en negativo, dos mutantes:** sin el `value` del bloodbag → 2 fallas por realm y
exit 1; con un `value = 1` de relleno en el medkit → el primer check **pasa** y el segundo lo caza,
que es precisamente para lo que está. **Falta la pasada en juego:** que un trader con categoría
`medical` liste las cuatro **con precio** y que el server deje comprarlas y venderlas.

---

## PARCHES DE sesión El bloqueante de Cargo cayó: barrido de drift — 2026-08-25

**Cero código y cero diseño nuevo.** Lo único que hace esta sesión es que las docs de este repo
dejen de afirmar algo que es falso desde el **2026-08-22**: que el pedido de **COA-51** seguía sin
ratificar y que por eso el área hospital no bajaba a código.

**Qué pasó del otro lado.** Cargo **ratificó el pedido y lo escribió** en tanda con su #65 — roadmap
**#60**, CHANGELOG **80**, commit `63c784f`, `corpus_cargo_containers.lua:646-741`, **server-only**.

**⭐ Y entregó CUATRO donde el pedido pedía TRES, por MEDICIÓN y no por criterio.** `AreaTakeUnique`,
gemela de `Inventory.TakeUnique`. La cuarta salió de que Cargo contara los llamadores reales en el
`lua/` **de este repo**: `treatment.lua:163` gatea con `HasItem` y `:170` consume con `TakeUnique`
**porque el torniquete es `unique`**. Con las tres pedidas, el área habría **visto** un torniquete en
un mueble y no habría tenido con qué consumirlo — **el fallo G4 exacto**, movido del lado de la
presencia al del **take**. Es decir: *la lección que el bloque de COA-51 invoca para exigir la tercera
se volvió a cobrar dentro de ese mismo bloque, y la cazó el dueño de la superficie contando
llamadores, no el pedidor releyendo su propia doc.* Vale como control de método: **un pedido escrito
desde el consumidor no está auditado por haberlo escrito el consumidor.**

**Segundo drift del mismo barrido, y es del tramo de precios:** el multiplicador por categoría que
la sesión del 2026-08-18 citaba como *«PEDIDO sin ratificar»* está **CERRADO EN JUEGO** desde el
2026-08-22 (Cargo #61, planilla AN 10/10). `medical` es una de las categorías que Cargo registra de
fábrica (`corpus_cargo_items.lua:94`) ⇒ **`cargo_value_mult_medical` existe hoy**, con lo que la
salida anotada para los cuatro precios médicos dejó de ser una promesa. **Los números no se tocan**:
la entrada del 2026-08-18 ya decía por qué no se compensa inflándolos.

- PARCHE 1 — docs(arquitectura): `Coagulant_Architecture.md` **§12** (la línea de Cargo pasa de
  *PEDIDO ABIERTO / no ratificado* a **ratificado y entregado**, con las cuatro y el porqué de la
  cuarta) y **§17** (el bloque *«la superficie que hay que pedirle a Cargo»* conserva el pedido como
  registro y gana la enmienda con la **semántica entregada** — `AreaCount` cuenta solo stacks,
  `AreaTake` es todo o nada y drena entre contenedores de fábrica antes que gastados (CRG-7), cada
  contenedor tocado se guarda y re-sincroniza; ya no hay que leer `_byId`). **[APLICADO 2026-08-25]**

- PARCHE 2 — docs(docs): `coagulant_roadmap.txt` [6] — el párrafo *BLOQUEANTE del area hospital*
  pasa a **CAÍDO**, con la vuelta de la dependencia escrita. **[APLICADO 2026-08-25]**

- PARCHE 3 — docs(docs): `coagulant_estado.md` — cabeza nueva del 2026-08-25 y **dos marcas ⚠ en
  sitio** sobre las dos frases viejas (la del #61 *«sin ratificar»* y la del #60 *«Hasta entonces el
  tramo no baja»*). Las frases **no se borran**: el estado acumula «Antes, …» y borrarlas dejaría el
  historial mintiendo en silencio; la marca dice qué quedó viejo y adónde mirar. **[APLICADO
  2026-08-25]**

- PARCHE 4 — docs(ids): `corpus/docs/ids.yaml` — **COA-51 enmendada**. El título deja de afirmar el
  bloqueo y enuncia el invariante que sí generaliza (*sólo superficie pública; se pide y se espera al
  dueño; nunca `_byId`*), y la nota gana el párrafo **CUMPLIDA**. **La evidencia sigue en
  `INTENCION`** y hay que decir por qué: sigue sin una línea de Lua **de este lado**, que es otra cosa
  que estar bloqueada. **[APLICADO 2026-08-25]**

**⚠ LA DEUDA SE DIO VUELTA, y es lo que hay que llevarse de esta sesión.** Cargo dejó la **pasada en
juego** de su #60 **diferida hasta que exista el área hospital**, por ser su **único consumidor** —
una planilla sobre un llamador que no existe vuelve a medir el harness y no el juego. Hasta el
2026-08-22 el que bloqueaba era Cargo; **desde el 2026-08-22 el que bloquea es este repo**, y cuando
el área baje a código esas filas viajan con ella.

**Y de la misma sesión sale el prompt del tramo siguiente, que NO es un parche de este repo
porque `dev/` está afuera de git:** `dev/PROMPT_coagulant_dolor_codigo.txt` — la bajada a código de
**COA-52**, con el mapa de toques anclado al código de hoy, las trampas medidas (entre ellas que el
score reparte las tratadas a `0.5` y el dolor a `0.35`, dos números distintos en funciones vecinas) y
la verificación en negativo obligatoria. **Trae una pregunta sin votar y está escrita como pregunta,
no como decisión** (COA-28, la lección de COA-37): bajado solo, el dolor **no tiene un solo consumidor
en juego**, así que su pasada sería por consola — o baja pelado con su planilla diferida, o baja con
el analgésico oral y el dolor en el menú médico, que es diseño y lo vota el autor.

**Verificación.** No se tocó Lua, así que no había nada que pudiera moverse — **pero el harness se
corrió igual**, porque un ALL GREEN heredado de la sesión anterior y citado sin medir es la mitad
exacta del drift que esta sesión vino a arreglar: `dev/harness_coagulant.py` **189 checks, 0 fallos,
ALL GREEN, exit 0**; selftest **192 OK server / 142 client**. El registro de IDs se validó con
`corpus/.claude/check-ids/corpus_check_ids.ps1`.

---

## PARCHES DE sesión El dolor baja a código (COA-52) + el analgésico oral — 2026-08-25

Ejecución de `dev/PROMPT_coagulant_dolor_codigo.txt`. **COA-52 se votó el 2026-08-17 con la
tabla de balance escrita y cero Lua; esta sesión la COPIA a código.** El diseño no se
re-discutió: los seis puntos, las seis colisiones y los números vienen de §17 y se bajaron
tal cual, comentarios incluidos.

> **⚠ LA PREGUNTA DEL §3.1 SE CONTESTÓ POR DELEGACIÓN, y se escribe así para que se pueda
> vetar barato.** El prompt traía UN eje sin votar —bajado solo, el dolor **no tiene un solo
> consumidor en juego**, así que su pasada sería por consola— y el autor delegó el voto
> (*«Hace votos sobre la pregunta que ibas a formular»*). Los votos son **míos, no del
> autor**, y están marcados como tales acá, en el estado y en la planilla. **COA-28 no se
> saltea: se difiere.** Si el autor no está de acuerdo con alguno, el costo de revertirlo es
> el PARCHE 6 entero y tres líneas de UI — nada más cuelga de ahí.
>
> - **§3.1 → (B) en su forma MÍNIMA.** Entra el **analgésico oral** como quinto ítem médico y
>   el dolor **como número** en el menú médico. Motivo, con la cuenta hecha: es exactamente
>   la situación que Cargo declaró en su #60 — *una planilla sobre un llamador que no existe
>   vuelve a medir el harness y no el juego*—, y un tramo que sólo se puede ver en el harness
>   es el que después se cita como verificado (nº 42 del catálogo de controles). **NO entra
>   la morfina**: su constante está votada (`PAIN_SUPPRESS.morphine = 80`) pero su ítem
>   arrastra la sobredosis y la naloxona, que son del tramo del catálogo (COA-50).
> - **§3.2 → la silueta NO se toca.** Se sigue pintando con el SCORE. La rampa de dolor
>   (`PainFrac`) existe y está verificada, pero **no la llama nadie que pinte**: es de la
>   niebla (COA-44) y baja con ella. Cambiar hoy lo que el jugador ve sería diseño de UI sin
>   votar.
> - **Los CINCO campos del ítem que COA-52 no especificaba** —clase, peso, tiempo, `value` y
>   `can()`— se votaron aparte y con su cuenta, y viven comentados arriba de la def: clase
>   `stackable` (el único `unique` del set es el torniquete, y su razón —se OCUPA mientras
>   está puesto— no aplica a un frasco), peso **0.1** (el escalón de la venda), tiempo **3 s**
>   (entre el torniquete y la venda), `value` **10** (frasco de venta libre, ~8-12 USD,
>   **estimación etiquetada como tal**, mismo método que los otros cuatro) y `can()` = la
>   puerta `pain > PAIN_ANALGESIC_AT`, que **no es un número nuevo**: es el `pain > 10` que el
>   spec v5 ya tenía escrito para la morfina y que COA-52 deja donde está.

- PARCHE 1 — feat(config): bloque **Dolor (§17, COA-52)** en
  `shared/corpus_coagulant_config.lua`, copiado literal de la tabla de §17 con sus
  comentarios: `PAIN_MAX`, `PAIN_FULL_AT`, `PAIN_PER_WOUND`, `PAIN_TYPE` (los valores de ACE3
  **literales**, con la fila inerte de `punzante`), `PAIN_SEVERITY`, `PAIN_TREATED_MULT`,
  `PAIN_INFECTED_MULT`, los tres pisos de D6, `ZONE_PAIN_WEIGHT`, la supresión y su
  decaimiento. Más las dos funciones puras: `Config.PainFromWound(tipo, sev)` y
  `Config.PainFrac(pain)` —espejo literal de `ZoneDamageFrac`—. Va **entre `WOUND_TYPES` y el
  bloque de tratamiento** por una razón mecánica: `TREATMENTS.painkillers` lee
  `PAIN_SUPPRESS.oral`, así que la tabla tiene que existir antes. **NO se acuña
  `coagulant_pain_scale`**: COA-52 lo niega por escrito, y hay un check que lo mide — una
  decisión de NO hacer algo es invisible salvo que alguien la mida. **[PENDIENTE]**

- PARCHE 2 — feat(core): el dolor en `server/corpus_coagulant_core.lua`. `NuevoEstado()` gana
  `painSuppress = 0` (lo **único** que el dolor almacena); `COAGULANT.ZonePain(ply, zone)` al
  lado de `GetZoneScore` y con su misma forma de recorrido; `GetRawPain` = Σ zonas ×
  `ZONE_PAIN_WEIGHT` **con clamp**; `GetPain` = `clamp(raw − painSuppress)`;
  `AddPainSuppression`, que **ensucia el snapshot** porque el percibido acaba de cambiar.
  **⚠ El reparto de las tratadas es `0.35` y NO el `0.5` de la función de al lado**: son dos
  números distintos a propósito (uno es debuff, el otro nocicepción) y copiar el vecino no da
  ningún síntoma. Los términos de **infección** (COA-49) y **fractura** (§1) se escriben y
  leen 0: sus ramas son **inalcanzables** con el árbol de hoy y está dicho en el comentario.
  **[PENDIENTE]**

- PARCHE 3 — feat(bleeding): el decaimiento de `painSuppress` en el tick de 1 s que **ya
  existía** (el dolor no necesitaba reloj propio), y el dolor en el snapshot: cada zona gana
  `p` (redondeado) y el blob gana `pain`, el **percibido** global. **⚠ El decaimiento ensucia
  el snapshot SÓLO si el número se movió de verdad**: el percibido cambia al decaer aunque
  nadie toque una herida, pero ensuciar siempre convierte el emisor on-change de COA-16 en un
  emisor por segundo — y eso no da ningún error, da tráfico multiplicado por jugador. El
  predicado del emisor pasa a *«aporta dolor ≠ 0, torniquete o isquemia»*. **La supresión NO
  viaja**: es capa de diagnóstico y este tramo no abre canales que la niebla todavía no sabe
  filtrar. **[PENDIENTE]**

- PARCHE 4 — feat(hud): `HUD.ZonePain(zona)` y `HUD.Pain()` en el cliente, que **LEEN** el
  snapshot. Prohibido derivarlos (COA-52, sexta colisión). El precedente de al lado —
  `ScoreZona`, que sí duplica la fórmula del server — **queda como está y no es precedente**:
  el score no es un vital que la niebla pueda ocultar. **[PENDIENTE]**

- PARCHE 5 — docs(init): el bloque CONTRATO nombra las cuatro funciones de dolor y la línea
  del snapshot dice que el dolor viaja ahí y **no** por NW2, con el motivo en una línea: un
  NW2 se replica a todos los clientes y no tiene filtro por observador. **[PENDIENTE]**

- PARCHE 6 — feat(items) + feat(treatment): el **analgésico oral**. `TREATMENTS.painkillers`
  (3 s, `suppress = PAIN_SUPPRESS.oral`), la def `corpus_coagulant_painkillers` contra Cargo
  con `pain_pills.mdl` —modelo ya portado desde el 2026-08-05 y que `ASSETS.md` listaba como
  el candidato para el día que el analgésico se abriera—, la puerta en `ApplyTreatment`
  leyendo el **percibido**, y el efecto en `Completar`. Nace también
  `Config.TREATMENT_NO_ZONE` (hoy `bloodbag` + `painkillers`): la pregunta *«¿este
  tratamiento usa zona?»* se hacía con un `kind == "bloodbag"` repetido en **tres** archivos,
  y así es como el quinto tratamiento se olvida en dos de ellos. **[PENDIENTE]**

- PARCHE 7 — feat(medmenu): el dolor por zona como número bajo el *Damage score*, el
  percibido global en la cabecera, y el botón **Painkillers** — grisado cuando el percibido
  no llega a la puerta, que es lo que vuelve **visible** la propiedad por la que COA-52 no
  escribió una regla de apilamiento. Cinco botones ya no entran en una fila con el de
  cancelar al lado, así que la cancelación baja a su propia fila: reflujo mecánico, no
  rediseño. **[PENDIENTE]**

- PARCHE 8 — feat(dev): `coagulant_status` imprime el dolor por zona y, en **renglón propio y
  corto** (la consola de GMod trunca en 255), el global **en sus dos formas** más la
  supresión vigente y su tasa. Que imprima las dos no es adorno: es lo único que distingue
  *«no duele»* de *«está tapado»*, que es exactamente el estado que el analgésico fabrica.
  `coagulant_dev_give` entrega 2 analgésicos. El **selftest** crece con la parte del dolor que
  se puede mirar desde adentro del juego. **[PENDIENTE]**

- PARCHE 9 — test(dev): `dev/harness_coagulant.py` pasa de **189 a 275 checks**, todos verdes.
  Las 86 filas nuevas **citan COA-52** (85 de las 86) —lo exige la evidencia del registro— y arrancan con su
  **familia** (`DOL-F/Z/A/S/N/I/C`), que es lo que le permite al control negativo medir su
  alcance. Además, dos checks viejos dejaron de contar 4 defs a mano y ahora **derivan** el
  número de `Config.TREATMENTS`: una lista de N sólo encuentra los N que alguien ya sabía.
  **[APLICADO 2026-08-25]** (es harness, se verifica corriéndolo)

- PARCHE 11 — test(dev): `dev/verificar_arbol_sabotaje.py` — control de HIGIENE del árbol tras una
  corrida de sabotaje interrumpida, genérico (toma el script de sabotaje como argumento). Nace
  porque esta sesión lo pagó: al matar la corrida colgada, el padre siguió y restauró unos sí y
  otros no, y quedó **una sola línea de sabotaje viva** que el harness igual daba verde. Corre con
  su control positivo hecho (se ensucia una línea a propósito y tiene que dar rojo). **[APLICADO
  2026-08-25]**

- PARCHE 10 — test(dev): `dev/sabotaje_coagulant_dolor.py` — verificación en negativo con
  **30 sabotajes** y **3 no-detectables declarados**, en el molde de `sabotaje_cargo_61.py`
  con la mejora del 2026-08-24: **cada sabotaje declara qué familias tiene que teñir** y el
  arnés falla en las **dos** direcciones. **[APLICADO 2026-08-25]**

**LA VERIFICACIÓN EN NEGATIVO AUDITÓ AL QUE LA ESCRIBIÓ, y es la mitad que justifica declarar
el alcance.** La primera corrida de los 30 sabotajes dio **cuatro** problemas y **tres eran defectos
de MIS CHECKS**, no del código:

- **El arnés se COLGÓ en vez de dar rojo.** El sabotaje que pone el decaimiento en `0` hace que el
  plazo derivado (`oral / DECAY`) sea **infinito**, y el `for` que lo recorría no terminaba nunca. La
  fila de arriba *comprobaba* que el plazo fuera finito y **no lo usaba para nada**: una precondición
  que se comprueba pero no **gatea** es prosa. Y el síntoma es peor que un rojo — un arnés colgado no
  se distingue de uno lento, y costó ~30 minutos de mirar un proceso vivo. El arreglo es un tope en
  el propio `for`.
- **Un check MATABA la pasada en vez de medir.** Con el `p` fuera del snapshot, mi fila hacía
  aritmética sobre un campo ausente y tumbaba el realm entero: rojo, sí, pero **sin poder repartirlo
  por familia** — y un realm tumbado se lee como *«el módulo no carga»*, que es la conclusión
  inversa. Ahora todo lo que lee el blob lee con default.
- **Un check HARDCODEABA un número** (`PainFromWound("corte", 1) == 2.8`) justo en el repo donde
  COA-35 lo prohíbe, y por eso se ponía rojo al tocar `PAIN_SEVERITY`, un eje que no tiene nada que
  ver con lo que esa fila mide. **Lo cazó la segunda dirección del arnés** —`EL CONTROL SE PASA`—,
  que es la que se olvida porque el rojo de más se lee como celo.
- **Y dos líneas no tenían quién las mirara**, las dos descubiertas por sabotajes que salieron
  VERDES: que `AddPainSuppression` ensucie el snapshot *por sí misma* (las dos filas que lo miraban
  lo ensuciaban a mano o dejaban que lo hiciera el tick), y que un tratamiento sin zona viaje con
  `chest` y no con `nil`. La segunda necesitó un caso que no existía en el banco: **el analgésico
  pedido con el cuerpo sin una sola herida abierta** — posible porque una zona isquémica duele 60 sin
  herida. El arreglo fue **agregar los checks que faltaban**, no aflojar la declaración.

Sólo **uno** de los cuatro era una declaración incompleta y no un defecto: borrar el piso de isquemia
también tiñe `DOL-I`, porque la isquemia es hoy el **único** mecanismo capaz de producir dolor sin
una herida abierta, o sea el único fixture con el que ese caso se puede construir. Eso se declara,
que es lo útil: dice que las dos familias comparten un mecanismo.

**LO QUE ESTA SESIÓN APRENDIÓ Y NO ESTABA EN NINGÚN LADO — la trampa de COA-35.** *Un check
que DERIVA su esperado de la constante no puede auditar esa constante.* `ZonePain(tratada) ==
base × PAIN_TREATED_MULT` sigue **verde** con el mult puesto en `1.0` (o sea, con la venda sin
aliviar nada), y `painSuppress == inicial − N × DECAY` sigue **verde** con la tasa en `0` (o
sea, con el analgésico que no se pasa nunca). Las dos constantes se vuelven incomprobables
**justo por la disciplina que las hace tuneables**. Lo que las caza son las filas que miden la
**propiedad**: *vendar ALIVIA* y *el efecto SE PASA*. Los dos casos se **vieron fallar** con
los sabotajes #3 y #13. Regla que queda escrita en §17: **por cada constante de balance, una
fila derivada (qué vale) y una fila de propiedad (para qué está).**

**Y UNA FILA QUE SE DECLARÓ EN VEZ DE ACREDITARSE**, porque el prompt lo mandaba y porque es
honesto: el cambio de predicado del emisor —de *«tiene heridas»* a *«aporta dolor ≠ 0»*—
**no puede fallar hoy**. Toda herida de los cinco tipos vivos produce dolor > 0, así que los
dos predicados seleccionan el **mismo** conjunto; la diferencia aparece recién con una zona
cuyo único contenido sea `frac`, y nada del árbol escribe ese campo. Está corrido como
**no-detectable declarado** en el sabotaje, exigiendo verde: el día que se ponga rojo, el
límite del instrumento cambió y esta nota envejeció. Lo que **sí** sostiene la equivalencia es
otro check —`PAIN_TYPE` cubre todo `WOUND_TYPES`—, sin el cual un tipo de herida nuevo sacaría
su zona del snapshot **en silencio**.

**Verificación.** `dev/glua_check.py` 13/13 parsean. `dev/harness_coagulant.py`: **275 checks,
0 fallos, ALL GREEN, exit 0**; selftest **221 OK server / 161 client**. Verificación en
negativo: `dev/sabotaje_coagulant_dolor.py`. Registro de IDs validado con
`corpus/.claude/check-ids/corpus_check_ids.ps1`. **Falta la pasada en juego** — planilla en
`dev/checks/coagulant-dolor-r1.html`; para código de addon GMod, *verificado* = confirmado en
juego, y por eso los parches 1-8 nacen `[PENDIENTE]`. La planilla está publicada como
artefacto: https://claude.ai/code/artifact/f9e534e3-2843-453c-88bf-e786e6778cd1

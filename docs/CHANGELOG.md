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
  **0.54°/4.05°** (idle/ADS). **[PENDIENTE]**

- PARCHE 2 — feat(hud): el hook `CreateMove` rampa el factor de ADS con
  `math.Approach` en vez de leer el clic derecho como un booleano. Solo se rampa la
  **amplitud**: la fase del bamboleo nunca se corta, así que la mira se abre y se cierra
  en lugar de dar un tirón. El paso se clampea a 0.1 s de frame para que un tirón de FPS
  no teletransporte la rampa, y `CortarSway` la resetea junto con el offset.
  **[PENDIENTE]**

- PARCHE 3 — test(dev): el selftest cubre la curva (extremos exactos, simetría en 0.5,
  clamp), que la rampa crezca monótona de idle a ADS y que su mitad caiga entre las dos
  capas; los checks de amplitud dejan de hardcodear 0.70 y se derivan de
  `SWAY_PER_SCORE` (si no, retunear el número rompía el selftest en vez de validarlo).
  **[PENDIENTE]**

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
  herida entera: se traduce en UN lugar, no en cada llamador). **[PENDIENTE]**

- PARCHE 2 — feat(hud): la silueta de 6 zonas y la barra de tratamiento. Color por
  score en dos tramos (sano → amarillo → rojo: un lerp directo de verde a rojo se come
  el amarillo), **la zona sangrante LATE** —la única señal que hay que ver sin leer
  nada—, banda azul de torniquete que se pone morada con la isquemia, y **la silueta se
  desvanece sola** cuando el cuerpo está sano y la sangre llena (un corte seco se lee
  como un bug del HUD). Todo el pintado va en `pcall` con aviso una sola vez. La
  superficie `COAGULANT.HUD` (score/sangrado/datos de zona por snapshot) queda expuesta
  para que el menú médico lea **el mismo estado**, nunca uno propio. **[PENDIENTE]**

- PARCHE 3 — feat(hud): barra de sangre en el **StatusPanel de Cargo** (§10/§12) —
  `RegisterBar("coagulant", {id="blood", getValue=ply→NW2 0..100})`, con lazy-check en
  `Corpus.OnReady`, jamás en file-scope (el orden de mount no está garantizado). **Sin
  Cargo la sangre no desaparece:** el HUD propio pinta una mini-barra bajo la silueta —
  la información vital no puede depender de un soft-dep (§14). **[PENDIENTE]**

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
  abierto. **[PENDIENTE]**

- PARCHE 5 — feat(options): el tab Q deja de ser el cartel del scaffold — convars de
  cliente y de server, binder del menú médico, detección de soft-deps **con lo que
  implica cada ausencia** (sin Cargo: tratamiento degradado; sin Caliber: hit-location
  por hitgroup crudo) y la lista de comandos de verificación. **[PENDIENTE]**

- PARCHE 6 — test(dev): el selftest cubre lo puro del slice — que la silueta cubra las
  6 zonas sin repetirlas ni salirse de su caja, que **el centro de cada rect pintado
  resuelva a su propia zona** (el contrato entre lo que se ve y lo que se clickea), la
  saturación del color, la barra de tratamiento en sus tres puntos y la traducción del
  snapshot; en realm cliente, que la superficie `COAGULANT.HUD` exista completa.
  **[PENDIENTE]**

- PARCHE 7 — chore(init): el manifest suma `medmenu` (client, **después** de `hud`: lee
  su silueta), el header y el log de boot pasan a "Block 3 slice 4". Las convenciones de
  commits ganan el alcance `medmenu`. **[PENDIENTE]**

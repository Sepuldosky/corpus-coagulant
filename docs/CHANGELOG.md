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
  quedan **sin cambio**: el doc ya era correcto, se alinea el código. **[PENDIENTE]** (verificación
  en juego del autor — flujo §1 PASO 4)

Verificación: PARCHES 1-2 sin superficie de runtime (solo docs). PARCHE 3 toca `server/treatment`
(realm server) — nace **[PENDIENTE]** hasta la pasada en juego; el selftest/harness siguen en verde
por construcción (170 OK server / 132 client), pero el «nunca CountItem» solo se confirma probando
un tratamiento con stackable en juego. Cambios trazables al acta (§7.1: el código manda). No
commiteado ni pusheado (GIT-7).

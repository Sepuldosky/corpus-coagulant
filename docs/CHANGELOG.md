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
  de cancelación. **[PENDIENTE]**

- PARCHE 2 — feat(treatment): `server/corpus_coagulant_treatment.lua` — motor
  server-authoritative (§7/§9): `ApplyTreatment(ply, kind, zone)` con zona
  automática por tipo y validaciones (ocupado, zona/extremidad, HP/sangre llenos,
  ítem presente con Cargo, cooldown sin Cargo), tick fino de 0.25 s (completar a
  término + cancelar por velocidad), cancelación por daño real (el drenaje propio
  NO cancela) y por salto, **consumo AL COMPLETAR** (`TakeItem` re-validado; el
  torniquete nunca se consume), torniquete toggle poner/quitar con isquemia
  persistente, eventos `Coagulant_TreatmentStart/Complete/Cancel`, intents de net
  `treat`/`cancel` (server re-valida todo), y `ApplyBandage` = azúcar del contrato.
  **[PENDIENTE]**

- PARCHE 3 — feat(items): set v1 completo contra Cargo — Bandage (stackable 0.1),
  Tourniquet (unique 0.2, no consumible), Medkit (stackable 0.5), Blood Bag
  (stackable 0.3), categoría `medical`, trivia de cara al jugador en inglés;
  `onUse` fabricado que devuelve **false** e inicia el tratamiento (aviso por chat
  si no puede). El debug `coagulant_bandage` queda como efecto instantáneo
  explícitamente rotulado. **[PENDIENTE]**

- PARCHE 4 — feat(core): `WorstBleedingZone` (zona automática), isquemia impone
  piso de score en `GetZoneScore` (§7), `freeCooldownAt` en el estado; el efecto
  puro `BandageEffect` queda como primitiva del motor. **[PENDIENTE]**

- PARCHE 5 — test(dev): selftest cubre `TREATMENTS`/`EXTREMITIES`, arranque con
  +25% por brazo herido, doble-tratamiento rechazado, cancelación, torniquete
  rechazando zonas no-extremidad, y las 4 defs si Cargo está (ambos realms);
  `coagulant_status` muestra el tratamiento en curso. **[PENDIENTE]**

- PARCHE 6 — chore(init): manifest suma `treatment` (después de bleeding), bloque
  CONTRATO gana `ApplyTreatment`; log de boot → "Block 3 slice 2". Convenciones de
  commits ganan los alcances `config` y `treatment` (el mapa de archivos creció).
  **[PENDIENTE]**

- PARCHE 7 — test(dev): `coagulant_dev_give` (admin, requiere Cargo) — entrega el
  kit médico de prueba (3 vendas, 1 torniquete, 2 medkits, 2 bolsas). Nace del
  primer intento de la ronda 3 (2026-07-13): el `lua_run` con los cuatro `GiveItem`
  **se trunca en la consola de GMod** (límite de largo del comando) y tira
  `')' expected near '<eof>'` — lección: los comandos de checklist deben ser
  concommands cortos, nunca lua_run largos. **[PENDIENTE]**

Nota — ronda 3 interrumpida en G1 por lo anterior (el resto de la sección G quedó
sin correr); A-F re-confirmadas ✓ por el autor en la misma ronda. La ronda 3 se
repite con el comando nuevo.

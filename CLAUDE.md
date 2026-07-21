# CLAUDE.md

Guía para trabajar en **Coagulant** — el módulo médico de jugador del ecosistema Corpus (addon GLua para Garry's Mod). Léela antes de tocar código o docs de este repo.

## Qué es

Coagulant es el módulo **médico de jugador** del ecosistema Corpus, estilo ACE3: heridas por zona, sangrado, vitales y tratamiento. Es un addon Gmod independiente con su propio git, que **hard-depende** de Corpus (la única dependencia dura del ecosistema) y de nadie más. Detecta a otros módulos en runtime vía `Corpus.GetModule`/`Corpus.HasModule`, nunca los asume: **Caliber** (hit-location enriquecido) y **Cargo** (ítems médicos) son soft-deps con degradación honesta — sin Caliber, hit-location por hitgroup crudo del engine; sin Cargo, tratamiento por vía mínima propia. Ver §2, §4-§5 de `../corpus/docs/CORPUS_Architecture.md`.

**Estado actual: BLOCK 3 CERRADO (ronda 7, 2026-07-20).** El diseño está en [`docs/Coagulant_Architecture.md`](docs/Coagulant_Architecture.md) (ratificado por el autor el 2026-07-13; números de balance tunables). Los **4 slices están verificados en juego** (rondas 1-7; la 7 cerró la UI, el sway retuneado y el modo degradado sin Cargo). Pendiente chico: la **mini-ronda 8** (sesión «Fix ronda 7» del CHANGELOG: tecla del menú por poleo + reset limpio del selftest) y **dos decisiones de diseño abiertas** — ver [`docs/coagulant_estado.md`](docs/coagulant_estado.md). **COA-28 — No implementes nada que la arquitectura no especifique** — cambios de diseño se discuten con el autor y se anotan primero en el doc.

**Regla cardinal (cita COR-10 y COR-1):** nada de lógica de dominio sube a Corpus, y la lógica ajena no baja acá: el hit-location enriquecido es de Caliber, el contenedor/grid/peso de los ítems es de Cargo. Coagulant posee solo la medicina (qué hace una venda, cómo sangra una zona).

## Docs del proyecto — jerarquía de lectura

Antes de tocar código o diseño, lee en este orden (los tres primeros son **docs vivos**):

1. **Estado de HOY** → [`docs/coagulant_estado.md`](docs/coagulant_estado.md). Foto del AHORA, ≤1 pantalla. **Léelo ANTES** que la arquitectura.
2. **Rumbo** → [`docs/coagulant_roadmap.txt`](docs/coagulant_roadmap.txt). Qué sigue y en qué orden.
3. **Historial de parches** → [`docs/CHANGELOG.md`](docs/CHANGELOG.md). `[PENDIENTE]`/`[APLICADO YYYY-MM-DD]`, nunca se borra ni renumera.
4. **Metodología de trabajo** → [`../corpus/docs/corpus_flujo_trabajo.txt`](../corpus/docs/corpus_flujo_trabajo.txt). **Doc canónico compartido** por todo el ecosistema — no se duplica acá.
5. **Arquitectura del módulo** → [`docs/Coagulant_Architecture.md`](docs/Coagulant_Architecture.md) (Block 3: sustrato v1 — **ratificado por el autor el 2026-07-13**; los números de balance son propuesta tunable por convar). La frontera general sigue en `../corpus/docs/CORPUS_Architecture.md` §2, §4-§5; la semilla con el registro de decisiones en [`docs/Coagulant_Block3_Semilla.md`](docs/Coagulant_Block3_Semilla.md).
6. **Convenciones de commit** → [`docs/coagulant_convenciones_commits.txt`](docs/coagulant_convenciones_commits.txt). Alcances específicos de **este** repo.

## Idioma

- **Código (comentarios): español** (estilo corpus/caliber; Cargo es la excepción en inglés). Iguala el del archivo que edites.
- **Strings de cara al jugador (UI, nombres de ítems): inglés** — es el idioma del mod (decisión del autor, fijada en Cargo el 2026-07-10).
- **Docs, commits y logs (`Corpus.Log`): español**; los `<tipo>` de commit en inglés (ver convenciones).

## El workspace multi-repo

Este repo (`corpus-coagulant/`) es una de **siete** raíces git del workspace `corpus.code-workspace` (ocho carpetas: las siete más `dev/`, que no es repo y nunca se publica). La raíz `corpus/` es el framework del que todos hard-dependen; otras cuatro (`corpus-cortex/`, `corpus-caliber/`, `corpus-craving/`, `corpus-cargo/`) son módulos hermanos que se detectan en runtime, nunca se asumen. La séptima, [`corpus-stalker/`](../corpus-stalker/), no es un módulo sino el **addon de contenido** de S.T.A.L.K.E.R. (anomalías, artefactos, PDA, detectores, defs de ítem y de NPC): consumidor puro del framework y de los módulos — **nada de su contenido baja acá**, Coagulant es genérico y no sabe nada de la Zona. Al diseñar integración con mods ajenos, consulta `../dev/mods_workshop_mapa.md` (RECICLAR vs. COMPAT-RUNTIME).

## Mapa de archivos

Un **manifest de carga explícito** (`corpus_coagulant_init.lua`, único archivo en `lua/autorun/`) registra el módulo, declara el contrato público y hace `include()` en orden determinista — patrón template tomado de Caliber (boot diferido a `Initialize` — cita **CAL-1** —, sonda `CorpusListo`, falla ruidoso sin framework). Los sub-archivos viven en `lua/corpus_coagulant/<realm>/`, **fuera** de `lua/autorun/`.

| Archivo | Realm | Rol |
|---|---|---|
| [`lua/autorun/corpus_coagulant_init.lua`](lua/autorun/corpus_coagulant_init.lua) | shared | Entry + registro (`coagulant`) + **bloque CONTRATO** (arquitectura §8) + manifest |
| [`lua/corpus_coagulant/shared/corpus_coagulant_zones.lua`](lua/corpus_coagulant/shared/corpus_coagulant_zones.lua) | shared | Zonas clínicas (7 — COA-8, enmienda 2026-07-21) + mapa hitgroup nativo → zona, fallback `chest` (**la vía de degradación sin Caliber** — puro, sin hooks) |
| [`lua/corpus_coagulant/shared/corpus_coagulant_config.lua`](lua/corpus_coagulant/shared/corpus_coagulant_config.lua) | shared | Convars + tablas de balance + funciones puras (§3-§5, §11): `WoundTypeFromDMG`, `SeverityFromDamage`, `BleedRate`, `HPDrainRate` |
| [`lua/corpus_coagulant/shared/corpus_coagulant_dev.lua`](lua/corpus_coagulant/shared/corpus_coagulant_dev.lua) | shared | `coagulant_selftest` + comandos de verificación `coagulant_status` / `coagulant_setblood` (admin) |
| [`lua/corpus_coagulant/server/corpus_coagulant_core.lua`](lua/corpus_coagulant/server/corpus_coagulant_core.lua) | server | Estado clínico v1 + **heridas en `PostEntityTakeDamage` con daño final** (hitgroup capturado en `ScalePlayerDamage`, guard `_selfDrain`) + eventos `Coagulant_*` + contrato de lectura + efecto venda (`BandageEffect`/`ApplyBandage`) + `OnEncumbrance` (stub del contrato de Cargo) |
| [`lua/corpus_coagulant/server/corpus_coagulant_bleeding.lua`](lua/corpus_coagulant/server/corpus_coagulant_bleeding.lua) | server | Timer único 1 s (§4-§5): drenaje, regen natural, HP crítico (`DMG_GENERIC` + "You bled out."), NW2 `coagulant_blood`, snapshot on-change (`corpus_coagulant_state`) |
| [`lua/corpus_coagulant/server/corpus_coagulant_treatment.lua`](lua/corpus_coagulant/server/corpus_coagulant_treatment.lua) | server | Motor de tratamiento (§7/§9): `ApplyTreatment`/`CancelTreatment`, tick 0.25 s, cancelación por daño/salto/velocidad, **consumo al completar**, torniquete toggle + isquemia, eventos `Coagulant_Treatment*`, intents net `treat`/`cancel` |
| [`lua/corpus_coagulant/server/corpus_coagulant_debuffs.lua`](lua/corpus_coagulant/server/corpus_coagulant_debuffs.lua) | server | Debuffs (§6): tick 0.5 s (la isquemia entra y sale sola por tiempo), `GetLegScore`/`GetArmScore`/`RefreshSpeed` (publica `NW2Float "coagulant_speed_mult"`; **el sway y la visión son de CLIENTE**, ver `hud`) |
| [`lua/corpus_coagulant/shared/corpus_coagulant_move.lua`](lua/corpus_coagulant/shared/corpus_coagulant_move.lua) | shared | Hook `Move`: **aplica** la cojera escalando `mv:SetMaxSpeed` (nunca `SetWalkSpeed` → compone con el movecompat de Cargo). Shared porque `Move` es **predicho** |
| [`lua/corpus_coagulant/shared/corpus_coagulant_items.lua`](lua/corpus_coagulant/shared/corpus_coagulant_items.lua) | shared | Set v1 de 4 defs contra Cargo (Bandage/Tourniquet/Medkit/Blood Bag, `onUse` → `false` + inicia tratamiento) + `coagulant_bandage` (debug instantáneo, server). **Shared obligatorio (cita COR-12): Cargo no sincroniza defs por net** — registrarlas solo en server = ítem invisible en la UI (pagado el 2026-07-13) |
| [`lua/corpus_coagulant/client/corpus_coagulant_hud.lua`](lua/corpus_coagulant/client/corpus_coagulant_hud.lua) | client | Estado replicado (`COAGULANT.ClientState`, receptor del snapshot) + sway + capa de visión (vignette elíptico, fade a negro, sangre crítica) + **silueta de 7 zonas, barra de tratamiento y la barra de sangre en el StatusPanel de Cargo**. Expone `COAGULANT.HUD` (score/sangrado por zona + `DrawSilhouette`), que el menú médico consume |
| [`lua/corpus_coagulant/client/corpus_coagulant_medmenu.lua`](lua/corpus_coagulant/client/corpus_coagulant_medmenu.lua) | client | Menú médico (`coagulant_menu` + bind): silueta clickeable → heridas de la zona → tratamientos. Manda intents; **el server re-valida todo**. Carga DESPUÉS de `hud` (usa su silueta) |
| [`lua/corpus_coagulant/client/corpus_coagulant_options.lua`](lua/corpus_coagulant/client/corpus_coagulant_options.lua) | client | Tab único `Corpus.UI.RegisterTab("coagulant", …)`: convars de cliente y server, binder del menú médico, soft-deps, comandos de verificación |

## Contratos que no debes romper

1. **Namespace: tabla única registrada (cita COR-2 y COR-7).** Cada archivo abre con `local COAGULANT = Corpus.GetModule("coagulant")` (el init la registró antes). Ningún archivo declara globals sueltos. Depende del invariante by-ref del registro de Corpus (§3 de su arquitectura).
2. **Detección, nunca asunción (cita COR-5).** El hard-dep (Corpus) se detecta en el init (falla ruidoso si falta). Caliber y Cargo se consultan con lazy-check en el momento del uso, o en `Corpus.OnReady` para wiring de una vez — jamás en file-scope, jamás asumidos.
3. **COA-7 — Degradación honesta.** Sin Caliber: hitgroup crudo vía `COAGULANT.Zones.FromHitgroup` (ese mapa **nunca se borra**, es la vía standalone). Sin Cargo: los ítems médicos se apagan con log, nada crashea.
4. **Contrato público = arquitectura §8.** `ApplyBandage`/`ApplyTreatment` (slice 2), `GetBlood`, `IsBleeding`, `GetZoneScore`, `OnEncumbrance` (**COA-18** — contrato que Cargo ya llama, no le cambies la firma), `Zones.*` y los eventos `Coagulant_*`. **COA-8 (enmendado 2026-07-21) —** Los IDs de zona son contrato y son **7**: `head`, `chest`, `stomach`, `left_arm`, `right_arm`, `left_leg`, `right_leg` — `torso` se partió y murió **sin alias** (barrido: ningún repo externo consumía los IDs; `Zones.IsValid("torso")` es false). La bajada a código aterrizó el mismo 2026-07-21. Enmienda completa: [`docs/Coagulant_Architecture.md`](docs/Coagulant_Architecture.md) §3. El resto es off-contract por convención, documentado en el bloque CONTRATO del init.
5. **La semántica médica es de Coagulant; el contenedor es de Cargo.** `onUse` corre acá. Ojo desde el slice 2: el consumo es AL COMPLETAR el tratamiento (`onUse` devuelve `false` + `TakeItem` al terminar), no al iniciar. **COA-2 — Presencia de un ítem = `Inventory.HasItem`, nunca `CountItem`** — este último solo cuenta stacks y es ciego a los `unique` como el torniquete (pagado en juego el 2026-07-13).
6. **COA-12 — La silueta se pinta y se clickea desde la MISMA tabla.** `Config.SILHOUETTE` (geometría normalizada) + `Config.ZoneAt` (qué zona hay bajo el clic) son la única fuente: el HUD la dibuja chica, el menú médico grande, y el clic se resuelve contra lo que se pintó. Dos tablas = el jugador venda una zona que no eligió en cuanto alguien retoque un rectángulo. El selftest lo asserta zona por zona.
7. **COA-13 — El cliente nunca es autoridad.** El menú médico manda intents (`treat`/`cancel`) y el server re-valida todo. Habilitar o no un botón es puro UX. **Presencia de ítems en el cliente = contar las dos clases** (stacks *y* `unique` con `uid`): contar solo stacks deja el torniquete invisible — el mismo G4 que se pagó en el server.
8. **COA-4 — Coagulant nunca re-escala daño ni pisa `SetWalkSpeed`.** El daño es de Caliber (las heridas nacen del daño FINAL en `PostEntityTakeDamage`); la cojera compone vía hook `Move` + NW2, como el movecompat de Cargo — dos módulos escribiendo walk/run se pisan, dos escalando el `MaxSpeed` del move data se multiplican. Ese hook es **shared (COA-5)** porque `Move` se predice: si el cliente escalara distinto, el jugador haría rubber-band. Sin persistencia a disco (spawn = cuerpo nuevo, decisión F).
9. **Prefijo de archivo por módulo (cita COR-6):** `corpus_coagulant_*.lua` en todo lo que cargue el engine.

## Verificación

No hay test runner de GMod — el patrón es cargar mapa y confirmar (flujo §1 PASO 4), **la corre el autor**. Capas previas:

1. **`coagulant_selftest`** (consola, realm que lo invoca): zonas, contrato público, round-trip de estado si hay jugador, reporte de soft-deps. En listen server, realm server: `lua_run Corpus.GetModule("coagulant")._SelfTest()`.
2. **Harness offline** — [`../dev/harness_coagulant.py`](../dev/harness_coagulant.py) (LuaJIT vía `lupa` + stubs de GMod, carga el framework real de `corpus/` y este módulo en **ambos realms**): mismo patrón que verificó Corpus, Cargo y Craving. Es un **archivo permanente y versionado**, no un script de scratchpad: el registro acredita entradas `COA-nn` con `tipo: harness` y esa evidencia tiene que apuntar a algo citable (deuda D-12, materializada por voto del autor el 2026-07-19). Se corre con `python dev/harness_coagulant.py` y cierra en verde o falla con exit 1 (selftest actual: **170 OK server / 132 client**). El snapshot que produce el realm SERVER se **inyecta** en el CLIENT, así que la igualdad de escalado entre realms (**COA-5**) se verifica de verdad, no por construcción.

Flujo en juego: cargar mapa con corpus/ + coagulant/ (y opcionalmente cargo/, caliber/) → `coagulant_selftest` en consola → recibir un impacto y ver la herida y el `lastHit` (`lua_run PrintTable(Corpus.GetModule("coagulant").GetState(Entity(1)))`, o `coagulant_status`) → con Cargo: `Bandage` aparece en categoría `medical` y usarla **arranca un tratamiento de 4 s** (barra de progreso; se cancela por daño, salto o correr) — la unidad **no** se consume al iniciar: el `onUse` devuelve `false` y el `TakeItem` corre recién al COMPLETAR (contrato #5) → `coagulant_menu` abre el menú médico: clic en una zona → tratamiento (la tecla del bind **abre pero no cierra** — deuda anotada en §10 de la arquitectura; el cierre es la X del frame) → tab en Q → Utilities → Corpus → Coagulant.

Al cerrar un cambio con superficie de runtime: refresca [`docs/coagulant_estado.md`](docs/coagulant_estado.md) en sitio y actualiza [`docs/CHANGELOG.md`](docs/CHANGELOG.md) (`[PENDIENTE]` → `[APLICADO YYYY-MM-DD]`, sin borrar ni renumerar).

## Git / commits

Sigue [`docs/coagulant_convenciones_commits.txt`](docs/coagulant_convenciones_commits.txt): `<tipo>(<alcance>): <descripción>` — tipo en inglés, descripción en español, minúscula inicial, sin punto final, imperativo. Los 12 alcances de este repo (§3 del doc, que manda): `zones`, `core`, `config`, `treatment`, `debuffs`, `items`, `hud`, `medmenu`, `options`, `dev`, `init` y `docs`. `chore` **no** es un alcance sino un tipo (§2, junto a `feat`/`fix`/`refactor`/`docs`/`test`).

**Este repo está publicado en GitHub** (`github.com/Sepuldosky/corpus-coagulant`, público, remote `origin`, rama `main`). No hagas commit ni push salvo que se pida explícitamente.

**No agregues el trailer `Co-Authored-By: Claude` (ni ninguna atribución de co-autoría a Claude/Anthropic) en los mensajes de commit.** Esto sobreescribe el comportamiento por defecto del harness.

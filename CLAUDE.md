# CLAUDE.md

Guía para trabajar en **Coagulant** — el módulo médico de jugador del ecosistema Corpus (addon GLua para Garry's Mod). Léela antes de tocar código o docs de este repo.

## Qué es

Coagulant es el módulo **médico de jugador** del ecosistema Corpus, estilo ACE3: heridas por zona, sangrado, vitales y tratamiento. Es un addon Gmod independiente con su propio git, que **hard-depende** de Corpus (la única dependencia dura del ecosistema) y de nadie más. Detecta a otros módulos en runtime vía `Corpus.GetModule`/`Corpus.HasModule`, nunca los asume: **Caliber** (hit-location enriquecido) y **Cargo** (ítems médicos) son soft-deps con degradación honesta — sin Caliber, hit-location por hitgroup crudo del engine; sin Cargo, tratamiento por vía mínima propia. Ver §2, §4-§5 de `../corpus/docs/CORPUS_Architecture.md`.

**Estado actual: BLOCK 3 EN BAJADA (slice 2 de 4).** El diseño está en [`docs/Coagulant_Architecture.md`](docs/Coagulant_Architecture.md) (ratificado por el autor el 2026-07-13; números de balance tunables). El slice 1 (sangre + heridas + sangrado) está **verificado en juego**; el slice 2 (tratamiento con tiempo + 4 ítems) está en código; debuffs (slice 3) y UI (slice 4) siguen la secuencia de §15 de la arquitectura. **No implementes nada que la arquitectura no especifique** — cambios de diseño se discuten con el autor y se anotan primero en el doc.

**Regla cardinal:** nada de lógica de dominio sube a Corpus, y la lógica ajena no baja acá: el hit-location enriquecido es de Caliber, el contenedor/grid/peso de los ítems es de Cargo. Coagulant posee solo la medicina (qué hace una venda, cómo sangra una zona).

## Docs del proyecto — jerarquía de lectura

Antes de tocar código o diseño, lee en este orden (los tres primeros son **docs vivos**):

1. **Estado de HOY** → [`docs/coagulant_estado.md`](docs/coagulant_estado.md). Foto del AHORA, ≤1 pantalla. **Léelo ANTES** que la arquitectura.
2. **Rumbo** → [`docs/coagulant_roadmap.txt`](docs/coagulant_roadmap.txt). Qué sigue y en qué orden.
3. **Historial de parches** → [`docs/CHANGELOG.md`](docs/CHANGELOG.md). `[PENDIENTE]`/`[APLICADO YYYY-MM-DD]`, nunca se borra ni renumera.
4. **Metodología de trabajo** → [`../corpus/docs/corpus_flujo_trabajo.txt`](../corpus/docs/corpus_flujo_trabajo.txt). **Doc canónico compartido** por todo el ecosistema — no se duplica acá.
5. **Arquitectura del módulo** → [`docs/Coagulant_Architecture.md`](docs/Coagulant_Architecture.md) (Block 3: sustrato v1 — **borrador para ratificación del autor**; los números de balance son propuesta tunable). La frontera general sigue en `../corpus/docs/CORPUS_Architecture.md` §2, §4-§5; la semilla con el registro de decisiones en [`docs/Coagulant_Block3_Semilla.md`](docs/Coagulant_Block3_Semilla.md).
6. **Convenciones de commit** → [`docs/coagulant_convenciones_commits.txt`](docs/coagulant_convenciones_commits.txt). Alcances específicos de **este** repo.

## Idioma

- **Código (comentarios): español** (estilo corpus/caliber; Cargo es la excepción en inglés). Iguala el del archivo que edites.
- **Strings de cara al jugador (UI, nombres de ítems): inglés** — es el idioma del mod (decisión del autor, fijada en Cargo el 2026-07-10).
- **Docs, commits y logs (`Corpus.Log`): español**; los `<tipo>` de commit en inglés (ver convenciones).

## El workspace multi-repo

Este repo (`corpus-coagulant/`) es una de seis raíces del workspace `corpus.code-workspace`. La raíz `corpus/` es el framework del que todos hard-dependen; las otras cuatro (`corpus-cortex/`, `corpus-caliber/`, `corpus-craving/`, `corpus-cargo/`) son módulos hermanos que se detectan en runtime, nunca se asumen. Al diseñar integración con mods ajenos, consulta `../dev/mods_workshop_mapa.md` (RECICLAR vs. COMPAT-RUNTIME).

## Mapa de archivos

Un **manifest de carga explícito** (`corpus_coagulant_init.lua`, único archivo en `lua/autorun/`) registra el módulo, declara el contrato público y hace `include()` en orden determinista — patrón template tomado de Caliber (boot diferido a `Initialize`, sonda `CorpusListo`, falla ruidoso sin framework). Los sub-archivos viven en `lua/corpus_coagulant/<realm>/`, **fuera** de `lua/autorun/`.

| Archivo | Realm | Rol |
|---|---|---|
| [`lua/autorun/corpus_coagulant_init.lua`](lua/autorun/corpus_coagulant_init.lua) | shared | Entry + registro (`coagulant`) + **bloque CONTRATO** (arquitectura §8) + manifest |
| [`lua/corpus_coagulant/shared/corpus_coagulant_zones.lua`](lua/corpus_coagulant/shared/corpus_coagulant_zones.lua) | shared | Zonas clínicas (6, estilo ACE3) + mapa hitgroup nativo → zona (**la vía de degradación sin Caliber** — puro, sin hooks) |
| [`lua/corpus_coagulant/shared/corpus_coagulant_config.lua`](lua/corpus_coagulant/shared/corpus_coagulant_config.lua) | shared | Convars + tablas de balance + funciones puras (§3-§5, §11): `WoundTypeFromDMG`, `SeverityFromDamage`, `BleedRate`, `HPDrainRate` |
| [`lua/corpus_coagulant/shared/corpus_coagulant_dev.lua`](lua/corpus_coagulant/shared/corpus_coagulant_dev.lua) | shared | `coagulant_selftest` + comandos de verificación `coagulant_status` / `coagulant_setblood` (admin) |
| [`lua/corpus_coagulant/server/corpus_coagulant_core.lua`](lua/corpus_coagulant/server/corpus_coagulant_core.lua) | server | Estado clínico v1 + **heridas en `PostEntityTakeDamage` con daño final** (hitgroup capturado en `ScalePlayerDamage`, guard `_selfDrain`) + eventos `Coagulant_*` + contrato de lectura + efecto venda (`BandageEffect`/`ApplyBandage`) + `OnEncumbrance` (stub del contrato de Cargo) |
| [`lua/corpus_coagulant/server/corpus_coagulant_bleeding.lua`](lua/corpus_coagulant/server/corpus_coagulant_bleeding.lua) | server | Timer único 1 s (§4-§5): drenaje, regen natural, HP crítico (`DMG_GENERIC` + "You bled out."), NW2 `coagulant_blood`, snapshot on-change (`corpus_coagulant_state`) |
| [`lua/corpus_coagulant/server/corpus_coagulant_treatment.lua`](lua/corpus_coagulant/server/corpus_coagulant_treatment.lua) | server | Motor de tratamiento (§7/§9): `ApplyTreatment`/`CancelTreatment`, tick 0.25 s, cancelación por daño/salto/velocidad, **consumo al completar**, torniquete toggle + isquemia, eventos `Coagulant_Treatment*`, intents net `treat`/`cancel` |
| [`lua/corpus_coagulant/shared/corpus_coagulant_items.lua`](lua/corpus_coagulant/shared/corpus_coagulant_items.lua) | shared | Set v1 de 4 defs contra Cargo (Bandage/Tourniquet/Medkit/Blood Bag, `onUse` → `false` + inicia tratamiento) + `coagulant_bandage` (debug instantáneo, server). **Shared obligatorio: Cargo no sincroniza defs por net** — registrarlas solo en server = ítem invisible en la UI (pagado el 2026-07-13) |
| [`lua/corpus_coagulant/client/corpus_coagulant_options.lua`](lua/corpus_coagulant/client/corpus_coagulant_options.lua) | client | Tab único `Corpus.UI.RegisterTab("coagulant", …)` (estado + detección de soft-deps; crece con convars en el slice 4) |

## Contratos que no debes romper

1. **Namespace: tabla única registrada.** Cada archivo abre con `local COAGULANT = Corpus.GetModule("coagulant")` (el init la registró antes). Ningún archivo declara globals sueltos. Depende del invariante by-ref del registro de Corpus (§3 de su arquitectura).
2. **Detección, nunca asunción.** El hard-dep (Corpus) se detecta en el init (falla ruidoso si falta). Caliber y Cargo se consultan con lazy-check en el momento del uso, o en `Corpus.OnReady` para wiring de una vez — jamás en file-scope, jamás asumidos.
3. **Degradación honesta.** Sin Caliber: hitgroup crudo vía `COAGULANT.Zones.FromHitgroup` (ese mapa **nunca se borra**, es la vía standalone). Sin Cargo: los ítems médicos se apagan con log, nada crashea.
4. **Contrato público = arquitectura §8.** `ApplyBandage`/`ApplyTreatment` (slice 2), `GetBlood`, `IsBleeding`, `GetZoneScore`, `OnEncumbrance` (contrato que Cargo ya llama — no le cambies la firma), `Zones.*` y los eventos `Coagulant_*`. Los IDs de zona (`head`, `torso`, `left_arm`, `right_arm`, `left_leg`, `right_leg`) son contrato. El resto es off-contract por convención, documentado en el bloque CONTRATO del init.
5. **La semántica médica es de Coagulant; el contenedor es de Cargo.** `onUse` corre acá. Ojo desde el slice 2: el consumo es AL COMPLETAR el tratamiento (`onUse` devuelve `false` + `TakeItem` al terminar), no al iniciar.
6. **Coagulant nunca re-escala daño ni pisa `SetWalkSpeed`.** El daño es de Caliber (las heridas nacen del daño FINAL en `PostEntityTakeDamage`); la cojera (slice 3) compone vía hook `Move` + NW2, como el movecompat de Cargo. Sin persistencia a disco (spawn = cuerpo nuevo, decisión F).
7. **Prefijo de archivo por módulo:** `corpus_coagulant_*.lua` en todo lo que cargue el engine.

## Verificación

No hay test runner de GMod — el patrón es cargar mapa y confirmar (flujo §1 PASO 4), **la corre el autor**. Capas previas:

1. **`coagulant_selftest`** (consola, realm que lo invoca): zonas, contrato público, round-trip de estado si hay jugador, reporte de soft-deps. En listen server, realm server: `lua_run Corpus.GetModule("coagulant")._SelfTest()`.
2. **Harness offline** (LuaJIT vía `lupa` + stubs de GMod, carga el framework real de `corpus/`): mismo patrón que verificó Corpus y Cargo; el script se reconstruye en el scratchpad de sesión.

Flujo en juego: cargar mapa con corpus/ + coagulant/ (y opcionalmente cargo/, caliber/) → `coagulant_selftest` en consola → recibir un impacto y ver `lastHit` (`lua_run PrintTable(Corpus.GetModule("coagulant").GetState(Entity(1)))`) → con Cargo: `Bandage` aparece en categoría `medical`, usarla loguea el stub y consume una unidad → tab en Q → Utilities → Corpus → Coagulant.

Al cerrar un cambio con superficie de runtime: refresca [`docs/coagulant_estado.md`](docs/coagulant_estado.md) en sitio y actualiza [`docs/CHANGELOG.md`](docs/CHANGELOG.md) (`[PENDIENTE]` → `[APLICADO YYYY-MM-DD]`, sin borrar ni renumerar).

## Git / commits

Sigue [`docs/coagulant_convenciones_commits.txt`](docs/coagulant_convenciones_commits.txt): `<tipo>(<alcance>): <descripción>` — tipo en inglés, descripción en español, minúscula inicial, sin punto final, imperativo. Alcances de este repo: `zones`, `core`, `items`, `options`, `dev`, `init` (+ `docs`, `chore`).

**Este repo está publicado en GitHub** (`github.com/Sepuldosky/corpus-coagulant`, público, remote `origin`, rama `main`). No hagas commit ni push salvo que se pida explícitamente.

**No agregues el trailer `Co-Authored-By: Claude` (ni ninguna atribución de co-autoría a Claude/Anthropic) en los mensajes de commit.** Esto sobreescribe el comportamiento por defecto del harness.

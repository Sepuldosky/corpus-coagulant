# CLAUDE.md

Guía para trabajar en **Coagulant** — el módulo médico de jugador del ecosistema Corpus (addon GLua para Garry's Mod). Léela antes de tocar código o docs de este repo.

## Qué es

Coagulant es el módulo **médico de jugador** del ecosistema Corpus, estilo ACE3: heridas por zona, sangrado, vitales y tratamiento. Es un addon Gmod independiente con su propio git, que **hard-depende** de Corpus (la única dependencia dura del ecosistema) y de nadie más. Detecta a otros módulos en runtime vía `Corpus.GetModule`/`Corpus.HasModule`, nunca los asume: **Caliber** (hit-location enriquecido) y **Cargo** (ítems médicos) son soft-deps con degradación honesta — sin Caliber, hit-location por hitgroup crudo del engine; sin Cargo, tratamiento por vía mínima propia. Ver §2, §4-§5 de `../corpus/docs/CORPUS_Architecture.md`.

**Estado actual: SCAFFOLD PRE-BLOCK 3.** El diseño de dominio (Block 3 del ecosistema, §9 de la arquitectura de Corpus) **no cerró todavía** — se diseña en este mismo repo iterando con el autor (semilla → [`docs/Coagulant_Block3_Semilla.md`](docs/Coagulant_Block3_Semilla.md)) y aterrizará como `docs/Coagulant_Architecture.md`. Lo que existe hoy es la estructura del módulo: boot, namespace, zonas clínicas (la vía de degradación), estado por jugador sin gameplay, un ítem semilla contra Cargo y el contrato público mínimo congelado (patrón mock-first, flujo §3). **No inventes curvas de sangrado, vitales ni semántica de heridas sin ese diseño.**

**Regla cardinal:** nada de lógica de dominio sube a Corpus, y la lógica ajena no baja acá: el hit-location enriquecido es de Caliber, el contenedor/grid/peso de los ítems es de Cargo. Coagulant posee solo la medicina (qué hace una venda, cómo sangra una zona).

## Docs del proyecto — jerarquía de lectura

Antes de tocar código o diseño, lee en este orden (los tres primeros son **docs vivos**):

1. **Estado de HOY** → [`docs/coagulant_estado.md`](docs/coagulant_estado.md). Foto del AHORA, ≤1 pantalla. **Léelo ANTES** que la arquitectura.
2. **Rumbo** → [`docs/coagulant_roadmap.txt`](docs/coagulant_roadmap.txt). Qué sigue y en qué orden.
3. **Historial de parches** → [`docs/CHANGELOG.md`](docs/CHANGELOG.md). `[PENDIENTE]`/`[APLICADO YYYY-MM-DD]`, nunca se borra ni renumera.
4. **Metodología de trabajo** → [`../corpus/docs/corpus_flujo_trabajo.txt`](../corpus/docs/corpus_flujo_trabajo.txt). **Doc canónico compartido** por todo el ecosistema — no se duplica acá.
5. **Arquitectura del módulo** → `docs/Coagulant_Architecture.md` — **no existe todavía**; llega con el Block 3 de diseño. Mientras tanto, la frontera del módulo vive en `../corpus/docs/CORPUS_Architecture.md` §2, §4-§5.
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
| [`lua/autorun/corpus_coagulant_init.lua`](lua/autorun/corpus_coagulant_init.lua) | shared | Entry + registro (`coagulant`) + **bloque CONTRATO** + manifest |
| [`lua/corpus_coagulant/shared/corpus_coagulant_zones.lua`](lua/corpus_coagulant/shared/corpus_coagulant_zones.lua) | shared | Zonas clínicas (6, estilo ACE3) + mapa hitgroup nativo → zona (**la vía de degradación sin Caliber** — puro, sin hooks) |
| [`lua/corpus_coagulant/shared/corpus_coagulant_dev.lua`](lua/corpus_coagulant/shared/corpus_coagulant_dev.lua) | shared | `coagulant_selftest`: auto-test determinista de la superficie pura |
| [`lua/corpus_coagulant/server/corpus_coagulant_core.lua`](lua/corpus_coagulant/server/corpus_coagulant_core.lua) | server | Estado clínico por jugador (forma sustrato) + hooks de enganche (`ScalePlayerDamage` registra zona del último impacto, **sin gameplay**) + stub `ApplyBandage` |
| [`lua/corpus_coagulant/server/corpus_coagulant_items.lua`](lua/corpus_coagulant/server/corpus_coagulant_items.lua) | server | Ítem semilla `corpus_coagulant_bandage` contra Cargo (soft-dep, en `Corpus.OnReady`) + `coagulant_bandage` (vía mínima de debug) |
| [`lua/corpus_coagulant/client/corpus_coagulant_options.lua`](lua/corpus_coagulant/client/corpus_coagulant_options.lua) | client | Tab único `Corpus.UI.RegisterTab("coagulant", …)` (estado del scaffold + detección de soft-deps) |

## Contratos que no debes romper

1. **Namespace: tabla única registrada.** Cada archivo abre con `local COAGULANT = Corpus.GetModule("coagulant")` (el init la registró antes). Ningún archivo declara globals sueltos. Depende del invariante by-ref del registro de Corpus (§3 de su arquitectura).
2. **Detección, nunca asunción.** El hard-dep (Corpus) se detecta en el init (falla ruidoso si falta). Caliber y Cargo se consultan con lazy-check en el momento del uso, o en `Corpus.OnReady` para wiring de una vez — jamás en file-scope, jamás asumidos.
3. **Degradación honesta.** Sin Caliber: hitgroup crudo vía `COAGULANT.Zones.FromHitgroup` (ese mapa **nunca se borra**, es la vía standalone). Sin Cargo: los ítems médicos se apagan con log, nada crashea.
4. **Contrato público mínimo congelado.** Solo `COAGULANT.ApplyBandage(ply)` (firma del `onUse` de §5 de la arquitectura de Corpus) y `COAGULANT.Zones.*` son superficie pública. Los IDs de zona (`head`, `torso`, `left_arm`, `right_arm`, `left_leg`, `right_leg`) ya son contrato. El resto es off-contract por convención, documentado en el bloque CONTRATO del init.
5. **La semántica médica es de Coagulant; el contenedor es de Cargo.** `onUse` corre acá; Cargo solo consume 1 unidad si devuelve `true`. Nunca metas grid/peso/persistencia de inventario en este repo.
6. **Sin gameplay antes del diseño.** Hasta que el Block 3 cierre, ningún hook de este repo modifica daño, velocidad ni salud — solo observa. No agregues persistencia (`Corpus.Data`) ni net (`Corpus.Net`) hasta que exista estado/protocolo diseñado que lo justifique.
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

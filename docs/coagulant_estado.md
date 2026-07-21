# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-21 (**barrido de drifts de docs**: el CLAUDE.md ya
no lista la mini-ronda 8 como pendiente —está 2/2, N1 ✓—, los comentarios «6 zonas»
del HUD pasan a 7, y los ecos de estado de Coagulant en `corpus/`, `corpus-cargo/` y
`corpus-craving/` quedan corregidos. CHANGELOG sesión «Barrido de drifts de docs»
`[APLICADO]`. El tramo de zonas `torso` → `chest`/`stomach` sigue **COMPLETO** —ronda O
6/6, selftest 170/132—; el **Block 3 sigue CERRADO** —ronda 7 13/13, mini-ronda 8 2/2,
check N1 ✓— y siguen las **dos decisiones de diseño abiertas**)

---

## Qué existe hoy

- **Block 3 completo y verificado en juego** (rondas 1-7, 2026-07-13 → 2026-07-20):
  - **Slice 1** — sangre 0-100 con NW2, heridas por damage type con el daño FINAL,
    timer de 1 s (drenaje, regen, HP crítico → "You bled out."), eventos
    `Coagulant_*` y snapshot on-change.
  - **Slice 2** — tratamiento server-authoritative con **consumo AL COMPLETAR**,
    cancelación por daño/salto/velocidad, torniquete toggle con isquemia, 4 defs
    contra Cargo (Bandage/Tourniquet/Medkit/Blood Bag).
  - **Slice 3** — debuffs zonales: cojera (NW2 + hook `Move` shared, compone con el
    peso de Cargo), sway continuo en dos capas con rampa de ADS (cliente), visión
    (vignette elíptico + capa de sangre crítica). El Medkit borra la secuela tratada.
  - **Slice 4** — UI: silueta de 7 zonas que late y se desvanece, menú médico por
    zona (dibujo y clic desde la MISMA tabla; intents que el server re-valida),
    barra de tratamiento, sangre en el StatusPanel de Cargo (mini-barra propia sin
    él) y tab Q real. **El flujo completo sin consola (§15) confirmado en J5**, y el
    modo degradado sin Cargo verificado EN JUEGO (L1 — la vieja deuda G6, saldada).
- **Fixes post-cierre verificados en juego** (mini-ronda 8: 2/2; check N1 ✓): la tecla
  del menú se lee por **poleo en `Think`** con guard de cursor (`PlayerButtonDown` no
  dispara client-side en singleplayer; elegir la tecla en el binder ya no despliega el
  menú) y `ResetState` despublica la cojera del selftest.
- **Zonas: 7 desde el 2026-07-21** (COA-8 enmendado, bajado a código y verificado en
  juego el mismo día — ronda O: 6/6): `torso` partido en `chest`/`stomach` sin alias,
  fallback `chest` (COA-7), `ZONE_BLEED_MULT` neutra como eje de tuning, silueta 58/42.
- **Verificación offline:** sintaxis (luaparser, 13 archivos) + harness versionado
  ([`../../dev/harness_coagulant.py`](../../dev/harness_coagulant.py), checks de la
  partición incluidos + selftest en ambos realms): **170 OK server / 132 client,
  0 fallos, ALL GREEN**.
- Mapa archivo → rol en [`../CLAUDE.md`](../CLAUDE.md). Comandos: `coagulant_selftest`,
  `coagulant_status`, `coagulant_setblood`, `coagulant_bandage`, `coagulant_dev_give`.

## Pendiente de verificar

- Nada — el CHANGELOG está todo en `[APLICADO]` (la ronda O cerró 6/6 el 2026-07-21).

## Remanentes / deuda conocida

- **DECISIÓN ABIERTA (autor) — toggle del paperdoll** (pedido de la ronda 7): hoy la
  silueta se desvanece sola con el cuerpo sano **y la sangre llena**, y la regen lenta
  (0.10/s) la mantiene visible minutos. ¿Convar propia para la silueta pasiva?
  ¿Mostrarla solo sangrando/tratando? Se anota en la arquitectura ANTES de
  implementar (COA-28).
- **DECISIÓN ABIERTA (autor) — ¿la tecla del menú también cierra?** Hoy solo abre
  (cierre = X del frame). El poleo nuevo lo hace posible con el patrón de Cargo.
- **Un torniquete `unique` puede atar varias extremidades** (no se consume y nada lo
  impide). Si molesta, es decisión de diseño, no un bug.
- **ARC9 fino, diferido** (§6): «apuntando» = clic derecho (`IN_ATTACK2`), agnóstico
  al arma; la API real de ARC9 se verifica contra `dev/other/`, nunca de memoria.
- **Silueta y vignette: geometría propia** — nada se recicla de mods con licencia
  silenciosa; la vía legal para assets dibujados es `corpus-stalker` o HL2.
- **Rama Caliber vacía a propósito** hasta su Block 3 (arquitectura §12).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. El tramo acordado con el autor: (1) arreglar drifts de docs — **HECHO** (barrido del
   2026-07-21: el «Estado actual» del CLAUDE.md ya no lista la mini-ronda 8 como
   pendiente, los comentarios «6 zonas» del HUD pasan a 7, y los ecos de estado en
   `corpus/`, `corpus-cargo/` y `corpus-craving/` corregidos). Quedan **(2) las dos
   decisiones de diseño abiertas** de arriba y **(3) la mejora a la UI que el autor
   tiene diseñada en Claude** (la trae él).
2. Cross-repo: ratificar `ApplyExternalCondition(ply, id, severity)` con **Craving**
   (deuda D-5). **Ojo con el 2.º argumento**: es el **id de condición clínica**
   `{"starvation", "dehydration"}`, NO el stat de Craving — implementarlo switcheando
   sobre el stat pasaría el gate de CAPACIDAD sin aplicar nada y la inanición quedaría
   inofensiva en silencio. Después, el wiring real con Caliber cuando su Block 3
   exponga el hit-location de jugador (roadmap [3]).

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

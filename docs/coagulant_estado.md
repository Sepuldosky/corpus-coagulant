# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-21 (**enmienda `torso` → `chest` & `stomach`
RATIFICADA** — las cinco preguntas de la semilla resueltas con el autor y los docs
enmendados: arquitectura §3-§10, CLAUDE.md contrato 4, ids.yaml COA-7/COA-8; CHANGELOG
sesión «Enmienda de zonas», todo `[APLICADO]` — es solo docs. **La bajada a código está
PENDIENTE**: el árbol aún dice `torso`. El **Block 3 sigue CERRADO** (ronda 7: 13/13;
mini-ronda 8: 2/2; check N1 ✓) y siguen las **dos decisiones de diseño abiertas**)

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
  - **Slice 4** — UI: silueta de 6 zonas que late y se desvanece, menú médico por
    zona (dibujo y clic desde la MISMA tabla; intents que el server re-valida),
    barra de tratamiento, sangre en el StatusPanel de Cargo (mini-barra propia sin
    él) y tab Q real. **El flujo completo sin consola (§15) confirmado en J5**, y el
    modo degradado sin Cargo verificado EN JUEGO (L1 — la vieja deuda G6, saldada).
- **Fixes post-cierre verificados en juego** (mini-ronda 8: 2/2; check N1 ✓): la tecla
  del menú se lee por **poleo en `Think`** con guard de cursor (`PlayerButtonDown` no
  dispara client-side en singleplayer; elegir la tecla en el binder ya no despliega el
  menú) y `ResetState` despublica la cojera del selftest.
- **Verificación offline:** sintaxis (luaparser, 13 archivos) + harness versionado
  ([`../../dev/harness_coagulant.py`](../../dev/harness_coagulant.py), 173 checks +
  selftest en ambos realms): **146 OK server / 108 client, 0 fallos, ALL GREEN**.
- Mapa archivo → rol en [`../CLAUDE.md`](../CLAUDE.md). Comandos: `coagulant_selftest`,
  `coagulant_status`, `coagulant_setblood`, `coagulant_bandage`, `coagulant_dev_give`.

## Pendiente de verificar

- Nada — el CHANGELOG está todo en `[APLICADO]`.

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

1. **Bajar a código la enmienda de zonas** (ratificada 2026-07-21, ver arquitectura §3;
   semilla de la sesión: `dev/HANDOFF_coagulant_zonas_codigo.md`):
   `zones.lua` (LIST/LABELS 7 zonas, fallback `chest`), `config.lua` (SILHOUETTE 7
   rects 58/42 + `ZONE_BLEED_MULT` neutra en el drenaje), barrido de `or "torso"` en
   medmenu/core/treatment, dev + harness (los conteos 146/108 cambian), y después la
   ronda **O** de la planilla.
2. Las dos **decisiones de diseño abiertas** de arriba (se discuten y se anotan en la
   arquitectura antes de tocar código).
3. Cross-repo: ratificar `ApplyExternalCondition(ply, id, severity)` con **Craving**
   (deuda D-5). **Ojo con el 2.º argumento**: es el **id de condición clínica**
   `{"starvation", "dehydration"}`, NO el stat de Craving — implementarlo switcheando
   sobre el stat pasaría el gate de CAPACIDAD sin aplicar nada y la inanición quedaría
   inofensiva en silencio. Después, el wiring real con Caliber cuando su Block 3
   exponga el hit-location de jugador (roadmap [3]).

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

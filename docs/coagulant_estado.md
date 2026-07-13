# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-13 (scaffold escrito + primera pasada de diseño del
Block 3 cerrada con el autor + `Coagulant_Architecture.md` en borrador — pendientes:
verificación del scaffold en juego y ratificación del doc)

---

## Qué existe hoy

- **Scaffold pre-Block 3, SIN diseño de dominio cerrado.** Estructura del módulo
  sobre las 6 primitivas de Corpus: init con boot diferido (patrón template de
  Caliber), namespace `coagulant` (tabla única by-ref), manifest explícito. Mapa
  archivo → rol en [`../CLAUDE.md`](../CLAUDE.md). **Nada de esto tiene efecto de
  gameplay todavía** — el sustrato observa, no modifica.
- **Vía de degradación standalone:** `Zones` (6 zonas clínicas estilo ACE3 + mapa
  hitgroup nativo → zona, puro). Es lo que corre sin Caliber; nunca se borra.
- **Contrato público mínimo congelado (mock-first):** `ApplyBandage(ply)` (stub que
  loguea y devuelve `true`) + IDs de zona. Es la firma que consume el `onUse` del
  ítem de Cargo (§5 de la arquitectura de Corpus).
- **Ítem semilla contra Cargo:** `corpus_coagulant_bandage` registrado en
  `Corpus.OnReady` con lazy-check (sin Cargo: log y apagado honesto). Vía de debug
  sin inventario: `coagulant_bandage` (admin).
- **Sustrato de estado:** estado clínico por jugador en memoria (forma placeholder
  `zones[zona] = {wounds, bleeding}` + `lastHit` vía `ScalePlayerDamage`, solo
  observación). Sin persistencia ni net — llegan con diseño que las justifique.
- **Verificación previa:** `coagulant_selftest` (superficie pura + soft-deps) y tab
  Q → Utilities → Corpus → Coagulant (estado + detección de deps).

## Pendiente de verificar

- **Todo el scaffold en juego** (CHANGELOG sesión 2026-07-13 en `[PENDIENTE]`):
  boot, selftest, lastHit, venda vía Cargo, tab de UI. La corre el autor.

## Remanentes / deuda conocida

- **`Coagulant_Architecture.md` es BORRADOR** — las decisiones estructurales las
  resolvió el autor (semilla §3), pero los números de balance (curvas §4-§6, tiempos
  §7) son propuesta inicial sin ratificar ni probar en juego. Quedaron PENDIENTE en
  la semilla y resueltos como propuesta en el doc: vía sin Cargo (tratamiento gratis
  con cooldown) y convars — ojo al ratificar.
- **Rama Caliber vacía a propósito:** el lazy-check en `ScalePlayerDamage` está, pero
  no hay nada que consumir hasta que Caliber cierre su Block 3 (pipeline de jugador).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. **Verificación en juego del scaffold** (autor) → flipear el CHANGELOG.
2. **Ratificación de `Coagulant_Architecture.md`** (autor) → Block 3 de diseño cerrado
   (sección resumen en `CORPUS_Architecture.md` §9).
3. **Bajada a código por 4 vertical slices** (arquitectura §15): sangre/heridas →
   tratamiento vía Cargo → debuffs → UI.

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

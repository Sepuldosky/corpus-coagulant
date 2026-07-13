# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-13 (scaffold pre-Block 3 escrito — pendiente de verificación en juego)

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

- **`docs/Coagulant_Architecture.md` no existe** — el Block 3 de diseño (heridas,
  sangrado, vitales, tratamiento real) se diseña **en este repo, iterando con el
  autor** (decisión 2026-07-13: para mods el diseño denso en Desktop no hace falta;
  eso queda para Kontrol). Semilla con las decisiones abiertas →
  [`Coagulant_Block3_Semilla.md`](Coagulant_Block3_Semilla.md). El scaffold no lo
  condiciona más allá de los contratos congelados (zonas, `ApplyBandage`).
- **Rama Caliber vacía a propósito:** el lazy-check en `ScalePlayerDamage` está, pero
  no hay nada que consumir hasta que Caliber cierre su Block 3 (pipeline de jugador).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. **Verificación en juego del scaffold** (autor) → flipear el CHANGELOG.
2. **Block 3 de diseño** (acá, iterando con el autor sobre la semilla): sustrato v1 —
   heridas por zona, sangrado, vitales, vendaje/torniquete. Al cerrar:
   `Coagulant_Architecture.md` acá + sección resumen en `CORPUS_Architecture.md`.

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-13 (slice 1 **verificado en juego por el autor**
salvo el punto E — venda invisible en la UI de Cargo por defs server-only; fix
aplicado (items → shared), re-test pendiente vía el artefacto)

---

## Qué existe hoy

- **Diseño del Block 3 cerrado:** [`Coagulant_Architecture.md`](Coagulant_Architecture.md)
  (ratificado 2026-07-13; números de balance tunables en juego). Registro de
  decisiones en la semilla §3.
- **Slice 1 de 4 en código (sangre + heridas + sangrado):** sangre 0-100 con NW2,
  heridas por damage type creadas en `PostEntityTakeDamage` con el daño final
  (hitgroup vía `ScalePlayerDamage`, caída → pierna), timer único 1 s (drenaje,
  regen natural, HP crítico bajo 40 con muerte "You bled out."), eventos
  `Coagulant_WoundAdded/WoundClosed/BloodCritical`, snapshot on-change, efecto
  venda real (grave cuesta 2), `OnEncumbrance` stub (contrato que Cargo ya llama).
  Mapa archivo → rol en [`../CLAUDE.md`](../CLAUDE.md).
- **Verificación offline pasada:** sintaxis (luaparser) + harness (lupa + framework
  real): flujo completo del slice y selftest 49 OK. Comandos en juego:
  `coagulant_selftest`, `coagulant_status`, `coagulant_setblood`, `coagulant_bandage`.
- **Vía de degradación standalone:** `Zones` (hitgroup crudo sin Caliber) + ítem
  `corpus_coagulant_bandage` contra Cargo con lazy-check (sin Cargo: log y apagado).

## Pendiente de verificar

- **Solo el punto E (venda vía UI de Cargo)**, tras el fix items→shared (sesión
  "Fix punto E" del CHANGELOG). El resto del scaffold + slice 1 quedó `[APLICADO]`
  el 2026-07-13. Re-test con el artefacto de verificación.

## Remanentes / deuda conocida

- **Regla aprendida (punto E): las defs contra Cargo van en SHARED** — Cargo no
  sincroniza defs por net; el grid cliente lee su tabla local. Anotado en
  arquitectura §13 y CLAUDE.md.
- **Consumo de la venda es interim:** hasta el slice 2, el `onUse` consume al
  instante (efecto inmediato); la arquitectura §7 pide tiempo de aplicación +
  consumo al completar (`onUse` → `false` + `TakeItem`).
- **Snapshot sin consumidor:** `corpus_coagulant_state` se envía pero el cliente
  recién lo lee en el slice 4 (HUD/menú). Inofensivo.
- **Rama Caliber vacía a propósito** hasta su Block 3 (las heridas ya nacerían
  post-armadura sin tocar código acá, arquitectura §12).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. **Re-test del punto E en juego** (autor, artefacto: sección E) → flipear el fix.
2. **Slice 2:** tratamiento con tiempo (ApplyTreatment, barra, cancelación, consumo
   al completar, torniquete con isquemia) + los 4 ítems contra Cargo.
3. Luego slice 3 (debuffs) y slice 4 (UI) — arquitectura §15.

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

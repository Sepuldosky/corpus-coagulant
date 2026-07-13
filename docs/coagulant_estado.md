# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-13 (slice 1 + punto E verificados 14/14; **slice 2
en código**, verificado offline. La ronda 3 en juego se interrumpió en G1: el
`lua_run` largo del kit se trunca en consola — reemplazado por `coagulant_dev_give`;
la sección G queda por correr entera)

---

## Qué existe hoy

- **Slice 2 en código (tratamiento con tiempo + set v1 de ítems):** `ApplyTreatment`
  server-authoritative con zona automática, cancelación por daño/salto/velocidad,
  **consumo al completar** (`onUse` → `false` + `TakeItem`; el torniquete no se
  consume), torniquete toggle con isquemia (90 s → score 6, persiste 60 s),
  modo degradado sin Cargo (gratis, cooldown 30 s), intents net `treat`/`cancel`,
  eventos `Coagulant_Treatment*`. 4 defs: Bandage/Tourniquet/Medkit/Blood Bag.

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

- **El slice 2 en juego** (CHANGELOG sesión "slice 2" en `[PENDIENTE]`): artefacto
  ronda 3, sección G completa — el kit se da con `coagulant_dev_give` (el lua_run
  largo se truncaba en consola). Scaffold + slice 1 + punto E ya `[APLICADO]`.

## Remanentes / deuda conocida

- **Regla aprendida (punto E): las defs contra Cargo van en SHARED** — Cargo no
  sincroniza defs por net; el grid cliente lee su tabla local. Anotado en
  arquitectura §13 y CLAUDE.md.
- **Sin barra de progreso visible aún:** el tratamiento con tiempo corre y el
  snapshot lleva `{kind, endsAt, duration}`, pero la barra se dibuja recién en el
  slice 4 (HUD) — mientras tanto, `coagulant_status` muestra el tratamiento en curso.
- **Rama Caliber vacía a propósito** hasta su Block 3 (las heridas ya nacerían
  post-armadura sin tocar código acá, arquitectura §12).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. **Verificación en juego del slice 2** (autor, artefacto ronda 3 sección G).
2. **Slice 3:** debuffs zonales (cojera composable con Cargo vía Move+NW2, sway,
   visión) — arquitectura §6/§15.
3. Luego slice 4 (UI: HUD silueta, menú médico, StatusPanel, tab con convars).

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

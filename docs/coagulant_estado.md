# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-13 (**slices 1 y 2 cerrados**: la ronda 4 pasó
20/20 salvo el G6 opcional, y el fix G4 —`Inventory.HasItem` en Cargo— quedó
confirmado en juego. **Slice 3 en código** (debuffs zonales: cojera, sway,
visión), verificado offline en tres pasadas; **pendiente la ronda 5** en juego)

---

## Qué existe hoy

- **Slice 3 en código (debuffs zonales, §6):** cojera (`NW2Float
  "coagulant_speed_mult"` + hook `Move` **shared**, que escala el MaxSpeed del
  move data y COMPONE con el multiplicador de peso de Cargo — nunca
  `SetWalkSpeed`), sway de brazos (`ViewPunch` agnóstico al arma, 1.5-3 s,
  0.35° × score), visión de cabeza (vignette + fade a negro por herida
  media/grave) y la capa de sangre crítica (desaturación + vignette rojo, sin
  convar de apagado: es información vital). Tick propio de 0.5 s —la isquemia
  entra y sale sola por tiempo, no alcanza con los eventos de herida. Convars
  `coagulant_debuff_legs/arms/head`.
- **Slices 1 y 2 verificados en juego** (rondas 1-4): sangre 0-100 con NW2,
  heridas por damage type con el daño FINAL (`PostEntityTakeDamage`), timer 1 s
  (drenaje, regen, HP crítico → "You bled out."), eventos `Coagulant_*`, snapshot
  on-change; `ApplyTreatment` server-authoritative con **consumo AL COMPLETAR**,
  cancelación por daño/salto/velocidad, torniquete toggle con isquemia, modo
  degradado sin Cargo, y las 4 defs contra Cargo (Bandage/Tourniquet/Medkit/
  Blood Bag). Mapa archivo → rol en [`../CLAUDE.md`](../CLAUDE.md).
- **Diseño del Block 3 cerrado:** [`Coagulant_Architecture.md`](Coagulant_Architecture.md)
  (ratificado 2026-07-13; números de balance tunables en juego).
- **Verificación offline:** sintaxis (luaparser, 12 archivos) + harness (lupa +
  framework real + **Cargo real**) en tres pasadas — selftest **86 OK** con Cargo
  / 81 sin Cargo / 50 client. Comandos en juego: `coagulant_selftest`,
  `coagulant_status` (ahora también muestra los debuffs), `coagulant_setblood`,
  `coagulant_bandage`, `coagulant_dev_give`.
- **Vía de degradación standalone:** `Zones` (hitgroup crudo sin Caliber) + ítems
  contra Cargo con lazy-check (sin Cargo: log y apagado; tratamiento gratis con
  cooldown de 30 s).

## Pendiente de verificar

- **Slice 3 en juego** (artefacto, ronda 5, sección H): cojera que se compone con
  el peso de Cargo (y no se pelea), sway al herirse los brazos, vignette + fade a
  negro por herida de cabeza, capa de sangre crítica, y las tres convars de
  apagado. Todo el CHANGELOG del slice 3 está `[PENDIENTE]`.
- **G6 (opcional, diferido por el autor):** modo degradado sin Cargo — tratamiento
  gratis + cooldown 30 s (cubierto offline).
- **Ciclo largo de isquemia** (>90 s puesto → score 6, resaca de 60 s): confirmado
  solo por el harness — en la ronda 4 el torniquete fue a una zona sin herida
  grave. La ronda 5 lo vuelve a ofrecer (la cojera lo hace visible: la isquemia
  mueve la velocidad).

## Remanentes / deuda conocida

- **Regla aprendida (punto E + parche 8): las defs contra Cargo van en SHARED,
  onUse incluido** — Cargo no sincroniza defs por net; el grid cliente lee su
  tabla local y el menú "Use"/quick bind exige `isfunction(def.onUse)` en
  cliente (la closure solo CORRE en server).
- **Regla aprendida (G4): presencia de ítems contra Cargo = `Inventory.HasItem`**
  — `CountItem`/`TakeItem` son de stacks; los `unique` (`{id, uid}`, el
  torniquete) no existen para ellos. Anotado en arquitectura §12 y en el bloque
  CONTRACT del init de Cargo.
- **Sin barra de progreso ni silueta aún:** el snapshot ya lleva
  `{kind, endsAt, duration}` y el cliente ya lo recibe (`COAGULANT.ClientState`),
  pero la silueta de 6 zonas, la barra y el StatusPanel se dibujan en el slice 4.
- **ARC9 fino, diferido:** el sway es `ViewPunch` agnóstico; la integración por la
  API de ARC9 (spread/recoil) queda para más adelante (§6) — y sus nombres se
  verifican contra `dev/other/`, nunca de memoria.
- **Rama Caliber vacía a propósito** hasta su Block 3 (las heridas ya nacerían
  post-armadura sin tocar código acá, arquitectura §12).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. **Ronda 5 en juego** (autor, artefacto): sección H — los tres debuffs.
2. **Slice 4:** UI (HUD silueta, menú médico, StatusPanel de Cargo, tab Q con
   convars) — arquitectura §10/§15. Cierra el Block 3.

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

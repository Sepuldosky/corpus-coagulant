# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-14 (**ronda 5 corrida**: la cojera compone con el
peso de Cargo sin rubber-band —el punto crítico del slice— y los tres debuffs se
ven. Cayeron 2 bugs (**secuela permanente** y **torniquete clavado**) y el autor
decidió 3 cambios (medkit cura la secuela · sway en dos capas · vignette propio).
**Todo corregido en código**, verificado offline; **pendiente la ronda 6**)

---

## Qué existe hoy

- **Slice 3 en código (debuffs zonales, §6) — verificado en juego salvo los 2 fixes
  de la ronda 5:**
  - **Cojera** (`NW2Float "coagulant_speed_mult"` + hook `Move` **shared**, que
    escala el MaxSpeed del move data y COMPONE con el peso de Cargo — nunca
    `SetWalkSpeed`). **Confirmada en juego, incluida la composición con Cargo.**
  - **Sway** (reescrito tras la ronda 5): deriva **continua en dos capas** —
    temblor con el arma en mano, deriva incapacitante al apuntar (clic derecho,
    ×4). Vive en el **cliente** (`CreateMove`, aplicando el delta del offset: si
    no, la mira derivaría en vez de oscilar).
  - **Visión**: vignette **elíptico** (anillos triangulados, sin assets externos) +
    fade a negro por herida de cabeza media/grave, y la capa de sangre crítica
    (desaturación + vignette rojo que late), que no se apaga por convar.
  - Tick propio de 0.5 s — la isquemia entra y sale sola por tiempo. Convars
    `coagulant_debuff_legs/arms/head`.
- **La secuela tratada se cura con el Medkit** (decisión del autor, 2026-07-14):
  vendar corta el sangrado pero deja media severidad pesando en el debuff; el
  Medkit borra esa marca de una zona. Antes no se curaba nunca — una pierna
  vendada te dejaba cojo hasta morir.
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
  framework real + **Cargo real**) en tres pasadas — selftest **102 OK** con Cargo
  / 97 sin Cargo / 56 client. Comandos en juego: `coagulant_selftest`,
  `coagulant_status` (muestra score por zona, debuffs, **reloj del torniquete e
  isquemia**), `coagulant_setblood`, `coagulant_bandage`, `coagulant_dev_give`.
- **Vía de degradación standalone:** `Zones` (hitgroup crudo sin Caliber) + ítems
  contra Cargo con lazy-check (sin Cargo: log y apagado; tratamiento gratis con
  cooldown de 30 s).

## Pendiente de verificar

- **Ronda 6 en juego** (artefacto, sección H rehecha): los 4 fixes de la ronda 5 —
  el **Medkit curando la cojera**, el **torniquete que ahora SÍ se puede quitar**
  (+ isquemia visible en `coagulant_status`), el **sway nuevo** (¿alcanza el ×4 al
  apuntar?) y el **vignette elíptico**. La sesión "Fix ronda 5" del CHANGELOG está
  entera en `[PENDIENTE]`, junto con los parches 1-4 del slice 3 (el fix los
  reescribe en parte).
- **G6 (opcional, diferido por el autor):** modo degradado sin Cargo — tratamiento
  gratis + cooldown 30 s (cubierto offline).

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
- **ARC9 fino, diferido:** "apuntando" se detecta por el clic derecho
  (`IN_ATTACK2`) — agnóstico al arma y suficiente para ARC9/TFA/MW. La integración
  por la API real de ARC9 (spread/recoil) queda para más adelante (§6), y sus
  nombres se verifican contra `dev/other/`, nunca de memoria.
- **Sangre en pantalla: efecto propio, no reciclado.** Screen Blood Remaster y el
  mod de CoD tienen **licencia silenciosa = all-rights-reserved**
  (`dev/mods_workshop_mapa.md`): son COMPAT-RUNTIME, **no se pueden copiar**. El
  vignette es geometría propia; si algún día se quiere textura de sangre, la vía
  legal son los assets de `corpus-stalker` (GSC, política ya aceptada) o HL2.
- **Un torniquete `unique` puede atar varias extremidades** (no se consume y nada
  lo impide). No lo reportó nadie todavía; si molesta, es decisión de diseño
  (¿uno por zona?), no un bug.
- **Rama Caliber vacía a propósito** hasta su Block 3 (las heridas ya nacerían
  post-armadura sin tocar código acá, arquitectura §12).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. **Ronda 6 en juego** (autor, artefacto): los 4 fixes de la ronda 5.
2. **Slice 4:** UI (HUD silueta, menú médico, StatusPanel de Cargo, tab Q con
   convars) — arquitectura §10/§15. Cierra el Block 3.

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

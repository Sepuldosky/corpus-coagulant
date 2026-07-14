# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-07-14 (**ronda 6 corrida: los 4 fixes ✓ y con ellos
todo el slice 3** — los slices 1-3 quedan verificados en juego. Sobre eso bajó el
**slice 4 (UI): silueta, menú médico, barra de tratamiento, StatusPanel y tab Q** —
en código, verificado offline, **pendiente la ronda 7**, que lleva también el sway
retuneado. **Esa ronda cierra el Block 3**)

---

## Qué existe hoy

- **Slice 4 en código (UI, §10) — pendiente de la ronda 7:**
  - **Silueta de 6 zonas en el HUD**: color por score (sano → amarillo → rojo), la
    zona sangrante **late**, banda de torniquete (morada si hay isquemia). Se
    desvanece sola con el cuerpo sano y la sangre llena.
  - **Menú médico** (`coagulant_menu`, bind default M): silueta clickeable →
    heridas de la zona → los 4 tratamientos con el conteo real del inventario.
    Manda intents; **el server re-valida todo**.
  - **Barra de tratamiento** centrada abajo, calculada client-side desde el
    `{endsAt, duration}` del snapshot (§9 no ganó canal de red).
  - **Sangre**: barra en el StatusPanel de Cargo; **sin Cargo**, mini-barra propia
    bajo la silueta — la información vital no depende de un soft-dep.
  - **Tab Q real**: convars de cliente y server, binder del menú, soft-deps con lo
    que implica cada ausencia.
  - **La geometría de la silueta es UNA sola** (`Config.SILHOUETTE` + `ZoneAt`): lo
    que se pinta y lo que se clickea salen de la misma tabla, o el jugador vendaría
    una zona que no eligió. El selftest lo asserta zona por zona.

- **Slice 3 verificado en juego (debuffs zonales, §6) — rondas 5 y 6:**
  - **Cojera** (`NW2Float "coagulant_speed_mult"` + hook `Move` **shared**, que
    escala el MaxSpeed del move data y COMPONE con el peso de Cargo — nunca
    `SetWalkSpeed`). **Confirmada en juego, incluida la composición con Cargo.**
  - **Sway** (reescrito tras la ronda 5, **retuneado tras la 6**): deriva
    **continua en dos capas** — temblor con el arma en mano, deriva incapacitante
    al apuntar (clic derecho, ×4.5). Las capas son los **extremos de una rampa**,
    no un `if`: el factor de ADS va de 0 a 1 en 0.45 s por smoothstep (antes la
    amplitud saltaba 3.5° en un frame — el "tosco" de la ronda 6). Vive en el
    **cliente** (`CreateMove`, aplicando el delta del offset: si no, la mira
    derivaría en vez de oscilar).
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
- **Verificación offline:** sintaxis (luaparser, 13 archivos) + harness (lupa +
  framework real) en los **cuatro** cruces realm × Cargo — selftest **145 OK**
  (server+Cargo) / 140 (server) / **108** (client+Cargo) / 104 (client), más 69
  checks de harness. Comandos en juego: `coagulant_selftest`,
  `coagulant_status` (muestra score por zona, debuffs, **reloj del torniquete e
  isquemia**), `coagulant_setblood`, `coagulant_bandage`, `coagulant_dev_give`.
- **Vía de degradación standalone:** `Zones` (hitgroup crudo sin Caliber) + ítems
  contra Cargo con lazy-check (sin Cargo: log y apagado; tratamiento gratis con
  cooldown de 30 s).

## Pendiente de verificar

- **Ronda 7 — cierra el Block 3.** Dos cosas:
  1. **El slice 4 entero** (silueta, menú médico por zona, barra de tratamiento,
     barra de sangre en el StatusPanel, tab Q). El criterio de §15: *el flujo
     completo sin consola* — herirse, abrir el menú con la tecla, vendarse.
  2. El **sway retuneado** — ¿alcanza la amplitud nueva y se siente suave el paso a
     ADS? Los tres números (`SWAY_PER_SCORE`, `SWAY_IDLE_MULT`, `SWAY_ADS_MULT`) y
     el tiempo de rampa (`SWAY_ADS_RAMP_S`) son constantes del config: retunear no
     es tocar lógica.
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
- **La silueta es geometría propia** (rects por zona, no un modelo ni una textura):
  legible y sin depender de la licencia de nadie — misma política que el vignette.
  Si algún día se quiere una silueta dibujada, la vía legal son los assets de
  `corpus-stalker` o HL2.
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

1. **Ronda 7 en juego** (autor, artefacto): el slice 4 + el sway retuneado.
2. Si pasa: **checklist de cierre del Block 3** (arquitectura §16) — resumen + link
   en `CORPUS_Architecture.md` §9, CLAUDE.md al día, y anotar en
   `corpus/docs/corpus_estado.md` que Coagulant deja de ser scaffold. Después, el
   pendiente cross-repo: negociar `ApplyExternalCondition(ply, stat, severity)` con
   **Craving**, que tiene un puente mock-first esperándolo.

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

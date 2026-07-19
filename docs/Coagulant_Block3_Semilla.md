# Coagulant — Semilla del Block 3 (diseño del dominio médico)

> **Qué es este doc:** el punto de partida del Block 3 de diseño (sustrato v1 del
> médico de jugador estilo ACE3). NO es la arquitectura — es el inventario de lo ya
> congelado + las **decisiones abiertas** que se resuelven iterando con el autor,
> acá en el repo (decisión 2026-07-13: el diseño de mods no pasa por Desktop). A
> medida que las decisiones cierran, se anotan en §3 con su resolución; cuando el
> bloque converge, este doc se **vuelca** a `Coagulant_Architecture.md` (doc
> particular autocontenido, flujo §2) y la semilla queda como registro histórico.
>
> **Ese volcado ya ocurrió** (arquitectura ratificada el 2026-07-13, en bajada a
> código desde entonces): este doc es **registro histórico**, no una lista de
> trabajo. La fuente de verdad del diseño es `Coagulant_Architecture.md`; el estado
> vivo, `coagulant_estado.md`.
>
> Metodología: planificación densa por bloques + vertical slice
> (`../../corpus/docs/corpus_flujo_trabajo.txt` §2-§3).

---

## 1. Marco fijo (no se rediscute acá)

- **Frontera** (CORPUS_Architecture.md §4): Coagulant posee heridas por zona
  (jugador), sangrado, vitales, tratamiento; expone eventos de estado clínico;
  consume Caliber (hit-location enriquecido, mock-first hasta su Block 3) y Cargo
  (ítems médicos, ya disponible).
- **Contratos ya congelados por el scaffold** (CHANGELOG sesión 2026-07-13):
  - IDs de zona: `head`, `torso`, `left_arm`, `right_arm`, `left_leg`, `right_leg`
    (6 zonas estilo ACE3, mapa hitgroup nativo como vía de degradación).
  - `COAGULANT.ApplyBandage(ply) -> bool` como firma de `onUse` (§5 de la
    arquitectura de Corpus). El diseño puede generalizarla (p.ej.
    `ApplyTreatment(ply, kind, zone)`) manteniendo `ApplyBandage` como azúcar.
    > **DEROGADO por el slice 2** (CHANGELOG PARCHE 2 y PARCHE 3, ambos
    > `[APLICADO 2026-07-13]`): la generalización prevista ocurrió, pero la identidad
    > `onUse == ApplyBandage` **no** sobrevivió. Hoy `ApplyBandage` es SOLO azúcar del
    > contrato público (`= ApplyTreatment(ply, "bandage")`, `true` si el tratamiento
    > ARRANCÓ) y el `onUse` de cada ítem es un wrapper fabricado por
    > `UsarTratamiento(kind)` que devuelve **SIEMPRE `false`** — el `TakeItem` corre al
    > COMPLETAR. Sede vigente: **COA-3** (`Coagulant_Architecture.md` §7).
  - Degradación honesta: sin Caliber → hitgroup crudo; sin Cargo → vía mínima
    propia. Nunca crash, nunca asunción.
- **Reglas de ecosistema:** nada de dominio ajeno acá (contenedor/peso = Cargo,
  daño/armadura = Caliber); persistencia y net entran recién cuando el estado y el
  protocolo diseñados lo justifiquen; strings de jugador en inglés.

## 2. Referente de diseño

ACE3 medical (Arma 3) como norte conceptual — heridas por zona con severidad,
volumen de sangre, tratamiento por ítem y por zona — **adaptado a Gmod sandbox**:
sesiones cortas, sin médico dedicado garantizado, HP nativo del engine como
interfaz con todo lo demás (otros mods leen/escriben `Health()`). La traducción
literal de ACE3 (30+ ítems, vitales completos, cirugía) NO es el objetivo del
sustrato v1: se diseña el esqueleto que permita crecer hacia allá.

## 3. Decisiones abiertas

Cada decisión se cierra en conversación con el autor y se anota acá con
`→ RESUELTO:` antes de bajar nada a código. **Primera pasada cerrada el 2026-07-13**
(tres rondas de preguntas al autor). **No queda ninguna decisión abierta:** las tres
que quedaron delegadas a la arquitectura (curva de drenaje, vía sin Cargo, set de
convars) se cerraron ahí y ya están en código — cada una lleva abajo el puntero a
dónde vive su resolución.

### A. Modelo de vitales — la decisión estructural
- **→ RESUELTO (2026-07-13): A2 — sangre propia en paralelo.** Volumen de sangre
  estilo ACE3 como stat propio de Coagulant; el HP nativo queda para trauma
  directo del engine (y sigue siendo lo que leen/escriben los demás mods).
- **→ RESUELTO: regeneración lenta natural.** Con el sangrado cortado, la sangre
  se recupera sola muy lento (escala de minutos); la bolsa de sangre es el atajo.
  Evita quedar tullido permanente en sandbox sin médico.

### B. Incapacitación y muerte
- **→ RESUELTO (2026-07-13): muerte directa en v1** — sin estado caído/revive
  (se difiere a bloque futuro, ver §4).
- **→ RESUELTO (COA-10): la sangre no mata por umbral propio — sangre baja drena HP.**
  Por debajo de un % crítico, la sangre drena HP progresivamente; la muerte es
  SIEMPRE por HP 0 (compatible con killfeed, respawn y mods que setean HP). Los
  medkits HL2 curan HP pero no sangre: con sangre crítica, el HP curado se vuelve
  a drenar — el tratamiento real pasa por Coagulant.

### C. Heridas y sangrado — la mecánica núcleo
- **→ RESUELTO (2026-07-13): tipos de herida por damage type** (estilo ACE3:
  bala / corte / quemadura / contusión-caída…), cada tipo con sangrado y
  tratamiento compatible propios. La tabla exacta damage type → tipo de herida ×
  severidad es trabajo de la arquitectura (abajo).
- Apilado: **lista de heridas por zona** (implícito en la UI resuelta en F: se
  elige zona → se ven heridas → se trata herida por herida).
- **→ RESUELTO (arquitectura §3-§4, en código):** drenaje = `base(severidad) ×
  mult(tipo)` por tick de 1 s, con `base = { [1]=0.15, [2]=0.40, [3]=1.00 }`
  (`Config.BLEED_BASE` / `Config.BleedRate`) y `mult` por tipo en
  `Config.WOUND_TYPES` (bala 1.0, corte 0.8, metralla 0.9, quemadura 0.2,
  contusión 0.0). Severidad por daño **final**: `<15` leve · `15-40` media · `>40`
  grave. Tope de 5 heridas por zona (al exceder se agrava la más leve). La
  **contusión no sangra pero sí cuenta para el debuff zonal** (entra al score de
  `GetZoneScore` como cualquier herida); fractura como efecto estructural propio
  **no** entra en v1. Todos los números son tunables por convar/tabla.

### D. Efectos por zona (el "para qué" de las zonas)
- **→ RESUELTO (2026-07-13): los tres debuffs entran en v1** — pierna → cojera
  (walk/run), brazo → precisión (sway/cono; con ARC9 puede requerir su API —
  verificar contra `dev/other/`, nunca de memoria), cabeza → visión (blur/
  oscurecimiento o desmayo breve).
- Frontera con Caliber Block 3: **Coagulant es dueño de los debuffs CLÍNICOS del
  jugador; Caliber, de la mitigación** (propuesta en pie, a ratificar cuando
  Caliber abra su bloque).
- Dolor como stat: **diferido** (no hay analgésico en el set v1; entra con el
  bloque que lo necesite).

### E. Tratamiento v1
- **→ RESUELTO (2026-07-13): set de 4 ítems contra Cargo** — venda (corta
  sangrado leve/medio), torniquete (sangrado grave, solo extremidades, penalidad
  si queda puesto; ítem único no-stackable), kit médico (restaura HP/trauma),
  bolsa de sangre/salina (restaura volumen de sangre).
- **→ RESUELTO: uso con tiempo de aplicación + barra de progreso**, interrumpible
  (movimiento brusco / recibir daño).
- **→ RESUELTO: solo auto-tratamiento en v1** — tratar a otros se difiere (§4).
- **→ RESUELTO (arquitectura §7, en código): la propuesta se validó tal cual.** Sin
  Cargo, el menú médico ofrece los mismos tratamientos **sin consumir ítems**, con
  cooldown de 30 s (`Config.DEGRADED_COOLDOWN_S`) y los botones rotulados «field»;
  el concommand `coagulant_bandage` queda solo como debug/admin. La interacción con
  world-entities (botiquín de pared) queda **diferida**.

### F. Presentación y configuración
- **→ RESUELTO (2026-07-13): HUD silueta zonal + StatusPanel de Cargo.** Silueta
  propia de 6 zonas coloreadas (ACE3/EFT) para el detalle + barra de sangre vía
  `CARGO.StatusPanel.RegisterBar` si Cargo está (fallback a HUD propio si no).
- **→ RESUELTO: menú médico propio por zona** (tecla propia → silueta clickeable:
  zona → heridas → aplicar ítem del inventario). El uso rápido desde Cargo/quick
  slot aplica automáticamente a la zona más grave compatible.
- **→ RESUELTO (COA-29): spawn = cuerpo nuevo.** Morir/respawnear resetea el estado;
  desconectarse en vida lo conserva en memoria del server. **Sin persistencia a
  disco en v1** (sin `Corpus.Data` hasta que algo lo justifique).
- **→ RESUELTO (arquitectura §11, en código): 10 convars** — 8 de server
  (`coagulant_enabled`, los tres multiplicadores de dificultad `bleed_scale` /
  `regen_scale` / `hpdrain_scale`, `coagulant_debug`, y el on/off por subsistema
  `debuff_legs` / `debuff_arms` / `debuff_head`) y 2 de cliente (`coagulant_hud`,
  `coagulant_key_menu`). El tab Q (`corpus_coagulant_options.lua`) expone las de
  cliente, las de server (editables por admin), el binder del menú médico, el
  estado de los soft-deps y los comandos de verificación.

## 4. No-scope explícito del Block 3 (candidatos a bloques futuros)

- Medicina de NPCs (la frontera dice **jugador**; NPC limbs es de Caliber).
- Cirugía/hospital, enfermedades, temperatura.
- Integración fina con Craving (efectos de inanición) — Craving detecta a
  Coagulant cuando exista su superficie de eventos, no al revés.
- Sincronización de heridas al modelo visual (decals/gore).

## 5. Al cerrar el bloque (checklist, flujo §2)

1. Volcar las resoluciones a `Coagulant_Architecture.md` (autocontenido).
2. Sección resumen + link en `CORPUS_Architecture.md` (§9: Block 3 → Cerrado).
3. CHANGELOG: sesión nueva con los parches de bajada a código, `[PENDIENTE]`
   hasta verificación en juego.
4. Refrescar `coagulant_estado.md` y `coagulant_roadmap.txt` en sitio.

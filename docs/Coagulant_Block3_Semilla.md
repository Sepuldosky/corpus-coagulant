# Coagulant — Semilla del Block 3 (diseño del dominio médico)

> **Qué es este doc:** el punto de partida del Block 3 de diseño (sustrato v1 del
> médico de jugador estilo ACE3). NO es la arquitectura — es el inventario de lo ya
> congelado + las **decisiones abiertas** que se resuelven iterando con el autor,
> acá en el repo (decisión 2026-07-13: el diseño de mods no pasa por Desktop). A
> medida que las decisiones cierran, se anotan en §3 con su resolución; cuando el
> bloque converge, este doc se **vuelca** a `Coagulant_Architecture.md` (doc
> particular autocontenido, flujo §2) y la semilla queda como registro histórico.
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
`→ RESUELTO:` antes de bajar nada a código. Orden sugerido de discusión: A → F
(las de arriba condicionan a las de abajo).

### A. Modelo de vitales — la decisión estructural
¿Cuál es la fuente de verdad de "qué tan muerto estás"?
- **A1. HP nativo como única verdad:** el sangrado drena `Health()`; heridas y
  zonas son modificadores. Simple, compatible con todo (HUD, otros mods, respawn).
- **A2. Vitales propios (sangre) en paralelo:** volumen de sangre estilo ACE3;
  HP queda para trauma directo. Más fiel, pero dos barras de vida que reconciliar
  (¿qué pasa con un medkit HL2? ¿con `SetHealth` de otro mod?).
- Sub-decisión: ¿regeneración? (HL2 sandbox no regenera; ¿Coagulant introduce
  recuperación solo por tratamiento?)

### B. Incapacitación y muerte
- ¿Existe estado "caído pero no muerto" (unconscious/revive de ACE3) en v1, o
  muerte directa al llegar al umbral? Revive implica: ragdoll controlado, timer,
  interacción de segundo jugador — costo alto en Gmod.
- ¿La muerte por desangrado es distinta de la muerte por daño (feedback, killfeed)?

### C. Heridas y sangrado — la mecánica núcleo
- Tipos de herida v1: ¿solo "herida sangrante" genérica con severidad (1-3), o
  tipos por damage type (bala/corte/quemadura/fractura)?
- Apilado: ¿N heridas por zona (lista) o un nivel agregado por zona?
- Curva de sangrado: ¿drenaje = f(severidad total) lineal por tick? ¿umbral mínimo?
- Fracturas/efectos estructurales: ¿en v1 o se difieren?

### D. Efectos por zona (el "para qué" de las zonas)
- Pierna herida → ¿cojera (velocidad)? Brazo → ¿precisión/sway? Cabeza → ¿blur/
  desmayo? Torso → ¿solo sangrado mayor?
- Ojo con la frontera: Caliber Block 3 traerá su propio pipeline de daño de
  jugador; hay que definir quién aplica el debuff (propuesta: Coagulant es dueño
  de los debuffs CLÍNICOS del jugador; Caliber, de la mitigación).
- ¿Dolor como stat (afecta efectos, se trata con analgésico) o se difiere?

### E. Tratamiento v1
- Set de ítems inicial (contra Cargo): venda (corta sangrado leve), torniquete
  (corta sangrado fuerte en extremidad, con penalidad si se deja puesto),
  ¿kit médico (recupera HP)? ¿analgésico (si hay dolor)?
- ¿Uso instantáneo o con tiempo de aplicación (progress bar, interrumpible)?
- ¿Tratar a OTRO jugador en v1 (core de ACE3) o solo auto-tratamiento?
- Vía sin Cargo: ¿world-entity (botiquín de pared HL2) o solo el concommand?

### F. Presentación y configuración
- HUD: ¿silueta con zonas coloreadas (estilo ACE3/EFT), barras en el StatusPanel
  de Cargo (`CARGO.StatusPanel.RegisterBar` ya existe), o ambos con fallback?
- ¿Menú de tratamiento propio (tecla/radial) o el uso pasa solo por el inventario
  de Cargo + quick slots?
- Config del server (convars vía el tab Q): dificultad del sangrado, on/off de
  subsistemas.
- Persistencia: ¿el estado clínico sobrevive desconexión/cambio de mapa, o
  spawn = cuerpo nuevo siempre (como el scaffold hoy)?

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

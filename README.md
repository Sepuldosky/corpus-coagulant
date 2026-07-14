# Coagulant

Módulo **médico de jugador** del ecosistema [Corpus](https://github.com/Sepuldosky/corpus)
para **Garry's Mod**, estilo ACE3: heridas por zona, sangrado, vitales y tratamiento. Addon
independiente que **hard-depende** de Corpus (la única dependencia dura del ecosistema) y
detecta a los demás módulos en runtime, nunca los asume.

> **Estado: Block 3 en bajada — slice 4 de 4.** El diseño del dominio médico está
> ratificado (2026-07-13) en [`docs/Coagulant_Architecture.md`](docs/Coagulant_Architecture.md)
> y bajado a código: volumen de sangre (0-100) en paralelo al HP nativo, heridas por zona
> con tipo según el damage type y severidad según el daño final, sangrado que drena sangre
> y —bajo el umbral crítico— HP, tres debuffs zonales (cojera, sway de puntería, visión),
> tratamiento con tiempo de aplicación e interrupción, cuatro ítems médicos contra el
> framework de ítems de [Cargo](https://github.com/Sepuldosky/corpus-cargo) (venda,
> torniquete, medkit, bolsa de sangre) y la UI (silueta zonal, menú médico, tab Q). Los
> slices 1-3 están verificados en juego; el 4 (UI) espera su ronda de verificación, que
> **cierra el bloque**. La integración con Caliber va mock-first hasta que exista su
> pipeline de jugador. Foto de HOY → [`docs/coagulant_estado.md`](docs/coagulant_estado.md);
> el rumbo del ecosistema vive en el
> [roadmap de Corpus](https://github.com/Sepuldosky/corpus/blob/main/docs/corpus_roadmap.txt).

## Dependencias

- **Corpus** (dura — framework del ecosistema).
- **Caliber** (soft — hit-location enriquecido con datos de armadura/zona). Sin él,
  Coagulant degrada a hit-location por hitgroup crudo del engine.
- **Cargo** (soft — vendas, torniquetes y demás ítems médicos como ítems de inventario).
  Sin él, el menú médico ofrece los mismos tratamientos sin consumir ítems, con un
  cooldown de 30 s y rotulados «field» — modo degradado explícito.

Diseño de referencia del ecosistema y grafo de dependencias →
[`CORPUS_Architecture.md`](https://github.com/Sepuldosky/corpus/blob/main/docs/CORPUS_Architecture.md)
(§1-§2, §9).

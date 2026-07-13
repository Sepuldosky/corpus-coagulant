# Coagulant

Módulo **médico de jugador** del ecosistema [Corpus](https://github.com/Sepuldosky/corpus)
para **Garry's Mod**, estilo ACE3: heridas por zona, sangrado, vitales y tratamiento. Addon
independiente que **hard-depende** de Corpus (la única dependencia dura del ecosistema) y
detecta a los demás módulos en runtime, nunca los asume.

> **Estado: scaffold pre-diseño.** El repo tiene la estructura del módulo (boot sobre las
> primitivas de Corpus, zonas clínicas, estado por jugador sin gameplay, ítem semilla
> contra el framework de ítems de [Cargo](https://github.com/Sepuldosky/corpus-cargo) —
> ya en código y verificado), pero su bloque de diseño de dominio (heridas, sangrado,
> vitales, tratamiento) sigue pendiente. La integración con Caliber va mock-first hasta
> que exista su pipeline de jugador. Foto de HOY → [`docs/coagulant_estado.md`](docs/coagulant_estado.md);
> el rumbo del ecosistema vive en el
> [roadmap de Corpus](https://github.com/Sepuldosky/corpus/blob/main/docs/corpus_roadmap.txt).

## Dependencias previstas

- **Corpus** (dura — framework del ecosistema).
- **Caliber** (soft — hit-location enriquecido con datos de armadura/zona). Sin él,
  Coagulant degrada a hit-location por hitgroup crudo del engine.
- **Cargo** (soft — vendas, torniquetes y demás ítems médicos como ítems de inventario).
  Sin él, tratamiento por world-entity o vía mínima propia.

Diseño de referencia del ecosistema y grafo de dependencias →
[`CORPUS_Architecture.md`](https://github.com/Sepuldosky/corpus/blob/main/docs/CORPUS_Architecture.md)
(§1-§2, §9).

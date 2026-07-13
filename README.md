# Coagulant

Módulo **médico de jugador** del ecosistema [Corpus](https://github.com/Sepuldosky/corpus)
para **Garry's Mod**, estilo ACE3: heridas por zona, sangrado, vitales y tratamiento. Addon
independiente que **hard-depende** de Corpus (la única dependencia dura del ecosistema) y
detecta a los demás módulos en runtime, nunca los asume.

> **Estado: sin empezar.** Este repo aún no tiene código. Coagulant espera su bloque de
> diseño; sus ítems médicos ya tienen dónde registrarse (el framework de ítems de
> [Cargo](https://github.com/Sepuldosky/corpus-cargo) está en código y verificado), y la
> integración con Caliber irá mock-first hasta que exista su pipeline de jugador. El rumbo
> del ecosistema vive en el
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

# Assets — qué modelos existen y cuáles están sin usar

**Esta página contesta una sola pregunta: «¿tenemos ya un modelo para X?».** Existe porque la
respuesta estaba escrita sólo en [`CREDITOS.md`](CREDITOS.md), que es una página de *licencias* —
nadie la abre buscando un asset— y ni el `CLAUDE.md` ni el roadmap la nombraban. Un inventario
guardado donde nadie lo busca no existe para la sesión siguiente.

Los `.mdl` **sí están en el repo** (a diferencia de phantasmagoria, que los deja fuera). Se cargan
solos; no hay nada que montar.

- **Créditos y licencia:** [`CREDITOS.md`](CREDITOS.md). Los tres packs son **CC BY 4.0** y la
  atribución es obligatoria, no cortesía.
- **Cómo se regeneran:** cada `.mdl` tiene su `.qc` en `dev/phastools/compile/src/` con el comando
  exacto. Herramientas en `dev/phastools/` (`fbx2smd.py`, `pbr2source.py`, `png2vtf.py`,
  `verify_model.py`).

---

## Los 19 modelos

`models/corpus_coagulant/` — 10,8 MB. Materiales en `materials/models/corpus_coagulant/`
(18 VMT + 31 VTF, 16,5 MB). El **tamaño** es la dimensión mayor del modelo terminado.

| `.mdl` | Qué es | Tris | Tamaño | Translúcido | Usado por |
|---|---|---:|---|---|---|
| `bandage` | tres rollos de gasa | 1.926 | 9,0 cm | — | **`corpus_coagulant_bandage`** |
| `firstaidkit` | botiquín blanco con cruz | 8.860 | 17,9 cm | — | **`corpus_coagulant_medkit`** |
| `bloodbag` | bolsa de sangre / suero | 3.732 | 26,4 cm | sí | **`corpus_coagulant_bloodbag`** |
| `medkit_large` | botiquín naranja abierto — **bodygroup, ver abajo** | 48.278 | 30,0 cm | — | — |
| `medkit_large_closed` | el mismo, **cerrado** (modelo aparte) | 3.590 | 29,7 cm | — | — |
| `pill_bottles` | dos frascos de pastillas + sueltas | 20.376 | 9,0 cm | sí | — |
| `pill_blisters` | blísteres de pastillas | 13.632 | 7,1 cm | — | — |
| `vials` | cinco frascos de medicación | 8.360 | 12,1 cm | sí | — |
| `gloves_box` | caja de guantes de nitrilo | 7.132 | 10,0 cm | — | — |
| `test_tubes` | gradilla con cinco tubos | 6.434 | 21,2 cm | sí | — |
| `syringes` | cinco jeringas | 5.900 | 11,5 cm | — | — |
| `bust_stethoscope` | busto de maniquí con estetoscopio | 3.460 | 19,7 cm | — | — |
| `sutures` | dos carretes de sutura con aguja | 2.832 | 5,0 cm | — | — |
| `patches` | caja de curitas + dos sueltas | 2.368 | 11,4 cm | — | — |
| `spray` | frasco de desinfectante | 1.232 | 17,6 cm | — | — |
| `pain_pills` | frasco de analgésicos | 732 | 10,0 cm | — | — |
| `mask` | barbijo quirúrgico | 600 | 11,0 cm | — | — |
| `tray` | bandeja de instrumental | 380 | 21,5 cm | — | — |
| `thermometer` | termómetro digital | 232 | 12,9 cm | — | — |

**140.056 tris en total** (19 modelos). El `medkit_large` solo es el 35 % de eso; si alguna vez hay que recortar,
ése es el número a mirar.

## El botiquín grande son DOS modelos

| `.mdl` | Qué es | Tris | Alto del casco |
|---|---|---:|---|
| `medkit_large` | abierto — `$bodygroup state` de dos opciones | 48.278 / 3.590 | 11,81 u |
| `medkit_large_closed` | **cerrado, modelo aparte** | 3.590 | **3,52 u** |

El bodygroup del abierto:

| # | Opción | Tris que dibuja |
|---|---|---:|
| **0** | `open_full` — abierto y lleno (**el default**) | 48.278 |
| 1 | `open_empty` — abierto y vacío | 3.590 |

```lua
ent:SetBodygroup(ent:FindBodygroupByName("state"), 1)   -- abierto y vacío
ent:SetModel("models/corpus_coagulant/medkit_large_closed.mdl")   -- cerrado
```

**Por qué el cerrado no es una tercera opción del bodygroup.** Source tiene **un
`$collisionmodel` por modelo, no por bodygroup**. Mientras estuvo adentro había que darle el casco
del abierto, y medido eso dejaba **8,29 u (~21 cm) de colisión invisible por encima** de la caja:
apoyaba bien en el piso pero no se podía pasar por arriba. Separado tiene el suyo, ajustado a su
malla con 0,000 u de holgura, y además pesa lo que dibuja — 244 KB de `.vvd` contra 2,75 MB.

Las dos opciones que quedan **sí** comparten casco legítimamente: `open_empty` es un subconjunto
de `open_full`. Y comparten centrado y escala, fijados por la opción 0 — si cada una se centrara
sola, el modelo **saltaría** al cambiar de bodygroup y dejaría de coincidir con el `.phy`.

Los dos `.mdl` comparten la textura (`medkit_large.vmt`): es el mismo objeto. Y **el cerrado hereda
el factor de escala del abierto, no lo recalcula** — si se normalizara a 30 cm por su cuenta saldría
~3,4× más grande, porque cerrado es mucho más bajo. El generador lo comprueba comparando el ancho de
la caja en los dos y aborta si no coincide.

> **`firstaidkit` (el blanco) también está abierto y NO tiene variantes.** El naranja se prestó
> porque trae la tapa como objeto propio (`MetalCover`) con la bisagra deducible de la geometría;
> para el otro ese trabajo hay que rehacerlo desde cero. Se puede; no está hecho.

## Los 16 sin def

Tres modelos tienen ítem; **dieciséis no**. Están ahí a propósito: son material para defs futuras, no
sobras. Lo que hay que saber antes de usarlos:

- **No se inventan ítems para justificar un modelo.** COA-28 manda al revés: el diseño se discute
  con el autor y se anota en la arquitectura primero. Que exista `syringes.mdl` no crea un ítem
  «jeringa».
- Los que la arquitectura **ya tiene diferidos** (§1, §7) y podrían encontrar modelo acá el día que
  se abran: **analgésico** → `pain_pills` o `pill_bottles`; **férula** → nada apropiado todavía.
- `bust_stethoscope`, `tray`, `test_tubes` y `medkit_large` son **props de escenario**, no cosas que
  un jugador lleve encima.

## Los huecos conocidos

- **Torniquete: no hay modelo, y no es un olvido.** En los tres packs no existe ninguno. El
  candidato que lo parecía (`Lines` en el FBX) resultó, al renderizarlo, ser dos carretes de sutura
  con aguja — el modelo que acá se llama `sutures`. `corpus-stalker` llegó a la misma conclusión con
  sus propios packs el 2026-07-23. El ítem cae a la cajita de cartón de Cargo hasta que aparezca uno.
- **`sutures` mide 1,97 unidades de Source** y es el único que marca C1 de `verify_model.py`, cuyo
  umbral es 2. **El tamaño es el correcto** (un carrete de sutura mide 5 cm): el check marca props
  chicos, no un defecto. Si en juego resulta incómodo de agarrar, la salida es subirle la escala a
  ése solo — a costa de romper la del resto del set, que comparte un único factor.
- **`firstaidkit` lleva una cruz roja** y su pack no trae variante alternativa. El emblema está
  protegido por los Convenios de Ginebra. El `medkit_large` sí tenía variante y se usa la segura
  (ver [`CREDITOS.md`](CREDITOS.md)). **Decisión pendiente si esto se publica al Workshop.**

## El modelo declarado es un default, no un candado

Las defs declaran `model`, pero `Cargo.Items.SetModel` **pisa el modelo declarado y se re-aplica en
cada `Register`**. Un addon de contenido puede vestirlos a su setting sin tocar este repo.

**Hoy nadie lo hace.** `corpus-stalker` sustituía la venda y el medkit hasta el 2026-08-06 y lo
**retiró**: sus botiquines de la Zona tienen otro peso, otro precio y otra curación, así que van a
ser ítems propios y no una piel sobre los genéricos. La puerta sigue abierta; lo que cambió es que
vestir al genérico con el modelo de otro ítem se considera una mentira sobre lo que es.

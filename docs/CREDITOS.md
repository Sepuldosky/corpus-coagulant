# Créditos

Coagulant **incluye modelos 3D de terceros**. El código es del proyecto; **los modelos no**, y sus
autores conservan sus derechos. Esta página existe para que el crédito sea explícito y verificable,
y porque **la licencia lo exige**: los tres packs son CC BY 4.0, que permite redistribuir, modificar
y usar comercialmente **a cambio de atribuir**.

> **Si sos el autor de alguno de estos assets y querés que se retiren, se retiran.** Sin discusión y
> sin condiciones. Abrí un issue o escribí, y sale en la siguiente versión.

> **¿Buscabas saber qué modelos hay, no de quién son?** Está en [`ASSETS.md`](ASSETS.md): los 19 con
> qué es cada uno, cuáles tienen def y cuáles no. Esta página es sobre licencias.

---

## Modelos

Los tres se bajaron de Sketchfab con licencia **CC Attribution 4.0 International**
(<https://creativecommons.org/licenses/by/4.0/>) y **están modificados**: convertidos a formato
Source (`.mdl`), reescalados, separados en piezas y con sus materiales PBR reconvertidos al modelo
de iluminación de Source. Decir que se modificaron es parte de la obligación de CC BY, no un
detalle.

### Medical Supplies Collection — 16 modelos

- **Autor:** **Miguel Adão** (`@theauditor`)
- **Fuente:** <https://sketchfab.com/3d-models/medical-supplies-collection-eae9fc470e674c458791cf00b892340f>
- **Licencia:** CC BY 4.0
- **Rutas:** `models/corpus_coagulant/`, `materials/models/corpus_coagulant/`

| `.mdl` | Qué es | Tamaño |
|---|---|---|
| `bandage` | tres rollos de gasa | 9,0 cm |
| `bloodbag` | bolsa de sangre / suero | 26,4 cm |
| `bust_stethoscope` | busto de maniquí con estetoscopio | 19,7 cm |
| `firstaidkit` | botiquín blanco con cruz | 17,9 cm |
| `gloves_box` | caja de guantes de nitrilo | 10,0 cm |
| `mask` | barbijo quirúrgico | 11,0 cm |
| `patches` | caja de curitas + dos sueltas | 11,4 cm |
| `pill_blisters` | blísteres de pastillas | 7,1 cm |
| `pill_bottles` | dos frascos de pastillas | 9,0 cm |
| `spray` | frasco de desinfectante | 17,6 cm |
| `sutures` | dos carretes de sutura con aguja | 5,0 cm |
| `syringes` | cinco jeringas | 11,5 cm |
| `test_tubes` | gradilla con cinco tubos | 21,2 cm |
| `thermometer` | termómetro digital | 12,9 cm |
| `tray` | bandeja de instrumental | 21,5 cm |
| `vials` | cinco frascos de medicación | 12,1 cm |

Los 16 comparten **un solo factor de escala** (×2 sobre el original). El archivo trae proporciones
correctas **entre sus ítems** y sólo está a media escala real; normalizar cada uno por separado
habría dejado la venda del tamaño de la bandeja.

### Medical First Aid Emergency Kit

- **Autor:** **RayznGames**
- **Fuente:** <https://sketchfab.com/3d-models/medical-first-aid-emergency-kit-d588fee3c3a94c0d82884c2fc1505e9c>
- **Licencia:** CC BY 4.0
- **Rutas:** `models/corpus_coagulant/medkit_large.mdl` (abierto, 30 cm, 48.278 tris, con
  bodygroup lleno/vacío) y `models/corpus_coagulant/medkit_large_closed.mdl` (cerrado, 3.590
  tris, colisión propia). Comparten textura. Ver [`ASSETS.md`](ASSETS.md).

> **Se usa la textura `RedCrossSafe` del propio autor, no su albedo principal.** Los dos archivos
> difieren en 13.462 píxeles, todos en un cluster de 232×213: el albedo lleva una **cruz roja**
> sobre disco blanco y la variante segura la deja calada. El emblema de la Cruz Roja está protegido
> por los Convenios de Ginebra y su uso está restringido fuera del contexto sanitario y militar —
> el autor separó las dos versiones justamente por eso.

### Simple Pain Pills

- **Autor:** **Blender3D**
- **Fuente:** <https://sketchfab.com/3d-models/simple-pain-pills-e8ff733b5a184335aac1e59d4c0820e0>
- **Licencia:** CC BY 4.0
- **Ruta:** `models/corpus_coagulant/pain_pills.mdl` — 10 cm, 732 tris

---

## Qué usa cada def

De los 19 modelos, las defs de ítem usan **tres**; el resto son props de escenario disponibles
para defs futuras.

| Ítem | Modelo |
|---|---|
| `corpus_coagulant_bandage` | `bandage.mdl` |
| `corpus_coagulant_medkit` | `firstaidkit.mdl` |
| `corpus_coagulant_bloodbag` | `bloodbag.mdl` |
| `corpus_coagulant_tourniquet` | **ninguno** — no hay torniquete en los packs |

**El modelo declarado es un DEFAULT, no un candado.** `Cargo.Items.SetModel` pisa el modelo del def
y se re-aplica en cada registro, así que un addon de contenido —`corpus-stalker` ya lo hace con la
venda y el medkit de la Zona— los sigue vistiendo a su setting sin tocar este repo.

---

## Cómo se reproducen

Los `.mdl` no se editaron a mano. Cada uno tiene su `.qc` en `dev/phastools/compile/src/` con el
comando exacto que lo regenera desde el archivo de origen, y las herramientas
(`fbx2smd.py`, `pbr2source.py`, `png2vtf.py`, `verify_model.py`) viven en `dev/phastools/`.
El registro de créditos del workspace, con el censo completo, está en
`dev/Creditos_Modelos_Terceros.md`.

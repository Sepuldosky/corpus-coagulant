# Coagulant — Estado de HOY

> **Foto del AHORA**, volátil. Es lo primero que se lee al retomar el módulo —
> **antes** que el doc de arquitectura. Se actualiza **en sitio** (no se agregan
> secciones ni historial). El historial vive en `git` + [`CHANGELOG.md`](CHANGELOG.md).
> Si crece de una pantalla, está mal redactado: recortar.

**Última actualización:** 2026-08-25d (**EL METABOLISMO BAJÓ A CÓDIGO — COA-38/39/40, la superficie para Craving.** El diseño se votó el 2026-08-08 en cinco puntos y con cero Lua; hoy lo ejerce el código: `ApplyExternalCondition` con los dos ids clínicos y **la tabla de config como PUERTA** —un id que no está devuelve `false`, y eso no es burocracia: es lo que le avisa al emisor que ese daño **sigue siendo suyo**—, las tres palancas sobre el tick de 1 s que ya existía, la lectura de Craving por capacidad (COA-38) y la fila METABOLIC en el menú. **El consumidor ya estaba esperando**: el puente de Craving llama a la función con `pcall` detrás de un gate de capacidad desde hace un mes, así que enciende solo. **⚠ Y LA BAJADA MIDIÓ QUE UNA PREMISA DEL DISEÑO ES FALSA:** COA-40 afirma que *«los cinco entran por palancas que YA EXISTEN»*, y `hunger` y `energy` apuntan al **techo de stamina**, que **§1 del mismo documento difiere por escrito**; los **bpm** de `dehydration` tampoco existen (0 hits). Nadie cruzó las dos secciones al votar. Bajaron **tres** palancas vivas y **dos escritas y NEUTRAS**, declaradas con `live = false` y sostenidas por harness — el mismo precedente que COA-52 estrenó con `PAIN_FRAC`, y con una fila (`MET-F5`) que **se pone roja el día que la stamina exista**, para que el término inerte no envejezca en silencio. **Voto del autor, no delegado:** la fila METABOLIC dibuja las **cinco** causas con las dos sin palanca **en gris**, porque un chip encendido que no produce efecto acredita algo que no está pasando. **Tres decisiones de implementación que el diseño no fijaba:** las dos vías que llegan a una palanca —la condición empujada y el crudo leído— se combinan con **`max()`** y no sumando, porque describen el mismo cuerpo y sumarlas cobra **dos veces la misma sed**; el techo **TECHA Y FRENA, NUNCA MATA** (acota hasta dónde regenera y jamás empuja la sangre hacia abajo — un `math.min` ahí le daría a la sed su propia vía de muerte); y el factor de sangrado se aplica en `DrenajeTotal` y **no dentro de `BleedRate`**, que es pura y no tiene jugador. **La verificación en negativo volvió a auditar al que la escribió, y esta vez los CUATRO problemas fueron de MIS INSTRUMENTOS y NINGUNO del código**: un check que no discriminaba porque le di el mismo `mag` a las dos ramas de un `max()`; un fixture que mi propio parche había borrado, dejando dos checks vecinos midiendo lo mismo; un selftest que medía con la condición equivocada todavía puesta; y un alcance declarado que estaba mal —el tick **también** consume COA-38—. Más un quinto del control de higiene: el texto de reemplazo de un sabotaje era `st.dirty = true`, que aparece cinco veces más en `core.lua` por razones legítimas, y el verificador daba «árbol sucio» con el árbol impecable. **Regla que queda: el `nuevo` de un sabotaje tiene que ser un texto ÚNICO.** Verificación: **331 checks ALL GREEN**, selftest **238 server / 161 client**, y `dev/sabotaje_coagulant_metabolismo.py` **21/21 en rojo, cada uno sólo en las familias que declaró**, con 2 no-detectables en verde. **FALTA LA PASADA EN JUEGO** — planilla de 12 filas en `dev/checks/coagulant-metabolismo-r1.html`, publicada acá: https://claude.ai/code/artifact/fa3fd433-cc7d-428e-b72a-a34bff488132 Antes, 2026-08-25c: **EL DOLOR CERRÓ EN JUEGO — COA-52, planilla de 12 filas: 12 PASA, 0 FALLA, 0 SIN CORRER, y ningún defecto.** Ninguna fila se acreditó por su marca: cada `dolor` impreso en las notas se volvió a derivar contra la tabla de tres ejes y todos dan exacto. **Lo que la ronda compró de verdad es la fila ★★:** vendar dejó el `chest` con `score 3.0 → 1.5` (×0.5) y el `dolor 38 → 13` (37,8 × **0.35**), así que los dos repartos **vecinos** de `core.lua` quedan medidos como distintos **EN JUEGO** y no derivados de la constante — que es exactamente lo que la trampa de COA-35 no deja hacer con un check. **La otra fila que sólo podía pasar de una manera es la 07:** la segunda dosis se desgatilló con el percibido en 4-6 mientras el crudo seguía en **24** — leyendo `GetRawPain` la puerta (`pain > 10`) se habría abierto, o sea que el reporte prueba el LLAMADOR y no sólo el umbral. La 05 cerró sus **tres** mitades y la tercera es la que importa: supresión **33,8** a los 6 s de la pastilla (35 − 6×0,20), percibido **0** y **crudo 24 INTACTO** — el analgésico enmascara y no cura, que es lo votado en D5. La 06 midió el decaimiento como propiedad (33,8 → 20,0 en ~69 s = 0,20/s) y la 09 dio `ClientState.pain = 6` con el NW2 en `-1` y la consola diciendo `percibido 6`. **Los dos votos delegados quedaron EN PIE: el autor no vetó ninguno.** **Tres cosas salieron de notas de filas VERDES y ninguna es un defecto del dolor:** (1) en la 03 hay un `bala sev2` donde la 02 tenía cinco `bala sev1`, y no es dolor sino `MAX_WOUNDS_PER_ZONE = 5` — con la zona llena `AddWound` **agrava la más leve en vez de agregar** y además la des-trata (`core.lua:231-242`), así que **la lista de heridas de una zona no es el registro de lo que le pegó**; (2) la planilla prometía `[ISQUEMIA — Ns restantes]` y el juego imprimió `[ISQUEMIA activa]` — **sobre-prometió el INSTRUMENTO, no el código**: `ischemiaUntil` sólo se escribe al QUITAR el torniquete pasados los 90 s (`treatment.lua:197`, `ISCHEMIA_LINGER_S`), y con la banda puesta la isquemia no tiene fin, así que la rama de fallback es la correcta — la planilla **no se reescribe** (§6.5) y ésta es la corrección; (3) en la 04 cada zona imprimió **100** con 3 × metralla sev3 = **120**, o sea que `ZonePain` **también** clampea en `PAIN_MAX` y el clamp de ZONA dispara **antes** que el global — la fila igual mide lo que dice (Σ 300 → 100), y hoy el clamp de zona **no puede cambiar el resultado global**, porque los siete `ZONE_PAIN_WEIGHT` valen 1.0 y una zona en ≥100 ya satura sola; deja de ser neutro el día que un peso baje de 1, y eso es pregunta de COA-44. Árbol re-medido ANTES de leer el reporte: **275 checks ALL GREEN**, selftest **221 server / 161 client**, y `dev/verificar_arbol_sabotaje.py` con el árbol **LIMPIO**. Los parches **1-8** pasan a `[APLICADO 2026-08-25]`, y la **niebla diagnóstica (COA-44)** queda sin bloqueante y con su insumo **confirmado en juego**. Antes, 2026-08-25b: **EL DOLOR BAJÓ A CÓDIGO — COA-52, y con su primer consumidor EN JUEGO.** La norma se votó el 2026-08-17 con tabla de balance propuesta y cero Lua; hoy la ejerce el código: la tabla entera en `config.lua` (bloque *Dolor (§17, COA-52)*, con `PainFromWound` y `PainFrac` como las dos puras), `ZonePain`/`GetRawPain`/`GetPain`/`AddPainSuppression` en `core.lua`, el decaimiento de `painSuppress` en el tick de 1 s que YA existía y el `p` por zona + el percibido global en el snapshot (`bleeding.lua`), y `HUD.ZonePain`/`HUD.Pain` en el cliente, **que sólo LEEN**. **El dolor no gana un NW2 y eso es norma, no detalle**: un NW2 se replica a todos los clientes y no tiene filtro por observador, así que un vital que la niebla (COA-44) pueda ocultar tiene que ir en el snapshot, que es owner-only. **LA PREGUNTA QUE EL PROMPT TRAÍA SIN VOTAR SE RESOLVIÓ POR DELEGACIÓN DEL AUTOR** (*«Hace votos sobre la pregunta que ibas a formular»*, 2026-08-25) y queda escrita como voto delegado y no como decisión del autor —**se puede vetar barato**—: se eligió **(B) en su forma mínima**, o sea el **analgésico oral** como quinta def médica (`corpus_coagulant_painkillers`, `pain_pills.mdl`, stackable, 0.1 kg, 3 s, `value` 10 est., puerta `pain > 10` **sobre el percibido**) más el dolor **como número** en el menú médico. El motivo es el que Cargo acaba de pagar en su #60: **sin nada que mueva el dolor en juego, la ronda no puede ver fallar ninguna de las seis decisiones y el tramo queda acreditado sólo offline**. La **morfina NO entra** —su constante está votada pero su ítem arrastra sobredosis y naloxona, que son del catálogo (COA-50)— y **la silueta NO se tocó**: se sigue pintando con el SCORE, porque la rampa de dolor es de la niebla y baja con ella. **Dos trampas de COA-35 que este tramo destapó y que valen para todo el repo:** un check que DERIVA su esperado de la constante **no puede auditar esa constante** —`ZonePain(tratada) == base × PAIN_TREATED_MULT` sigue verde con el mult en 1.0, y el decaimiento derivado sigue verde con la tasa en 0—, así que cada constante lleva **dos filas**: una derivada (qué vale) y una de propiedad (*vendar ALIVIA*, *el efecto SE PASA*); y el reparto de las tratadas es **0.35 en el dolor contra 0.5 en el score**, dos números distintos en funciones **vecinas** de `core.lua`, que es el error natural de este archivo y no da ningún síntoma. Verificación: harness **275 checks, ALL GREEN, exit 0** (86 filas nuevas, 85 de ellas citando COA-52), selftest **221 server / 161 client**, y verificación en negativo propia en `dev/sabotaje_coagulant_dolor.py` — cada sabotaje **declara qué familias tiene que teñir** y falla en las dos direcciones, más **tres no-detectables declarados** que se corren exigiendo verde. Uno de ellos es el que el prompt mandó **declarar en vez de acreditar**: el cambio de predicado del emisor (*«aporta dolor ≠ 0»* en vez de *«tiene heridas»*) **no puede fallar hoy**, porque las dos condiciones seleccionan lo mismo hasta que exista `frac`. **FALTA LA PASADA EN JUEGO** — planilla en `dev/checks/coagulant-dolor-r1.html`. Y con esto **la niebla diagnóstica (COA-44) se queda sin su único bloqueante**. Antes, 2026-08-25: **BARRIDO DE DRIFT, cero código: el bloqueante que este repo declaraba contra Cargo está CAÍDO hace dos días y las docs seguían diciendo que no.** Cargo **ratificó y escribió** el pedido de COA-51 el **2026-08-22** — `AreaHas`/`AreaCount`/`AreaTake` **y una cuarta que no se había pedido, `AreaTakeUnique`** (su roadmap **#60**, CHANGELOG 80, commit `63c784f`, `corpus_cargo_containers.lua:646-741`, **server-only**) —, así que **el área hospital (COA-50/COA-51) ya no tiene bloqueante externo**. La cuarta no es un regalo: salió de que Cargo **midiera el `lua/` de este repo** —`treatment.lua:163` gatea con `HasItem` y `:170` consume con `TakeUnique` porque **el torniquete es `unique`**—, o sea que con las tres pedidas el área habría **visto** un torniquete en un mueble sin poder consumirlo: **el fallo G4 otra vez, movido del lado de la presencia al del take**, y cobrado dentro del bloque de doc que se escribió para evitarlo. **Y la deuda se dio vuelta:** Cargo dejó la **pasada en juego** de su #60 **diferida hasta que exista el área hospital**, por ser su único consumidor — **hoy el que bloquea es este repo**, y cuando el área baje, esa planilla viaja con ella. Segundo drift del mismo barrido: el **multiplicador de precio por categoría** que este estado citaba como *«sin ratificar»* está **CERRADO EN JUEGO** desde el 2026-08-22 (Cargo #61, planilla AN 10/10), y `medical` es una de las categorías que Cargo registra de fábrica ⇒ **`cargo_value_mult_medical` ya existe**: la salida que los cuatro precios médicos tenían anotada dejó de ser una promesa. **Nada de esto toca una línea de Lua.** El harness se re-corrió igual, porque un ALL GREEN citado y no medido es la mitad del drift que este barrido vino a arreglar: **189 checks, ALL GREEN, exit 0**; selftest **192 server / 142 client**. Sigue faltando la pasada en juego de los precios. Antes, 2026-08-18: **las cuatro defs médicas tienen `value`** — nacieron sin él, y sin `value` Cargo NO las comercia: su `Trade.IsTradeable` exige `value > 0` y la AUSENCIA significa *«no está a la venta»*, no *«gratis»*. Un trader las **listaba** y el server se negaba a moverlas. Nadie de este repo lo podía notar —Coagulant no vende nada—: salió desde afuera, escribiendo los traders de `corpus-stalker`. Venda **8** · torniquete **35** · medkit **50** · bolsa de sangre **220**, los cuatro **estimaciones etiquetadas como tales** (anclas de retail EE.UU., sin serie publicada detrás como la que tiene la comida). Quedan por debajo de los suministros HL2 de Cargo por la misma razón que la comida queda debajo de la munición, y con la misma salida pendiente: el multiplicador por categoría de Cargo (su roadmap **61**, sin ratificar — **⚠ quedó viejo: CERRADA en juego el 2026-08-22, ver arriba**). Harness **189 checks**, ALL GREEN, verificado en negativo con dos mutantes; **falta la pasada en juego**. Antes, 2026-08-17: **el DOLOR tiene diseño — COA-52, sesión de diseño, CERO código.** Se votaron los seis puntos y con eso se levanta el bloqueo que la niebla (COA-44) y COA-49 tenían enfrente: **el dolor sale de los diferidos de §1** y quedan escritas la tabla de balance propuesta y las seis colisiones. Lo que se resolvió: es **estado por zona derivado MÁS un agregado global saturado** — `clamp(Σ 7 zonas, 0, 100)`, y ése es el clamp que **salva las cuatro fórmulas** (suma cruda daría `bpm +154` y `StaminaCap −245`); la zona vive en la misma escala 0..100 con `PAIN_FULL_AT = 60` para la rampa; la producción sale de **una constante × la tabla de ACE3 literal × un eje de severidad que es NUESTRO** (ACE no tiene ninguno). Los dos resultados que abaratan el tramo: **el dolor NO se almacena y NO tiene reloj propio** —se deriva de las heridas, y su decaimiento **ES el reloj `HEAL_S` de COA-49**, así que el síntoma de infección sale exacto en sus dos mitades—, y **lo único almacenado es la supresión** (`painSuppress`), porque a un derivado no se le resta sin almacenar la resta. De ahí sale lo mejor del tramo: bajo niebla **la morfina te ciega el diagnóstico**, o sea que es un costo de información y no un buff. **La dependencia estaba escrita al revés**: el dolor no está bloqueado por COA-49, **consume** su reloj. Tres correcciones medidas contra el prompt: la matriz son **15 celdas y no 18** (hay CINCO tipos; `punzante` lo nombra COA-49 y no existe), el doble cobro del torniquete/fractura **cuesta cero migrar** (`StaminaCap`, `frac` y `splint` tienen 0 hits en el `lua/`), y la colisión del snapshot **muerde recién con la forma de COA-49** (hoy una herida `treated` sigue en `wounds`, así que la zona ya viaja). Y una sexta colisión que nadie había listado: **un vital que la niebla puede ocultar no puede viajar por NW2** —no hay filtro por observador—, con la **deuda que destapa: `coagulant_blood` YA viaja a todos los clientes y la cifra de sangre es capa de diagnóstico**, o sea un agujero de la niebla anterior al dolor. Antes, 2026-08-09: **los dos ejes abiertos de §17 quedaron VOTADOS y ninguno baja a código todavía.** El segundo es **COA-50/COA-51 — el área hospital**: UNA entidad (la estación) que provee **capacidad** y define el **área de suministro**, dos gates INDEPENDIENTES en cada `can()`; el modelo es la piel — camilla comprada o `SetNoDraw` para mapas que ya traen hospital—, así que **la compra de modelos es opcional por construcción** y se compra **una sola cosa, la camilla**, por ser la única con papel mecánico y la marca visible de un radio que si no es invisible. «El paciente se queda» sale gratis: canalización larga + radio + la cancelación que ya existe. **BLOQUEANTE DECLARADO:** necesita `AreaHas`/`AreaCount`/`AreaTake` de Cargo — las TRES, que un `AreaCount` sin `AreaHas` repite el fallo G4 del torniquete— y **Cargo NO las ratificó**: escrito el mismo día en su roadmap **#60** para no repetir D-5. Hasta entonces el tramo no baja. **⚠ Quedó viejo: Cargo las ratificó y las escribió el 2026-08-22, y entregó CUATRO — ver arriba.** Y el primero, **la herida tratada tiene TIEMPO** — COA-49, voto del autor sobre el primero de los dos ejes que §17 había dejado sin votar: `t` se resuelve sola por reloj y una herida tratada SUCIA va a `i`, que no se cura sola y termina en sepsis. El **Medkit no cambia una línea** — pasa a ser el atajo de algo que además ocurre solo—, y esa resolución automática es lo que impide reintroducir el bug de COA-21 con otro nombre. La sepsis mata por **perfusión** y no por ruta propia. Le da su `can()` al **antibiótico**, que estaba sin gate. Antes, 2026-08-08: **la muerte cambia de insumo: perfusión, no volumen** — sesión de diseño, **cero código**. El autor votó tres puntos y quedaron escritos en Architecture **§17** (COA-41…COA-48): (1) el drenaje de HP de §5 pasa a alimentarse de `blood × sat/100` —el dueño de la muerte NO cambia, sigue siendo HP 0 por `DMG_GENERIC`, cambia qué lo alimenta, y con `sat` sano = 100 la sustitución es **exacta**: ningún número de balance se mueve—; (2) entra la **niebla diagnóstica** detrás de convar y **apagada por default**, con tres capas —síntoma gratis, signo por examen, diagnóstico por instrumento—, lo que **promueve al dolor de diferido a requisito** y convierte el snapshot de §9 en un filtro por observador; (3) los dispositivos persistentes siguen siendo **casos especiales** como `z.tq`, así que tubo torácico, ventilador y vía IV quedan diferidos y nombrados. El hallazgo que ordenó todo: **tres de los 24 ítems del catálogo v4 tratan condiciones que nada en el simulador produce** (la categoría AIRWAY entera) y la atropina estaba sin gate — el daño ambiental que §3 ignoraba era justamente el paciente que les faltaba. De código vivo salen tres correcciones a la tabla de §3 (**`DMG_ACID` cae al default y produce una CONTUSIÓN**, `DMG_SHOCK` pierde la arritmia, `DMG_BLAST` no produce nada torácico) y una omisión del catálogo: **no hay RCP ni desfibrilador en un menú cuyo ECG dice `ASYSTOLE`**. Stalker entra a §12 como emisor: su doc ya prometía este pacto desde el otro lado mientras §12 ni lo listaba. Antes en el día, **dos defs cambiaron de modelo por reporte del autor**: la
**venda es UNA** —la rama `Bandages` del pack son tres rollos sueltos y el port se los llevó los
tres, así que el ítem se veía como «tres vendas juntas»; ahora corta con `--object Bandage2`, 1.926
→ **642 tris**— y el **Medkit es el naranja cerrado** en vez del `firstaidkit` blanco (8.860 →
**3.590 tris**). Un rollo solo con el factor del set mide 3,0 cm = 1,18 u y **reprobaba C1**, así
que se normaliza a **9 cm con factor propio**: excepción votada, escrita en tres lugares. De paso
se va de la vista el único modelo con la **cruz roja de Ginebra** —aunque el `.mdl` sigue en el
repo, así que esa decisión sigue abierta—. **`fbx2smd.py` ganó `--object`.** Harness **192/142 ALL
GREEN**, `verify_model.py` 7/7 contra un control negativo **fabricado** (los cinco conocidos-buenos
pasaban todo, y el que la doc citaba como discriminante ya no falla). **CONFIRMADOS en juego por el
autor el mismo día, los dos.** Ojo con la trampa que casi cuesta la pasada: el ícono del grid se
cachea con el CRC de la **RUTA** del modelo, y la de la venda no cambió — hay que borrar
`garrysmod/data/corpus/cargo/icons/` o el ícono viejo de tres rollos sobrevive. Antes, 2026-08-06:
**el botiquín grande son dos `.mdl`** —`medkit_large` abierto
con `$bodygroup state` de dos opciones y `medkit_large_closed` aparte con colisión propia, porque
Source tiene un `$collisionmodel` por modelo y no por bodygroup: el alto del casco del cerrado bajó
de 11,81 u a 3,52—; y **corpus-stalker dejó de sustituir la venda y el medkit** — sus botiquines de
la Zona serán ítems propios, no una piel del genérico, así que ahora se ven los modelos de este
módulo. La puerta de `Items.SetModel` sigue abierta. Antes, 2026-08-05: **los ítems médicos traen
su modelo** — enmienda del autor a
la decisión del 2026-07-23, que los dejaba sin `model` a propósito. El motivo de aquélla era que un
addon de contenido pudiera vestirlos, y **sigue cubierto**: `Cargo.Items.SetModel` pisa el modelo
declarado y se re-aplica en cada `Register`, así que declarar un default no cierra ninguna puerta —
sólo cambia qué se ve cuando nadie sustituye, que hasta hoy era una cajita de cartón. **18 `.mdl`
nuevos** portados de tres packs de Sketchfab **CC BY 4.0** (créditos obligatorios en
[`CREDITOS.md`](CREDITOS.md)); tres se cablean a las defs — venda, medkit (`firstaidkit`, 16 cm) y
bolsa de sangre — y **el torniquete queda sin modelo porque en los packs no hay ninguno**: el
candidato resultó ser carretes de sutura al renderizarlo. Harness **192/142 ALL GREEN** sin cambios,
y 17 de los 18 `.mdl` dan 7/7 en `verify_model.py`; el 18.º (`sutures`) marca C1 por medir 1,97 u
contra un umbral de 2 — es un carrete de 5 cm y el tamaño es correcto. **Falta la pasada en juego.**
Antes, 2026-07-29: **COA-37 — la venda cubre el trauma cerrado**: hasta hoy una
`contusion` (mult 0.0) era **invendable** y, como el medkit solo borra lo ya `treated`, **incurable**
— pesaba entera en cojera/sway/visión hasta morir, y una caída dejaba cojera permanente. La venda
deja de preguntar «¿sangra?» y pregunta «¿está abierta?»: es la salida (1) de las tres que ACE3 le
da al trauma cerrado —dolor con analgésico y fractura con férula **siguen diferidos** por §1— y no
cuesta mecánica nueva: la contusión entra al circuito venda → medkit que ya existe. Nace
`Config.BandagePriority` y `WorstOpenZone`. Enmienda en Architecture §7 + alta de COA-37 en
`ids.yaml`. **Pasada del autor 4/5**: la cura de la contusión quedó confirmada, pero el check 4
destapó que el ORDEN estaba invertido —con un balazo mínimo y un moretón medio la venda atendía el
moretón—, así que se corrigió el mismo día: **manda el sangrado**, la severidad ordena dentro de
cada grupo (hemorragia primero; el peso se deriva de `SEVERITY_MAX`, COA-35). La re-pasada cerró el
check 4 ✓ → **COA-37 5/5 en juego**, harness **192/142 ALL GREEN**, commiteado y pusheado. Antes,
2026-07-23 noche: **decisión de modelos ratificada** — los ítems
médicos quedan **sin `model` a propósito** (cajita de Cargo + ícono de letra); la sustitución es
de los addons de contenido vía `Cargo.Items.SetModel` (Cargo #34; corpus-stalker re-vestía
venda y medkit — **retirado el 2026-08-06**). Nota en Architecture §7 + comentario en `items`; solo prosa acá. Antes en el
día, **COA-2 confirmado en juego**: la re-validación de consumo
al completar con `HasItem` —PARCHE 3 de la tanda del gate— pasó ✓ en la pasada del autor —venda
3→2, bloodbag 2→1, torniquete no consumido—, CHANGELOG `[APLICADO 2026-07-23]`. Antes, 2026-07-21,
**barrido de drifts de docs**: el CLAUDE.md ya
no lista la mini-ronda 8 como pendiente —está 2/2, N1 ✓—, los comentarios «6 zonas»
del HUD pasan a 7, y los ecos de estado de Coagulant en `corpus/`, `corpus-cargo/` y
`corpus-craving/` quedan corregidos. CHANGELOG sesión «Barrido de drifts de docs»
`[APLICADO]`. El tramo de zonas `torso` → `chest`/`stomach` sigue **COMPLETO** —ronda O
6/6, selftest 170/132—; el **Block 3 sigue CERRADO** —ronda 7 13/13, mini-ronda 8 2/2,
check N1 ✓— y siguen las **dos decisiones de diseño abiertas**)

---

## Qué existe hoy

- **Block 3 completo y verificado en juego** (rondas 1-7, 2026-07-13 → 2026-07-20):
  - **Slice 1** — sangre 0-100 con NW2, heridas por damage type con el daño FINAL,
    timer de 1 s (drenaje, regen, HP crítico → "You bled out."), eventos
    `Coagulant_*` y snapshot on-change.
  - **Slice 2** — tratamiento server-authoritative con **consumo AL COMPLETAR**,
    cancelación por daño/salto/velocidad, torniquete toggle con isquemia, 4 defs
    contra Cargo (Bandage/Tourniquet/Medkit/Blood Bag).
  - **Slice 3** — debuffs zonales: cojera (NW2 + hook `Move` shared, compone con el
    peso de Cargo), sway continuo en dos capas con rampa de ADS (cliente), visión
    (vignette elíptico + capa de sangre crítica). El Medkit borra la secuela tratada.
  - **Slice 4** — UI: silueta de 7 zonas que late y se desvanece, menú médico por
    zona (dibujo y clic desde la MISMA tabla; intents que el server re-valida),
    barra de tratamiento, sangre en el StatusPanel de Cargo (mini-barra propia sin
    él) y tab Q real. **El flujo completo sin consola (§15) confirmado en J5**, y el
    modo degradado sin Cargo verificado EN JUEGO (L1 — la vieja deuda G6, saldada).
- **Fixes post-cierre verificados en juego** (mini-ronda 8: 2/2; check N1 ✓): la tecla
  del menú se lee por **poleo en `Think`** con guard de cursor (`PlayerButtonDown` no
  dispara client-side en singleplayer; elegir la tecla en el binder ya no despliega el
  menú) y `ResetState` despublica la cojera del selftest.
- **Zonas: 7 desde el 2026-07-21** (COA-8 enmendado, bajado a código y verificado en
  juego el mismo día — ronda O: 6/6): `torso` partido en `chest`/`stomach` sin alias,
  fallback `chest` (COA-7), `ZONE_BLEED_MULT` neutra como eje de tuning, silueta 58/42.
- **Dolor (COA-52), desde el 2026-08-25** — estado **por zona derivado** (producción
  `PAIN_PER_WOUND × PAIN_TYPE × PAIN_SEVERITY`, reparto activa 1.00 / tratada 0.35 /
  infectada 1.00, pisos de isquemia y fractura por `max()`) **más un agregado global
  SATURADO** en 0..100 — el clamp es lo que salva a las cuatro fórmulas del spec v5.
  No se almacena y no tiene reloj propio: **lo único almacenado es `painSuppress`**,
  que decae en el tick de 1 s que ya existía. Viaja en el **snapshot** (`p` por zona +
  `pain` percibido global), **nunca por NW2**, y el cliente **lee, no deriva**. Quinta
  def médica: **Painkillers** (analgésico oral, 35 de supresión, puerta `pain > 10`
  sobre el percibido — la 2.ª dosis se desgatilla sola). **CERRADO EN JUEGO el 2026-08-25** (planilla `dev/checks/coagulant-dolor-r1.html`, **12/12**).
- **Metabolismo y condiciones externas (COA-38/39/40), desde el 2026-08-25** — el canal
  `ApplyExternalCondition(ply, id, severity)` con los **dos ids clínicos** de §8
  (`starvation` / `dehydration`; el 0 limpia) y **la tabla de config como PUERTA**: un id
  que no está devuelve `false`, que es lo que le avisa al emisor que ese daño **sigue
  siendo suyo**. Semántica de §8: starvation suprime la regeneración de sangre ∝ severity
  (en 1 la anula) y dehydration hace **además** eso, más bajar el techo de plasma. En el
  otro sentido (**COA-38**) Coagulant **lee** a Craving por capacidad —`GetMetabolic`, los
  cinco crudos— y los traduce a déficit con umbral **propio** (`METABOLIC_DEFICIT_AT = 40`).
  **⚠ De las cinco palancas de COA-40 sólo TRES tienen blanco en el árbol** —`micro`→
  `BleedRate`, `protein`→`REGEN_PER_S`, `hydration`→techo de sangre—: `hunger` y `energy`
  apuntan al **techo de stamina**, que §1 difiere, y los **bpm** no existen. Las dos quedan
  **escritas y neutras** (`live = false`), con harness que lo sostiene. Las dos vías que
  llegan a una palanca se combinan con **`max()`**: la condición empujada y el crudo leído
  describen el mismo cuerpo, y sumarlas cobraría dos veces la misma sed. **El techo TECHA
  Y FRENA, NUNCA MATA**: acota hasta dónde regenera y jamás empuja la sangre hacia abajo.
  En pantalla, la marca de techo al lado de la sangre y la fila **METABOLIC** de cinco
  chips (los dos sin palanca, en gris — voto del autor). **Sin pasada en juego.**
- **Verificación offline:** sintaxis (`dev/glua_check.py`, 13 archivos) + harness
  versionado ([`../../dev/harness_coagulant.py`](../../dev/harness_coagulant.py),
  checks de la partición incluidos + selftest en ambos realms): **331 checks, 0
  fallos, ALL GREEN**; selftest **238 OK server / 161 client**. Verificación en
  negativo, DOS scripts:
  [`../../dev/sabotaje_coagulant_dolor.py`](../../dev/sabotaje_coagulant_dolor.py) (dolor, 30)
  y [`../../dev/sabotaje_coagulant_metabolismo.py`](../../dev/sabotaje_coagulant_metabolismo.py)
  (metabolismo, 21), los dos con alcance declarado por sabotaje.
- Mapa archivo → rol en [`../CLAUDE.md`](../CLAUDE.md). Comandos: `coagulant_selftest`,
  `coagulant_status`, `coagulant_setblood`, `coagulant_bandage`, `coagulant_dev_give`.

## Pendiente de verificar

> **Si vuelves a regenerar un `.mdl` EN LA MISMA RUTA, borra `garrysmod/data/corpus/cargo/icons/`
> antes de mirarlo.** El nombre del PNG cacheado ES la clave de invalidación —
> `<defid>_<CRC(recipe|modelo|cámara|footprint)>.png` — así que un cambio de **contenido** con la
> misma **ruta** no la mueve, y el ícono viejo sobrevive. Pasó con la venda el 2026-08-08: el
> Medkit se re-renderizó solo porque cambió de ruta y la venda no. Sin borrar, el reporte natural
> habría sido «la venda no cambió», que era falso.

- **EL METABOLISMO Y LAS CONDICIONES EXTERNAS, y es lo primero de la lista** (2026-08-25):
  §8, COA-38/39/40. Planilla en `dev/checks/coagulant-metabolismo-r1.html`, publicada en
  [este artefacto](https://claude.ai/code/artifact/fa3fd433-cc7d-428e-b72a-a34bff488132). Qué mirar, en un gesto solo: `coagulant_status` imprime las **tres capas
  por separado** —qué te EMPUJARON, qué LEÍSTE de Craving y qué EFECTO quedó—, que es lo
  único que distingue *«Craving no está montado»* de *«Craving dice que estás bien»*. Con
  Craving montado y hambre, el techo de sangre baja y la fila METABOLIC del menú dice por
  qué; sin Craving, la fila **no existe**. ⚠ **La propiedad que hay que ver fallar si algo
  está mal es que el techo NO empuje la sangre hacia abajo**: con la sangre por encima del
  techo, no se mueve.
- **El botiquín grande abierto** (2026-08-06): el `medkit_large` con `$bodygroup state` de dos
  opciones (0 `open_full` default, 1 `open_empty`). Qué mirar: que el bodygroup no salte al cambiar
  de opción. **El cerrado ya está confirmado** — es el que quedó cableado al Medkit el 2026-08-08 y
  el autor lo vio en juego. Detalle en [`ASSETS.md`](ASSETS.md).
- **Los 18 modelos, en juego** (2026-08-05, PARCHES 1-3 de su sesión en el CHANGELOG). **Venda,
  medkit y bolsa de sangre ya están CONFIRMADOS** (los dos primeros el 2026-08-08, la bolsa antes);
  queda lo demás. Qué mirar: que los **cuatro `$translucent`** (`bloodbag`,
  `pill_bottles`, `test_tubes`, `vials`) se vean translúcidos y **sin artefactos de ordenamiento**;
  y que `sutures` —1,97 u, el único que marca C1— sea agarrable con la physgun o se decida subirlo.
- **EL DOLOR ENTERO cerró 12/12 en juego** el 2026-08-25 (planilla
  `dev/checks/coagulant-dolor-r1.html`, publicada en
  [este artefacto](https://claude.ai/code/artifact/f9e534e3-2843-453c-88bf-e786e6778cd1)):
  12 PASA, 0 FALLA, 0 SIN CORRER, **ningún defecto**, y los **dos votos delegados EN PIE** —
  el autor no vetó ni el analgésico (§3.1) ni la silueta sin cambiar de insumo (§3.2). Las dos
  filas que decidieron: la **03** midió el `0.35` del dolor contra el `0.5` del score **en juego**
  (`score 3.0 → 1.5` y `dolor 38 → 13` sobre el mismo `chest`), y la **07** desgatilló la 2.ª
  dosis con el percibido en 4-6 y el **crudo en 24**, que es lo único que prueba que la puerta
  lee `GetPain` y no `GetRawPain`. Las tres cosas que salieron de las notas VERDES —ninguna
  defecto del dolor— están en la cabeza de este archivo; una de ellas corrige a la planilla y
  **no** al código, y por §6.5 la planilla no se reescribe.
- Nada más — **COA-37 cerró 5/5 en juego** el 2026-07-29: los checks 1-3 y 5 en la primera pasada, y
  el 4 en la re-pasada tras invertir el orden (balazo leve antes que moretón medio). Commiteado y
  pusheado.
- El cap del torniquete (COA-20 enmendada) quedó **confirmado en juego** el 2026-07-23
  (TQ ✓: ponerlo descuenta, la 2.ª pierna no alcanza, quitarlo lo devuelve); CHANGELOG `[APLICADO]`.
  Cross-repo cerrado con Cargo `TakeUnique` (#29).

## Remanentes / deuda conocida

- **DECISIÓN ABIERTA (autor) — toggle del paperdoll** (pedido de la ronda 7): hoy la
  silueta se desvanece sola con el cuerpo sano **y la sangre llena**, y la regen lenta
  (0.10/s) la mantiene visible minutos. ¿Convar propia para la silueta pasiva?
  ¿Mostrarla solo sangrando/tratando? Se anota en la arquitectura ANTES de
  implementar (COA-28).
- **DECISIÓN ABIERTA (autor) — ¿la tecla del menú también cierra?** Hoy solo abre
  (cierre = X del frame). El poleo nuevo lo hace posible con el patrón de Cargo.
- **ARC9 fino, diferido** (§6): «apuntando» = clic derecho (`IN_ATTACK2`), agnóstico
  al arma; la API real de ARC9 se verifica contra `dev/other/`, nunca de memoria.
- **Silueta y vignette: geometría propia** — nada se recicla de mods con licencia
  silenciosa; la vía legal para assets dibujados es `corpus-stalker` o HL2.
- **Rama Caliber vacía a propósito** hasta su Block 3 (arquitectura §12).
- **Sin `addon.json`** — igual que el resto del ecosistema; no bloquea testeo local.

## Próximo paso

1. El tramo acordado con el autor: (1) arreglar drifts de docs — **HECHO** (barrido del
   2026-07-21: el «Estado actual» del CLAUDE.md ya no lista la mini-ronda 8 como
   pendiente, los comentarios «6 zonas» del HUD pasan a 7, y los ecos de estado en
   `corpus/`, `corpus-cargo/` y `corpus-craving/` corregidos). Quedan **(2) las dos
   decisiones de diseño abiertas** de arriba y **(3) la mejora a la UI que el autor
   tiene diseñada en Claude** (la trae él).
2. Cross-repo: **la ratificación de `ApplyExternalCondition(ply, id, severity)` está
   HECHA en diseño** (2026-08-08, voto del autor → §8, **COA-39**; **D-5 cerrada**),
   junto con la enmienda que deja a Coagulant **leer** a Craving (**COA-38**, enmienda
   COA-31) y las cinco palancas metabólicas (**COA-40**). **Nada de eso está en código**:
   `ApplyExternalCondition` sigue con 0 hits en el `lua/`, así que el puente de Craving
   sigue —correctamente— en su fallback por capacidad. Lo que falta es la bajada, y el
   orden de COA-28 ya está satisfecho: el diseño está escrito antes.
   **Ojo con el 2.º argumento** al implementarlo: es el **id de condición clínica**
   `{"starvation", "dehydration"}`, NO el stat de Craving — switchear sobre el stat
   pasaría el gate de CAPACIDAD sin aplicar nada y la inanición quedaría inofensiva en
   silencio. Después, el wiring real con Caliber cuando su Block 3 exponga el
   hit-location de jugador (roadmap [3]).
3. **Enmienda §17 (2026-08-08b) — también SIN una línea de código**, y es lo que la hace fácil de confundir con avance: `sat`, `Perfusion`, la niebla y las condiciones ambientales **no existen** en el `lua/`. Lo que existe es el permiso de COA-28 para bajarlas. **No dar por sentado el orden**: la niebla depende del dolor como stat.
   **Actualizado el 2026-08-17:** ese orden **ya no bloquea el diseño** — el dolor tiene el suyo votado (COA-52, §17), con tabla de balance propuesta. Sigue bloqueando la **bajada**: el dolor va antes que la niebla, porque sin él la silueta no tiene qué pintar. Y el dolor a su vez conviene bajarlo **junto con COA-49** o con su término `i` leyendo 0, que es exactamente neutro con la forma de lista de hoy.
4. **EL TRAMO DEL DOLOR ESTÁ CERRADO (2026-08-25c): 12/12 en juego, cero defectos.**
   Los **dos votos delegados** quedaron EN PIE — el autor no vetó ninguno, así que el
   analgésico se queda y la silueta sigue con el score. Con el dolor confirmado, la
   **niebla diagnóstica (COA-44)** se queda sin su único bloqueante: ya hay qué pintar
   en la silueta y qué tapar, y es **lo que sigue**. El prompt que ordenó la ronda
   queda como registro:
   ~~**El tramo del dolor tiene PROMPT DE EJECUCIÓN escrito**~~ (2026-08-25):
   `../../dev/PROMPT_coagulant_dolor_codigo.txt`. Baja COA-52 a código —tablas,
   `ZonePain`/`GetRawPain`/`GetPain`/`AddPainSuppression`, la supresión en el tick de
   1 s, el `p` por zona en el snapshot— con el mapa de toques anclado al código de hoy,
   las trampas medidas y la verificación en negativo obligatoria.
   ⚠ **Trae UNA pregunta sin votar y es lo primero del prompt:** bajado solo, el dolor
   **no tiene un solo consumidor en juego** —las cuatro fórmulas del v5 no existen en el
   `lua/` y la niebla es el tramo siguiente—, así que su pasada en juego sería por
   consola. O baja **pelado** (y su planilla se difiere, como hizo Cargo con la #60), o
   baja **con su primer consumidor visible** (el analgésico oral + el dolor en el menú
   médico), que es diseño y COA-28 obliga a votarlo antes. La recomendación escrita es
   la segunda en su forma mínima; **la decisión es del autor**.
5. **El área hospital (COA-50/COA-51) ya no tiene bloqueante externo** y es
   INDEPENDIENTE del dolor: Cargo entregó las cuatro `Area*` el 2026-08-22 y su pasada
   en juego espera a que este tramo baje.

---

*Rumbo / qué sigue → [`coagulant_roadmap.txt`](coagulant_roadmap.txt). Frontera del módulo →
`../../corpus/docs/CORPUS_Architecture.md` §2, §4-§5. Metodología →
[`../../corpus/docs/corpus_flujo_trabajo.txt`](../../corpus/docs/corpus_flujo_trabajo.txt).*

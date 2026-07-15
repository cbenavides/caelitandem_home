# Plan de Aseguramiento A Priori Para Texto y Voz - NLP/VOSK Comandas

Fecha base: 2026-07-10

## Objetivo

Construir un mecanismo de aseguramiento a priori para que el catalogo de tacos, bebidas y especialidades pueda publicarse con evidencia objetiva de que las combinaciones coherentes dictadas por texto y por voz funcionan antes de llegar a operacion.

El objetivo no es probar frases sueltas, sino convertir el catalogo en una especificacion ejecutable: cada producto, sinonimo, cantidad, mesa, nota, tamanio y combinacion acumulativa debe poder validarse contra el parser, contra el detector de colisiones, contra la gramatica VOSK y, en una fase posterior, contra audios de regresion.

## Estado Actual Relevante

### Catalogo activo

Segun la base `vcd01`, el menu activo contiene:

- 55 productos disponibles.
- 34 bebidas.
- 18 tacos tradicionales.
- 3 especialidades y alambres.
- 5 mesas activas actualmente: 1, 2, 3, 4, 5.

Familias con riesgo natural de colision:

- `Taco de Tripa` vs `Taco de Tripa Dorada`.
- `Taco Campechano` vs `Taco Campechano con Queso`.
- `Taco Al Pastor` vs `Gringa de Pastor` vs `Alambre de Pastor`.
- `Coca-Cola (600ml)` vs `Coca-Cola (1L)` vs `Coca-Cola (2L)` vs `Coca-Cola (Familiar 3L)`.
- `Horchata (Vaso 500ml)` vs `Horchata (Jarra 1L)` vs `Horchata (Jarra 2L)`.
- `Jamaica (Vaso)` vs `Jamaica (Jarra)`.
- Genericos peligrosos: `taco`, `tacos`, `agua`, `refresco`, `cerveza`.

### Estabilizacion ya realizada

Ya existe una base tecnica aprovechable:

- Parser compartido en `www/web-assets/libs/models/nlp-comanda-parser.js`.
- PWA Mesero usa `parsearTranscripcionComanda()` desde `app-voice.js`.
- Tokens genericos `taco/tacos` no resuelven producto por si solos.
- `suadero/sueadero`, `pastor`, `tripa/tripitas` ya tienen pruebas puntuales.
- Dictado acumulativo simple ya esta probado: varios productos separados por `y`.
- Mesa fuera de configuracion se bloquea contra `mesas_validas`.
- Backend expone `mesas_validas` y `mesa_max` en `/restaurant/api/catalogo/actual.php`.
- Backend rechaza comanda si la mesa no existe o no esta activa.
- Service Worker tecnico actual: `comandas-v15`.

## Principios De La Solucion

1. El catalogo es el contrato de lenguaje.
2. El parser no debe inventar productos por genericos.
3. El fuzzy corrige errores razonables, no ambiguedades reales.
4. Si dos productos son plausibles, se debe pedir aclaracion o bloquear publicacion.
5. El dictado acumulativo es requisito principal, no caso secundario.
6. Texto y voz se aseguran con pipelines distintos pero conectados.
7. La publicacion de catalogo debe depender de una compuerta de QA.
8. La operacion offline debe usar el ultimo contrato validado y versionado.

## Arquitectura Propuesta

```text
Catalogo BD
  -> Contrato NLP derivado
  -> Generador de frases coherentes
  -> Generador de variantes fuzzy
  -> Auditor de colisiones
  -> Pruebas de parser texto
  -> Generador/validador de gramatica VOSK
  -> Pruebas de transcripcion por audio
  -> Reporte QA
  -> Publicacion permitida o bloqueada
```

Componentes nuevos sugeridos:

```text
www/tests/nlp/catalog_contract.mjs
www/tests/nlp/phrase_generator.mjs
www/tests/nlp/fuzzy_variants.mjs
www/tests/nlp/collision_audit.mjs
www/tests/nlp/text_matrix.test.mjs
www/tests/nlp/grammar_coverage.test.mjs
www/tests/nlp/voice_audio_regression.test.mjs
www/tests/nlp/fixtures/catalog_snapshot.json
www/tests/nlp/fixtures/audio/
```

En una segunda etapa se puede integrar el mismo motor al Admin Catalogo para mostrar un boton:

```text
Validar NLP del catalogo antes de publicar
```

## Plan 1 - Aseguramiento A Priori Para Texto

### Objetivo

Garantizar que toda frase textual coherente del menu se convierta en una comanda estructurada correcta, sin colisiones, sin falsos positivos y con soporte de dictado acumulativo.

### Alcance

Incluye:

- Mesa valida/invalida.
- Cantidades por palabra y digito.
- Productos por nombre canonico, keywords y sinonimos.
- Tacos, bebidas, aguas, cervezas, especialidades y alambres.
- Tamanios: `600ml`, `1L`, `2L`, `3L`, `vaso`, `jarra`, `familiar`.
- Notas: `con todo`, `sin cebolla`, `sin salsa`, `con queso`, `bien fria`, `con hielo`, `sin hielo`.
- Dictado acumulativo de 2 a 5 items.
- Falla parcial segura.
- Auditoria de colisiones entre productos.

No incluye en esta fase:

- Reconocimiento acustico real.
- Evaluacion de microfono/ruido.
- Rendimiento de VOSK.

### Capa 1 - Contrato NLP Del Catalogo

Crear un contrato derivado desde `productos`:

```js
{
  id: 3,
  nombre: "Taco de Suadero",
  familia: "taco",
  genericos: ["taco", "tacos"],
  distintivos: ["suadero"],
  sinonimos: [],
  frasesCanonicas: [
    "taco de suadero",
    "tacos de suadero",
    "suadero"
  ],
  modificadoresRelevantes: []
}
```

Para bebidas:

```js
{
  id: 20,
  nombre: "Coca-Cola (600ml)",
  familia: "bebida",
  genericos: ["refresco", "coca"],
  distintivos: ["coca", "600", "600ml", "chica"],
  tamanio: "600ml",
  sinonimos: ["chesco", "cocacola"]
}
```

Reglas del contrato:

- Cada producto debe tener al menos un token distintivo.
- Los tokens genericos no pueden ser suficientes para resolver producto.
- Productos con mismo token base deben tener modificador obligatorio:
  - `tripa` vs `tripa dorada`.
  - `campechano` vs `campechano con queso`.
  - `coca` con tamanio.
- Si un producto requiere tamanio para distinguirse, el generador debe producir frases con tamanio.
- Si un producto comparte familia y token con otro, debe pasar auditoria de colision.

Entregable:

- `catalog_contract.mjs` que produce un contrato normalizado desde catalogo real o fixture.

### Capa 2 - Generador De Frases Coherentes

Generar automaticamente frases de entrada para cada producto.

Plantillas base:

```text
mesa {mesa} {cantidad} {producto}
mesa {mesa} {cantidad} {producto} {nota}
mesa {mesa} {cantidad} {producto} {tamanio}
mesa {mesa} {cantidad} {producto} {tamanio} {nota}
```

Ejemplos esperados:

```text
mesa uno dos tacos de pastor
mesa cinco tres tacos de tripa dorada con todo
mesa dos una coca de 600
mesa cuatro dos aguas de horchata vaso
mesa tres un alambre de pastor
mesa cinco una gringa de pastor
```

Reglas:

- No generar combinaciones incoherentes como `taco de coca`.
- No aplicar `bien fria` a tacos salvo que se permita explicitamente.
- No aplicar `sin cebolla` a refrescos salvo que se configure como permitido.
- `con queso` puede ser nota o parte del producto; debe distinguirse en productos como `Taco Campechano con Queso`.
- Para productos con tamanio, el tamanio debe probarse como parte de la frase.

Entregable:

- `phrase_generator.mjs` con generador por familia.

### Capa 3 - Variantes Fuzzy Controladas

Crear un diccionario de variantes permitidas por token, no un fuzzy sin limite.

Ejemplos:

```js
{
  suadero: ["sueadero"],
  pastor: ["vastor"],
  tripa: ["tripitas"],
  cocacola: ["coca cola", "coca-cola"],
  pina: ["piña"],
  limon: ["limón"],
  fria: ["fría"]
}
```

Reglas:

- Las variantes se prueban contra el producto esperado.
- Si una variante acerca dos productos al mismo nivel, se marca colision.
- Las variantes largas pueden tolerar distancia mayor que las cortas.
- Tokens cortos deben tener umbral estricto.

Entregable:

- `fuzzy_variants.mjs`.

### Capa 4 - Auditor De Colisiones

Ejecutar cada frase generada contra todo el catalogo y revisar si el ganador es correcto.

Casos de colision a detectar:

```text
tripa dorada -> Taco de Tripa     FAIL
campechano con queso -> Taco Campechano     FAIL
gringa pastor -> Taco Al Pastor     FAIL
alambre pastor -> Taco Al Pastor     FAIL
agua -> cualquier agua saborizada     FAIL
refresco -> Coca-Cola arbitraria     FAIL
cerveza -> Corona arbitraria     FAIL
coca -> Coca 600/1L/2L sin tamanio     WARNING o FAIL segun regla operativa
```

Resultado esperado:

```json
{
  "status": "fail",
  "collisions": [
    {
      "phrase": "mesa tres dos tacos de tripa dorada",
      "expected": "Taco de Tripa Dorada",
      "actual": "Taco de Tripa",
      "reason": "producto_especifico_perdio_contra_producto_base"
    }
  ]
}
```

Entregable:

- `collision_audit.mjs`.

### Capa 5 - Dictado Acumulativo

El acumulativo debe ser una capa formal.

Escenarios obligatorios:

```text
mesa seis dos tacos de tripa y tres tacos de pastor
mesa seis dos tacos de tripa y tres de pastor
mesa seis dos tacos de tripa sin cebolla y tres tacos de pastor con todo
mesa seis un alambre de pastor y dos tacos de suadero y una coca de 600
mesa cuatro una horchata vaso y dos tacos campechanos con queso
```

Reglas:

- El orden de `orderItems` debe ser el orden dictado.
- Cada segmento conserva su cantidad.
- Cada segmento conserva sus notas.
- Una nota no debe contaminar al siguiente segmento.
- Una frase con N segmentos debe producir N items, salvo que un segmento sea ambiguo.
- Si un segmento falla, el preview debe pedir correccion y no enviar una comanda incompleta sin aviso.
- Se debe decidir explicitamente si existe herencia de familia:
  - `dos tacos de tripa y tres de pastor` puede interpretarse como `tres tacos de pastor` si la familia anterior fue `taco`.
  - Si se implementa, debe quedar como regla probada, no como casualidad.

Entregables:

- Pruebas acumulativas generativas 2, 3, 4 y 5 items.
- Decision documentada sobre herencia de familia.
- Falla parcial segura en UI.

### Capa 6 - Mesas Y Configuracion Operativa

Reglas:

- `mesa` debe existir en `mesas` y estar activa.
- La PWA debe recibir `mesas_validas` desde backend.
- El backend debe rechazar comanda fuera de configuracion.
- La configuracion de Caja debe actualizar `mesas` y cambiar el delta hash efectivo.

Casos:

```text
mesa cinco dos tacos de pastor -> OK si mesa 5 activa
mesa seis dos tacos de pastor -> OK solo si mesa 6 activa
mesa 1024 dos tacos de pastor -> FAIL mesa_fuera_de_configuracion
```

Entregables:

- Pruebas de mesa valida e invalida.
- Validacion backend.
- Diagnostico PWA que muestre mesas validas cargadas.

### Capa 7 - Compuerta De Publicacion Para Texto

Antes de publicar catalogo:

1. Generar contrato NLP.
2. Generar frases canonicas.
3. Generar variantes fuzzy permitidas.
4. Generar acumulativos.
5. Ejecutar parser.
6. Ejecutar auditor de colisiones.
7. Emitir reporte.

Estados:

```text
PASS: publicable
WARNING: publicable con observaciones operativas
FAIL: publicacion bloqueada
```

Criterios `FAIL`:

- Producto disponible sin frase canonica reconocible.
- Generico resuelve producto.
- Producto A resuelve Producto B.
- Producto especifico pierde contra producto base.
- Acumulativo pierde segmentos.
- Mesa fuera de configuracion genera preview enviable.

Criterios `WARNING`:

- Producto tiene pocos sinonimos.
- Tamanio no aparece en keywords.
- Variante fuzzy no cubierta pero no rompe flujo canonico.
- Producto con token muy corto y riesgo acustico.

## Plan 2 - Aseguramiento A Priori Para Voz

### Objetivo

Garantizar antes de operacion que VOSK puede reconocer el vocabulario necesario del menu y que las transcripciones generadas por voz llegan al mismo parser con resultados correctos.

Texto prueba el parser. Voz prueba tres cosas adicionales:

1. Cobertura de gramatica.
2. Calidad de transcripcion esperada.
3. Resiliencia ante audio real, ruido y pronunciaciones.

### Alcance

Incluye:

- Validacion de tokens requeridos por catalogo.
- Validacion de gramatica VOSK cerrada.
- Pruebas de transcripciones simuladas con errores foneticos.
- Banco de audio sintetico para regresion amplia.
- Banco de audio real para regresion operativa.
- Reporte de diferencias: audio esperado, texto reconocido, parseo final.

No incluye inicialmente:

- Entrenar un modelo acustico nuevo.
- Cambiar VOSK por otro motor.
- Resolver ruido extremo sin evidencias de campo.

### Capa V1 - Cobertura De Gramatica VOSK

La funcion actual `compilarVocabularioGramatica()` arma el vocabulario desde:

- `palabras_clave`.
- `nombre` de producto.
- Sinonimos de cantidad.
- Controles: `mesa`, `sin`, `con`, `y`, `mas`, etc.
- Numeros comunes.

Se debe extraer esta logica a un modulo testeable o duplicar temporalmente su contrato en pruebas.

Validar que la gramatica contenga:

```text
mesa
uno..treinta
un, una, dos, tres, par
con, sin, todo, cebolla, salsa, queso, hielo, fria
andadores de acumulativo: y, mas
familia tacos: taco, tacos
familia bebidas: agua, refresco, cerveza
productos: pastor, suadero, tripa, dorada, campechano, bistec, arrachera...
bebidas: coca, pepsi, sprite, fanta, jamaica, horchata, tamarindo...
tamanios: vaso, jarra, litro, familiar, 600, 600ml, 1l, 2l, 3l
```

Criterios `FAIL`:

- Token distintivo de producto no esta en gramatica.
- Token obligatorio de mesa/cantidad no esta.
- Token de acumulativo `y`/`mas` no esta.
- Token de nota comun no esta.

Entregable:

- `grammar_coverage.test.mjs`.

### Capa V2 - Puente Voz A Texto Con Variantes Fonologicas

Antes de audio real, simular transcripciones tipicas de VOSK:

```text
sueadero -> suadero
vastor -> pastor
tripa dorada -> tripa dorada
coca seiscientos -> coca 600
coca de litro -> Coca-Cola (1L)
agua de jamaica vaso -> Jamaica (Vaso)
```

Este nivel sigue siendo texto, pero representa errores acusticos.

Criterios:

- Variantes esperables deben resolver al producto correcto.
- Variantes no configuradas deben producir warning, no falso positivo.
- Si VOSK suele omitir palabras cortas, se debe probar frase sin esas palabras.

Ejemplos:

```text
mesa seis dos tacos sueadero
mesa seis dos tacos de vastor
mesa seis una coca seiscientos
mesa seis una agua jamaica vaso
```

Entregable:

- `voice_transcript_variants.test.mjs`.

### Capa V3 - Banco De Audio Sintetico

Objetivo: cobertura amplia y repetible.

Generar audio sintetico para frases criticas:

- Una frase canonica por producto.
- Una frase por producto con nota.
- Acumulativos de 2, 3, 4 items.
- Frases de bebidas con tamanio.
- Frases de colision conocida.

Pipeline:

```text
frase esperada
  -> TTS offline o servicio controlado
  -> archivo wav 16k mono
  -> VOSK WASM/CLI
  -> transcripcion
  -> parser
  -> assert esperado
```

Formato de fixture:

```json
{
  "id": "taco_suadero_basico",
  "audio": "fixtures/audio/taco_suadero_basico.wav",
  "expectedText": "mesa seis dos tacos de suadero",
  "expectedItems": [
    { "nombre": "Taco de Suadero", "cantidad": 2 }
  ]
}
```

Criterios:

- El parser final debe acertar, aunque la transcripcion no sea identica palabra por palabra.
- Si la transcripcion pierde token distintivo, el test falla como riesgo de voz.
- El audio sintetico no sustituye prueba real; sirve como regresion rapida.

Entregable:

- `voice_audio_regression.test.mjs` para fixtures sinteticos.

### Capa V4 - Banco De Audio Real De Operacion

Objetivo: validar condiciones reales.

Recolectar audios cortos:

- 2 o 3 voces distintas.
- Ambiente silencioso.
- Ambiente con ruido moderado de restaurante.
- Android/PWA real.
- Frases criticas y acumulativas.

Set minimo recomendado:

```text
20 frases canonicas de tacos
15 frases de bebidas/tamanios
10 frases acumulativas mixtas
10 frases de colision conocida
10 frases con notas
5 frases invalidas/controladas
```

Cada audio debe guardar metadata:

```json
{
  "speaker": "mesero_1",
  "device": "android_pwa_sandbox",
  "noise": "moderado",
  "expectedText": "mesa seis dos tacos de tripa dorada",
  "expectedItems": [...]
}
```

Criterios:

- Las frases criticas deben pasar en dispositivos objetivo.
- Donde VOSK falle recurrentemente, se decide:
  - agregar sinonimo fonetico,
  - cambiar gramatica,
  - pedir confirmacion visual,
  - bloquear una frase ambigua,
  - o ajustar entrenamiento/proceso operativo.

Entregable:

- Carpeta `fixtures/audio/real/`.
- Reporte de precision por familia.

### Capa V5 - Metricas De Voz

Medir:

- Tasa de reconocimiento de token distintivo.
- Tasa de parseo correcto final.
- Tasa de colision.
- Tasa de falta de producto.
- Tasa de perdida de segmentos acumulativos.
- Tiempo de carga VOSK.
- Tiempo hasta preview.

Metas iniciales:

```text
Parser final correcto en texto generado: 100%
Parser final correcto en variantes foneticas controladas: >= 98%
Gramatica coverage: 100% tokens obligatorios
Audio sintetico critico: >= 95%
Audio real critico: >= 90% al inicio, subir con tuning
Falsos positivos de genericos: 0
Comandas enviables con mesa invalida: 0
```

### Capa V6 - Compuerta De Publicacion Para Voz

Antes de publicar una nueva version de catalogo o gramatica:

1. Validar coverage de gramatica.
2. Ejecutar variantes foneticas.
3. Ejecutar audios sinteticos criticos.
4. Ejecutar subset de audios reales si hubo cambios de keywords relevantes.
5. Generar reporte.

Estados:

```text
PASS VOZ: publicable para PWA
WARNING VOZ: publicable con observaciones de pronunciacion
FAIL VOZ: no publicar hasta corregir gramatica/keywords/sinonimos
```

Criterios `FAIL`:

- Token distintivo ausente en gramatica.
- VOSK no reconoce sistematicamente un producto critico.
- Producto de colision se confunde con producto base.
- Dictado acumulativo por audio pierde un segmento sin advertencia.
- Comanda de voz termina enviable sin producto o mesa valida.

## Alineacion Entre Texto Y Voz

Texto y voz deben compartir el mismo resultado final:

```text
Texto manual -> parser -> comanda_json
Voz -> VOSK -> transcripcion -> parser -> comanda_json
```

Por eso:

- El parser debe ser unico y compartido.
- La gramatica se deriva del mismo contrato NLP.
- Las variantes foneticas se prueban antes de audio.
- Los audios validan el tramo VOSK, no reemplazan las pruebas de parser.
- El reporte final debe unir ambos planes.

## Construccion Propuesta Por Fases

### Fase A - Base De Contrato Y Matriz Texto

Tareas:

1. Crear `www/tests/nlp/`.
2. Crear fixture de catalogo desde BD o cargar via API autenticada en modo test.
3. Crear `catalog_contract.mjs`.
4. Crear `phrase_generator.mjs`.
5. Crear `text_matrix.test.mjs`.
6. Integrar pruebas actuales de `nlp_text_parser_cases.mjs` a la nueva matriz.

Entregables:

- Cobertura canonica de los 55 productos.
- Reporte de productos sin frase segura.

### Fase B - Colisiones Y Fuzzy

Tareas:

1. Crear `fuzzy_variants.mjs`.
2. Crear `collision_audit.mjs`.
3. Definir genericos por familia.
4. Definir reglas para productos base/especificos.
5. Bloquear genericos arbitrarios.

Entregables:

- Reporte de colisiones.
- Lista de ajustes requeridos en `palabras_clave`.

### Fase C - Acumulativo Avanzado

Tareas:

1. Generar combinaciones multi-item.
2. Probar notas por segmento.
3. Probar mezcla taco + bebida + especialidad.
4. Decidir e implementar herencia de familia para frases como `tres de pastor`.
5. Implementar falla parcial segura si falta un segmento.

Entregables:

- Matriz acumulativa 2-5 items.
- Decision formal sobre herencia de familia.

### Fase D - Gramatica VOSK

Tareas:

1. Extraer generador de vocabulario VOSK a modulo testeable.
2. Crear `grammar_coverage.test.mjs`.
3. Comparar contrato NLP contra vocabulario.
4. Reportar tokens ausentes.

Entregables:

- Coverage 100% de tokens obligatorios.

### Fase E - Voz Simulada Y Audio Sintetico

Tareas:

1. Crear variantes foneticas de transcripcion.
2. Crear banco inicial de audio sintetico.
3. Ejecutar VOSK contra fixtures.
4. Pasar transcripcion al parser.
5. Reportar precision por familia.

Entregables:

- Primer reporte de regresion de voz.

### Fase F - Audio Real Y Publicacion En Admin

Tareas:

1. Grabar banco real minimo.
2. Integrar boton `Validar NLP` en Admin Catalogo.
3. Guardar reportes por version de catalogo.
4. Bloquear publicacion si hay FAIL.

Entregables:

- Compuerta real antes de publicar catalogo.
- Historial de QA por version.

## Criterios De Aceptacion Final

Texto:

- 100% productos disponibles tienen al menos una frase canonica que resuelve correctamente.
- 0 falsos positivos de genericos.
- 0 colisiones criticas producto base/producto especifico.
- 100% acumulativos generados conservan cantidad, orden y notas.
- 100% mesas invalidas quedan bloqueadas.

Voz:

- 100% tokens obligatorios estan en gramatica.
- Variantes foneticas controladas pasan con objetivo >= 98%.
- Audio sintetico critico pasa con objetivo >= 95%.
- Audio real critico pasa con objetivo inicial >= 90%.
- 0 comandas enviables con mesa invalida o producto ambiguo.

## Riesgos Y Decisiones Pendientes

1. Herencia de familia en acumulativos:
   - Decidir si `dos tacos de tripa y tres de pastor` debe inferir `tacos`.
   - Recomendacion: si, pero solo dentro de la misma comanda y si el producto distintivo pertenece inequivocamente a la familia anterior.

2. Bebidas con tamanios:
   - Decidir si `una coca` por si sola debe resolver a 600ml o pedir aclaracion.
   - Recomendacion: pedir aclaracion si hay varias Coca activas, salvo que Caja defina una presentacion default.

3. Genericos de bebida:
   - `agua`, `refresco`, `cerveza` no deben resolver solos.
   - Recomendacion: exigir sabor/marca/tamanio cuando haya multiples opciones.

4. Productos con modificador como parte del nombre:
   - `con queso`, `dorada`, `jarra`, `vaso` deben tratarse como discriminadores, no solo notas.

5. Audio real:
   - La validacion sintetica ayuda, pero no sustituye el ruido real de cocina/restaurante.

## Siguiente Paso Recomendado

Construir primero la Fase A y Fase B:

1. `catalog_contract.mjs`.
2. `phrase_generator.mjs`.
3. `text_matrix.test.mjs`.
4. `collision_audit.mjs`.

Con eso se obtiene el primer reporte objetivo de brechas del catalogo actual. Despues se avanza a gramatica VOSK y banco de audio.

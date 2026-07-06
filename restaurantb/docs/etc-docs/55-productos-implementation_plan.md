# Plan Revisado: Merge Dataset NLP/VOSK — Motor de Gramática y Catálogo

> **Aclaraciones incorporadas:**
> - ✅ Usar precios del dataset (unitario + precio de orden para 5 piezas)
> - ✅ Refrescos por tamaño = productos separados en BD
> - ✅ Cervezas incluidas en el catálogo
> - ❌ Emojis en PWA: **NO requerido** — el campo `image_emoji` se guarda en BD para uso en Admin/futuro, pero el payload que descarga la PWA y el motor NLP no lo necesitan

---

## Análisis del Gap Revisado

### ¿Qué tiene el dataset que NO tiene la BD actual?

| Aspecto | Dataset `tacos-bebidas.html` | BD Actual (`productos`) | Acción |
|---|---|---|---|
| **Catálogo de productos** | 93 items (31 tacos, 22 refrescos, 28 aguas, 12 cervezas) | 23 items (básicos sin cervezas ni tamaños) | Expandir seed con ~55 productos |
| **Precio de orden** | `orderPrice` (precio por 5 pzas) + `orderQty` | Solo `precio` unitario | Nueva columna `precio_orden` y `cantidad_orden` |
| **Sinónimos por producto** | `generateSynonyms()` dinámico (Trompo, Tripitas, Coronita…) | `palabras_clave` string plano | Nueva columna `sinonimos_json` en `productos` |
| **Emojis** | `imageEmoji` por item | Ninguno | Nueva columna `image_emoji` en BD (Admin solo, NO en PWA payload) |
| **Parser de tamaños** | `parseComplexOrder()` + `getClosestSize()` — "800" → 1L, "familiar" → 3L | ❌ Inexistente | Agregar a `app-voice.js` y endpoint simulador PHP |
| **Parser de temperatura** | Regex `fria/al tiempo/con hielo` como `notas` adicionales | ❌ Inexistente | Agregar a `app-voice.js` como extractor de notas |
| **Levenshtein normalizado** | `findBestItemByCleanName()` usa ratio (dist/maxLen ≤ 0.5) | Distancia absoluta con umbral fijo | Mejorar en `app-voice.js` y PHP simulador |

### Explicación: ¿Por qué las órdenes largas fallan por NLP y no por diseño?
El diseño del sistema y la arquitectura de **VOSK** ya soportan inherentemente el dictado continuo de frases compuestas o largas. La lógica actual en `app-voice.js` ya sabe dividir una frase por comas (`,`) o la conjunción `"y"`. 

**El verdadero cuello de botella es el motor NLP (diccionario y Levenshtein):**
Al tener un vocabulario de solo 23 palabras clave rígidas, si el mesero dicta una orden larga y natural (ej. *"mesa dos, dos tripitas con todo y una coca de litro bien fría"*), el VOSK transcribe el audio correctamente, pero el motor NLP actual **descarta o malinterpreta** "tripitas" (porque no existe el sinónimo) y "de litro" (porque no hay parser de tamaño). Como el motor no sabe qué hacer con esas palabras desconocidas, la orden larga falla silenciosamente o asigna productos incorrectos, dando la falsa impresión de que el sistema "no soporta órdenes largas". Al enriquecer el catálogo, incluir sinónimos y agregar parsers de atributos (tamaño/temperatura), el mismo diseño actual procesará oraciones largas sin problema.

---

## Catálogo Objetivo (~55 productos)

### Tacos Tradicionales (15 items)

| ID | Nombre | Precio Unit | Precio Orden (5) | `palabras_clave` reforzadas | Sinónimos clave |
|:---:|---|:---:|:---:|---|---|
| 1 | Taco Al Pastor | $35 | $160 | `taco pastor tacos pastor trompo al pastor` | Trompo |
| 2 | Taco de Tripa | $35 | $170 | `taco tripa tacos tripa tripitas taco arto taco arta tripa` | Tripitas |
| 3 | Taco de Suadero | $35 | $170 | `taco suadero tacos suadero suadero` | — |
| 4 | Taco de Bistec | $35 | $165 | `taco bistec tacos bistec asada bistec` | — |
| 5 | Taco Campechano | $40 | $190 | `taco campechano tacos campechano mixto campechano` | Mixto |
| 6 | Taco de Cabeza | $33 | $155 | `taco cabeza tacos cabeza cabeza` | — |
| 7 | Taco de Lengua | $45 | $210 | `taco lengua tacos lengua lengua` | — |
| 8 | Taco de Cachete | $42 | $195 | `taco cachete tacos cachete cachete` | — |
| 9 | Taco de Costilla | $38 | $175 | `taco costilla tacos costilla costilla` | — |
| 10 | Taco de Chorizo | $34 | $160 | `taco chorizo tacos chorizo chorizo` | — |
| 11 | Taco de Longaniza | $35 | $170 | `taco longaniza tacos longaniza longaniza` | — |
| 12 | Taco de Barbacoa | $37 | $175 | `taco barbacoa tacos barbacoa barbacoa` | — |
| 13 | Taco de Arrachera | $46 | $215 | `taco arrachera tacos arrachera arrachera` | — |
| 14 | Taco Alambre | $42 | $200 | `taco alambre tacos alambre alambre` | — |
| 15 | Taco Adobada | $34 | $160 | `taco adobada tacos adobada adobada` | — |

### Especialidades (2 items)

| ID | Nombre | Precio Unit | `palabras_clave` |
|:---:|---|:---:|---|
| 16 | Gringa de Pastor | $105 | `gringa gringas gringa pastor gringas pastor` |
| 17 | Consome de Barbacoa | $35 | `consome caldo consome barbacoa caldito` |

### Refrescos por Tamaño (16 items)

| ID | Nombre | Precio Unit | `palabras_clave` |
|:---:|---|:---:|---|
| 20 | Coca-Cola (600ml) | $20 | `coca coca cola refresco cocacola chesco 600 600ml pequena chica` |
| 21 | Coca-Cola (1L) | $32 | `coca cola litro un litro 1l coca litro` |
| 22 | Coca-Cola (2L) | $42 | `coca cola dos litros 2l dos litros` |
| 23 | Coca-Cola (Familiar 3L) | $55 | `coca familiar tres litros 3l familiar` |
| 24 | Pepsi (600ml) | $19 | `pepsi refresco pepsi 600` |
| 25 | Pepsi (1L) | $30 | `pepsi litro pepsi 1l` |
| 26 | Sprite (600ml) | $18 | `sprite limon sprite refresco` |
| 27 | Fanta Naranja (600ml) | $18 | `fanta naranja fanta` |
| 28 | Fanta Fresa (600ml) | $18 | `fanta fresa fanta rosa` |
| 29 | Manzanita Sol (600ml) | $18 | `manzanita manzana sidral` |
| 30 | Sidral Mundet (600ml) | $19 | `sidral mundet manzana verde` |
| 31 | Jarritos Tamarindo (600ml) | $20 | `jarritos tamarindo jarrito` |
| 32 | Jarritos Piña (600ml) | $20 | `jarritos pina jarrito pina` |
| 33 | Jarritos Mandarina (600ml) | $20 | `jarritos mandarina jarrito mandarina` |
| 34 | Jarritos Guayaba (600ml) | $20 | `jarritos guayaba jarrito guayaba` |
| 35 | Jarritos Sandía (600ml) | $20 | `jarritos sandia jarrito sandia` |

### Aguas Frescas (10 items — Vaso y Jarra)

| ID | Nombre | Precio Unit | `palabras_clave` |
|:---:|---|:---:|---|
| 40 | Horchata (Vaso 500ml) | $25 | `agua horchata horchata vaso` |
| 41 | Horchata (Jarra 1L) | $48 | `agua horchata jarra horchata jarra` |
| 42 | Jamaica (Vaso) | $25 | `agua jamaica jamaica vaso` |
| 43 | Jamaica (Jarra) | $48 | `agua jamaica jarra jamaica jarra` |
| 44 | Limón (Vaso) | $24 | `agua limon limon vaso` |
| 45 | Mango (Vaso) | $27 | `agua mango mango vaso` |
| 46 | Guayaba (Vaso) | $25 | `agua guayaba guayaba vaso` |
| 47 | Tamarindo (Vaso) | $25 | `agua tamarindo tamarindo vaso` |
| 48 | Piña (Vaso) | $26 | `agua pina pina vaso` |
| 49 | Tepache (Vaso) | $30 | `agua tepache tepache pina fermentado` |

### Cervezas (5 items)

| ID | Nombre | Precio Unit | `palabras_clave` |
|:---:|---|:---:|---|
| 50 | Corona (355ml) | $38 | `corona coronita cerveza corona` |
| 51 | Modelo Especial | $40 | `modelo modelito cerveza modelo especial` |
| 52 | Pacifico | $39 | `pacifico cerveza pacifico` |
| 53 | Indio | $38 | `indio cerveza indio` |
| 54 | Victoria | $37 | `victoria vicky cerveza victoria` |

**Total: 55 productos semilla**

---

## Propuesta de Cambios por Capa

### Capa 1: Base de Datos

#### [NEW] `09_alter_add_nlp_columns.sql`
Script idempotente de migración delta:

```sql
USE `vcd01`;

-- Precio de orden (ejemplo: 5 tacos = precio especial)
ALTER TABLE `productos`
  ADD COLUMN IF NOT EXISTS `precio_orden`    decimal(10,2)          DEFAULT NULL AFTER `precio`,
  ADD COLUMN IF NOT EXISTS `cantidad_orden`  tinyint(3) unsigned    DEFAULT NULL AFTER `precio_orden`,
  ADD COLUMN IF NOT EXISTS `sinonimos_json`  text                   DEFAULT NULL AFTER `palabras_clave`,
  ADD COLUMN IF NOT EXISTS `image_emoji`     varchar(10)            DEFAULT '🍽️' AFTER `sinonimos_json`;
```

> `image_emoji` se guarda en BD pero **NO se incluye en el payload que recibe la PWA**.

#### [MODIFY] `02_core_schema.sql`
Añadir las 5 columnas nuevas al `CREATE TABLE productos` original para que el `setup.sh` sea idempotente desde cero.

#### [MODIFY] `05_seed_data.sql`
Reemplazar las 23 filas actuales con los 55 productos enriquecidos con precios reales del dataset, `sinonimos_json`.

#### [MODIFY] `07_catalogo_versiones.sql`
Insertar versión semilla `v2.0.0` con el nuevo delta_hash calculado sobre el catálogo expandido.

#### [MODIFY] `setup.sh`
Agregar `09_alter_add_nlp_columns.sql` después de `02_core_schema.sql` en la cadena de ejecución.

---

### Capa 2: Backend PHP

#### [MODIFY] `www/restaurant/index.php`
**Ruta GET `/api/catalogo/actual`** — El payload JSON que devuelve el servidor incluye los campos:
- `palabras_clave` ✅ (ya existe)
- `sinonimos_json` → decodificado a array (nuevo)
- `precio_orden` → nuevo
- `cantidad_orden` → nuevo
- **NO incluir:** `image_emoji` (campo de Admin, no de la PWA)

```php
// NUEVO: incluir sinonimos_json en el SELECT
$stmt_p = $db->query("
    SELECT p.`id`, p.`categoria_id`, p.`nombre`, p.`precio`, 
           p.`precio_orden`, p.`cantidad_orden`,
           p.`palabras_clave`, p.`sinonimos_json`, c.`nombre` as categoria_nombre 
    FROM `productos` p JOIN `categorias` c ON p.`categoria_id` = c.`id`
    WHERE p.`disponible` = 1
    ORDER BY c.`orden` ASC, p.`nombre` ASC
");
```

**Ruta POST `/admin/catalogo/simular`** — Mejorar el simulador NLP PHP con:
- Parser de tamaños (`600ml`, `1l`, `2l`, `familiar`) antes de la búsqueda Levenshtein
- Extracción de temperatura como notas (`fría`, `al tiempo`, `con hielo`)
- Búsqueda por sinónimos expandidos (desde `sinonimos_json`)
- Levenshtein normalizado (ratio) para palabras cortas (≤5 chars: umbral 0.65 ratio, >5 chars: dist ≤ 3)

---

### Capa 3: JavaScript (PWA Client)

#### [MODIFY] `www/web-assets/libs/models/app-voice.js`

**A) `sincronizarCatalogoLocal()`** — El catálogo cacheado en Dexie ahora incluye `sinonimos_json`, `precio_orden`, `cantidad_orden`.

**B) `compilarVocabularioGramatica()`** — Incluir sinónimos expandidos como vocabulario Kaldi:
```js
// Nuevo: procesar sinonimos_json por producto
catalogCached.forEach(p => {
  // palabras_clave (ya existía)
  // NUEVO: sinónimos expandidos
  const syns = p.sinonimos_json ? 
    (Array.isArray(p.sinonimos_json) ? p.sinonimos_json : JSON.parse(p.sinonimos_json || '[]'))
    : [];
  syns.forEach(syn => syn.toLowerCase().split(/\s+/).forEach(w => {
    const nw = normalizeWord(w); if (nw) wordsSet.add(nw);
  }));
});
// Nuevo: vocabulario de tamaños y temperatura
['fria','frio','caliente','tiempo','hielo','familiar','litro','litros',
 'vaso','jarra','chica','grande','chico','mediana'].forEach(w => wordsSet.add(w));
```

**C) Nuevas funciones de parser (porteo desde `tacos-bebidas.html`)**:
```js
function extractSizeFromText(text) { ... } // "800" → 800, "1.5" → 1500 (en ml)
function getClosestSizeLabel(requestedMl) { ... } // 800 → "1L", 1500 → "2L"
function extractTemperatureAttr(text) { ... } // "fría" → {attr: "fría", cleanText: "..."} 
```

**D) `procesarTranscripcionFinal()`** — Pipeline mejorado antes del Levenshtein:
1. Extraer temperatura de cada segmento → añadir a `notas`
2. Extraer tamaño del texto → filtrar candidatos por tamaño (p.ej. "litro" filtra a productos con "litro" en `palabras_clave`)
3. Buscar match Levenshtein con **ratio normalizado** en vez de distancia absoluta

**E) Levenshtein ratio normalizado**:
```js
function levenshteinRatio(a, b) {
  const dist = levenshtein(a, b);
  const maxLen = Math.max(a.length, b.length);
  return maxLen === 0 ? 1.0 : 1.0 - (dist / maxLen);
}
// Para palabras ≤ 5 chars: ratio >= 0.65 para aceptar
// Para palabras > 5 chars: dist <= umbralLargo (3) para aceptar
```

**F) `renderComandaPrevia()`** — Sin cambios de emojis (como solicitado). Solo añadir columna "Precio Ord." si el producto tiene `precio_orden`:
```html
<!-- Si el producto tiene precio de orden, mostrar badge opcional -->
<td>Taco Al Pastor <small>[5 x $160]</small></td>
```

---

## Refinamiento del Protocolo de Voz (Flujo del Mesero)

Basado en el análisis de usabilidad, el protocolo híbrido de voz y táctil se alinea de la siguiente manera, agregando palabras de control específicas para dar mayor fluidez a órdenes largas con pausas:

1. **Activar Escucha:** El mesero da **Touch (Táctil)** al botón del micrófono. Se activa el `AudioContext` de VOSK.
2. **Palabra de Inicio:** El mesero comienza a hablar. La frase **debe iniciar** con `"Mesa [N]..."` (Regla ya existente).
3. **Pausas Naturales:** El mesero puede hacer pausas mientras el cliente ordena. VOSK seguirá escuchando y acumulando el texto (transcripción continua).
4. **Palabra para Limpiar (Nuevo):** Si el mesero se equivoca, dicta **`"Limpiar"`**. El motor JS interceptará esta palabra, vaciará el `textarea` y permitirá reiniciar el dictado sin tocar la pantalla.
5. **Palabra para Terminar (Nuevo):** Cuando el cliente finaliza, el mesero dicta **`"Listo"`**. Al detectar esta palabra al final del dictado, el sistema corta inmediatamente la escucha de VOSK, elimina la palabra "listo" del texto y detona la transformación NLP. Esto es útil para forzar el procesamiento sin esperar al timeout de silencio.
6. **Fin por Silencio (Mantenido):** Si el mesero deja de hablar por varios segundos (VAD), el sistema asume el fin del dictado y pasa al preview automáticamente (comportamiento actual preservado).
7. **Preview y Edición:** Se muestra la comanda interpretada. El mesero puede tocar el `textarea` para editar manualmente si es necesario.
8. **Confirmación de Envío:** El mesero valida visualmente y da **Touch (Táctil)** al botón 🚀 **"Enviar a Cocina"**.

---

### Capa 4: Actualización de Versión

#### [MODIFY] `07_catalogo_versiones.sql`
Insertar `v2.0.0` con:
- JSON expandido de 55 productos (incluyendo `sinonimos_json`, `precio_orden`, `cantidad_orden`)
- Sinónimos de cantidad actualizados: añadir `"par": 2, "orden": 5`
- Umbral Levenshtein largo = 3, corto = 1 (sin cambios)
- `publicado = 1`
- Nuevo `delta_hash` calculado

---

## Fases de Ejecución

| Fase | Tarea | Archivos Afectados | Est. |
|:---:|---|---|:---:|
| **F1** | `09_alter_add_nlp_columns.sql` + integrar en `setup.sh` | `09_alter.sql`, `setup.sh` | 15 min |
| **F2** | Expandir `02_core_schema.sql` (columnas nuevas en CREATE TABLE) | `02_core_schema.sql` | 10 min |
| **F3** | Reemplazar `05_seed_data.sql` con 55 productos (precios dataset + sinónimos) | `05_seed_data.sql` | 45 min |
| **F4** | Modificar endpoint PHP `/api/catalogo/actual` para devolver nuevos campos | `index.php` | 20 min |
| **F5** | Mejorar simulador PHP POST `/admin/catalogo/simular` (parser tamaños + temperatura + Levenshtein ratio) | `index.php` | 30 min |
| **F6** | Actualizar `app-voice.js`: sinónimos en gramática + parser tamaños/temperatura + Levenshtein ratio | `app-voice.js` | 45 min |
| **F7** | Generar v2.0.0 y actualizar `07_catalogo_versiones.sql` | `07_catalogo_versiones.sql` | 20 min |
| **F8** | `setup.sh` completo + `run_functional_tests.php` (24/24 ✅) | CI local | 10 min |
| **F9** | Actualizar casos de prueba (`Pruebas_Casos_Validacion_Comandas_VOSK.html`) | Doc HTML | 20 min |

---

## Nuevos Casos de Prueba QA Requeridos

Los siguientes casos de prueba deben **añadirse** al HTML de validación:

### CLI Automatizados — Nueva Sección 1.5: Schema NLP Expandido

| ID | Caso | Criterio de Aceptación |
|:---:|---|---|
| **F5-01** | Columna `precio_orden` en `productos` | `SHOW COLUMNS` devuelve la columna |
| **F5-02** | Columna `cantidad_orden` en `productos` | `SHOW COLUMNS` devuelve la columna |
| **F5-03** | Columna `sinonimos_json` en `productos` | `SHOW COLUMNS` devuelve la columna |
| **F5-04** | Catálogo expandido ≥ 50 productos | `SELECT COUNT(*) FROM productos WHERE disponible=1` ≥ 50 |
| **F5-05** | Versión activa v2.0.0 publicada | `SELECT * FROM catalogo_versiones WHERE publicado=1` devuelve version_label = 'v2.0.0' |
| **F5-06** | Productos de categoría Cerveza presentes | `SELECT COUNT(*) FROM productos p JOIN categorias c... WHERE c.nombre='Cervezas'` ≥ 5 |
| **F5-07** | Refrescos por tamaño (≥4 registros para Coca-Cola) | `SELECT COUNT(*) FROM productos WHERE nombre LIKE 'Coca%'` ≥ 4 |
| **F5-08** | Al menos 1 producto con `sinonimos_json` no nulo | `SELECT COUNT(*) FROM productos WHERE sinonimos_json IS NOT NULL` ≥ 1 |
| **F5-09** | `precio_orden` positivo en tacos | `SELECT precio_orden FROM productos WHERE nombre LIKE 'Taco%' LIMIT 1` > 0 |

### Manuales Browser — Nueva Sección 2.9: NLP Extendido y Gramática Enriquecida

#### QA-NLP-01: Dictado con sinónimo fonético (Tripitas)
- **Frase:** `"mesa dos, dos tripitas con todo"`
- **Resultado esperado:** El motor NLP resuelve "tripitas" → **Taco de Tripa** (via `sinonimos_json`)
- **Verificar:** En el preview de comanda se muestra "Taco de Tripa x2"

#### QA-NLP-02: Dictado con sinónimo de cantidad (Trompo)
- **Frase:** `"mesa uno, trompo y una jamaica"`
- **Resultado esperado:** "trompo" → **Taco Al Pastor x1**, "jamaica" → **Jamaica (Vaso) x1**

#### QA-NLP-03: Refresco con tamaño detectado
- **Frase:** `"mesa tres, una coca de litro y dos tacos de pastor"`
- **Resultado esperado:** "coca de litro" → **Coca-Cola (1L)** (parser extrae "litro" → 1000ml → 1L)

#### QA-NLP-04: Refresco familiar
- **Frase:** `"una coca familiar para mesa cuatro"`
- **Resultado esperado:** "coca familiar" → **Coca-Cola (Familiar 3L)**

#### QA-NLP-05: Temperatura como nota
- **Frase:** `"mesa cinco, una coca bien fría y dos de suadero"`
- **Resultado esperado:** Coca-Cola (600ml) registrada con nota `bien fría`, Taco de Suadero x2

#### QA-NLP-06: Cerveza reconocida
- **Frase:** `"mesa dos, dos coronitas y tres de pastor"`
- **Resultado esperado:** "coronitas" → **Corona (355ml) x2**, "pastor" → **Taco Al Pastor x3**

#### QA-NLP-07: Levenshtein ratio — fonética imperfecta real
- **Frase:** `"mesa uno, un taco de vastor"` (VOSK transcribe mal "pastor")
- **Resultado esperado:** dist("vastor","pastor") = 1, ratio = 0.833 ≥ 0.65 → **Taco Al Pastor x1**

#### QA-NLP-08: Agua con presentación
- **Frase:** `"mesa cuatro, una jarra de horchata"`
- **Resultado esperado:** "jarra de horchata" → **Horchata (Jarra 1L)**

#### QA-NLP-09: Simulador NLP Panel Admin
- **URL:** `https://192.168.1.71:8443/admin/catalogo`
- **Acción:** Usar el Simulador NLP con la frase "tres cocas una de 600 al tiempo una de litro fría"
- **Resultado esperado:** El simulador devuelve 2 items (Coca 600ml con nota "al tiempo", Coca 1L con nota "fría") y muestra la distancia Levenshtein = 0 (coincidencia exacta)

#### QA-NLP-10: Validación de Delta Hash v2.0.0
- **Acción:** Limpiar datos de sitio en Chrome → Ingresar como Mesero → Abrir DevTools → Network
- **Resultado esperado:** La primera llamada a `/api/catalogo/actual` responde con `"version_label": "v2.0.0"` y la PWA descarga el catálogo completo. En la segunda carga, no hay descarga (hash en paridad).

---

## Decisiones de Diseño Confirmadas

> [!IMPORTANT]
> **Emojis en BD pero NO en payload PWA**: El campo `image_emoji` se almacena en la tabla `productos` para uso futuro en el panel Admin y el Simulador NLP. El endpoint `/api/catalogo/actual` no lo incluye en el JSON para mantener el payload ligero. Esto no requiere cambios en `app-voice.js` ni en `renderComandaPrevia()`.

> [!IMPORTANT]
> **Precio de Orden como campo de referencia**: `precio_orden` se muestra en el panel Admin del catálogo y en el Simulador NLP. En la comanda final que se envía a cocina se usa siempre el `precio` unitario × cantidad. El `precio_orden` es solo referencia comercial para el mesero.

> [!IMPORTANT]
> **Levenshtein ratio vs. distancia absoluta**: El motor JS actual usa distancia absoluta. El cambio a ratio normalizado impacta directamente la tasa de falsos positivos en palabras cortas (≤5 chars). **Umbral propuesto:**
> - Palabras ≤ 5 chars: `ratio >= 0.65` (equivale a 1 error en 3 chars)
> - Palabras > 5 chars: mantener `dist <= umbralLargo` (= 3) como ahora

> [!WARNING]
> **Refrescos por tamaño como productos separados**: Cada presentación (600ml, 1L, 2L, Familiar) es un producto independiente con su propio ID. El parser de tamaños en JS debe **filtrar candidatos** antes de aplicar Levenshtein: primero detectar el tamaño pedido, luego buscar entre los productos que contengan ese tamaño en `palabras_clave`.

---

## Verificación del Plan

### CLI Automatizado
```bash
# Recrear BD completa con el nuevo catálogo
bash setup/bds/voz_cocina_dual/setup.sh

# Suite funcional (debe pasar 24+ tests sin regresiones)
php tests/run_functional_tests.php
```

### Manual Browser
1. Dictar: `"Mesa dos, dos tripitas con todo y una coca de litro bien fría"` en la PWA del Mesero.
2. Verificar: **Taco de Tripa x2** + **Coca-Cola (1L) x1** con nota `bien fría`.
3. Confirmar comanda → aparece en KDS de cocina.
4. Abrir panel Admin → Simulador NLP: frase de prueba "tres cocas una familiar y dos de suadero".
5. Verificar: Coca Familiar 3L x3, Taco de Suadero x2, distancias Levenshtein y notas mostradas.


# ANÁLISIS: VOSK Grammar + IndexedDB para Menú de Restaurante Oaxaqueño

## Resumen Ejecutivo

Para un restaurante típico oaxaqueño con ~120 platillos únicos, el vocabulario 
completo ronda las **150-170 palabras únicas**. Esto es PERFECTAMENTE manejable 
por VOSK en modo Grammar en Android, siempre que se use la estrategia correcta.

---

## 1. Tamaño del Vocabulario Oaxaqueño

### Platillos típicos identificados:
- **Desayunos**: huevos con chorizo, chilaquiles (rojos/verdes/mole), tasajo, etc.
- **Antojitos**: tamales oaxaqueños, molotes, memelitas, tlayudas, tetelas
- **Sopas**: caldo de guías, sopa zapoteca, sopa milpa
- **Moles**: negro, rojo, coloradito, verde, amarillito
- **Carnes**: tasajo, cecina enchilada, chorizo oaxaqueño, chicharrón
- **Bebidas**: tejate, chilacayota, chocolate oaxaqueño, mezcal
- **Postres**: lechecilla, nieve oaxaqueña, plátanos fritos mixtecos
- **Especiales**: chapulines, chicatanas, gusanos de maguey, huitlacoche

### Métricas:
| Métrica | Valor |
|---------|-------|
| Platillos únicos | ~120 |
| Palabras únicas | ~150 |
| Grammar JSON (nombres) | ~2.1 KB |
| Grammar JSON (con variantes) | ~17.5 KB |

---

## 2. Cómo Funciona VOSK Grammar Mode

VOSK utiliza un **Weighted Finite-State Transducer (WFST)** internamente:

- **Modo completo**: El grafo WFST incluye TODAS las palabras del diccionario 
  (miles de palabras). Búsqueda amplia, más lentitud.

- **Modo Grammar**: El grafo se reemplaza por un **subgrafo** que solo contiene 
  las frases especificadas. Esto reduce drásticamente:
  - Falsos positivos
  - Carga de CPU
  - Tiempo de reconocimiento

### Formato JSON requerido:
```json
["mole negro", "mole rojo", "tlayuda", "tasajo", "[unk]"]
```

⚠️ **IMPORTANTE**: Siempre incluir `"[unk]"` al final. Sin él, si el usuario dice 
algo fuera del grammar, el reconocedor se "atasca" y deja de responder.

---

## 3. Límites de VOSK Grammar en Android

| Aspecto | Límite/Recomendación |
|---------|---------------------|
| Frases por grammar | Ideal: < 50, Máximo recomendado: < 200 |
| Tamaño JSON grammar | < 20 KB óptimo |
| Modelos que soportan grammar | Modelos "small" (lookahead models) |
| Modelos que NO soportan grammar | Modelos "big" (precompiled HCLG graph) |
| Memoria runtime (modelo small) | ~300 MB |
| Tiempo SetGrm (cambio grammar) | 100-300 ms |

**Nota**: Los modelos "small" (~40-50 MB) permiten reconfiguración dinámica de 
vocabulario. Los modelos "big" (1-2 GB) son estáticos.

---

## 4. Persistencia en IndexedDB - ¿Es viable?

### ¡ABSOLUTAMENTE SÍ!

| Recurso | Tamaño | ¿Cabe en IndexedDB? |
|---------|--------|---------------------|
| Grammar JSON (1 categoría) | ~0.5 KB | ✅ Sí |
| Grammar JSON (completo) | ~2 KB | ✅ Sí |
| Menú completo en JSON | ~10 KB | ✅ Sí |
| Modelo VOSK | ~50 MB | ❌ No (va en assets) |
| Límite IndexedDB | ~50-250 MB | ✅ Amplio margen |

### Estructura recomendada en IndexedDB:

```javascript
// Object Store: grammars
{
  id: "grammar_moles",
  version: 1,
  last_updated: "2026-06-10T14:53:00Z",
  phrases: ["mole negro", "mole rojo", "coloradito", "[unk]"],
  category: "moles"
}

// Object Store: menu_catalog
{
  id: "mole_negro",
  name: "Mole Negro con Pollo",
  category: "moles",
  price: 140,
  variants: ["con pollo", "con res"],
  grammar_id: "grammar_moles"
}
```

---

## 5. Estrategia Recomendada: Grammar por Contexto

### Flujo de pedido por voz:

```
┌─────────────────────────────────────────────────────────────┐
│  PASO 1: Selección de categoría                             │
│  Grammar: ["desayunos", "antojitos", "sopas",               │
│           "moles", "carnes", "bebidas",                     │
│           "postres", "[unk]"]                               │
│  → Usuario dice: "moles"                                    │
├─────────────────────────────────────────────────────────────┤
│  PASO 2: Selección de platillo                              │
│  Grammar: ["mole negro", "mole rojo", "coloradito",        │
│           "mole verde", "amarillito", "[unk]"]              │
│  → Usuario dice: "mole negro"                               │
├─────────────────────────────────────────────────────────────┤
│  PASO 3: Variantes/Confirmación                           │
│  Grammar: ["con pollo", "con res", "para llevar",          │
│           "para comer aquí", "[unk]"]                       │
│  → Usuario dice: "con pollo, para llevar"                   │
├─────────────────────────────────────────────────────────────┤
│  PASO 4: Confirmación final                                │
│  Grammar: ["sí", "correcto", "confirmar",                 │
│           "no", "cancelar", "[unk]"]                         │
└─────────────────────────────────────────────────────────────┘
```

### Ventajas de esta estrategia:
1. **Mayor precisión**: Grammar pequeño = menos confusiones
2. **Menor latencia**: WFST más pequeño = reconocimiento más rápido
3. **Escalable**: Agregar platillos no afecta otros grammars
4. **Actualizable**: Cambios de menú solo requieren regenerar JSON

---

## 6. Código de Ejemplo (Android/Kotlin)

```kotlin
class VoskMenuRecognizer(private val model: Model, private val sampleRate: Float) {

    private var recognizer: Recognizer? = null

    // Cargar grammar desde IndexedDB (simulado)
    fun loadGrammarForCategory(category: String, grammarJson: String) {
        // Liberar recognizer anterior
        recognizer?.free()

        // Crear nuevo recognizer con grammar
        recognizer = Recognizer(model, sampleRate, grammarJson)
    }

    // Cambiar grammar dinámicamente con SetGrm
    fun switchGrammar(grammarJson: String) {
        recognizer?.setGrm(grammarJson)
    }

    fun processAudio(buffer: ShortArray) {
        recognizer?.acceptWaveform(buffer)
    }

    fun getResult(): String {
        return recognizer?.result ?: ""
    }
}

// Uso
val menuRecognizer = VoskMenuRecognizer(model, 16000f)

// Paso 1: Categorías
val categoriesGrammar = '["desayunos","antojitos","sopas","moles","carnes","bebidas","postres","[unk]"]'
menuRecognizer.loadGrammarForCategory("categories", categoriesGrammar)

// Después de detectar "moles"...
val molesGrammar = '["mole negro","mole rojo","coloradito","mole verde","amarillito","[unk]"]'
menuRecognizer.switchGrammar(molesGrammar)
```

---

## 7. Optimización de Tiempos

| Operación | Tiempo Estimado | Optimización |
|-----------|-----------------|--------------|
| Carga modelo VOSK | 2-5s (única vez) | Precargar al iniciar app |
| Carga grammar desde IndexedDB | < 50ms | Usar caché en memoria |
| SetGrm (cambio grammar) | 100-300ms | Hacer durante transiciones UI |
| Reconocimiento frase | 200-800ms | Grammar pequeño = más rápido |
| Sincronización menú API | 1-3s | Background thread |

---

## 8. Consideraciones para Pruebas con Meseros Reales

### Desafíos identificados:
1. **Acento oaxaqueño**: VOSK modelo español-México debería manejarlo bien
2. **Ruido ambiental**: Restaurante = ruido. Usar VAD (Silero) antes de VOSK
3. **Formas coloquiales**: "Dame un...", "Quiero...", "Me das..."
4. **Variantes de pronunciación**: "tlayuda" vs "clayuda", "chapulín" vs "chapulin"

### Recomendaciones para pruebas:
1. Grabar audio de meseros reales en ambiente de restaurante
2. Incluir variantes de frases en el grammar:
   ```json
   ["quiero mole negro", "dame mole negro", "mole negro",
    "quiero tlayuda", "dame una tlayuda", "tlayuda",
    "[unk]"]
   ```
3. Usar Silero VAD para detectar inicio/fin de voz
4. Ajustar threshold de VAD para ambiente ruidoso (0.65 recomendado)

---

## 9. Conclusión

✅ **SÍ es viable** usar VOSK grammar con IndexedDB para un menú oaxaqueño típico.

✅ El vocabulario (~150 palabras) cabe perfectamente en la arquitectura de 
   grammars dinámicos de VOSK.

✅ IndexedDB es más que suficiente para persistir grammars y catálogo de menú.

✅ La estrategia de **grammar por contexto** (categoría → platillo → variantes) 
   es la óptima para precisión y rendimiento.

⚠️ Los modelos "big" de VOSK NO permiten grammar dinámico. Usar solo modelos 
   "small" para esta aplicación.

---

*Análisis generado el 2026-06-10*

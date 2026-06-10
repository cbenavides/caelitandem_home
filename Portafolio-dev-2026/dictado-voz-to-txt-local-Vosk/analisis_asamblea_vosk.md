# Análisis de Funcionalidad e Integración de Vosk-D en la Web App de Asambleas

Este documento presenta una propuesta de modernización y optimización de la micro-webapp de **Gestión de Asambleas** (`/asamblea/`) incorporando el motor de reconocimiento de voz offline **Vosk-D** bajo una arquitectura frugal y eficiente.

---

## 🔍 Diagnóstico de la Operación de Asambleas
La micro-webapp de Asambleas cumple la función de pase de lista presencial y emisión de tickets térmicos de asistencia. Durante las asambleas generales (flujo masivo de cientos de ciudadanos), el registro físico se convierte en un cuello de botella debido a:
1. **Fatiga del operador** por tecleo repetitivo de nombres y números de contrato.
2. **Registro de notas incompleto:** Se omiten aclaraciones críticas (ej. *"asiste representante"*, *"tercera edad exento"*) en el campo `reg-nota` para no demorar la fila.
3. **Coordinación óculo-manual constante:** Alternar entre tecleo, clic en buscar, clic en registrar ("OK"), y clics en el diálogo de ticket de impresión.

---

## 💡 Propuestas de Integración Funcional con Vosk-D

A continuación, se listan las características funcionales más efectivas para optimizar el registro en asambleas utilizando Vosk-D:

### 1. Buscador Híbrido por Voz con Gramáticas Duales
* **Propósito:** Permitir al operador dictar un nombre o número de contrato en el campo `#buscador` sin tocar el teclado.
* **Flujo Técnico Frugal:**
  * Al activar el micrófono, el sistema utiliza un reconocedor inicial de dígitos si el operador dicta números (ej. *"uno dos tres"*), o conmuta al diccionario completo en español si dicta texto.
  * **Gramática del Contrato:** `'["cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "listo", "borrar", "[unk]"]'`
  * Esto asegura un **100% de precisión** al eliminar el ruido fonético del español en los campos numéricos de contratos.

### 2. Dictado Rápido de Notas de Asistencia (`#reg-nota`)
* **Propósito:** Facilitar al operador el ingreso de comentarios especiales de forma rápida a manos libres mientras atiende al ciudadano.
* **Flujo Técnico Frugal:**
  * Un botón de dictado dedicado junto al cuadro de texto `Comentario (opcional)`.
  * El operador activa el micrófono y dicta la observación: *"Asiste hija en representación con carta poder, listo"*.
  * El reconocedor escucha la palabra de control `"listo"`, detiene la captura de audio automáticamente, limpia la palabra de control y la puntuación, e inserta el texto final.

### 3. Navegación Operativa Manos Libres (Poka-Yoke por Voz)
* **Propósito:** Eliminar por completo el uso del mouse/táctil durante el flujo de registro presencial.
* **Flujo Técnico Frugal:**
  * Un reconocedor pasivo en segundo plano utilizando una gramática ultra-restringida y de bajísimo consumo de CPU (menos de 10 palabras):
    ```json
    ["buscar", "asistir", "confirmar", "imprimir", "cerrar", "listo", "nuevo", "[unk]"]
    ```
  * **Comandos y Acciones en `asamblea.js`:**
    * **"buscar"** $\rightarrow$ Invoca inmediatamente la función `buscar()`.
    * **"confirmar"** o **"asistir"** $\rightarrow$ Registra la asistencia (`registrarAsistencia()`) de la coincidencia activa en pantalla.
    * **"imprimir"** $\rightarrow$ Ejecuta el disparo de impresión del ticket (`window.print()`).
    * **"cerrar"** o **"listo"** $\rightarrow$ Invoca `cerrarTicket()`, cerrando el modal de impresión y regresando el foco automáticamente al `#buscador`.

---

## 🛠️ Arquitectura de Implementación Frugal para Asamblea

Para integrar estas funciones sin ralentizar la aplicación en computadoras o tabletas del personal de registro, se deben seguir los siguientes patrones de la arquitectura frugal:

1. **Compartir Recursos (`pcm-processor.js`):**
   * El módulo de asambleas debe cargar el AudioWorklet optimizado `/web-assets/js/pcm-processor.js` para realizar la captura en segundo plano con baja latencia y sin bloquear la UI.

2. **Wake Lock API Activa:**
   * Al iniciar el pase de lista de la asamblea, la aplicación debe solicitar el bloqueo de suspensión de pantalla (`navigator.wakeLock`) para garantizar que la tableta o laptop no se apague ni suspenda el micrófono durante lapsos de inactividad física.

3. **Lazy Loading del Modelo:**
   * El modelo de voz solo se carga en memoria en el momento en que se ingresa a la vista de `Registro` (`switchView('registro')`) y se descarga de la memoria RAM con `.terminate()` al volver a la vista de `Administración` o `Volver al Sistema`.

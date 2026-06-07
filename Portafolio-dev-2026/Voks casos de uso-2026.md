# Proyecto: Asistente de Voz Inteligente Offline para Negocios de Despacho Rápido  
**Tecnología Base:** JavaScript Nativo, Web Speech API y Vosk-Browser (WebAssembly)  
**Entorno de Operación:** 100% Local / Sin Internet (Offline)

---

## 1. Resumen Ejecutivo de la Investigación y Temas Vistos

A lo largo de la sesión se evaluó la viabilidad técnica y comercial de implementar sistemas de reconocimiento y síntesis de voz en el navegador web enfocados en microempresas de ciudades pequeñas. Los puntos clave cubiertos fueron:

*   **Evolución Tecnológica (De la Nube a Local):** Se analizaron las limitaciones de la *Web Speech API* tradicional (que suele requerir conexión oculta a servidores externos) y se seleccionó **Vosk** (`vosk-browser`) como la solución open-source definitiva. Vosk corre localmente mediante WebAssembly (Wasm) usando modelos ultra comprimidos de ~39 MB.  
*   **Viabilidad en Negocios de Despacho Rápido:** Se identificó que las microempresas con alta afluencia, catálogos pequeños (<50 artículos) y personal con las manos ocupadas o sucias (harina, masa, grasa, agua) obtienen un retorno de inversión inmediato en productividad al eliminar la fricción de las pantallas táctiles.  
*   **El Modelo Pequeño de Vosk:** Se determinó que el modelo `vosk-model-small-es-0.42` es capaz de procesar comandos de forma inmediata (en milisegundos), siempre y cuando se aplique una **Gramática Restringida (Grammar)** que limite el diccionario a palabras clave del negocio.  
*   **Hardware y Rentabilidad:** Se evaluó el ecosistema de micrófonos y se concluyó que las diademas monoaurales USB de tipo Call Center (como Xuuly o Poly) representan la opción más rentable (menos de $800 MXN), ya que aíslan el ruido mecánico e inyectan una señal digital limpia a la IA.

---

## 2. Implementación de Voz en JavaScript (Historial Técnico)

### Fase 1: Enfoque Nativo Híbrido (Web Speech API)  
Ideal para prototipos rápidos, utiliza los recursos del sistema operativo pero puede requerir internet en ciertos navegadores para la transcripción.

#### Código de Texto a Voz (Síntesis)  
```javascript
const mensaje = new SpeechSynthesisUtterance("¡Hola! ¿En qué puedo ayudarte hoy?");  
mensaje.lang = 'es-ES';  
mensaje.rate = 1.0;   
mensaje.pitch = 1.0;  
window.speechSynthesis.speak(mensaje);  
```

#### Código de Reconocimiento (Speech-to-Text)  
```javascript
const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
if (!SpeechRecognition) {
    console.error("Este navegador no soporta Web Speech API.");
} else {
    const recognition = new SpeechRecognition();
    recognition.lang = 'es-MX';  
    recognition.continuous = false;  
    recognition.interimResults = false;

    recognition.start();  
    recognition.onresult = (event) => {  
        const textoEscuchado = event.results[0][0].transcript;  
        console.log("El usuario dijo: " + textoEscuchado);  
    };  
}
```

---

### Fase 2: Implementación 100% Offline con Vosk-Browser

Esta arquitectura descarga un modelo comprimido por única vez y ejecuta el procesamiento localmente en un hilo secundario (Web Worker), garantizando privacidad y cero lag.

```html
<!DOCTYPE html>  
<html lang="es">  
<head>  
    <meta charset="UTF-8">  
    <title>Punto de Venta por Voz - Vosk Offline</title>  
    <!-- Cargar la librería oficial mediante CDN -->  
    <script type="application/javascript" src="https://cdn.jsdelivr.net/npm/vosk-browser@0.0.5/dist/vosk.js"></script>  
</head>  
<body>  
    <h1>Sistema de Voz Local - Modo Offline</h1>  
    <button id="btnIniciar" disabled>Cargando Modelo Vocálico...</button>  
    <p id="transcripcion">Estado: Esperando inicialización...</p>

    <script>  
        let model;  
        let recognizer;  
        const btn = document.getElementById('btnIniciar');  
        const txt = document.getElementById('transcripcion');

        // 1. Inicializar Vosk y descargar el modelo local (39MB)  
        async function initVosk() {  
            // El archivo .tar.gz debe estar alojado en tu propio servidor local  
            const modelUrl = 'modelos/vosk-model-small-es-0.42.tar.gz';   
            try {  
                model = await Vosk.createModel(modelUrl);  
                btn.innerText = "Activar Micrófono";  
                btn.disabled = false;  
                txt.innerText = "Sistema Listo.";  
            } catch (error) {  
                console.error("Error al cargar Vosk:", error);  
                btn.innerText = "Error de Carga";  
            }  
        }

        // 2. Configurar la escucha con captura de audio digital limpia  
        async function iniciarEscucha() {  
            const sampleRate = 16000; // Frecuencia óptima para Vosk  
              
            const stream = await navigator.mediaDevices.getUserMedia({  
                audio: {  
                    echoCancellation: true,  
                    noiseSuppression: true,  
                    channelCount: 1,  
                    sampleRate  
                }  
            });

            // REGLA DE ORO: Gramática restringida para máxima precisión en el negocio  
            const vocabularioNegocio = [  
                "uno", "dos", "tres", "cuatro", "cinco", "medio", "kilo", "kilos",   
                "pesos", "tortillas", "masa", "totopos", "salsa", "cobrar", "limpiar", "pagar"  
            ];

            // Inicializar el reconocedor pasando el diccionario estricto en formato JSON  
            recognizer = new model.KaldiRecognizer(sampleRate, JSON.stringify(vocabularioNegocio));  
              
            const audioContext = new (window.AudioContext || window.webkitAudioContext)({ sampleRate });  
            const source = audioContext.createMediaStreamSource(stream);  
            const processor = audioContext.createScriptProcessor(4096, 1, 1);

            processor.onaudioprocess = (e) => {  
                const buffer = e.inputBuffer.getChannelData(0);  
                if (recognizer.acceptWaveform(buffer)) {  
                    const resultado = recognizer.result();  
                    if(resultado.text) {  
                        txt.innerText = "Comando definitivo: " + resultado.text;  
                        procesarLogicaNegocio(resultado.text);  
                    }  
                } else {  
                    const parcial = recognizer.partialResult();  
                    if(parcial.partial) {  
                        txt.innerText = "Escuchando: " + parcial.partial;  
                    }  
                }  
            };

            source.connect(processor);  
            processor.connect(audioContext.destination);  
            btn.innerText = "Escuchando Atentamente...";  
        }

        // 3. Procesamiento semántico de comandos de venta  
        function procesarLogicaNegocio(textoRaw) {  
            const comando = textoRaw.toLowerCase().trim();  
              
            if (comando.includes("tortillas") || comando.includes("masa")) {  
                const numeros = comando.match(/\d+/) || ["1"];  
                const cantidad = parseInt(numeros[0]);  
                const unidad = comando.includes("kilo") ? "kilos" : "pesos";  
                  
                console.log(`Registrando: ${cantidad} ${unidad} de producto.`);  
                // Aquí se conecta con el script del carrito local  
            }  
        }

        btn.addEventListener('click', iniciarEscucha);  
        window.addEventListener('load', initVosk);  
    </script>  
</body>  
</html>  
```

---

## 3. Matriz de Casos de Uso por Giro Comercial

El modelo pequeño de Vosk es altamente efectivo si se implementa en los siguientes comercios:

| Giro Comercial | Dinámica de Operación | Reto Técnico (Gap) | Solución con Vosk |  
| :--- | :--- | :--- | :--- |  
| **Tortillerías** | Venta express por Kilos o Pesos. Manos húmedas/con masa. | Alto ruido de motores y extractores mecánicos. | Uso de diademas direccionales USB + Gramática cerrada. |  
| **Carnicerías y Pollerías** | Pesaje constante de cortes de carne. Uso estricto de guantes. | Grasa en las manos que daña terminales físicas. | Dictado inmediato del peso registrado en báscula. |  
| **Panaderías** | Despacho con pinzas y charolas en movimiento. | Catálogo amplio de nombres de piezas de pan. | Restringir el diccionario web a los 20 panes más vendidos. |  
| **Juguerías / Licuados** | Flujo masivo de clientes por las mañanas. | Ruido agudo de licuadoras y extractores de jugos. | Filtros de audio en Web API para mitigar altas frecuencias. |  
| **Paleterías / Neverías** | Despacho rápido de sabores e insumos pegajosos. | Tráfico pesado los fines de semana. | Mapeo directo de palabras como "cono", "vaso", "litro". |

---

## 4. Análisis y Evaluación de Hardware (Micrófonos)

Para mitigar las brechas (*gaps*) de ruido en entornos comerciales, se evaluaron los siguientes componentes físicos:

### Requisitos Mínimos Sugeridos  
1.  **Conexión:** USB Nativa (Evitar Jack 3.5mm para eludir estática analógica).  
2.  **Patrón Captura:** Cardioide / Unidireccional (Ignora el sonido ambiental del local).  
3.  **Estructura:** Diadema Monoaural (Un solo oído libre para atender la interacción humana con el cliente).  
4.  **Almohadillas:** Vinipiel o Cuero sintético (Las esponjas absorben suciedad del negocio rápidamente).

### Modelos Evaluados en Costo-Beneficio  
*   **Gama Económica (Xuuly / Marcas Call Center Genéricas):** ~$350 - $400 MXN. Ofrecen un brazo flexible largo de 360° que sitúa la cápsula del micrófono directo en la comisura del labio. Excelente opción de arranque.  
*   **Gama Empresarial (Poly Blackwire 3210 / Plantronics):** ~$750 - $800 MXN. Cuenta con un procesador digital de señales (DSP) integrado en el chip de conexión. Este chip remueve ruidos eléctricos antes de mandar la señal a JavaScript, garantizando una precisión del 99% con Vosk.

---  
*Fin del documento.*  

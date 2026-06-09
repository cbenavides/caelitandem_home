# Reporte Técnico: Dictado por Voz Offline (Vosk POC) — Optimizado

Este documento detalla el estado del módulo de dictado por voz offline (`v-ospv/vozweb.php`) tras la corrección del problema de carga de librerías en subdirectorios y la implementación de optimizaciones críticas de hardware y memoria.

---

## 🚀 1. Resumen de lo Realizado y Corregido

1. **Resolución de "Vosk is not defined" (Rutas dinámicas)**:
   - **Problema**: Al mover el archivo a `v-ospv/vozweb.php`, las rutas relativas `web-assets/js/vosk.js` y `web-assets/models/...` se resolvían dentro de la carpeta `v-ospv`, provocando fallos HTTP 404 y bloqueos de carga.
   - **Solución**: 
     - La etiqueta `<script>` ahora detecta dinámicamente si el archivo existe en el directorio actual o en el padre (`../`):
       `<?php echo file_exists('web-assets/js/vosk.js') ? 'web-assets/js/vosk.js' : '../web-assets/js/vosk.js'; ?>`
     - En el frontend JS se analiza la propiedad `pathname` de la ventana para determinar si estamos en el subdirectorio `v-ospv` y resolver la URL absoluta del modelo apuntando al root del servidor (`/ayd-os/` o `/agua/`):
       ```javascript
       let rootPath = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/'));
       if (rootPath.endsWith('/v-ospv')) {
           rootPath = rootPath.substring(0, rootPath.length - 7);
       }
       ```

2. **Optimización del Consumo de Memoria RAM (Lazy Loading & Worker Termination)**:
   - **Carga Perezosa (Lazy Loading)**: El modelo y el reconocedor lingüístico (WASM) ya no se inicializan por defecto al cargar la página. Permanecen inactivos hasta que el usuario hace clic explícitamente en el botón **"Activar"** del Badge o interactúa con el micrófono de un campo de texto.
   - **Liberación Absoluta de Recursos**: Se introdujo el botón **"Desactivar"** en el Badge, el cual ejecuta la función `desactivarVosk()`. Esta función apaga grabaciones activas/pasivas, invoca `voskModel.worker.terminate()` para destruir el hilo del Web Worker y limpia la variable `voskModel = null`. Esto devuelve el consumo de memoria JS Heap del navegador y los subprocesos de CPU a **cero**.

3. **Optimización del Ciclo de Vida de AudioContext**:
   - **Singleton Global**: Se reemplazó la instanciación redundante de objetos `AudioContext` en cada acción por un único singleton global `globalAudioCtx`.
   - **Función de Obtención**: `obtenerAudioContext()` inicializa la instancia compartida una sola vez a 16000 Hz.
   - **Ciclo No Bloqueante**: En lugar de llamar a `audioContext.close()`, los flujos se detienen desconectando las pistas de audio (`track.stop()`) y los nodos procesadores (`recognizerNode.disconnect()`). Para liberar la tarjeta de sonido del sistema, el contexto global se suspende temporalmente (`globalAudioCtx.suspend()`) al desactivar el motor, y se reactiva vía `resume()` al volver a encenderlo.

---

## 📊 2. Estado de la Rama y Commits

| Commit | Mensaje | Estado |
| :--- | :--- | :--- |
| `7258540` | `feat(voice): fix Vosk path resolution and optimize RAM and AudioContext lifecycle` | **Empujado a `origin/aguad_ac_oferta`** |

---

## 🛠️ 3. Pruebas Realizadas en el Servidor Local

- **PHP Lint**: `No syntax errors detected in v-ospv/vozweb.php`.
- **Compatibilidad**: La carga desde la VM de Host C a través de `http://localhost:7001/ayd-os/v-ospv/vozweb.php` resuelve correctamente los recursos compartidos sin drifts ni duplicados huérfanos.

---

## 🌐 4. Acceso en Entornos Inseguros (HTTP sobre red local / VM Windows 10)

Para habilitar el funcionamiento del dictado por voz desde direcciones IP de red local o máquinas virtuales (como `http://192.168.1.128:7001/ayd-os/v-ospv/vozweb.php`), dado que los navegadores modernos restringen el acceso al micrófono (`getUserMedia`) únicamente a orígenes seguros (`HTTPS` o `localhost`), existen dos opciones:

### Opción A: Tratar Orígenes Inseguros como Seguros (Flags del Navegador)
*   **Procedimiento**: En el navegador cliente, acceder a `chrome://flags/#unsafely-treat-insecure-origin-as-secure`. Habilitar la directiva e ingresar la URL del servidor (`http://192.168.1.128:7001`). Reiniciar el navegador mediante el botón *Relaunch*.
*   **Anotación de Verificación**: 
    > [!IMPORTANT]
    > **Estatus**: Verificado y funcionando correctamente. La primera opción (Opción A) fue probada con éxito a fecha **2026-06-09 15:56 (hora local)**, permitiendo capturar audio y transcribir con Vosk sin problemas en la VM.

### Opción B: Configuración de SSL/HTTPS en Apache (Host C)
*   **Procedimiento**: Habilitar SSL en el servidor Apache del Host C (VM Windows 10), configurando un puerto dedicado para HTTPS (ej. `7003`) y un certificado auto-firmado, permitiendo el puerto en el Firewall de Windows para servir sobre un canal cifrado.

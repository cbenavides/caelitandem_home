/*
 * Agua WebApp - Voice Assistant and Dictation Module (Vosk offline)
 * Handles passive listening and active dictation for user & contract search fields.
 */

// Variables globales para Vosk y Audio
let voskModel = null;
let cargandoModelo = false;
let grabadorActivo = null;
let oyentePasivo = null;
let globalAudioCtx = null;

let testMicStream = null;
let testMicAudioContext = null;
let testMicProcessor = null;

let logsHistorico = []; // Guarda las últimas 50 entradas para persistencia entre páginas

// Telemetría de Storage y Memoria al cargar
window.addEventListener('DOMContentLoaded', () => {
    if (navigator.storage && navigator.storage.estimate) {
        navigator.storage.estimate().then(estimate => {
            const usadoMB = (estimate.usage / (1024 * 1024)).toFixed(2);
            const limiteMB = (estimate.quota / (1024 * 1024)).toFixed(2);
            const libreMB = (limiteMB - usadoMB).toFixed(2);
            logErrorAlServidor("JS_INFO", `[ALMACENAMIENTO] Usado: ${usadoMB}MB / Límite: ${limiteMB}MB (Libre: ${libreMB}MB)`);
        });
    }
    
    if (window.performance && window.performance.memory) {
        const memoryLimit = (performance.memory.jsHeapSizeLimit / (1024 * 1024)).toFixed(2);
        const memoryUsed = (performance.memory.usedJSHeapSize / (1024 * 1024)).toFixed(2);
        logErrorAlServidor("JS_INFO", `[MEMORIA RAM] Heap usado: ${memoryUsed}MB / Límite: ${memoryLimit}MB`);
    }

    logErrorAlServidor("JS_INFO", "DOM Cargado. Inicialización del dictado por voz configurada bajo demanda.");
    actualizarBadgeVoz();

    // Si el asistente de voz estaba guardado como activo, inicializarlo automáticamente
    if (sessionStorage.getItem('voz_asistente_activo') === 'true') {
        logErrorAlServidor("JS_INFO", "El asistente estaba activo anteriormente. Auto-inicializando...");
        inicializarVosk();
    }
});

// Traducir palabras numéricas en español a dígitos dentro de un texto
function palabrasANumeros(texto) {
    if (!texto) return "";
    
    const unidades = {
        'cero': 0, 'uno': 1, 'un': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9,
        'diez': 10, 'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15, 'dieciseis': 16, 'dieciséis': 16,
        'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19, 'veinte': 20, 'veintiuno': 21, 'veintidos': 22, 'veintidós': 22,
        'veintitres': 23, 'veintitrés': 23, 'veinticuatro': 24, 'veinticinco': 25, 'veintiseis': 26, 'veintiséis': 26,
        'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29, 'treinta': 30, 'cuarenta': 40, 'cincuenta': 50,
        'sesenta': 60, 'setenta': 70, 'ochenta': 80, 'noventa': 90
    };
    
    const centenares = {
        'cien': 100, 'ciento': 100, 'doscientos': 200, 'trescientos': 300, 'cuatrocientos': 400, 'quinientos': 500,
        'seiscientos': 600, 'setecientos': 700, 'ochocientos': 800, 'novecientos': 900
    };

    const tokens = texto.toLowerCase().replace(/,/g, ' ').replace(/\./g, ' ').trim().split(/\s+/);
    
    let parsedTokens = [];
    let i = 0;
    
    while (i < tokens.length) {
        const token = tokens[i];
        if (!token) {
            i++;
            continue;
        }
        
        if (token === 'y') {
            const prevIsNum = i > 0 && (unidades[tokens[i-1]] !== undefined || centenares[tokens[i-1]] !== undefined || tokens[i-1] === 'mil');
            const nextIsNum = i < tokens.length - 1 && (unidades[tokens[i+1]] !== undefined || centenares[tokens[i+1]] !== undefined || tokens[i+1] === 'mil');
            if (prevIsNum && nextIsNum) {
                i++;
                continue;
            }
        }
        
        const isNumWord = unidades[token] !== undefined || centenares[token] !== undefined || token === 'mil';
        const isNativeNum = /^\d+$/.test(token);
        
        if (isNumWord || isNativeNum) {
            let numSeq = [];
            while (i < tokens.length) {
                const t = tokens[i];
                if (t === 'y') {
                    const prevIsNum = i > 0 && (unidades[tokens[i-1]] !== undefined || centenares[tokens[i-1]] !== undefined || tokens[i-1] === 'mil');
                    const nextIsNum = i < tokens.length - 1 && (unidades[tokens[i+1]] !== undefined || centenares[tokens[i+1]] !== undefined || tokens[i+1] === 'mil');
                    if (prevIsNum && nextIsNum) {
                        i++;
                        continue;
                    } else {
                        break;
                    }
                }
                
                const isNumWordInner = unidades[t] !== undefined || centenares[t] !== undefined || t === 'mil';
                const isNativeNumInner = /^\d+$/.test(t);
                
                if (isNumWordInner || isNativeNumInner) {
                    numSeq.push(t);
                    i++;
                } else {
                    break;
                }
            }
            
            parsedTokens.push(convertirSecuenciaADigito(numSeq, unidades, centenares));
        } else {
            parsedTokens.push(token);
            i++;
        }
    }
    
    return parsedTokens.join(" ");
}

function convertirSecuenciaADigito(seq, unidades, centenares) {
    let esDigitosIndividuales = true;
    for (let j = 0; j < seq.length; j++) {
        const t = seq[j];
        if (t === 'mil' || centenares[t] !== undefined || (unidades[t] !== undefined && unidades[t] > 9)) {
            esDigitosIndividuales = false;
            break;
        }
    }
    
    if (esDigitosIndividuales) {
        let res = "";
        for (let j = 0; j < seq.length; j++) {
            const t = seq[j];
            if (unidades[t] !== undefined) {
                res += unidades[t].toString();
            } else if (/^\d+$/.test(t)) {
                res += t;
            }
        }
        return res;
    }
    
    let total = 0;
    let current = 0;
    for (let j = 0; j < seq.length; j++) {
        const t = seq[j];
        if (unidades[t] !== undefined) {
            current += unidades[t];
        } else if (centenares[t] !== undefined) {
            current += centenares[t];
        } else if (t === 'mil') {
            if (current === 0) current = 1;
            total += current * 1000;
            current = 0;
        } else if (/^\d+$/.test(t)) {
            if (current > 0) {
                total += current;
                current = 0;
            }
            total += parseInt(t, 10);
        }
    }
    total += current;
    return total.toString();
}

function extraerUltimoNumero(texto) {
    const textoProcesado = palabrasANumeros(texto);
    const matches = textoProcesado.match(/\d+/g);
    if (matches && matches.length > 0) {
        return matches[matches.length - 1];
    }
    return "";
}

function normalizarFoneticaEspanol(texto) {
    if (!texto) return "";
    let temp = texto.toLowerCase();
    
    // Tabla de reemplazos comunes para el modelo pequeño (homófonos o variantes inglés/español)
    const reemplazos = {
        "\\bjoshep\\b": "josé",
        "\\bjoseph\\b": "josé",
        "\\bjosehp\\b": "josé",
        "\\bjosep\\b": "josé",
        "\\bjozep\\b": "josé",
        "\\bjozef\\b": "josé",
        "\\bjohn\\b": "juan",
        "\\bjhon\\b": "juan",
        "\\bmary\\b": "maría",
        "\\bmery\\b": "maría",
        "\\bcharles\\b": "carlos",
        "\\bthe\\b": "de",
        "\\bandres\\b": "andrés",
        "\\bpedro\\b": "pedro"
    };
    
    for (const [key, value] of Object.entries(reemplazos)) {
        const regex = new RegExp(key, "gi");
        temp = temp.replace(regex, value);
    }
    
    return temp;
}

function extraerUltimoNombre(texto) {
    if (!texto) return "";
    let temp = texto.toLowerCase().trim();
    
    // Limpiar comandos de activación, palabras de parada, borrado y redundancia
    temp = temp.replace(/\bpersona\b/g, '');
    temp = temp.replace(/\busuario\b/g, '');
    temp = temp.replace(/\b(listo|esto|punto|ya|fin|ok)\b/g, '');
    temp = temp.replace(/(borrar|borra|borre|borro|borras|limpiar|limpia|limpie|cancelar|cancel|descartar|quitar|quita)/g, '');
    temp = temp.replace(/\./g, '');
    
    // Normalización fonética
    temp = normalizarFoneticaEspanol(temp);
    
    // Búfer corrector de nombres completo
    const palabras = temp.split(/\s+/);
    let ultimoIndiceCorreccion = -1;
    for (let idx = 0; idx < palabras.length; idx++) {
        const p = palabras[idx];
        if (p === 'no' || p === 'o' || p === 'correcion' || p === 'corrección' || p === 'borra' || p === 'borrar') {
            ultimoIndiceCorreccion = idx;
        }
    }
    
    if (ultimoIndiceCorreccion !== -1 && ultimoIndiceCorreccion < palabras.length - 1) {
        temp = palabras.slice(ultimoIndiceCorreccion + 1).join(" ");
    } else if (ultimoIndiceCorreccion !== -1) {
        temp = palabras.slice(0, ultimoIndiceCorreccion).join(" ");
    }
    
    return capitalizarNombres(temp.trim());
}

function capitalizarNombres(texto) {
    if (!texto) return "";
    return texto.split(/\s+/)
        .map(word => {
            if (word.length === 0) return "";
            return word.charAt(0).toUpperCase() + word.slice(1);
        })
        .join(" ");
}

function contieneListoFinal(texto) {
    if (!texto) return false;
    const textoL = texto.toLowerCase().trim();
    const regexFin = /\b(listo|esto|punto|ya|fin|ok)\b/i;
    return regexFin.test(textoL) || textoL.endsWith(".");
}

function contieneLimpiarOTexto(texto) {
    if (!texto) return false;
    const textoL = texto.toLowerCase().trim();
    // Expresión regular ultra tolerante a subcadenas para variaciones acústicas de borrar/limpiar/cancelar
    const regexLimpiar = /(borrar|borra|borre|borro|borras|limpiar|limpia|limpie|cancelar|cancel|descartar|quitar|quita)/i;
    return regexLimpiar.test(textoL);
}

function limpiarComandosFinales(texto) {
    if (!texto) return "";
    let temp = texto.replace(/\b(listo|esto|punto|ya|fin|ok)\b/gi, '');
    temp = temp.replace(/(borrar|borra|borre|borro|borras|limpiar|limpia|limpie|cancelar|cancel|descartar|quitar|quita)/gi, '');
    return temp.replace(/\./g, '').trim();
}

// Inicialización del sistema de logging al servidor
function logErrorAlServidor(tipo, mensaje, detalles = {}) {
    agregarLogUI(tipo, mensaje);

    fetch("index2.php?action=log_client_error", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            tipo: tipo,
            mensaje: mensaje,
            detalles: detalles,
            url: window.location.href,
            linea: detalles.linea || 0
        })
    }).catch(err => {
        console.error("Error al enviar el log al servidor:", err);
    });
}

function agregarLogUI(tipo, mensaje) {
    const ahora = new Date().toLocaleTimeString();
    let prefijo = "[LOG]";
    let claseLog = "log-info";
    if (tipo.includes("ERROR")) {
        prefijo = "[ERROR]";
        claseLog = "log-error";
    } else if (tipo.includes("WARN")) {
        prefijo = "[ADVERTENCIA]";
        claseLog = "log-warning";
    } else {
        prefijo = "[INFO]";
        claseLog = "log-info";
    }

    const entradaTexto = `[${ahora}] ${prefijo} ${mensaje}`;
    logsHistorico.push({ clase: claseLog, texto: entradaTexto });
    if (logsHistorico.length > 50) {
        logsHistorico.shift();
    }

    const diagnosticLogs = document.getElementById("diagnosticLogs");
    if (!diagnosticLogs) return;

    const entrada = document.createElement("div");
    entrada.className = `log-entry ${claseLog}`;
    entrada.innerText = entradaTexto;
    diagnosticLogs.appendChild(entrada);
    
    const panel = document.getElementById("diagnosticPanel");
    if (panel) {
        panel.scrollTop = panel.scrollHeight;
    }
}

function renderizarHistoricoLogs() {
    const diagnosticLogs = document.getElementById("diagnosticLogs");
    if (!diagnosticLogs) return;

    diagnosticLogs.innerHTML = "";
    if (logsHistorico.length === 0) {
        diagnosticLogs.innerHTML = '<div class="log-entry log-info">[Asistente] Consola de diagnóstico lista.</div>';
        return;
    }

    logsHistorico.forEach(log => {
        const entrada = document.createElement("div");
        entrada.className = `log-entry ${log.clase}`;
        entrada.innerText = log.texto;
        diagnosticLogs.appendChild(entrada);
    });

    const panel = document.getElementById("diagnosticPanel");
    if (panel) {
        panel.scrollTop = panel.scrollHeight;
    }
}

function limpiarLogsUI() {
    logsHistorico = [];
    const diagnosticLogs = document.getElementById("diagnosticLogs");
    if (diagnosticLogs) {
        diagnosticLogs.innerHTML = '<div class="log-entry log-info">[Asistente] Consola limpia. Esperando comandos...</div>';
    }
}

// Registrar manejadores globales de errores JS
window.onerror = function(message, source, lineno, colno, error) {
    logErrorAlServidor("JS_RUNTIME_ERROR", message, {
        archivo: source,
        linea: lineno,
        columna: colno,
        stack: error ? error.stack : ""
    });
    return false;
};

window.onunhandledrejection = function(event) {
    logErrorAlServidor("JS_PROMISE_REJECTION", event.reason ? event.reason.message : "Rechazo de promesa sin razón", {
        stack: event.reason ? event.reason.stack : ""
    });
};

// Obtener el AudioContext único
function obtenerAudioContext(sampleRate = 16000) {
    if (!globalAudioCtx) {
        try {
            globalAudioCtx = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: sampleRate });
        } catch (e) {
            globalAudioCtx = new (window.AudioContext || window.webkitAudioContext)();
        }
        logErrorAlServidor("JS_INFO", `[AUDIO_CTX] Contexto global único creado/inicializado a ${globalAudioCtx.sampleRate} Hz.`);
    }
    return globalAudioCtx;
}

// Beeps de audio nativos con Web Audio API
async function reproducirBeep(tipo) {
    try {
        const ctx = obtenerAudioContext();
        if (ctx.state === 'suspended') {
            await ctx.resume();
        }
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);

        if (tipo === 'start') {
            osc.frequency.setValueAtTime(880, ctx.currentTime);
            gain.gain.setValueAtTime(0.1, ctx.currentTime);
            osc.start();
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);
            osc.stop(ctx.currentTime + 0.15);
        } else if (tipo === 'stop') {
            osc.frequency.setValueAtTime(440, ctx.currentTime);
            gain.gain.setValueAtTime(0.1, ctx.currentTime);
            osc.start();
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.25);
            osc.stop(ctx.currentTime + 0.25);
        }
    } catch (e) {
        console.error("Error al reproducir beep:", e);
    }
}

// Inicialización del dictado por voz (carga vosk.js dinámicamente)
async function inicializarVosk() {
    if (cargandoModelo || voskModel) return;
    sessionStorage.setItem('voz_asistente_activo', 'true');
    cargandoModelo = true;

    actualizarBadgeVoz();
    
    // Cargar biblioteca vosk.js de forma dinámica
    if (typeof Vosk === 'undefined') {
        logErrorAlServidor("JS_INFO", "Cargando biblioteca vosk.js dinámicamente...");
        try {
            await new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = 'web-assets/js/vosk.js';
                script.onload = () => {
                    logErrorAlServidor("JS_INFO", "Biblioteca vosk.js cargada con éxito.");
                    resolve();
                };
                script.onerror = () => {
                    logErrorAlServidor("JS_ERROR", "Error al cargar la biblioteca vosk.js.");
                    reject(new Error("No se pudo cargar la biblioteca vosk.js"));
                };
                document.head.appendChild(script);
            });
        } catch (e) {
            cargandoModelo = false;
            actualizarBadgeVoz();
            alert("No se pudo cargar la biblioteca de voz. Verifique la conexión o el archivo vosk.js.");
            return;
        }
    }

    logErrorAlServidor("JS_INFO", "Descargando modelo de voz en español desde el servidor...");

    try {
        let rootPath = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/'));
        if (rootPath.endsWith('/v-ospv')) {
            rootPath = rootPath.substring(0, rootPath.length - 7);
        }
        const absoluteModelUrl = window.location.origin + rootPath + '/web-assets/models/vosk-model-small-es-0.42.tar.gz';
        
        logErrorAlServidor("JS_INFO", "Cargando modelo de voz desde la URL absoluta: " + absoluteModelUrl);
        voskModel = await Vosk.createModel(absoluteModelUrl);
        
        if (voskModel && voskModel.worker) {
            voskModel.worker.addEventListener("message", (event) => {
                const msg = event.data;
                if (msg && msg.event !== "audioChunk") {
                    logErrorAlServidor("JS_DEBUG", "Worker emitió: " + JSON.stringify(msg));
                }
            });
        }
        
        logErrorAlServidor("JS_INFO", "¡Modelo de voz en español cargado y listo para transcripción offline!");
        cargandoModelo = false;
        
        // Iniciar oyente pasivo al terminar carga
        iniciarOyentePasivo();
    } catch (error) {
        cargandoModelo = false;
        actualizarBadgeVoz();
        logErrorAlServidor("JS_ERROR", "Error crítico al inicializar el modelo Vosk: " + error.message, {
            stack: error.stack
        });
        alert("No se pudo cargar el modelo de voz local. Verifica que el archivo de modelo exista en el servidor.");
    }
}

// Liberar recursos de Vosk de la memoria
function desactivarVosk() {
    sessionStorage.setItem('voz_asistente_activo', 'false');
    logErrorAlServidor("JS_INFO", "Desactivando dictado por voz y liberando memoria...");
    
    if (grabadorActivo) {
        detenerGrabacionActiva();
    }
    
    detenerOyentePasivo();
    
    if (voskModel) {
        try {
            if (voskModel.worker) {
                voskModel.worker.terminate();
                logErrorAlServidor("JS_INFO", "[RAM] Web Worker de Vosk terminado y memoria liberada.");
            }
        } catch (e) {
            console.error("Error al terminar el worker:", e);
        }
        voskModel = null;
    }

    if (globalAudioCtx && globalAudioCtx.state !== 'closed') {
        try {
            globalAudioCtx.suspend();
            logErrorAlServidor("JS_INFO", "[AUDIO_CTX] AudioContext suspendido.");
        } catch (e) {
            console.error("Error al suspender AudioContext:", e);
        }
    }
    
    actualizarBadgeVoz();
}

// Mantener la interfaz de estado en sincronía
function actualizarBadgeVoz(texto = null, clase = null) {
    const badge = document.getElementById('modelStatusBadge');
    if (!badge) return;

    if (texto && clase) {
        badge.innerText = texto;
        badge.className = 'status-badge ' + clase;
        renderizarHistoricoLogs();
        return;
    }

    if (cargandoModelo) {
        badge.innerText = 'Cargando motor de voz offline...';
        badge.className = 'status-badge status-loading';
    } else if (voskModel) {
        if (grabadorActivo) {
            badge.innerText = `🎙️ Dictando: ${grabadorActivo.tipoDictado === 'usuario' ? 'Nombre' : 'Contrato'}...`;
            badge.className = 'status-badge status-loading';
        } else if (oyentePasivo) {
            badge.innerText = '🎙️ Escuchando "usuario" o "contrato"...';
            badge.className = 'status-badge status-ready';
        } else {
            badge.innerText = 'Motor de voz offline LISTO';
            badge.className = 'status-badge status-ready';
        }
        // Agregar botón de apagado de recursos
        badge.innerHTML += ' <button type="button" onclick="desactivarVosk()" style="margin-left: 8px; background: rgba(239, 68, 68, 0.2); border: 1px solid #ef4444; color: #f87171; border-radius: 4px; padding: 2px 6px; font-size: 9px; cursor: pointer; line-height: 1;">Desactivar</button>';
    } else {
        badge.innerText = '🎙️ Dictado por voz desactivado';
        badge.className = 'status-badge status-error';
        // Agregar botón de encendido de recursos
        badge.innerHTML += ' <button type="button" onclick="inicializarVosk()" style="margin-left: 8px; background: rgba(56, 189, 248, 0.2); border: 1px solid #38bdf8; color: #38bdf8; border-radius: 4px; padding: 2px 6px; font-size: 9px; cursor: pointer; line-height: 1;">Activar</button>';
    }
    renderizarHistoricoLogs();
}

// Inicializar oyente pasivo continuo
async function iniciarOyentePasivo() {
    if (oyentePasivo || grabadorActivo || !voskModel) return;

    try {
        const mediaStream = await navigator.mediaDevices.getUserMedia({
            video: false,
            audio: {
                echoCancellation: true,
                noiseSuppression: true,
                channelCount: 1
            }
        });

        const audioContext = obtenerAudioContext();
        if (audioContext.state === 'suspended') {
            await audioContext.resume();
        }

        const actualSampleRate = audioContext.sampleRate;
        const source = audioContext.createMediaStreamSource(mediaStream);
        const recognizer = new voskModel.KaldiRecognizer(actualSampleRate);

        const recognizerNode = audioContext.createScriptProcessor(4096, 1, 1);
        recognizerNode.onaudioprocess = (event) => {
            try {
                recognizer.acceptWaveform(event.inputBuffer);
            } catch (err) {
                console.error("Error en oyente pasivo acceptWaveform:", err);
            }
        };

        source.connect(recognizerNode);
        recognizerNode.connect(audioContext.destination);

        recognizer.on("result", (message) => {
            procesarResultadoPasivo(message.result.text);
        });

        recognizer.on("partialresult", (message) => {
            procesarResultadoPasivo(message.result.partial);
        });

        oyentePasivo = {
            mediaStream: mediaStream,
            recognizerNode: recognizerNode,
            recognizer: recognizer
        };

        actualizarBadgeVoz();
        logErrorAlServidor("OYENTE_INFO", "Oyente pasivo listo. Esperando palabra clave 'usuario' o 'contrato'...");

    } catch (error) {
        logErrorAlServidor("OYENTE_ERROR", "No se pudo iniciar el oyente pasivo: " + error.message);
        actualizarBadgeVoz();
    }
}

function procesarResultadoPasivo(texto) {
    if (!texto) return;
    const textoL = texto.toLowerCase().trim();

    if (textoL.includes("contrato")) {
        logErrorAlServidor("OYENTE_INFO", "Palabra clave 'contrato' detectada. Iniciando dictado de contrato.");
        reproducirBeep('start');
        detenerOyentePasivo();
        
        // Cargar submenu contrato
        menu('contrato');
        
        setTimeout(() => {
            const btn = document.querySelector("#buscacto .btn-mic");
            if (btn) {
                activarDictado('cadena', 'contrato', btn);
            } else {
                logErrorAlServidor("OYENTE_ERROR", "No se encontró el botón de mic de contrato tras cargar menú.");
            }
        }, 100);
    } else if (textoL.includes("usuario") || textoL.includes("persona")) {
        logErrorAlServidor("OYENTE_INFO", "Palabra clave '" + (textoL.includes("usuario") ? "usuario" : "persona") + "' detectada. Iniciando dictado de usuario.");
        reproducirBeep('start');
        detenerOyentePasivo();
        
        // Cargar submenu usuario
        menu('usuario');
        
        setTimeout(() => {
            const btn = document.querySelector("#buscausr .btn-mic");
            if (btn) {
                activarDictado('cadena', 'usuario', btn);
            } else {
                logErrorAlServidor("OYENTE_ERROR", "No se encontró el botón de mic de usuario tras cargar menú.");
            }
        }, 100);
    }
}

function detenerOyentePasivo() {
    if (!oyentePasivo) return;
    try {
        logErrorAlServidor("OYENTE_INFO", "Deteniendo oyente pasivo...");
        oyentePasivo.mediaStream.getTracks().forEach(track => track.stop());
        oyentePasivo.recognizerNode.disconnect();
        if (oyentePasivo.recognizer) {
            oyentePasivo.recognizer.remove();
        }
    } catch (e) {
        console.error("Error al detener oyente pasivo:", e);
    } finally {
        oyentePasivo = null;
    }
}

async function activarDictado(idInput, tipoDictado, botonAsociado) {
    if (!voskModel) {
        logErrorAlServidor("JS_INFO", "Dictado por voz solicitado. Inicializando motor de voz...");
        await inicializarVosk();
        if (!voskModel) return;
    }

    let inputDestino = null;
    if (tipoDictado === 'usuario') {
        inputDestino = document.querySelector('#buscausr #cadena');
    } else if (tipoDictado === 'contrato') {
        inputDestino = document.querySelector('#buscacto #cadena');
    } else {
        inputDestino = document.getElementById(idInput);
    }

    if (!inputDestino) {
        logErrorAlServidor("JS_ERROR", `Input destino no encontrado para: ${idInput} (${tipoDictado})`);
        return;
    }

    if (grabadorActivo) {
        const mismo = (grabadorActivo.tipoDictado === tipoDictado);
        detenerGrabacionActiva();
        if (mismo) return;
    }

    detenerOyentePasivo();

    try {
        logErrorAlServidor("SPEECH_INFO", `Activando captura de audio para: '${idInput}' (${tipoDictado})`);
        actualizarBadgeVoz(`🎙️ Dictando: ${tipoDictado === 'usuario' ? 'Nombre' : 'Contrato'}...`, 'status-loading');

        const mediaStream = await navigator.mediaDevices.getUserMedia({
            video: false,
            audio: {
                echoCancellation: true,
                noiseSuppression: true,
                channelCount: 1
            },
        });

        const audioContext = obtenerAudioContext();
        if (audioContext.state === 'suspended') {
            await audioContext.resume();
        }

        const actualSampleRate = audioContext.sampleRate;
        const source = audioContext.createMediaStreamSource(mediaStream);
        const recognizer = new voskModel.KaldiRecognizer(actualSampleRate);
        
        const valorInicial = inputDestino.value;

        botonAsociado.classList.add('grabando');
        botonAsociado.innerText = "🛑";
        inputDestino.placeholder = "Escuchando... Di 'listo' al terminar";
        inputDestino.focus();

        recognizer.on("result", (message) => {
            let texto = message.result.text;
            if (texto && texto.trim() !== "") {
                logErrorAlServidor("SPEECH_INFO", `Resultado final: "${texto}"`);
                
                if (grabadorActivo) {
                    grabadorActivo.bufferTexto += " " + texto;
                }
                const bufferCompleto = grabadorActivo ? grabadorActivo.bufferTexto : texto;

                // 1. Detectar comando de limpieza/borrado
                if (contieneLimpiarOTexto(bufferCompleto) || contieneLimpiarOTexto(texto)) {
                    logErrorAlServidor("SPEECH_INFO", "Comando de borrado/limpieza detectado. Reseteando input.");
                    inputDestino.value = "";
                    if (grabadorActivo) {
                        grabadorActivo.bufferTexto = "";
                    }
                    detenerGrabacionActiva();
                    return;
                }

                if (tipoDictado === 'contrato') {
                    const ultimoNumero = extraerUltimoNumero(bufferCompleto);
                    if (ultimoNumero) {
                        inputDestino.value = ultimoNumero;
                    }
                    if (contieneListoFinal(bufferCompleto)) {
                        let limpio = inputDestino.value;
                        limpio = limpiarComandosFinales(limpio);
                        inputDestino.value = limpio;
                        detenerGrabacionActiva();
                        $('#buscacto').submit();
                    }
                } else if (tipoDictado === 'usuario') {
                    const ultimoNombre = extraerUltimoNombre(bufferCompleto);
                    if (ultimoNombre) {
                        inputDestino.value = ultimoNombre;
                    }
                    if (contieneListoFinal(bufferCompleto)) {
                        let limpio = inputDestino.value;
                        limpio = limpiarComandosFinales(limpio);
                        inputDestino.value = limpio;
                        detenerGrabacionActiva();
                        $('#buscausr').submit();
                    }
                } else {
                    const separador = inputDestino.value.trim() === "" ? "" : " ";
                    inputDestino.value = (inputDestino.value + separador + texto).trim();
                    if (contieneListoFinal(texto)) {
                        let limpio = inputDestino.value;
                        limpio = limpiarComandosFinales(limpio);
                        inputDestino.value = limpio;
                        detenerGrabacionActiva();
                    }
                }
            }
        });

        recognizer.on("partialresult", (message) => {
            const partial = message.result.partial;
            if (partial && partial.trim() !== "") {
                logErrorAlServidor("SPEECH_INFO", `Resultado parcial: "${partial}"`);
                const bufferCompleto = (grabadorActivo ? grabadorActivo.bufferTexto : "") + " " + partial;

                // 1. Detectar comando de limpieza/borrado
                if (contieneLimpiarOTexto(bufferCompleto) || contieneLimpiarOTexto(partial)) {
                    logErrorAlServidor("SPEECH_INFO", "Comando de borrado detectado en parcial. Reseteando.");
                    inputDestino.value = "";
                    if (grabadorActivo) {
                        grabadorActivo.bufferTexto = "";
                    }
                    detenerGrabacionActiva();
                    return;
                }

                if (tipoDictado === 'contrato') {
                    const ultimoNumero = extraerUltimoNumero(bufferCompleto);
                    if (ultimoNumero) {
                        inputDestino.value = ultimoNumero;
                    }
                    if (contieneListoFinal(bufferCompleto)) {
                        if (ultimoNumero) {
                            inputDestino.value = ultimoNumero;
                        }
                        let limpio = inputDestino.value;
                        limpio = limpiarComandosFinales(limpio);
                        inputDestino.value = limpio;
                        detenerGrabacionActiva();
                        $('#buscacto').submit();
                    }
                } else if (tipoDictado === 'usuario') {
                    const ultimoNombre = extraerUltimoNombre(bufferCompleto);
                    if (ultimoNombre) {
                        inputDestino.value = ultimoNombre;
                    }
                    if (contieneListoFinal(bufferCompleto)) {
                        if (ultimoNombre) {
                            inputDestino.value = ultimoNombre;
                        }
                        let limpio = inputDestino.value;
                        limpio = limpiarComandosFinales(limpio);
                        inputDestino.value = limpio;
                        detenerGrabacionActiva();
                        $('#buscausr').submit();
                    }
                } else {
                    const separador = valorInicial.trim() === "" ? "" : " ";
                    inputDestino.value = (valorInicial + separador + partial).trim();
                    if (contieneListoFinal(partial)) {
                        let limpio = (valorInicial + separador + partial).trim();
                        limpio = limpiarComandosFinales(limpio);
                        inputDestino.value = limpio;
                        detenerGrabacionActiva();
                    }
                }
            }
        });

        let totalChunks = 0;
        const recognizerNode = audioContext.createScriptProcessor(4096, 1, 1);
        recognizerNode.onaudioprocess = (event) => {
            try {
                totalChunks++;
                const channelData = event.inputBuffer.getChannelData(0);
                let sum = 0;
                for (let i = 0; i < channelData.length; i++) {
                    sum += channelData[i] * channelData[i];
                }
                const rms = Math.sqrt(sum / channelData.length);
                
                if (totalChunks === 1) {
                    logErrorAlServidor("SPEECH_INFO", "Captura de micrófono activa.");
                }
                if (totalChunks % 4 === 0) {
                    logErrorAlServidor("SPEECH_INFO", `Volumen mic (RMS): ${rms.toFixed(5)}`);
                }
                recognizer.acceptWaveform(event.inputBuffer);
            } catch (err) {
                console.error("Error al transferir audio:", err);
            }
        };

        source.connect(recognizerNode);
        recognizerNode.connect(audioContext.destination);

        grabadorActivo = {
            idInput: idInput,
            tipoDictado: tipoDictado,
            boton: botonAsociado,
            mediaStream: mediaStream,
            recognizerNode: recognizerNode,
            recognizer: recognizer,
            inputDestino: inputDestino,
            placeholderOriginal: tipoDictado === 'usuario' ? "Buscar por Nombre..." : "Contrato...",
            bufferTexto: "",
            timeoutTimer: null
        };

        grabadorActivo.timeoutTimer = setTimeout(() => {
            logErrorAlServidor("SPEECH_WARN", `Timeout de 5 minutos alcanzado.`);
            detenerGrabacionActiva();
        }, 300000);

    } catch (err) {
        logErrorAlServidor("SPEECH_ERROR", "Error al iniciar micrófono: " + err.message);
        alert("No se pudo acceder al micrófono. Verifique permisos.");
        inputDestino.placeholder = "Micrófono bloqueado/denegado.";
        iniciarOyentePasivo();
    }
}

function detenerGrabacionActiva() {
    if (!grabadorActivo) return;

    try {
        logErrorAlServidor("SPEECH_INFO", `Grabación detenida para '${grabadorActivo.idInput}'`);
        
        grabadorActivo.mediaStream.getTracks().forEach(track => track.stop());
        grabadorActivo.recognizerNode.disconnect();
        
        if (grabadorActivo.recognizer) {
            grabadorActivo.recognizer.remove();
        }

        if (grabadorActivo.boton && document.body.contains(grabadorActivo.boton)) {
            grabadorActivo.boton.classList.remove('grabando');
            grabadorActivo.boton.innerText = "🎤";
        }
        if (grabadorActivo.inputDestino && document.body.contains(grabadorActivo.inputDestino)) {
            grabadorActivo.inputDestino.placeholder = grabadorActivo.placeholderOriginal;
        }

        if (grabadorActivo.timeoutTimer) {
            clearTimeout(grabadorActivo.timeoutTimer);
        }

    } catch (e) {
        console.error("Error al detener grabación:", e);
    } finally {
        grabadorActivo = null;
        reproducirBeep('stop');
        iniciarOyentePasivo();
    }
}

// Prueba Rápida de Micrófono
async function toggleTestMicrofono() {
    const btn = document.getElementById("btnTestMicrofono");
    const barra = document.getElementById("testMicBarra");
    const valorText = document.getElementById("testMicValor");

    if (testMicStream) {
        detenerTestMicrofono();
        return;
    }

    try {
        logErrorAlServidor("SPEECH_INFO", "[TEST] Iniciando prueba rápida...");
        btn.innerText = "Detener";
        btn.style.background = "#ef4444";
        btn.style.color = "#ffffff";

        testMicStream = await navigator.mediaDevices.getUserMedia({
            video: false,
            audio: {
                echoCancellation: true,
                noiseSuppression: true
            }
        });

        testMicAudioContext = obtenerAudioContext();
        const source = testMicAudioContext.createMediaStreamSource(testMicStream);
        
        if (testMicAudioContext.state === 'suspended') {
            await testMicAudioContext.resume();
        }

        testMicProcessor = testMicAudioContext.createScriptProcessor(2048, 1, 1);
        
        testMicProcessor.onaudioprocess = (event) => {
            const channelData = event.inputBuffer.getChannelData(0);
            let sum = 0;
            for (let i = 0; i < channelData.length; i++) {
                sum += channelData[i] * channelData[i];
            }
            const rms = Math.sqrt(sum / channelData.length);
            let pct = Math.min(100, Math.round((rms / 0.15) * 100));
            
            if (barra) barra.style.width = pct + "%";
            if (valorText) valorText.innerText = (rms * 100).toFixed(1) + "%";
        };

        source.connect(testMicProcessor);
        testMicProcessor.connect(testMicAudioContext.destination);

        logErrorAlServidor("SPEECH_INFO", "[TEST] Prueba activa.");
    } catch (err) {
        logErrorAlServidor("SPEECH_ERROR", "[TEST] Error en prueba: " + err.message);
        alert("No se pudo iniciar la prueba: " + err.message);
        detenerTestMicrofono();
    }
}

function detenerTestMicrofono() {
    const btn = document.getElementById("btnTestMicrofono");
    const barra = document.getElementById("testMicBarra");
    const valorText = document.getElementById("testMicValor");

    if (btn) {
        btn.innerText = "Probar";
        btn.style.background = "#10b981";
        btn.style.color = "#020617";
    }
    if (barra) barra.style.width = "0%";
    if (valorText) valorText.innerText = "0.0%";

    if (testMicStream) {
        testMicStream.getTracks().forEach(track => track.stop());
        testMicStream = null;
    }
    if (testMicProcessor) {
        testMicProcessor.disconnect();
        testMicProcessor = null;
    }
    logErrorAlServidor("SPEECH_INFO", "[TEST] Prueba finalizada.");
}

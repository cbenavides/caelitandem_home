<?php
// Establecer el huso horario para registros locales
date_default_timezone_set('America/Mexico_City');

// Si se recibe una petición de log desde el cliente (AJAX/Fetch)
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_GET['action']) && $_GET['action'] == 'log_client_error') {
    header('Content-Type: application/json; charset=utf-8');
    
    // Obtener el JSON enviado
    $raw_input = file_get_contents('php://input');
    $data = json_decode($raw_input, true);
    
    $tipo = isset($data['tipo']) ? trim($data['tipo']) : 'ERROR_DESCONOCIDO';
    $mensaje_err = isset($data['mensaje']) ? trim($data['mensaje']) : 'Sin mensaje';
    $detalles = isset($data['detalles']) ? json_encode($data['detalles'], JSON_UNESCAPED_UNICODE) : '{}';
    $url = isset($data['url']) ? trim($data['url']) : '';
    $linea = isset($data['linea']) ? intval($data['linea']) : 0;
    
    // Formatear el mensaje de log para error_log
    $log_message = "[VozWeb POC Client Error] Tipo: $tipo | Mensaje: $mensaje_err | Línea: $linea | URL: $url | Detalles: $detalles";
    
    // Escribir en el log de errores de PHP
    error_log($log_message);
    
    echo json_encode(["status" => "logged"]);
    exit;
}

// Procesamiento de los datos cuando se envía el formulario
$mensaje = "";
$error_post = "";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $nombre = isset($_POST['nombre_completo']) ? trim($_POST['nombre_completo']) : '';
    $contrato = isset($_POST['numero_contrato']) ? trim($_POST['numero_contrato']) : '';

    // Loguear intento de envío
    error_log("[VozWeb POC Form Submit] Intento de registro: Nombre = '$nombre', Contrato = '$contrato'");

    // Validaciones básicas de negocio (POC)
    if (empty($nombre) || empty($contrato)) {
        $error_post = "Todos los campos son requeridos.";
        error_log("[VozWeb POC Form Error] Campos vacíos en envío de formulario.");
    } else {
        // En un contrato real, buscaríamos en la BD. Aquí sólo simulamos y logueamos el éxito.
        $mensaje = "¡Datos recibidos con éxito en PHP!<br>Nombre: <b>" . htmlspecialchars($nombre) . "</b><br>Contrato: <b>" . htmlspecialchars($contrato) . "</b>";
        error_log("[VozWeb POC Form Success] Registro exitoso procesado para Contrato #$contrato ($nombre).");
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Formulario con Dictado por Voz Offline (Vosk POC)</title>
    <!-- Cargar biblioteca de Vosk Browser localmente o buscando en el directorio padre -->
    <script src="<?php echo file_exists('web-assets/js/vosk.js') ? 'web-assets/js/vosk.js' : '../web-assets/js/vosk.js'; ?>"></script>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); 
            color: #f1f5f9;
            display: flex; 
            justify-content: center; 
            align-items: center; 
            min-height: 100vh; 
            margin: 0; 
            padding: 20px;
            box-sizing: border-box;
        }
        .form-container { 
            background: rgba(30, 41, 59, 0.7); 
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            padding: 30px; 
            border-radius: 12px; 
            box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37); 
            width: 100%; 
            max-width: 480px; 
            position: relative;
        }
        .header-wrapper {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin-bottom: 20px;
        }
        h2 { 
            text-align: center; 
            color: #38bdf8; 
            margin-top: 0;
            margin-bottom: 10px; 
            font-size: 24px;
            font-weight: 600;
        }
        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            text-align: center;
            transition: all 0.3s ease;
        }
        .status-loading {
            background-color: rgba(234, 179, 8, 0.15);
            color: #fbbf24;
            border: 1px solid rgba(234, 179, 8, 0.3);
            animation: pulse-badge 1.5s infinite;
        }
        .status-ready {
            background-color: rgba(16, 185, 129, 0.15);
            color: #34d399;
            border: 1px solid rgba(16, 185, 129, 0.3);
        }
        .status-error {
            background-color: rgba(239, 68, 68, 0.15);
            color: #f87171;
            border: 1px solid rgba(239, 68, 68, 0.3);
        }
        .input-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 8px; color: #94a3b8; font-weight: 500; font-size: 14px; }
        .campo-voz { display: flex; gap: 10px; }
        input[type="text"] { 
            flex: 1; 
            padding: 12px; 
            font-size: 16px; 
            border: 1px solid rgba(255, 255, 255, 0.15); 
            border-radius: 6px; 
            background: rgba(15, 23, 42, 0.6);
            color: #f1f5f9;
            transition: all 0.3s ease;
        }
        input[type="text"]:focus {
            outline: none;
            border-color: #38bdf8;
            box-shadow: 0 0 0 2px rgba(56, 189, 248, 0.2);
        }
        .btn-mic { 
            background-color: #38bdf8; 
            color: #0f172a; 
            border: none; 
            padding: 10px 18px; 
            border-radius: 6px; 
            cursor: pointer; 
            font-size: 18px; 
            transition: all 0.3s ease; 
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .btn-mic:hover { background-color: #0ea5e9; }
        .btn-mic.grabando { 
            background-color: #ef4444; 
            color: white;
            animation: pulso-mic 1.5s infinite; 
        }
        .btn-enviar { 
            width: 100%; 
            background-color: #10b981; 
            color: white; 
            border: none; 
            padding: 14px; 
            font-size: 16px; 
            border-radius: 6px; 
            cursor: pointer; 
            font-weight: 600; 
            margin-top: 15px; 
            transition: all 0.3s ease;
        }
        .btn-enviar:hover { background-color: #059669; }
        .alerta { 
            background-color: rgba(16, 185, 129, 0.15); 
            color: #34d399; 
            padding: 15px; 
            border-radius: 6px; 
            margin-bottom: 20px; 
            border: 1px solid rgba(16, 185, 129, 0.3); 
            font-size: 14px;
            line-height: 1.5;
        }
        .alerta-error {
            background-color: rgba(239, 68, 68, 0.15); 
            color: #f87171; 
            padding: 15px; 
            border-radius: 6px; 
            margin-bottom: 20px; 
            border: 1px solid rgba(239, 68, 68, 0.3); 
            font-size: 14px;
        }
        
        /* Diagnóstico */
        .diagnostic-panel { 
            margin-top: 25px; 
            background: #0f172a; 
            color: #cbd5e1; 
            border-radius: 6px; 
            padding: 12px; 
            font-family: 'Courier New', Courier, monospace; 
            font-size: 11px; 
            max-height: 180px; 
            overflow-y: auto; 
            border: 1px solid rgba(255, 255, 255, 0.1); 
        }
        .diagnostic-header { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            border-bottom: 1px solid rgba(255, 255, 255, 0.1); 
            padding-bottom: 6px; 
            margin-bottom: 8px; 
            font-weight: bold; 
            color: #38bdf8; 
        }
        .btn-clear-logs { 
            background: none; 
            border: none; 
            color: #ef4444; 
            cursor: pointer; 
            font-size: 11px; 
            padding: 0; 
        }
        .btn-clear-logs:hover { text-decoration: underline; }
        .log-entry { margin-bottom: 6px; line-height: 1.4; word-break: break-all; }
        .log-info { color: #34d399; }
        .log-warning { color: #fbbf24; }
        .log-error { color: #f87171; }

        @keyframes pulso-mic { 
            0% { transform: scale(1); opacity: 1; } 
            50% { transform: scale(0.95); opacity: 0.8; } 
            100% { transform: scale(1); opacity: 1; } 
        }

        @keyframes pulse-badge {
            0% { opacity: 0.6; }
            50% { opacity: 1; }
            100% { opacity: 0.6; }
        }
    </style>
</head>
<body>

<div class="form-container">
    <div class="header-wrapper">
        <h2>Dictado por Voz Offline</h2>
        <div id="modelStatusBadge" class="status-badge status-error">🎙️ Dictado por voz desactivado</div>
    </div>

    <?php if (!empty($mensaje)): ?>
        <div class="alerta"><?php echo $mensaje; ?></div>
    <?php endif; ?>

    <?php if (!empty($error_post)): ?>
        <div class="alerta-error"><?php echo htmlspecialchars($error_post); ?></div>
    <?php endif; ?>

    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="POST">
        
        <!-- Campo Nombre Completo -->
        <div class="input-group">
            <label for="nombre_completo">Nombre Completo:</label>
            <div class="campo-voz">
                <input type="text" id="nombre_completo" name="nombre_completo" placeholder="Dicta o escribe el nombre" required>
                <button type="button" class="btn-mic" onclick="activarDictado('nombre_completo', this)" title="Iniciar Dictado">🎤</button>
            </div>
        </div>

        <!-- Campo Número de Contrato -->
        <div class="input-group">
            <label for="numero_contrato">Número de Contrato:</label>
            <div class="campo-voz">
                <input type="text" id="numero_contrato" name="numero_contrato" placeholder="Dicta o escribe el contrato" required>
                <button type="button" class="btn-mic" onclick="activarDictado('numero_contrato', this)" title="Iniciar Dictado">🎤</button>
            </div>
        </div>

        <button type="submit" class="btn-enviar">Guardar Datos</button>
    </form>

    <!-- Panel de Prueba de Micrófono Rápida (Sin Modelos) -->
    <div style="background: rgba(255, 255, 255, 0.05); border: 1px dashed rgba(255, 255, 255, 0.15); border-radius: 8px; padding: 12px; margin-top: 15px; display: flex; flex-direction: column; gap: 8px;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <span style="font-size: 13px; font-weight: 500; color: #a7f3d0;">🧪 Prueba Rápida de Micrófono (Sin cargar modelo)</span>
            <button type="button" id="btnTestMicrofono" onclick="toggleTestMicrofono()" style="background: #10b981; color: #020617; border: none; border-radius: 4px; padding: 4px 8px; font-size: 11px; font-weight: 600; cursor: pointer; transition: background 0.2s;">Probar Micro</button>
        </div>
        <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 11px; color: #94a3b8; width: 70px;">Volumen:</span>
            <div style="flex-grow: 1; height: 10px; background: rgba(255, 255, 255, 0.1); border-radius: 5px; overflow: hidden; position: relative;">
                <div id="testMicBarra" style="width: 0%; height: 100%; background: linear-gradient(90deg, #10b981, #f59e0b, #ef4444); transition: width 0.1s ease;"></div>
            </div>
            <span id="testMicValor" style="font-size: 11px; font-family: monospace; color: #34d399; width: 50px; text-align: right;">0.0%</span>
        </div>
    </div>

    <!-- Consola de Diagnóstico (POC Logs) -->
    <div class="diagnostic-panel" id="diagnosticPanel">
        <div class="diagnostic-header">
            <span>Diagnóstico en Tiempo Real</span>
            <button type="button" class="btn-clear-logs" onclick="limpiarLogsUI()">Limpiar</button>
        </div>
        <div class="diagnostic-body" id="diagnosticLogs">
            <div class="log-entry log-info">[POC] Consola de diagnóstico lista. Haga clic en 'Activar' o en el icono de micrófono para iniciar.</div>
        </div>
    </div>
</div>

<script>
    // Telemetría de Storage y Memoria
    window.onload = function() {
        if (navigator.storage && navigator.storage.estimate) {
            navigator.storage.estimate().then(estimate => {
                const usadoMB = (estimate.usage / (1024 * 1024)).toFixed(2);
                const limiteMB = (estimate.quota / (1024 * 1024)).toFixed(2);
                const libreMB = (limiteMB - usadoMB).toFixed(2);

                console.log("=== TEST DE ALMACENAMIENTO LOCAL ===");
                console.log(`Espacio total permitido: ${limiteMB} MB`);
                console.log(`Espacio usado: ${usadoMB} MB`);
                console.log(`Espacio libre: ${libreMB} MB`);

                logErrorAlServidor("JS_INFO", `[ALMACENAMIENTO] Usado: ${usadoMB}MB / Límite: ${limiteMB}MB (Libre: ${libreMB}MB)`);
            });
        }
        
        if (performance && performance.memory) {
            const memoryLimit = (performance.memory.jsHeapSizeLimit / (1024 * 1024)).toFixed(2);
            const memoryUsed = (performance.memory.usedJSHeapSize / (1024 * 1024)).toFixed(2);
            logErrorAlServidor("JS_INFO", `[MEMORIA RAM] Heap usado: ${memoryUsed}MB / Límite: ${memoryLimit}MB`);
        }
    };

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
        
        // Limpiar comandos de activación, palabra de parada, borrado y redundancia
        temp = temp.replace(/\bpersona\b/g, '');
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

        fetch("vozweb.php?action=log_client_error", {
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
        const diagnosticLogs = document.getElementById("diagnosticLogs");
        if (!diagnosticLogs) return;

        const entrada = document.createElement("div");
        entrada.className = "log-entry";
        
        let prefijo = "[LOG]";
        if (tipo.includes("ERROR")) {
            entrada.classList.add("log-error");
            prefijo = "[ERROR]";
        } else if (tipo.includes("WARN")) {
            entrada.classList.add("log-warning");
            prefijo = "[ADVERTENCIA]";
        } else {
            entrada.classList.add("log-info");
            prefijo = "[INFO]";
        }

        const ahora = new Date().toLocaleTimeString();
        entrada.innerText = `[${ahora}] ${prefijo} ${mensaje}`;
        
        diagnosticLogs.appendChild(entrada);
        
        const panel = document.getElementById("diagnosticPanel");
        if (panel) {
            panel.scrollTop = panel.scrollHeight;
        }
    }

    function limpiarLogsUI() {
        const diagnosticLogs = document.getElementById("diagnosticLogs");
        if (diagnosticLogs) {
            diagnosticLogs.innerHTML = '<div class="log-entry log-info">[POC] Consola limpia. Esperando eventos...</div>';
        }
    }

    // Registrar manejadores globales de errores JS inmediatamente
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

    // Variables globales para Vosk
    let voskModel = null;
    let cargandoModelo = false;
    let grabadorActivo = null;
    let oyentePasivo = null;

    // Contexto de audio global compartido (Optimización de Ciclo de Vida)
    let globalAudioCtx = null;

    // Función para obtener el AudioContext único
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

    // Inicialización del dictado por voz configurada bajo demanda en page load
    window.addEventListener('DOMContentLoaded', async () => {
        logErrorAlServidor("JS_INFO", "DOM Cargado. Inicialización del dictado por voz configurada bajo demanda.");
        actualizarBadgeVoz();
    });

    async function inicializarVosk() {
        if (cargandoModelo || voskModel) return;
        cargandoModelo = true;

        actualizarBadgeVoz();
        logErrorAlServidor("JS_INFO", "Descargando modelo de voz en español desde el servidor...");

        try {
            // Determinar si estamos en el subdirectorio v-ospv para resolver recursos relativos
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

    // Liberar por completo el modelo Vosk de la memoria (Optimización de RAM)
    function desactivarVosk() {
        logErrorAlServidor("JS_INFO", "Desactivando dictado por voz y liberando memoria...");
        
        // 1. Detener dictado activo si existe
        if (grabadorActivo) {
            detenerGrabacionActiva();
        }
        
        // 2. Detener oyente pasivo si existe
        detenerOyentePasivo();
        
        // 3. Destruir el Web Worker y limpiar el objeto del modelo
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

        // 4. Suspender el AudioContext para liberar la tarjeta de sonido
        if (globalAudioCtx && globalAudioCtx.state !== 'closed') {
            try {
                globalAudioCtx.suspend();
                logErrorAlServidor("JS_INFO", "[AUDIO_CTX] AudioContext suspendido para liberar hardware de audio.");
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
            return;
        }

        if (cargandoModelo) {
            badge.innerText = 'Cargando motor de voz offline...';
            badge.className = 'status-badge status-loading';
        } else if (voskModel) {
            if (grabadorActivo) {
                badge.innerText = `🎙️ Dictando: ${grabadorActivo.idInput === 'nombre_completo' ? 'Nombre' : 'Contrato'}...`;
                badge.className = 'status-badge status-loading';
            } else if (oyentePasivo) {
                badge.innerText = '🎙️ Escuchando "contrato" o "persona"...';
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
            logErrorAlServidor("OYENTE_INFO", "Oyente pasivo en segundo plano iniciado. Esperando palabra clave 'contrato' o 'persona'...");

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
            const btn = document.querySelector("#numero_contrato").parentNode.querySelector(".btn-mic");
            activarDictado('numero_contrato', btn);
        } else if (textoL.includes("persona")) {
            logErrorAlServidor("OYENTE_INFO", "Palabra clave 'persona' detectada. Iniciando dictado de nombre completo.");
            reproducirBeep('start');
            detenerOyentePasivo();
            const btn = document.querySelector("#nombre_completo").parentNode.querySelector(".btn-mic");
            activarDictado('nombre_completo', btn);
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

    async function activarDictado(idInput, botonAsociado) {
        // Inicialización perezosa bajo demanda (Lazy Loading)
        if (!voskModel) {
            logErrorAlServidor("JS_INFO", "Dictado por voz solicitado. Inicializando motor de voz...");
            await inicializarVosk();
            if (!voskModel) return;
        }

        const inputDestino = document.getElementById(idInput);

        // Si ya hay un dictado activo
        if (grabadorActivo) {
            if (grabadorActivo.idInput === idInput) {
                detenerGrabacionActiva();
                return;
            } else {
                detenerGrabacionActiva();
            }
        }

        // Apagar el oyente pasivo mientras se graba de forma activa
        detenerOyentePasivo();

        try {
            logErrorAlServidor("SPEECH_INFO", `Activando captura de audio offline para el campo: '${idInput}'`);
            
            actualizarBadgeVoz(`🎙️ Dictando: ${idInput === 'nombre_completo' ? 'Nombre' : 'Contrato'}...`, 'status-loading');

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
                logErrorAlServidor("SPEECH_INFO", "AudioContext en estado suspendido. Reanudando...");
                await audioContext.resume();
            }

            const actualSampleRate = audioContext.sampleRate;
            logErrorAlServidor("SPEECH_INFO", `AudioContext activado con éxito a ${actualSampleRate} Hz.`);

            const source = audioContext.createMediaStreamSource(mediaStream);
            const recognizer = new voskModel.KaldiRecognizer(actualSampleRate);
            
            const valorInicial = inputDestino.value;

            botonAsociado.classList.add('grabando');
            botonAsociado.innerText = "🛑";
            inputDestino.placeholder = "Escuchando... Habla ahora (di 'listo' al terminar)";

            recognizer.on("result", (message) => {
                let texto = message.result.text;
                if (texto && texto.trim() !== "") {
                    logErrorAlServidor("SPEECH_INFO", `Resultado final original: "${texto}"`);
                    
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

                    if (idInput === 'numero_contrato') {
                        const ultimoNumero = extraerUltimoNumero(bufferCompleto);
                        if (ultimoNumero) {
                            inputDestino.value = ultimoNumero;
                            logErrorAlServidor("SPEECH_INFO", `Resultado final acumulado procesado: "${ultimoNumero}"`);
                        }
                        if (contieneListoFinal(bufferCompleto)) {
                            logErrorAlServidor("SPEECH_INFO", "Comando de finalización detectado en resultado final. Deteniendo grabación.");
                            detenerGrabacionActiva();
                        }
                    } else if (idInput === 'nombre_completo') {
                        const ultimoNombre = extraerUltimoNombre(bufferCompleto);
                        if (ultimoNombre) {
                            inputDestino.value = ultimoNombre;
                            logErrorAlServidor("SPEECH_INFO", `Nombre final acumulado procesado: "${ultimoNombre}"`);
                        }
                        if (contieneListoFinal(bufferCompleto)) {
                            logErrorAlServidor("SPEECH_INFO", "Comando de finalización detectado en resultado final para nombre. Deteniendo grabación.");
                            detenerGrabacionActiva();
                        }
                    } else {
                        const separador = inputDestino.value.trim() === "" ? "" : " ";
                        inputDestino.value = (inputDestino.value + separador + texto).trim();
                        if (contieneListoFinal(texto)) {
                            inputDestino.value = limpiarComandosFinales(inputDestino.value);
                            detenerGrabacionActiva();
                        }
                    }
                }
            });

            recognizer.on("partialresult", (message) => {
                const partial = message.result.partial;
                if (partial && partial.trim() !== "") {
                    logErrorAlServidor("SPEECH_INFO", `Resultado parcial original: "${partial}"`);
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

                    if (idInput === 'numero_contrato') {
                        const ultimoNumero = extraerUltimoNumero(bufferCompleto);
                        if (ultimoNumero) {
                            inputDestino.value = ultimoNumero;
                        }
                        if (contieneListoFinal(bufferCompleto)) {
                            logErrorAlServidor("SPEECH_INFO", "Comando de finalización detectado en resultado parcial. Deteniendo grabación.");
                            if (ultimoNumero) {
                                inputDestino.value = ultimoNumero;
                            }
                            detenerGrabacionActiva();
                        }
                    } else if (idInput === 'nombre_completo') {
                        const ultimoNombre = extraerUltimoNombre(bufferCompleto);
                        if (ultimoNombre) {
                            inputDestino.value = ultimoNombre;
                        }
                        if (contieneListoFinal(bufferCompleto)) {
                            logErrorAlServidor("SPEECH_INFO", "Comando de finalización detectado en resultado parcial para nombre. Deteniendo grabación.");
                            if (ultimoNombre) {
                                inputDestino.value = ultimoNombre;
                            }
                            detenerGrabacionActiva();
                        }
                    } else {
                        let textoMostrar = partial;
                        const separador = valorInicial.trim() === "" ? "" : " ";
                        inputDestino.value = (valorInicial + separador + textoMostrar).trim();
                        if (contieneListoFinal(partial)) {
                            let limpio = (valorInicial + separador + textoMostrar).trim();
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
                        logErrorAlServidor("SPEECH_INFO", "Captura de micrófono activa: enviando flujo de audio a Vosk...");
                    }
                    if (totalChunks % 4 === 0) {
                        logErrorAlServidor("SPEECH_INFO", `Nivel de volumen capturado (RMS): ${rms.toFixed(5)}`);
                    }
                    recognizer.acceptWaveform(event.inputBuffer);
                } catch (err) {
                    console.error("Error al transferir audio a acceptWaveform:", err);
                }
            };

            source.connect(recognizerNode);
            recognizerNode.connect(audioContext.destination);

            grabadorActivo = {
                idInput: idInput,
                boton: botonAsociado,
                mediaStream: mediaStream,
                recognizerNode: recognizerNode,
                recognizer: recognizer,
                inputDestino: inputDestino,
                placeholderOriginal: idInput === 'nombre_completo' ? "Dicta o escribe el nombre" : "Dicta o escribe el contrato",
                bufferTexto: "",
                timeoutTimer: null
            };

            // Temporizador de inactividad de seguridad de 5 minutos
            grabadorActivo.timeoutTimer = setTimeout(() => {
                logErrorAlServidor("SPEECH_WARN", `El dictado del campo '${idInput}' alcanzó el límite de inactividad de 5 minutos. Deteniendo de forma segura.`);
                detenerGrabacionActiva();
            }, 300000);

        } catch (err) {
            logErrorAlServidor("SPEECH_ERROR", "Error al inicializar micrófono para dictado Vosk: " + err.message, {
                nombre: err.name,
                mensaje: err.message
            });
            
            let msg = "No se pudo acceder al micrófono.";
            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                msg += "\n\n⚠️ El navegador bloquea el micrófono por seguridad en conexiones no seguras (HTTP).\n\nPara solucionarlo:\n1. Copia y abre en Chrome: chrome://flags/#unsafely-treat-insecure-origin-as-secure\n2. Activa la opción (Enabled).\n3. Agrega la URL 'http://192.168.0.100:7001' al cuadro de texto.\n4. Haz clic en 'Relaunch' abajo para reiniciar el navegador.";
            } else if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
                msg += "\n\n⚠️ El acceso al micrófono fue denegado.\n\nPor favor, haz clic en el icono del candado/configuración a la izquierda de la barra de direcciones y cambia el permiso de Micrófono a 'Permitir'.";
            } else {
                msg += "\n\nDetalles: " + err.message;
            }
            alert(msg);
            inputDestino.placeholder = "Micrófono bloqueado/denegado.";
            iniciarOyentePasivo();
        }
    }

    function detenerGrabacionActiva() {
        if (!grabadorActivo) return;

        try {
            logErrorAlServidor("SPEECH_INFO", `Grabación detenida por el operador para el campo: '${grabadorActivo.idInput}'`);
            
            grabadorActivo.mediaStream.getTracks().forEach(track => track.stop());
            grabadorActivo.recognizerNode.disconnect();
            
            if (grabadorActivo.recognizer) {
                grabadorActivo.recognizer.remove();
            }

            grabadorActivo.boton.classList.remove('grabando');
            grabadorActivo.boton.innerText = "🎤";
            grabadorActivo.inputDestino.placeholder = grabadorActivo.placeholderOriginal;

            if (grabadorActivo.timeoutTimer) {
                clearTimeout(grabadorActivo.timeoutTimer);
            }

        } catch (e) {
            console.error("Error al limpiar recursos de grabación:", e);
        } finally {
            grabadorActivo = null;
            reproducirBeep('stop');
            iniciarOyentePasivo();
        }
    }

    let testMicStream = null;
    let testMicAudioContext = null;
    let testMicProcessor = null;

    async function toggleTestMicrofono() {
        const btn = document.getElementById("btnTestMicrofono");
        const barra = document.getElementById("testMicBarra");
        const valorText = document.getElementById("testMicValor");

        if (testMicStream) {
            detenerTestMicrofono();
            return;
        }

        try {
            logErrorAlServidor("SPEECH_INFO", "[TEST] Iniciando prueba rápida de micrófono...");
            btn.innerText = "Detener Test";
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
                
                barra.style.width = pct + "%";
                valorText.innerText = (rms * 100).toFixed(1) + "%";
            };

            source.connect(testMicProcessor);
            testMicProcessor.connect(testMicAudioContext.destination);

            logErrorAlServidor("SPEECH_INFO", "[TEST] Prueba de micro activa. Habla para ver oscilar la barra de volumen.");
        } catch (err) {
            logErrorAlServidor("SPEECH_ERROR", "[TEST] Error en prueba de micrófono: " + err.message);
            alert("No se pudo iniciar la prueba rápida de micrófono: " + err.message);
            detenerTestMicrofono();
        }
    }

    function detenerTestMicrofono() {
        const btn = document.getElementById("btnTestMicrofono");
        const barra = document.getElementById("testMicBarra");
        const valorText = document.getElementById("testMicValor");

        if (btn) {
            btn.innerText = "Probar Micro";
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
        logErrorAlServidor("SPEECH_INFO", "[TEST] Prueba rápida de micrófono finalizada y recursos liberados.");
    }
</script>

</body>
</html>
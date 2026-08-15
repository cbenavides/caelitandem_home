<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Interactivo WhatzMeApi</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0; padding: 20px; font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #0f2027, #203a43, #2c5364);
            color: #fff; min-height: 100vh;
        }
        .header { margin-bottom: 20px; text-align: center; }
        .header h1 { margin: 0; font-weight: 300; }
        .header a.docs-link { color: #48c6ef; text-decoration: none; font-size: 0.9rem; border-bottom: 1px dashed; }
        
        /* Global Settings Bar */
        .global-settings {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px); border-radius: 10px;
            padding: 15px; margin-bottom: 30px;
            display: flex; gap: 20px; flex-wrap: wrap; justify-content: center;
            border: 1px solid rgba(255,255,255,0.2);
        }
        .form-group { display: flex; flex-direction: column; gap: 5px; min-width: 250px; }
        .form-group label { font-size: 0.85rem; color: #a5d6ff; font-weight: 600; }
        input[type="text"], input[type="file"], textarea {
            background: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.2);
            color: white; padding: 10px; border-radius: 6px; font-family: inherit; width: 100%;
        }
        input:focus, textarea:focus { outline: none; border-color: #48c6ef; }
        
        .container { display: flex; flex-direction: column; gap: 20px; }
        .scripts-container { display: flex; gap: 20px; flex-wrap: wrap; }
        .scripts-container .category-group { flex: 1; min-width: 350px; }
        .console-area { width: 100%; display: flex; flex-direction: column; }
        
        .category-group {
            background: rgba(0, 0, 0, 0.2);
            border-radius: 15px; padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.05);
        }
        .category-title {
            margin: 0 0 15px 0; font-size: 1.2rem; color: #fff; border-bottom: 1px solid rgba(255,255,255,0.2); padding-bottom: 10px; font-weight: 300;
        }

        .glass-card {
            background: rgba(255, 255, 255, 0.05); backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 10px;
            padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.2); margin-bottom: 15px;
        }
        .glass-card:last-child { margin-bottom: 0; }
        
        .card-title { font-size: 1.1rem; margin: 0 0 5px 0; font-weight: 600; color: #48c6ef; }
        .card-desc { font-size: 0.85rem; color: rgba(255,255,255,0.7); margin-bottom: 15px; }
        
        .form-section { margin-bottom: 15px; background: rgba(0,0,0,0.2); padding: 10px; border-radius: 8px; }

        button.run-btn {
            background: linear-gradient(90deg, #11998e, #38ef7d);
            border: none; color: white; padding: 10px 15px; border-radius: 8px;
            cursor: pointer; font-weight: 600; width: 100%; display: flex; justify-content: center; align-items: center; gap: 8px;
        }
        button.run-btn:hover { opacity: 0.9; }
        button.run-btn:disabled { background: #555; cursor: not-allowed; }
        
        .terminal {
            background: rgba(0, 0, 0, 0.6); border-radius: 15px; border: 1px solid rgba(255,255,255,0.1);
            padding: 20px; font-family: monospace; font-size: 14px;
            height: 400px; overflow-y: auto; color: #a5d6ff;
            box-shadow: inset 0 0 20px rgba(0,0,0,0.8);
        }
        .term-log { margin: 5px 0; border-bottom: 1px solid rgba(255,255,255,0.05); padding-bottom: 5px; }
        .term-success { color: #38ef7d; }
        .term-error { color: #ff5252; }
        .term-info { color: #48c6ef; }
        .term-json { color: #d2a8ff; font-size: 13px; white-space: pre-wrap; margin-top:5px; background: rgba(255,255,255,0.05); padding: 10px; border-radius: 5px;}
        
        /* JSON Syntax Highlighting */
        .json-key { color: #82aaff; font-weight: 600; }
        .json-string { color: #c3e88d; }
        .json-number { color: #f78c6c; }
        .json-boolean { color: #ff5370; }
        .json-null { color: #89ddff; font-style: italic; }
        
        .loader {
            border: 3px solid rgba(255,255,255,0.1); border-top: 3px solid white;
            border-radius: 50%; width: 16px; height: 16px; animation: spin 1s linear infinite; display: none;
        }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <div class="header">
        <h1>WhatzMeApi Interactive Sandbox</h1>
        <a href="instrucciones.html" class="docs-link" target="_blank">Leer Arquitectura y Documentación de Scripts</a>
    </div>

    <div class="global-settings">
        <div class="form-group">
            <label>Token de WhatzMeApi</label>
            <input type="text" id="global_token" placeholder="Ej: v2~abc123..." onchange="saveSettings()">
        </div>
        <div class="form-group">
            <label>Número de WhatsApp Destino (con código país)</label>
            <input type="text" id="global_numero" placeholder="Ej: 5215500000000" onchange="saveSettings()">
        </div>
    </div>

    <div class="container">
        <div class="scripts-container">
            
            <div class="category-group">
                <h2 class="category-title">🧩 Scripts Unitarios</h2>
                <p style="font-size: 0.8rem; color: #ccc; margin-top:-10px; margin-bottom: 15px;">Endpoints atómicos independientes para validación base.</p>
                
                <!-- 1. Sesión -->
                <form id="form_sesion" class="glass-card" onsubmit="event.preventDefault(); runTest('test_sesion.php', this, this.querySelector('button'))">
                    <h3 class="card-title">🔌 1. Sesión y QR</h3>
                    <p class="card-desc">Verifica estado y genera QR si no está conectado.</p>
                    <button type="submit" class="run-btn">
                        <span class="text">Ejecutar Sesión</span><div class="loader"></div>
                    </button>
                </form>
                
                <!-- 2. Contactos -->
                <form id="form_contactos" class="glass-card">
                    <h3 class="card-title">👥 2. Gestión de Contactos</h3>
                    <p class="card-desc">Accede a tu agenda, consulta perfiles o crea un contacto nuevo interactuando paso a paso.</p>
                    <div class="form-section">
                        <div class="form-group" style="display: flex; gap: 10px;">
                            <div style="flex: 1;">
                                <label>Nombre (para crear):</label>
                                <input type="text" name="nombre_contacto" value="John">
                            </div>
                            <div style="flex: 1;">
                                <label>Apellido:</label>
                                <input type="text" name="apellido_contacto" value="Doe">
                            </div>
                        </div>
                    </div>
                    <div style="display:flex; flex-direction:column; gap: 10px; margin-top: 15px;">
                        <div style="display:flex; gap: 10px;">
                            <button type="button" class="run-btn" onclick="runTestInteractive('test_contactos.php', this.form, this, 'agenda')">
                                <span class="text">1. Ver Agenda</span><div class="loader"></div>
                            </button>
                            <button type="button" class="run-btn" onclick="runTestInteractive('test_contactos.php', this.form, this, 'info_foto')">
                                <span class="text">2. Info y Foto</span><div class="loader"></div>
                            </button>
                        </div>
                        <div style="display:flex; gap: 10px;">
                            <button type="button" class="run-btn" onclick="runTestInteractive('test_contactos.php', this.form, this, 'mapeo')">
                                <span class="text">3. Mapeo LID &harr; Tel</span><div class="loader"></div>
                            </button>
                            <button type="button" class="run-btn" style="background: linear-gradient(90deg, #11998e, #38ef7d);" onclick="runTestInteractive('test_contactos.php', this.form, this, 'crear')">
                                <span class="text">4. Crear/Guardar</span><div class="loader"></div>
                            </button>
                        </div>
                    </div>
                </form>

                <!-- 3. Archivos -->
                <form id="form_archivos" class="glass-card">
                    <h3 class="card-title">🚀 3. Archivos y Multimedia</h3>
                    <p class="card-desc">Sube y envía imagen/audio. Puedes eliminarlo posteriormente.</p>
                    <div class="form-section">
                        <div class="form-group">
                            <label>Seleccionar Archivo (Imagen o Audio .ogg):</label>
                            <input type="file" name="archivo_subido" accept="image/*,audio/ogg" required>
                        </div>
                        <div class="form-group" style="margin-top:10px;">
                            <label>Pie de foto (Caption):</label>
                            <input type="text" name="caption" value="Imagen enviada desde WebApp">
                        </div>
                    </div>
                    <div style="display:flex; gap: 10px; margin-top: 15px;">
                        <button type="button" class="run-btn" onclick="runTestInteractive('test_archivos_masivos.php', this.form, this, 'enviar')">
                            <span class="text">1. Subir y Enviar</span><div class="loader"></div>
                        </button>
                        <button type="button" class="run-btn" style="background: linear-gradient(90deg, #ff416c, #ff4b2b);" onclick="runTestInteractive('test_archivos_masivos.php', this.form, this, 'eliminar')">
                            <span class="text">2. Eliminar Multimedia</span><div class="loader"></div>
                        </button>
                    </div>
                </form>
            </div>

            <div class="category-group">
                <h2 class="category-title">⛓️ Scripts tipo Pipeline</h2>
                <p style="font-size: 0.8rem; color: #ccc; margin-top:-10px; margin-bottom: 15px;">Orquestaciones secuenciales completas con transiciones de estado.</p>

                <!-- 4. Mensajería -->
                <form id="form_mensajeria" class="glass-card">
                    <h3 class="card-title">💬 4. Mensajería Interactiva</h3>
                    <p class="card-desc">Ejecuta el flujo paso a paso: envía, espera lo que gustes, y luego edita o elimina.</p>
                    <div class="form-section">
                        <div class="form-group">
                            <label>Mensaje Original:</label>
                            <textarea name="mensaje_original" rows="2" required>Hola, este es un mensaje interactivo de prueba.</textarea>
                        </div>
                        <div class="form-group" style="margin-top:10px;">
                            <label>Texto para Edición:</label>
                            <textarea name="mensaje_editado" rows="2" required>El mensaje ha sido editado exitosamente por la API.</textarea>
                        </div>
                    </div>
                    <div style="display:flex; gap: 10px; margin-top: 15px;">
                        <button type="button" class="run-btn" onclick="runTestInteractive('pipeline_mensajeria.php', this.form, this, 'enviar')">
                            <span class="text">1. Enviar</span><div class="loader"></div>
                        </button>
                        <button type="button" class="run-btn" onclick="runTestInteractive('pipeline_mensajeria.php', this.form, this, 'editar')">
                            <span class="text">2. Editar</span><div class="loader"></div>
                        </button>
                        <button type="button" class="run-btn" style="background: linear-gradient(90deg, #ff416c, #ff4b2b);" onclick="runTestInteractive('pipeline_mensajeria.php', this.form, this, 'eliminar')">
                            <span class="text">3. Eliminar</span><div class="loader"></div>
                        </button>
                    </div>
                </form>

                <!-- 5. Grupos -->
                <form id="form_grupos" class="glass-card">
                    <h3 class="card-title">👪 5. Gestión de Grupos</h3>
                    <p class="card-desc">Crea un grupo, actualiza permisos, promueve usuarios y extrae link paso a paso.</p>
                    <div class="form-section">
                        <div class="form-group">
                            <label>Nombre del Grupo Nuevo:</label>
                            <input type="text" name="nombre_grupo" value="Grupo Test Interactivo" required>
                        </div>
                    </div>
                    <div style="display:flex; flex-direction:column; gap: 10px; margin-top: 15px;">
                        <button type="button" class="run-btn" onclick="runTestInteractive('pipeline_grupos.php', this.form, this, 'crear')">
                            <span class="text">1. Crear Grupo</span><div class="loader"></div>
                        </button>
                        <div style="display:flex; gap: 10px;">
                            <button type="button" class="run-btn" onclick="runTestInteractive('pipeline_grupos.php', this.form, this, 'configurar')">
                                <span class="text">2. Solo Admins</span><div class="loader"></div>
                            </button>
                            <button type="button" class="run-btn" onclick="runTestInteractive('pipeline_grupos.php', this.form, this, 'promover')">
                                <span class="text">3. Promover</span><div class="loader"></div>
                            </button>
                            <button type="button" class="run-btn" onclick="runTestInteractive('pipeline_grupos.php', this.form, this, 'invitacion')">
                                <span class="text">4. Link</span><div class="loader"></div>
                            </button>
                        </div>
                    </div>
                </form>
            </div>
            
        </div>
        
        <div class="console-area">
            <div class="terminal" id="terminal">
                <div class="term-info">> WebApp Interactiva inicializada.</div>
                <div class="term-info">> Ingresa tu Token y un Número de prueba arriba.</div>
            </div>
        </div>
    </div>

    <script>
        const terminal = document.getElementById('terminal');
        const iToken = document.getElementById('global_token');
        const iNumero = document.getElementById('global_numero');

        // Restaurar estado de localStorage
        if(localStorage.getItem('wz_token')) iToken.value = localStorage.getItem('wz_token');
        if(localStorage.getItem('wz_numero')) iNumero.value = localStorage.getItem('wz_numero');

        function saveSettings() {
            localStorage.setItem('wz_token', iToken.value);
            localStorage.setItem('wz_numero', iNumero.value);
        }

        function syntaxHighlight(json) {
            if (typeof json != 'string') {
                 json = JSON.stringify(json, undefined, 2);
            }
            json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
            return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
                var cls = 'json-number';
                if (/^"/.test(match)) {
                    if (/:$/.test(match)) {
                        cls = 'json-key';
                    } else {
                        cls = 'json-string';
                    }
                } else if (/true|false/.test(match)) {
                    cls = 'json-boolean';
                } else if (/null/.test(match)) {
                    cls = 'json-null';
                }
                return '<span class="' + cls + '">' + match + '</span>';
            });
        }

        function log(message, type="info", json=null) {
            const div = document.createElement('div');
            div.className = `term-log term-${type}`;
            let time = new Date().toLocaleTimeString();
            let html = `<strong>[${time}]</strong> ${message}`;
            if (json) {
                let formattedJson = syntaxHighlight(json);
                html += `<div class="term-json">${formattedJson}</div>`;
            }
            div.innerHTML = html;
            terminal.appendChild(div);
            terminal.scrollTop = terminal.scrollHeight;
        }

        async function runTest(scriptName, formElement, btnElement) {
            const token = iToken.value.trim();
            const numero = iNumero.value.trim();

            if (!token || !numero) {
                log("ERROR: Debes proveer un Token y un Número Destino en la barra superior.", "error");
                return;
            }

            btnElement.disabled = true;
            btnElement.querySelector('.text').style.display = 'none';
            btnElement.querySelector('.loader').style.display = 'block';
            
            log(`Enviando petición a: ${scriptName}...`, 'info');
            
            try {
                // Preparar FormData
                const formData = new FormData(formElement);
                formData.append('token', token);
                formData.append('numero_destino', numero);
                formData.append('ajax', '1');

                const response = await fetch(scriptName, {
                    method: 'POST',
                    body: formData
                });
                
                if (!response.ok) throw new Error(`HTTP Error: ${response.status}`);
                
                const data = await response.json();
                
                if (data.status === 'success') {
                    log(`Ejecución Exitosa: ${scriptName}`, 'success');
                    if (data.output && Array.isArray(data.output)) {
                        data.output.forEach(item => {
                            log(item.title, item.type || 'info', item.data);
                        });
                    }
                } else {
                    log(`Fallo Reportado por Backend en: ${scriptName}`, 'error');
                    if (data.message) log(data.message, 'error');
                    if (data.output) log('Detalles:', 'error', data.output);
                }
                
            } catch (error) {
                log(`Error de Red/Sistema en ${scriptName}: ${error.message}`, 'error');
            } finally {
                btnElement.disabled = false;
                btnElement.querySelector('.text').style.display = 'block';
                btnElement.querySelector('.loader').style.display = 'none';
            }
        }
        let storedIdMensaje = null;
        let storedJidGrupo = null;

        async function runTestInteractive(scriptName, formElement, btnElement, accion) {
            const token = iToken.value.trim();
            const numero = iNumero.value.trim();

            if (!token || !numero) {
                log("ERROR: Debes proveer un Token y un Número Destino en la barra superior.", "error");
                return;
            }

            btnElement.disabled = true;
            btnElement.querySelector('.text').style.display = 'none';
            btnElement.querySelector('.loader').style.display = 'block';
            
            log(`Ejecutando Acción [${accion.toUpperCase()}] en ${scriptName}...`, 'info');
            
            try {
                const formData = new FormData(formElement);
                formData.append('token', token);
                formData.append('numero_destino', numero);
                formData.append('ajax', '1');
                formData.append('accion', accion);
                
                // Inject state if exists
                if (storedIdMensaje) formData.append('id_mensaje', storedIdMensaje);
                if (storedJidGrupo) formData.append('jid_grupo', storedJidGrupo);

                const response = await fetch(scriptName, {
                    method: 'POST',
                    body: formData
                });
                
                if (!response.ok) throw new Error(`HTTP Error: ${response.status}`);
                
                const data = await response.json();
                
                if (data.status === 'success') {
                    log(`Acción [${accion}] Exitosa.`, 'success');
                    if (data.idMensaje) storedIdMensaje = data.idMensaje;
                    if (data.jidGrupo) storedJidGrupo = data.jidGrupo;

                    if (data.output && Array.isArray(data.output)) {
                        data.output.forEach(item => {
                            log(item.title, item.type || 'info', item.data);
                        });
                    }
                } else {
                    log(`Fallo en Acción [${accion}]`, 'error');
                    if (data.message) log(data.message, 'error');
                    if (data.output && Array.isArray(data.output)) {
                        data.output.forEach(item => log(item.title, item.type, item.data));
                    }
                }
            } catch (error) {
                log(`Error en ${scriptName}: ${error.message}`, 'error');
            } finally {
                btnElement.disabled = false;
                btnElement.querySelector('.text').style.display = 'block';
                btnElement.querySelector('.loader').style.display = 'none';
            }
        }
    </script>
</body>
</html>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>PWA Mesero - Comanda (Voz)</title>
    <link rel="stylesheet" href="web-assets/css/main.css">
    <!-- Iconos -->
    <script src="https://unpkg.com/lucide@latest"></script>
</head>
<body>
    <div class="app-container">
        <!-- Header con Menú Hamburguesa -->
        <header class="app-header">
            <div style="display: flex; align-items: center; gap: 1rem;">
                <button class="icon-btn" onclick="toggleMenu(event)">
                    <i data-lucide="menu"></i>
                </button>
                <div>
                    <h1 style="font-size: 1.25rem;">Comanda Nueva</h1>
                    <div class="text-secondary" style="font-size: 0.875rem;">Mesero: Juan Pérez</div>
                </div>
            </div>
            <div style="background: rgba(16, 185, 129, 0.15); padding: 0.4rem 0.8rem; border-radius: 99px;">
                <span style="color: var(--status-success); font-weight: 600; font-size: 0.85rem;">VOSK Activo</span>
            </div>
        </header>

        <!-- Side Menu -->
        <div class="side-menu-overlay" id="side-menu-overlay" onclick="toggleMenu(event)"></div>
        <aside class="side-menu" id="side-menu">
            <div class="menu-header">
                <h2 style="font-size: 1.25rem;">Caeli Tandem</h2>
                <button class="icon-btn" onclick="toggleMenu(event)">
                    <i data-lucide="x"></i>
                </button>
            </div>
            <nav class="menu-nav">
                <a href="pwa_mesero_comanda.php" class="menu-item">
                    <i data-lucide="mic"></i> Nueva Comanda
                </a>
                <a href="pwa_mesero_notificaciones.php" class="menu-item">
                    <i data-lucide="list"></i> Mis Mesas Activas
                </a>
                <hr style="border: 0; border-top: 1px solid var(--glass-border); margin: 1rem 0;">
                <a href="#" class="menu-item" onclick="toggleTheme(event)">
                    <i data-lucide="moon"></i> Alternar Tema Oscuro/Claro
                </a>
                <a href="#" class="menu-item danger" onclick="logout(event)" style="margin-top: auto;">
                    <i data-lucide="log-out"></i> Cerrar Sesión
                </a>
            </nav>
        </aside>

        <main class="app-content">
            <!-- Instruction -->
            <div class="glass-panel" style="padding: 1rem; text-align: center;">
                <p class="text-secondary">Mantén presionado el micrófono para dictar la orden. Ejemplo: <i>"Mesa cinco, dos tacos..."</i></p>
            </div>

            <!-- Transcription Area -->
            <div style="flex: 1; display: flex; flex-direction: column; justify-content: center;">
                <h3 style="margin-bottom: 0.5rem; font-size: 0.9rem;" class="text-secondary">Transcripción (Toca para editar):</h3>
                <div class="transcription-box" id="transcription-text" contenteditable="true" spellcheck="false" style="outline: none;">
                    <!-- Text gets injected here by JS -->
                </div>
                
                <!-- Editor Toolbar -->
                <div class="editor-toolbar">
                    <button class="editor-btn" title="Deshacer" onclick="document.execCommand('undo')">
                        <i data-lucide="undo-2" style="width: 18px; height: 18px;"></i>
                    </button>
                    <button class="editor-btn" title="Rehacer" onclick="document.execCommand('redo')">
                        <i data-lucide="redo-2" style="width: 18px; height: 18px;"></i>
                    </button>
                    <button class="editor-btn" title="Limpiar" onclick="document.getElementById('transcription-text').innerHTML=''">
                        <i data-lucide="trash-2" style="width: 18px; height: 18px;"></i>
                    </button>
                </div>
            </div>

            <!-- Action Buttons Wrapper -->
            <div class="action-buttons-wrapper">
                <!-- Pencil / Manual Input -->
                <button class="alt-btn" title="Escritura Manual" onclick="document.getElementById('transcription-text').focus()">
                    <i data-lucide="pencil" style="width: 22px; height: 22px;"></i>
                </button>
                
                <!-- Main Mic Button -->
                <div class="mic-btn" id="btn-mic" title="Mantener para Hablar">
                    <i data-lucide="mic" style="width: 32px; height: 32px;"></i>
                </div>
                
                <!-- Invisible Spacer to keep Mic centered -->
                <div style="width: 50px;"></div>
            </div>

            <!-- Action Buttons -->
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; padding-bottom: 1rem;">
                <button class="btn glass-panel text-secondary">
                    <i data-lucide="x"></i> Limpiar
                </button>
                <button class="btn btn-primary">
                    Enviar <i data-lucide="send"></i>
                </button>
            </div>
        </main>
    </div>

    <script>
        lucide.createIcons();
    </script>
    <script src="web-assets/js/app.js"></script>
</body>
</html>

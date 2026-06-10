<?php
require_once('login/usuario.php');
session_start();
if (!isset($_SESSION['usuario'])) {
	print "<script>window.location='login/index.php'</script>";
	exit();
}
header('Content-Type: text/html; charset=UTF-8');
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SADM Tlapa - Consola de Operaciones Oscura V4.1.0</title>
    
    <!-- Google Fonts: JetBrains Mono & Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --bg-darker: #090d16;     /* Deep Space Blue */
            --bg-dark: #0f1524;       /* Slate Dark */
            --bg-card: #172033;       /* Card Background */
            --border-color: #23314f;
            --primary: #00f5d4;       /* Neon Turquoise */
            --primary-glow: rgba(0, 245, 212, 0.15);
            --accent: #3b82f6;        /* Electric Blue */
            --text-main: #f1f5f9;     /* Off-White */
            --text-muted: #64748b;    /* Gray-Slate */
            --success: #10b981;
            --warning: #ff9f1c;
            --danger: #ef4444;
            --border-radius: 10px;
            --transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', system-ui, sans-serif;
            -webkit-font-smoothing: antialiased;
        }

        body {
            background-color: var(--bg-darker);
            color: var(--text-main);
            height: 100vh;
            overflow: hidden;
            display: flex;
        }

        /* Loading Spinner Overlay */
        #loader-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(9, 13, 22, 0.85);
            z-index: 9999;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.2s ease;
        }
        
        #loader-overlay.active {
            opacity: 1;
            pointer-events: auto;
        }

        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid var(--border-color);
            border-top-color: var(--primary);
            border-radius: 50%;
            animation: spin 0.8s infinite linear;
            box-shadow: 0 0 15px var(--primary-glow);
        }

        .loader-text {
            color: var(--primary);
            margin-top: 15px;
            font-weight: 600;
            font-size: 13px;
            letter-spacing: 0.15em;
            font-family: 'JetBrains Mono', monospace;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Compact Left Menu */
        aside {
            width: 80px;
            background-color: var(--bg-dark);
            border-right: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: space-between;
            padding: 25px 0;
            z-index: 10;
        }

        .aside-logo {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary);
            box-shadow: 0 0 10px rgba(0, 245, 212, 0.1);
        }

        .aside-logo svg {
            width: 22px;
            height: 22px;
            fill: currentColor;
        }

        .nav-vertical {
            display: flex;
            flex-direction: column;
            gap: 15px;
            flex-grow: 1;
            margin-top: 40px;
            list-style: none;
            width: 100%;
            align-items: center;
        }

        .nav-item {
            width: 50px;
            height: 50px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--text-muted);
            text-decoration: none;
            transition: var(--transition);
        }

        .nav-item:hover {
            color: var(--text-main);
            background-color: rgba(255,255,255,0.05);
        }

        .nav-item.active {
            color: var(--bg-darker);
            background-color: var(--primary);
            box-shadow: 0 0 15px rgba(0, 245, 212, 0.4);
        }

        .nav-item svg {
            width: 22px;
            height: 22px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        /* Profile Bottom */
        .aside-avatar {
            width: 42px;
            height: 42px;
            border-radius: 50%;
            background-color: var(--bg-card);
            border: 1.5px solid var(--primary);
            color: var(--primary);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 700;
        }

        /* Workspace Structure */
        main {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            height: 100vh;
            overflow: hidden;
        }

        header {
            height: 70px;
            background-color: var(--bg-dark);
            border-bottom: 1px solid var(--border-color);
            padding: 0 30px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .header-title h2 {
            font-size: 18px;
            font-weight: 600;
            color: var(--text-main);
        }

        .header-title p {
            font-size: 11px;
            color: var(--text-muted);
            font-family: 'JetBrains Mono', monospace;
        }

        .badge-terminal {
            font-family: 'JetBrains Mono', monospace;
            font-size: 12px;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            padding: 6px 12px;
            border-radius: 6px;
            color: var(--primary);
        }

        /* Dashboard content container */
        .content-panel {
            padding: 25px;
            overflow-y: auto;
            flex-grow: 1;
            background-color: var(--bg-darker);
        }

        .tab-panel {
            display: none;
            animation: consoleFade 0.3s ease-out forwards;
        }

        .tab-panel.active {
            display: block;
        }

        @keyframes consoleFade {
            from { opacity: 0; filter: brightness(0.7); }
            to { opacity: 1; filter: brightness(1); }
        }

        /* Dark Card */
        .console-card {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius);
            padding: 24px;
            margin-bottom: 20px;
        }

        .console-title {
            font-size: 14px;
            font-weight: 600;
            color: var(--primary);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 15px;
            font-family: 'JetBrains Mono', monospace;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 8px;
        }

        /* Dual Pane Layout (Citizens & Details) */
        .dual-pane {
            display: grid;
            grid-template-columns: 1.2fr 1fr;
            gap: 20px;
            height: calc(100vh - 160px);
        }

        .pane-list, .pane-detail {
            height: 100%;
            overflow-y: auto;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius);
            padding: 20px;
        }

        /* Statistics Terminal Grid */
        .console-stat-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 25px;
        }

        .console-stat {
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius);
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 8px;
            position: relative;
            overflow: hidden;
        }

        .console-stat::after {
            content: '';
            position: absolute;
            top: 0; left: 0;
            width: 100%; height: 3px;
            background-color: var(--border-color);
        }

        .console-stat.active::after { background-color: var(--primary); }
        .console-stat.success::after { background-color: var(--success); }
        .console-stat.warning::after { background-color: var(--warning); }
        .console-stat.danger::after { background-color: var(--danger); }

        .stat-label {
            font-size: 11px;
            color: var(--text-muted);
            text-transform: uppercase;
            font-family: 'JetBrains Mono', monospace;
        }

        .stat-num {
            font-size: 24px;
            font-weight: 700;
            font-family: 'JetBrains Mono', monospace;
        }

        /* Form Controls Console Style */
        .console-input-group {
            position: relative;
            margin-bottom: 15px;
        }

        .console-input {
            width: 100%;
            height: 42px;
            background-color: var(--bg-darker);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 0 15px;
            font-size: 13px;
            color: var(--text-main);
            font-family: 'JetBrains Mono', monospace;
            outline: none;
            transition: var(--transition);
        }

        .console-input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 10px rgba(0, 245, 212, 0.1);
        }

        .btn-console {
            height: 42px;
            padding: 0 20px;
            background-color: var(--primary);
            color: var(--bg-darker);
            font-weight: 600;
            font-size: 13px;
            font-family: 'JetBrains Mono', monospace;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            transition: var(--transition);
        }

        .btn-console:hover {
            box-shadow: 0 0 15px var(--primary);
            filter: brightness(1.1);
        }

        /* High Contrast Console Table */
        .console-table {
            width: 100%;
            border-collapse: collapse;
        }

        .console-table th {
            padding: 10px 12px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 11px;
            color: var(--text-muted);
            text-align: left;
            text-transform: uppercase;
            border-bottom: 1.5px solid var(--border-color);
        }

        .console-table td {
            padding: 12px;
            font-size: 13px;
            border-bottom: 1px solid rgba(35, 49, 79, 0.5);
        }

        .console-table tr.clickable {
            cursor: pointer;
        }

        .console-table tr.clickable:hover td {
            background-color: rgba(255,255,255,0.02);
            color: var(--primary);
        }

        /* Indicator lights */
        .status-dot {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 6px;
        }
        .status-dot.active { background-color: var(--success); box-shadow: 0 0 8px var(--success); }
        .status-dot.lila { background-color: #a78bfa; box-shadow: 0 0 8px #a78bfa; }
        .status-dot.temp { background-color: var(--warning); box-shadow: 0 0 8px var(--warning); }
    </style>
</head>
<body>

    <!-- Loading Clock Spinner -->
    <div id="loader-overlay">
        <div class="spinner"></div>
        <div class="loader-text">SYS.CONSOLE_CONNECTING...</div>
    </div>

    <!-- Sidebar Compact Menu -->
    <aside>
        <div class="aside-logo">
            <svg viewBox="0 0 24 24"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
        </div>

        <ul class="nav-vertical">
            <li>
                <a href="#" class="nav-item active" data-tab="dashboard" data-title="Consola de Operaciones - Dashboard">
                    <svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></svg>
                </a>
            </li>
            <li>
                <a href="#" class="nav-item" data-tab="usuarios" data-title="Consola de Operaciones - Directorio Binario">
                    <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                </a>
            </li>
            <li>
                <a href="#" class="nav-item" data-tab="egresos" data-title="Consola de Operaciones - Gestión de Egresos">
                    <svg viewBox="0 0 24 24"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                </a>
            </li>
        </ul>

        <div class="aside-avatar" title="<?php echo htmlspecialchars($_SESSION['usuario']->getNombre()); ?>">
            <?php echo strtoupper(substr($_SESSION['usuario']->getNombre(), 0, 2)); ?>
        </div>
    </aside>

    <!-- Main Workspace -->
    <main>
        <header>
            <div class="header-title">
                <h2 id="console-header-title">Consola de Operaciones - Dashboard</h2>
                <p>INSTANCIA: TLAPA_DE_COMONFORT // BD: AGUAYD_OS // PORT: 7001</p>
            </div>
            <div class="badge-terminal">OPERADOR: <?php echo strtoupper($_SESSION['usuario']->getNombre()); ?></div>
        </header>

        <div class="content-panel">

            <!-- TAB 1: Dashboard -->
            <div class="tab-panel active" id="tab-dashboard">
                <div class="console-stat-grid">
                    <div class="console-stat active">
                        <span class="stat-label">Total Usuarios</span>
                        <span class="stat-num">1,409</span>
                    </div>
                    <div class="console-stat success">
                        <span class="stat-label">Activos</span>
                        <span class="stat-num">1,372</span>
                    </div>
                    <div class="console-stat warning">
                        <span class="stat-label">Suspensión Temp</span>
                        <span class="stat-num">28</span>
                    </div>
                    <div class="console-stat danger">
                        <span class="stat-label">Suspensión Def</span>
                        <span class="stat-num">10</span>
                    </div>
                </div>

                <div class="console-card">
                    <div class="console-title">Auditoría en Tiempo Real (Historial Cambios)</div>
                    <div style="font-family:'JetBrains Mono', monospace; font-size:12px; line-height:1.6; color:#a7f3d0;">
                        >> [2026-05-25 22:10] CONTRATO #391: Cobro registrado de Agua Potable ($150.00)<br>
                        >> [2026-05-25 21:40] CONTRATO #12: Cambio de estado a SUSPENSIÓN TEMPORAL<br>
                        >> [2026-05-25 20:15] USUARIO #1057: Duplicado enlazado a ID Maestro #1590
                    </div>
                </div>
            </div>

            <!-- TAB 2: Dual Pane Directorio -->
            <div class="tab-panel" id="tab-usuarios">
                <div class="dual-pane">
                    <!-- Left List Pane -->
                    <div class="pane-list">
                        <div class="console-title">Lista de Registros</div>
                        <div class="console-input-group">
                            <input type="text" class="console-input" id="console-search" placeholder="Filtro rápido [Nombre / Calle]...">
                        </div>
                        <table class="console-table">
                            <thead>
                                <tr>
                                    <th>Folio</th>
                                    <th>Nombre Ciudadano</th>
                                    <th>Estado</th>
                                </tr>
                            </thead>
                            <tbody id="console-list-body">
                                <tr class="clickable console-row" onclick="loadConsoleDetail('Silvia Aguirre Cabrera', 'Constitución n° 92, Centro', 'No registrado', '#1', 'Activo', '1 Contrato Activo')" data-name="silvia aguirre cabrera" data-addr="constitucion">
                                    <td>#1</td>
                                    <td style="text-transform:capitalize;">silvia aguirre cabrera</td>
                                    <td><span class="status-dot active"></span>Activo</td>
                                </tr>
                                <tr class="clickable console-row" onclick="loadConsoleDetail('Griselda Antunez Callejas', 'Josefa Ortiz de Dominguez n° 76', '757 556 7410', '#7', 'Activo', '1 Contrato Activo')" data-name="griselda antunez callejas" data-addr="josefa">
                                    <td>#7</td>
                                    <td style="text-transform:capitalize;">griselda antunez callejas</td>
                                    <td><span class="status-dot active"></span>Activo</td>
                                </tr>
                                <tr class="clickable console-row" onclick="loadConsoleDetail('Angel Arturo Aparicio Vazquez', 'Melchor Ocampo n° 102', '757 532 2099', '#8', 'Lila', 'Ninguno')" data-name="angel arturo aparicio vazquez" data-addr="melchor">
                                    <td>#8</td>
                                    <td style="text-transform:capitalize;">angel arturo aparicio vazquez</td>
                                    <td><span class="status-dot lila"></span>Sin Contrato</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Right Detail Pane -->
                    <div class="pane-detail" id="console-detail-pane">
                        <div class="console-title">Consola de Detalles</div>
                        <div style="display:flex; height:80%; align-items:center; justify-content:center; color:var(--text-muted); font-size:12px; font-family:'JetBrains Mono', monospace;">
                            [ SELECCIONA UN REGISTRO PARA VER DETALLES ]
                        </div>
                    </div>
                </div>
            </div>

            <!-- TAB 3: Egresos -->
            <div class="tab-panel" id="tab-egresos">
                <div class="console-card" style="max-width: 500px; margin: 0 auto;">
                    <div class="console-title">Nueva Transacción de Egreso</div>
                    <form onsubmit="alert('Egreso guardado en Consola'); return false;" style="display:flex; flex-direction:column; gap:12px;">
                        <input type="text" class="console-input" required placeholder="Folio del Recibo...">
                        <input type="number" step="0.01" class="console-input" required placeholder="Monto ($)...">
                        <input type="text" class="console-input" required placeholder="Nombre Beneficiario...">
                        <select class="console-input" style="height:42px;">
                            <option>PAGO DE ENERGÍA (CFE)</option>
                            <option>MATERIAL Y TUBERÍAS</option>
                            <option>OTROS GASTOS OPERATIVOS</option>
                        </select>
                        <button type="submit" class="btn-console" style="margin-top:10px;">Aplicar Egreso</button>
                    </form>
                </div>
            </div>

        </div>
    </main>

    <script>
        // Tab switching
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', function(e) {
                e.preventDefault();
                const tab = this.getAttribute('data-tab');
                const title = this.getAttribute('data-title');
                
                const loader = document.getElementById('loader-overlay');
                loader.classList.add('active');
                
                setTimeout(() => {
                    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
                    this.classList.add('active');
                    
                    document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.remove('active'));
                    document.getElementById(`tab-${tab}`).classList.add('active');
                    
                    document.getElementById('console-header-title').innerText = title;
                    
                    loader.classList.remove('active');
                }, 300);
            });
        });

        // Live filtering
        document.getElementById('console-search').addEventListener('input', function() {
            const query = this.value.toLowerCase().trim();
            document.querySelectorAll('.console-row').forEach(row => {
                const name = row.getAttribute('data-name');
                const addr = row.getAttribute('data-addr');
                if (name.includes(query) || addr.includes(query)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });

        // Detail Pane Dynamic loader
        function loadConsoleDetail(name, address, phone, id, state, contracts) {
            const pane = document.getElementById('console-detail-pane');
            pane.innerHTML = `
                <div class="console-title">Detalles del Folio ${id}</div>
                <div style="font-family:'JetBrains Mono', monospace; font-size:13px; line-height:1.8; color:var(--text-main);">
                    <p style="color:var(--primary); font-weight:600; margin-bottom:15px; font-size:15px;">>>> FICHA TÉCNICA: ${name.toUpperCase()}</p>
                    <p>• DIRECCIÓN : ${address.toUpperCase()}</p>
                    <p>• TELÉFONO  : ${phone}</p>
                    <p>• CONTRATOS : ${contracts}</p>
                    <p>• ESTADO    : <span style="color: ${state === 'Activo' ? 'var(--success)' : '#c084fc'}">${state.toUpperCase()}</span></p>
                    
                    <div style="margin-top:30px; display:flex; gap:10px;">
                        <button class="btn-console" onclick="alert('Editar')" style="background-color: var(--accent); color: white;">EDITAR</button>
                        <button class="btn-console" onclick="alert('Historial')" style="background-color: var(--bg-darker); border:1px solid var(--border-color); color:var(--text-main);">HISTORIAL</button>
                    </div>
                </div>
            `;
        }
    </script>
</body>
</html>

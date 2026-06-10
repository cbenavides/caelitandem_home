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
    <title>SADM Tlapa - Portal Glass V4.1.0</title>
    
    <!-- Google Fonts: Inter & Outfit -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --primary: #0f172a;       /* Slate 900 */
            --accent: #2563eb;        /* Royal Blue */
            --accent-hover: #1d4ed8;
            --success: #10b981;       /* Emerald */
            --warning: #f59e0b;       /* Amber */
            --danger: #ef4444;        /* Rose */
            --glass-bg: rgba(255, 255, 255, 0.7);
            --glass-border: rgba(255, 255, 255, 0.4);
            --glass-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.06);
            --border-radius: 16px;
            --transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', system-ui, sans-serif;
            -webkit-font-smoothing: antialiased;
        }

        body {
            /* Smooth background gradient */
            background: linear-gradient(135deg, #e0f2fe 0%, #f1f5f9 50%, #fae8ff 100%);
            background-attachment: fixed;
            color: var(--primary);
            height: 100vh;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }

        /* Loading Spinner Overlay */
        #loader-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(255, 255, 255, 0.4);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            z-index: 9999;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.25s ease;
        }
        
        #loader-overlay.active {
            opacity: 1;
            pointer-events: auto;
        }

        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid rgba(37, 99, 235, 0.1);
            border-top-color: var(--accent);
            border-radius: 50%;
            animation: spin 0.8s infinite linear;
        }

        .loader-text {
            color: var(--primary);
            margin-top: 15px;
            font-weight: 600;
            font-size: 14px;
            letter-spacing: 0.1em;
            font-family: 'Outfit', sans-serif;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Top Horizontal Glass Header */
        header {
            background: var(--glass-bg);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--glass-border);
            box-shadow: var(--glass-shadow);
            padding: 0 40px;
            height: 90px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            z-index: 10;
        }

        .brand-section {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .brand-icon {
            width: 44px;
            height: 44px;
            border-radius: 12px;
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
        }

        .brand-icon svg {
            width: 24px;
            height: 24px;
            fill: currentColor;
        }

        .brand-info h1 {
            font-family: 'Outfit', sans-serif;
            font-size: 20px;
            font-weight: 700;
            background: linear-gradient(135deg, #1e3a8a, #4f46e5);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .brand-info p {
            font-size: 11px;
            color: #64748b;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        /* Horizontal Menu */
        nav.nav-horizontal {
            display: flex;
            gap: 10px;
        }

        .nav-link {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 10px 18px;
            border-radius: 10px;
            text-decoration: none;
            color: #475569;
            font-weight: 600;
            font-size: 14px;
            transition: var(--transition);
        }

        .nav-link:hover {
            color: var(--accent);
            background: rgba(37, 99, 235, 0.06);
        }

        .nav-link.active {
            color: var(--white);
            background: var(--accent);
            box-shadow: 0 4px 14px rgba(37, 99, 235, 0.25);
            color: white;
        }

        .nav-link svg {
            width: 18px;
            height: 18px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        /* Profile Area */
        .profile-area {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .user-card {
            display: flex;
            align-items: center;
            gap: 10px;
            background: rgba(255, 255, 255, 0.4);
            padding: 6px 12px 6px 8px;
            border-radius: 30px;
            border: 1px solid var(--glass-border);
        }

        .avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            font-weight: 700;
            font-size: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .user-name {
            font-size: 13px;
            font-weight: 600;
        }

        .btn-exit {
            background: none;
            border: none;
            color: #94a3b8;
            cursor: pointer;
            transition: var(--transition);
        }

        .btn-exit:hover {
            color: var(--danger);
        }

        /* Layout Main Workspace */
        .workspace {
            padding: 30px 40px;
            overflow-y: auto;
            flex-grow: 1;
        }

        .glass-card {
            background: var(--glass-bg);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--glass-border);
            box-shadow: var(--glass-shadow);
            border-radius: var(--border-radius);
            padding: 30px;
            margin-bottom: 24px;
        }

        .breadcrumb {
            font-size: 12px;
            color: #64748b;
            margin-bottom: 24px;
            display: flex;
            gap: 5px;
        }

        .breadcrumb span:not(:last-child)::after {
            content: '/';
            margin-left: 6px;
        }

        .tab-panel {
            display: none;
            animation: slideUp 0.4s ease forwards;
        }

        .tab-panel.active {
            display: block;
        }

        @keyframes slideUp {
            from { opacity: 0; transform: translateY(12px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Stat Grid Glass */
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }

        .glass-stat-card {
            background: rgba(255, 255, 255, 0.45);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            border: 1px solid var(--glass-border);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.02);
            border-radius: var(--border-radius);
            padding: 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: var(--transition);
        }

        .glass-stat-card:hover {
            transform: scale(1.02);
            background: rgba(255, 255, 255, 0.6);
        }

        .stat-title {
            font-size: 12px;
            color: #64748b;
            text-transform: uppercase;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .stat-val {
            font-size: 28px;
            font-weight: 700;
            color: #1e293b;
            font-family: 'Outfit', sans-serif;
        }

        .stat-circle {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }

        .stat-circle.blue { background: linear-gradient(135deg, #3b82f6, #1d4ed8); }
        .stat-circle.green { background: linear-gradient(135deg, #10b981, #059669); }
        .stat-circle.yellow { background: linear-gradient(135deg, #f59e0b, #d97706); }
        .stat-circle.red { background: linear-gradient(135deg, #ef4444, #b91c1c); }

        /* Split Cards */
        .grid-split {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 24px;
        }

        /* Tables & Inputs */
        .search-container {
            display: flex;
            gap: 10px;
            margin-bottom: 24px;
        }

        .search-box {
            position: relative;
            flex-grow: 1;
        }

        .search-box svg {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            width: 18px;
            height: 18px;
            color: #94a3b8;
        }

        .input-text {
            width: 100%;
            height: 46px;
            border-radius: 10px;
            border: 1px solid rgba(0,0,0,0.1);
            padding: 10px 15px 10px 45px;
            background: rgba(255,255,255,0.5);
            font-size: 14px;
            outline: none;
            transition: var(--transition);
        }

        .input-text:focus {
            background: white;
            border-color: var(--accent);
            box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.12);
        }

        .btn-action {
            height: 46px;
            padding: 0 20px;
            border-radius: 10px;
            border: none;
            background: var(--accent);
            color: white;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: var(--transition);
            box-shadow: 0 4px 10px rgba(37, 99, 235, 0.2);
        }

        .btn-action:hover {
            background: var(--accent-hover);
        }

        /* Modern Glass Table */
        .glass-table {
            width: 100%;
            border-collapse: collapse;
        }

        .glass-table th {
            padding: 12px 16px;
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 700;
            color: #64748b;
            text-align: left;
            border-bottom: 1px solid rgba(0,0,0,0.06);
        }

        .glass-table td {
            padding: 14px 16px;
            font-size: 13px;
            border-bottom: 1px solid rgba(0,0,0,0.04);
        }

        .glass-table tr:hover td {
            background: rgba(255,255,255,0.3);
        }

        /* Status Badge */
        .status-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
        }

        .status-badge.active { background: rgba(16, 185, 129, 0.15); color: #047857; }
        .status-badge.lila { background: rgba(216, 180, 254, 0.3); color: #6d28d9; }
        .status-badge.suspended { background: rgba(245, 158, 11, 0.15); color: #b45309; }

        /* Drawer Overlay */
        .overlay-drawer {
            position: fixed;
            top: 0; right: 0;
            width: 100%; height: 100%;
            background: rgba(15, 23, 42, 0.2);
            backdrop-filter: blur(4px);
            z-index: 100;
            opacity: 0; pointer-events: none;
            transition: opacity 0.3s ease;
        }

        .overlay-drawer.open {
            opacity: 1; pointer-events: auto;
        }

        .side-drawer {
            position: fixed;
            top: 20px; right: -420px;
            width: 400px;
            height: calc(100% - 40px);
            background: rgba(255,255,255,0.85);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid var(--glass-border);
            border-radius: 20px 0 0 20px;
            box-shadow: -10px 0 40px rgba(15, 23, 42, 0.08);
            z-index: 101;
            padding: 30px;
            transition: right 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .side-drawer.open {
            right: 0;
        }

        /* Form Egresos Glass */
        .glass-form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
            margin-bottom: 18px;
        }

        .glass-label {
            font-size: 12px;
            font-weight: 600;
            color: #475569;
        }

        .glass-select {
            height: 46px;
            border-radius: 10px;
            border: 1px solid rgba(0,0,0,0.1);
            background: rgba(255,255,255,0.5);
            padding: 0 15px;
            font-size: 14px;
            outline: none;
        }

        .glass-select:focus {
            background: white;
            border-color: var(--accent);
        }

        .emergency-pill {
            background: white;
            border: 1px solid var(--glass-border);
            box-shadow: var(--glass-shadow);
            padding: 8px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
    </style>
</head>
<body>

    <!-- Wait Clock Loader -->
    <div id="loader-overlay">
        <div class="spinner"></div>
        <div class="loader-text">CARGANDO SERVICIOS...</div>
    </div>

    <!-- Header Glass with Horizontal Nav -->
    <header>
        <div class="brand-section">
            <div class="brand-icon">
                <svg viewBox="0 0 24 24"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
            </div>
            <div class="brand-info">
                <h1>PORTAL GLASS TLAPA</h1>
                <p>Dirección de Agua Potable</p>
            </div>
        </div>

        <nav class="nav-horizontal">
            <a href="#" class="nav-link active" data-tab="dashboard" data-path="Inicio > Panel Principal">
                <svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></svg>
                Panel
            </a>
            <a href="#" class="nav-link" data-tab="usuarios" data-path="Inicio > Directorio > Ciudadanos">
                <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                Ciudadanos
            </a>
            <a href="#" class="nav-link" data-tab="contratos" data-path="Inicio > Servicios > Registro Contratos">
                <svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                Contratos
            </a>
            <a href="#" class="nav-link" data-tab="egresos" data-path="Inicio > Caja > Control de Egresos">
                <svg viewBox="0 0 24 24"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                Caja Egresos
            </a>
        </nav>

        <div class="profile-area">
            <div class="emergency-pill">
                <span style="color:#2563eb;">●</span> Emergencias: 757 146 5083
            </div>
            <div class="user-card">
                <div class="avatar"><?php echo strtoupper(substr($_SESSION['usuario']->getNombre(), 0, 2)); ?></div>
                <div class="user-name"><?php echo htmlspecialchars($_SESSION['usuario']->getNombre()); ?></div>
            </div>
            <button class="btn-exit" onclick="window.location='ruteador.php?opc=salir'" title="Salir">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            </button>
        </div>
    </header>

    <!-- Main Workspace -->
    <div class="workspace">
        <div class="breadcrumb" id="breadcrumb-box">
            <span>Inicio</span>
            <span>Panel Principal</span>
        </div>

        <!-- TAB 1: Panel -->
        <div class="tab-panel active" id="tab-dashboard">
            <div class="stat-grid">
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Ciudadanos registrados</div>
                        <div class="stat-val">1,409</div>
                    </div>
                    <div class="stat-circle blue">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                    </div>
                </div>
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Tomas de agua</div>
                        <div class="stat-val">1,372</div>
                    </div>
                    <div class="stat-circle green">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                    </div>
                </div>
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Suspensiones Temp.</div>
                        <div class="stat-val">28</div>
                    </div>
                    <div class="stat-circle yellow">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/></svg>
                    </div>
                </div>
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Bajas Definitivas</div>
                        <div class="stat-val">10</div>
                    </div>
                    <div class="stat-circle red">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/></svg>
                    </div>
                </div>
            </div>

            <div class="grid-split">
                <div class="glass-card">
                    <h3 style="margin-bottom:15px;">Monitor de Ingresos Diarios</h3>
                    <div style="height: 200px; background: rgba(255,255,255,0.4); border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size:12px; color:#64748b;">
                        [ Gráfico lineal de recaudación - Línea Base V4 ]
                    </div>
                </div>
                <div class="glass-card">
                    <h3 style="margin-bottom:15px;">Caja Rápida</h3>
                    <p style="font-size:13px; color:#64748b; margin-bottom:15px;">Ingresa el folio o número de contrato para procesar cobro rápido:</p>
                    <input type="text" class="input-text" placeholder="Contrato..." style="margin-bottom:10px; padding-left: 15px;">
                    <button class="btn-action" style="width: 100%;">Buscar Deuda</button>
                </div>
            </div>
        </div>

        <!-- TAB 2: Ciudadanos -->
        <div class="tab-panel" id="tab-usuarios">
            <div class="glass-card">
                <h2 style="font-family:'Outfit', sans-serif; font-size:22px; margin-bottom: 20px;">Directorio de Ciudadanos</h2>
                <div class="search-container">
                    <div class="search-box">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                        <input type="text" class="input-text" id="glass-search" placeholder="Escribe el nombre o calle para filtrar...">
                    </div>
                    <button class="btn-action">Agregar Ciudadano</button>
                </div>

                <table class="glass-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nombre Completo</th>
                            <th>Domicilio Localizado</th>
                            <th>Lada Local</th>
                            <th>Estado</th>
                            <th>Acción</th>
                        </tr>
                    </thead>
                    <tbody id="glass-table-body">
                        <tr class="glass-row" data-name="silvia aguirre cabrera" data-addr="constitucion n° 92">
                            <td>#1</td>
                            <td style="font-weight:600; text-transform:capitalize;">silvia aguirre cabrera</td>
                            <td style="text-transform:capitalize;">constitucion n° 92, col. centro</td>
                            <td>—</td>
                            <td><span class="status-badge active">Activo</span></td>
                            <td><button class="btn-action" style="height:32px; padding:0 12px; font-size:12px;" onclick="openGlassDrawer('Silvia Aguirre Cabrera', 'Constitucion n° 92, Centro', '—')">Ver Ficha</button></td>
                        </tr>
                        <tr class="glass-row" data-name="griselda antunez callejas" data-addr="josefa ortiz de dominguez n° 76">
                            <td>#7</td>
                            <td style="font-weight:600; text-transform:capitalize;">griselda antunez callejas</td>
                            <td style="text-transform:capitalize;">josefa ortiz de dominguez n° 76</td>
                            <td>757 556 7410</td>
                            <td><span class="status-badge active">Activo</span></td>
                            <td><button class="btn-action" style="height:32px; padding:0 12px; font-size:12px;" onclick="openGlassDrawer('Griselda Antunez Callejas', 'Josefa Ortiz de Dominguez n° 76', '757 556 7410')">Ver Ficha</button></td>
                        </tr>
                        <tr class="glass-row" data-name="angel arturo aparicio vazquez" data-addr="melchor ocampo n° 102">
                            <td>#8</td>
                            <td style="font-weight:600; text-transform:capitalize;">angel arturo aparicio vazquez</td>
                            <td style="text-transform:capitalize;">melchor ocampo n° 102</td>
                            <td>757 532 2099</td>
                            <td><span class="status-badge lila">Sin Contratos</span></td>
                            <td><button class="btn-action" style="height:32px; padding:0 12px; font-size:12px;" onclick="openGlassDrawer('Angel Arturo Aparicio Vazquez', 'Melchor Ocampo n° 102', '757 532 2099')">Ver Ficha</button></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- TAB 3: Contratos -->
        <div class="tab-panel" id="tab-contratos">
            <div class="glass-card">
                <h2 style="font-family:'Outfit', sans-serif; font-size:22px; margin-bottom: 20px;">Catálogo de Contratos</h2>
                <table class="glass-table">
                    <thead>
                        <tr>
                            <th>Contrato</th>
                            <th>Propietario</th>
                            <th>Domicilio de la Toma</th>
                            <th>Servicio</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td style="font-weight:700; color:var(--accent);">#391</td>
                            <td>Zenón Martínez López</td>
                            <td>Hidalgo n° 34, Centro</td>
                            <td>Agua/Drenaje</td>
                            <td><span class="status-badge active">Activo</span></td>
                        </tr>
                        <tr>
                            <td style="font-weight:700; color:var(--accent);">#1378</td>
                            <td>Zenón Martínez López</td>
                            <td>Comonfort n° 12, Centro</td>
                            <td>Agua</td>
                            <td><span class="status-badge active">Activo</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- TAB 4: Egresos -->
        <div class="tab-panel" id="tab-egresos">
            <div class="glass-card" style="max-width: 600px; margin: 0 auto;">
                <h2 style="font-family:'Outfit', sans-serif; font-size:20px; margin-bottom: 20px; text-align:center;">Registrar Egreso de Caja</h2>
                <form onsubmit="alert('Egreso Registrado en la plantilla Glass'); return false;">
                    <div class="glass-form-group">
                        <label class="glass-label">Folio Comprobante</label>
                        <input type="text" class="input-text" required style="padding-left:15px;" placeholder="Folio...">
                    </div>
                    <div class="glass-form-group">
                        <label class="glass-label">Monto ($ MXN)</label>
                        <input type="number" step="0.01" class="input-text" required style="padding-left:15px;" placeholder="0.00">
                    </div>
                    <div class="glass-form-group">
                        <label class="glass-label">Proveedor / Beneficiario</label>
                        <input type="text" class="input-text" required style="padding-left:15px;" placeholder="Beneficiario...">
                    </div>
                    <div class="glass-form-group">
                        <label class="glass-label">Concepto General</label>
                        <select class="glass-select">
                            <option>COMPRA DE MATERIAL</option>
                            <option>PAGO DE ENERGÍA (CFE)</option>
                            <option>MANUFACTURA Y MANTENIMIENTO</option>
                        </select>
                    </div>
                    <button type="submit" class="btn-action" style="width:100%; margin-top:10px;">Registrar e Imprimir</button>
                </form>
            </div>
        </div>
    </div>

    <!-- Glass Side Drawer -->
    <div class="overlay-drawer" id="glass-overlay" onclick="closeGlassDrawer()"></div>
    <div class="side-drawer" id="glass-drawer">
        <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid rgba(0,0,0,0.06); padding-bottom:15px; margin-bottom:20px;">
            <h3 style="font-family:'Outfit', sans-serif;">Ficha de Ciudadano</h3>
            <button onclick="closeGlassDrawer()" style="background:none; border:none; cursor:pointer; font-size:16px;">✕</button>
        </div>
        <div id="glass-drawer-content"></div>
    </div>

    <script>
        // Tab routing with loader
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                const tab = this.getAttribute('data-tab');
                const path = this.getAttribute('data-path');
                
                const loader = document.getElementById('loader-overlay');
                loader.classList.add('active');
                
                setTimeout(() => {
                    document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
                    this.classList.add('active');
                    
                    document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.remove('active'));
                    document.getElementById(`tab-${tab}`).classList.add('active');
                    
                    // Update breadcrumbs
                    const crumbs = path.split(' > ').map(p => `<span>${p}</span>`).join('');
                    document.getElementById('breadcrumb-box').innerHTML = crumbs;
                    
                    loader.classList.remove('active');
                }, 350);
            });
        });

        // Search filtering
        document.getElementById('glass-search').addEventListener('input', function() {
            const query = this.value.toLowerCase().trim();
            document.querySelectorAll('.glass-row').forEach(row => {
                const name = row.getAttribute('data-name');
                const addr = row.getAttribute('data-addr');
                if (name.includes(query) || addr.includes(query)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });

        // Drawer
        function openGlassDrawer(name, address, phone) {
            const content = document.getElementById('glass-drawer-content');
            content.innerHTML = `
                <div style="text-align:center; margin-bottom:20px;">
                    <div style="width:60px; height:60px; border-radius:50%; background:linear-gradient(135deg, #2563eb, #8b5cf6); color:white; display:flex; align-items:center; justify-content:center; font-size:20px; font-weight:700; margin:0 auto 10px;">
                        ${name.substring(0,2).toUpperCase()}
                    </div>
                    <h4 style="font-family:'Outfit', sans-serif; text-transform:capitalize; font-size:16px;">${name}</h4>
                </div>
                <div style="display:flex; flex-direction:column; gap:15px; font-size:13px;">
                    <div>
                        <span style="color:#64748b; display:block; font-size:11px; text-transform:uppercase;">Dirección Localizada</span>
                        <strong style="text-transform:capitalize;">${address}, Tlapa de Comonfort, Gro.</strong>
                    </div>
                    <div>
                        <span style="color:#64748b; display:block; font-size:11px; text-transform:uppercase;">Teléfono (Tlapa)</span>
                        <strong>${phone}</strong>
                    </div>
                </div>
                <button class="btn-action" style="width:100%; margin-top:30px;" onclick="alert('Modificar ciudadano')">Editar Perfil</button>
            `;
            document.getElementById('glass-overlay').classList.add('open');
            document.getElementById('glass-drawer').classList.add('open');
        }

        function closeGlassDrawer() {
            document.getElementById('glass-overlay').classList.remove('open');
            document.getElementById('glass-drawer').classList.remove('open');
        }
    </script>
</body>
</html>

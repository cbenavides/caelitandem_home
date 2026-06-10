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
    <title>SADM Tlapa - Panel de Gestión V4.1.0</title>
    
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- Stylesheet -->
    <style>
        :root {
            --primary: #002f6c; /* SADM Dark Blue */
            --primary-light: #0d4a8e;
            --accent: #00b2a9;  /* SADM Turquoise */
            --accent-hover: #008f88;
            --bg-main: #f4f6fa;
            --bg-sidebar: #0b1f3b; /* Dark Navy Sidebar */
            --text-dark: #2d3748;
            --text-light: #718096;
            --white: #ffffff;
            --card-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
            --border-radius: 12px;
            --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            
            /* Status Colors */
            --state-active: #10b981;
            --state-suspended-temp: #f59e0b;
            --state-suspended-adm: #ef4444;
            --state-suspended-def: #374151;
            --state-lila: #d8b4fe;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
            -webkit-font-smoothing: antialiased;
        }

        body {
            background-color: var(--bg-main);
            color: var(--text-dark);
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
            background: rgba(11, 31, 59, 0.7);
            backdrop-filter: blur(4px);
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
            width: 60px;
            height: 60px;
            border: 5px solid rgba(255, 255, 255, 0.1);
            border-top-color: var(--accent);
            border-radius: 50%;
            animation: spin 1s infinite linear;
        }

        .loader-text {
            color: var(--white);
            margin-top: 20px;
            font-weight: 500;
            font-size: 16px;
            letter-spacing: 0.05em;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Sidebar Styling */
        aside {
            width: 280px;
            background-color: var(--bg-sidebar);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 30px 20px;
            color: var(--white);
            z-index: 100;
            transition: var(--transition);
        }

        .sidebar-brand {
            display: flex;
            align-items: center;
            gap: 12px;
            padding-bottom: 30px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }

        .sidebar-brand svg {
            fill: var(--accent);
            width: 32px;
            height: 32px;
        }

        .brand-text h1 {
            font-size: 18px;
            font-weight: 700;
            letter-spacing: -0.02em;
            background: linear-gradient(135deg, var(--white) 30%, var(--accent));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .brand-text p {
            font-size: 10px;
            color: var(--text-light);
            text-transform: uppercase;
            letter-spacing: 0.1em;
            margin-top: 2px;
        }

        .sidebar-menu {
            list-style: none;
            margin-top: 30px;
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .menu-item a {
            display: flex;
            align-items: center;
            gap: 15px;
            color: rgba(255, 255, 255, 0.7);
            text-decoration: none;
            padding: 12px 16px;
            border-radius: var(--border-radius);
            font-weight: 500;
            font-size: 14px;
            transition: var(--transition);
        }

        .menu-item a:hover {
            color: var(--white);
            background: rgba(255, 255, 255, 0.05);
        }

        .menu-item.active a {
            color: var(--white);
            background: var(--primary-light);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            position: relative;
        }

        .menu-item.active a::before {
            content: '';
            position: absolute;
            left: 0;
            top: 25%;
            height: 50%;
            width: 4px;
            background-color: var(--accent);
            border-radius: 0 4px 4px 0;
        }

        .menu-item svg {
            width: 20px;
            height: 20px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        .sidebar-footer {
            padding-top: 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background-color: var(--accent);
            color: var(--white);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: 14px;
            box-shadow: 0 2px 10px rgba(0, 178, 169, 0.3);
        }

        .user-details h4 {
            font-size: 13px;
            font-weight: 600;
        }

        .user-details p {
            font-size: 11px;
            color: var(--text-light);
        }

        .btn-logout {
            color: rgba(255, 255, 255, 0.5);
            background: none;
            border: none;
            cursor: pointer;
            transition: var(--transition);
        }

        .btn-logout:hover {
            color: #ef4444;
        }

        /* Main Workspace Panel */
        main {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            height: 100vh;
            overflow: hidden;
        }

        /* Top Header Styling */
        header {
            background-color: var(--white);
            height: 80px;
            padding: 0 40px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid #e2e8f0;
            z-index: 10;
        }

        .breadcrumb-container {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .breadcrumb-path {
            font-size: 12px;
            color: var(--text-light);
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .breadcrumb-path span:not(:last-child)::after {
            content: '/';
            margin-left: 6px;
            color: #cbd5e0;
        }

        .breadcrumb-current {
            font-size: 20px;
            font-weight: 700;
            color: var(--primary);
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 20px;
        }

        .emergency-badge {
            background-color: rgba(0, 178, 169, 0.1);
            color: var(--accent-hover);
            font-size: 12px;
            font-weight: 600;
            padding: 8px 16px;
            border-radius: 30px;
            display: flex;
            align-items: center;
            gap: 8px;
            border: 1px solid rgba(0, 178, 169, 0.2);
        }

        .version-badge {
            background-color: var(--bg-main);
            font-size: 11px;
            color: var(--text-light);
            padding: 6px 12px;
            border-radius: 6px;
            font-weight: 600;
        }

        /* Dashboard Container */
        .workspace-content {
            padding: 40px;
            overflow-y: auto;
            flex-grow: 1;
        }

        /* Tabs Container */
        .tab-panel {
            display: none;
            animation: fadeIn 0.4s ease forwards;
        }

        .tab-panel.active {
            display: block;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(8px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Dashboard View Layout */
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 24px;
            margin-bottom: 30px;
        }

        .stat-card {
            background-color: var(--white);
            padding: 24px;
            border-radius: var(--border-radius);
            box-shadow: var(--card-shadow);
            border: 1px solid #edf2f7;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: var(--transition);
        }

        .stat-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
        }

        .stat-details h3 {
            font-size: 13px;
            color: var(--text-light);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 6px;
        }

        .stat-details p {
            font-size: 26px;
            font-weight: 700;
            color: var(--primary);
        }

        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: var(--border-radius);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .stat-icon.blue { background-color: rgba(0, 47, 108, 0.1); color: var(--primary); }
        .stat-icon.teal { background-color: rgba(0, 178, 169, 0.1); color: var(--accent); }
        .stat-icon.orange { background-color: rgba(245, 158, 11, 0.1); color: var(--state-suspended-temp); }
        .stat-icon.red { background-color: rgba(239, 68, 68, 0.1); color: var(--state-suspended-adm); }

        .stat-icon svg { width: 24px; height: 24px; stroke: currentColor; fill: none; stroke-width: 2; }

        /* Secondary Grid */
        .content-split-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 24px;
        }

        .card {
            background-color: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--card-shadow);
            border: 1px solid #edf2f7;
            padding: 30px;
            margin-bottom: 24px;
        }

        .card-title {
            font-size: 16px;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        /* Search Layout */
        .search-wrapper {
            display: flex;
            gap: 12px;
            margin-bottom: 24px;
        }

        .search-input-group {
            position: relative;
            flex-grow: 1;
        }

        .search-input-group svg {
            position: absolute;
            left: 16px;
            top: 50%;
            transform: translateY(-50%);
            width: 20px;
            height: 20px;
            color: var(--text-light);
            pointer-events: none;
        }

        .form-control {
            width: 100%;
            height: 48px;
            padding: 10px 16px 10px 48px;
            border: 1.5px solid #e2e8f0;
            border-radius: 8px;
            font-size: 14px;
            color: var(--text-dark);
            background-color: #fafbfe;
            transition: var(--transition);
        }

        .form-control:focus {
            outline: none;
            border-color: var(--accent);
            background-color: var(--white);
            box-shadow: 0 0 0 3px rgba(0, 178, 169, 0.15);
        }

        .btn {
            height: 48px;
            padding: 0 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            border: none;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: var(--transition);
        }

        .btn-primary {
            background-color: var(--accent);
            color: var(--white);
        }

        .btn-primary:hover {
            background-color: var(--accent-hover);
        }

        /* Modern Table Style */
        .table-responsive {
            width: 100%;
            overflow-x: auto;
        }

        .modern-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        .modern-table th {
            padding: 14px 18px;
            font-size: 12px;
            font-weight: 700;
            color: var(--text-light);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            background-color: #fafbfe;
            border-bottom: 2px solid #edf2f7;
        }

        .modern-table td {
            padding: 16px 18px;
            font-size: 14px;
            color: var(--text-dark);
            border-bottom: 1px solid #edf2f7;
            vertical-align: middle;
        }

        .modern-table tr:hover td {
            background-color: #f8fafc;
        }

        /* State Badges */
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 12px;
            border-radius: 30px;
            font-size: 12px;
            font-weight: 600;
        }

        .badge-active { background-color: rgba(16, 185, 129, 0.1); color: #047857; }
        .badge-suspended-temp { background-color: rgba(245, 158, 11, 0.1); color: #d97706; }
        .badge-suspended-def { background-color: rgba(55, 65, 81, 0.1); color: #374151; }
        .badge-lila { background-color: rgba(216, 180, 254, 0.2); color: #7c3aed; }

        /* Floating Drawer Detail Panel */
        .drawer-overlay {
            position: fixed;
            top: 0;
            right: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.3);
            z-index: 200;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.3s ease;
        }

        .drawer-overlay.open {
            opacity: 1;
            pointer-events: auto;
        }

        .drawer {
            position: fixed;
            top: 0;
            right: -450px;
            width: 450px;
            height: 100%;
            background: var(--white);
            box-shadow: -4px 0 30px rgba(0, 0, 0, 0.15);
            z-index: 201;
            padding: 40px 30px;
            overflow-y: auto;
            transition: right 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .drawer.open {
            right: 0;
        }

        .drawer-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-bottom: 20px;
            border-bottom: 1px solid #edf2f7;
            margin-bottom: 24px;
        }

        .drawer-title {
            font-size: 18px;
            font-weight: 700;
            color: var(--primary);
        }

        .btn-close-drawer {
            background: none;
            border: none;
            cursor: pointer;
            color: var(--text-light);
            transition: var(--transition);
        }

        .btn-close-drawer:hover {
            color: var(--text-dark);
        }

        /* Detail lists */
        .detail-group {
            margin-bottom: 20px;
        }

        .detail-label {
            font-size: 11px;
            color: var(--text-light);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 4px;
        }

        .detail-value {
            font-size: 14px;
            font-weight: 500;
            color: var(--text-dark);
        }

        /* Egresos Form Layout */
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
            margin-bottom: 20px;
        }

        .form-label {
            font-size: 13px;
            font-weight: 600;
            color: var(--primary);
        }

        .form-textarea {
            width: 100%;
            height: 100px;
            padding: 12px;
            border: 1.5px solid #e2e8f0;
            border-radius: 8px;
            font-size: 14px;
            resize: none;
            transition: var(--transition);
            background-color: #fafbfe;
        }

        .form-textarea:focus {
            outline: none;
            border-color: var(--accent);
            background-color: var(--white);
            box-shadow: 0 0 0 3px rgba(0, 178, 169, 0.15);
        }

        .form-select {
            height: 48px;
            padding: 10px 16px;
            border: 1.5px solid #e2e8f0;
            border-radius: 8px;
            font-size: 14px;
            background-color: #fafbfe;
            outline: none;
            transition: var(--transition);
        }

        .form-select:focus {
            border-color: var(--accent);
            background-color: var(--white);
        }

        /* Footer emergency details */
        .footer-brand {
            margin-top: 40px;
            text-align: center;
            font-size: 11px;
            color: var(--text-light);
            line-height: 1.6;
        }
    </style>
</head>
<body>

    <!-- Loading overlay (Reloj de espera) -->
    <div id="loader-overlay">
        <div class="spinner"></div>
        <div class="loader-text">CARGANDO MÓDULO...</div>
    </div>

    <!-- Sidebar Navigation -->
    <aside>
        <div class="sidebar-brand">
            <!-- Drop SVG Icon -->
            <svg viewBox="0 0 24 24">
                <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
            </svg>
            <div class="brand-text">
                <h1>SADM TLAPA</h1>
                <p>Agua y Drenaje</p>
            </div>
        </div>

        <ul class="sidebar-menu">
            <li class="menu-item active" data-tab="dashboard" data-path="Inicio > Panel de Control">
                <a href="#">
                    <svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></svg>
                    Panel General
                </a>
            </li>
            <li class="menu-item" data-tab="usuarios" data-path="Inicio > Catálogos > Usuarios">
                <a href="#">
                    <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                    Usuarios (Localizados)
                </a>
            </li>
            <li class="menu-item" data-tab="contratos" data-path="Inicio > Servicios > Contratos">
                <a href="#">
                    <svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                    Contratos
                </a>
            </li>
            <li class="menu-item" data-tab="egresos" data-path="Inicio > Finanzas > Registro de Egresos">
                <a href="#">
                    <svg viewBox="0 0 24 24"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                    Egresos
                </a>
            </li>
        </ul>

        <div class="sidebar-footer">
            <div class="user-info">
                <div class="user-avatar">
                    <?php echo strtoupper(substr($_SESSION['usuario']->getNombre(), 0, 2)); ?>
                </div>
                <div class="user-details">
                    <h4><?php echo htmlspecialchars($_SESSION['usuario']->getNombre()); ?></h4>
                    <p>Administrador</p>
                </div>
            </div>
            <button class="btn-logout" onclick="window.location='ruteador.php?opc=salir'" title="Cerrar Sesión">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            </button>
        </div>
    </aside>

    <!-- Main Content Workspace -->
    <main>
        <!-- Header -->
        <header>
            <div class="breadcrumb-container">
                <div class="breadcrumb-path" id="breadcrumb-path">
                    <span>Inicio</span>
                    <span>Panel de Control</span>
                </div>
                <div class="breadcrumb-current" id="breadcrumb-title">Panel General</div>
            </div>

            <div class="header-actions">
                <div class="emergency-badge">
                    <!-- Phone Icon SVG -->
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
                    Emergencias: 757 146 5083
                </div>
                <div class="version-badge">V4.1.0</div>
            </div>
        </header>

        <!-- Workspace Dynamic Tabs Content -->
        <div class="workspace-content">

            <!-- TAB 1: Panel General / Dashboard -->
            <div class="tab-panel active" id="tab-dashboard">
                <!-- Grid Cards Statistics -->
                <div class="dashboard-grid">
                    <div class="stat-card">
                        <div class="stat-details">
                            <h3>Usuarios Totales</h3>
                            <p>1,409</p>
                        </div>
                        <div class="stat-icon blue">
                            <svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-details">
                            <h3>Contratos Activos</h3>
                            <p>1,372</p>
                        </div>
                        <div class="stat-icon teal">
                            <svg viewBox="0 0 24 24"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-details">
                            <h3>Suspensión Temporal</h3>
                            <p>28</p>
                        </div>
                        <div class="stat-icon orange">
                            <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-details">
                            <h3>Suspensión Definitiva</h3>
                            <p>10</p>
                        </div>
                        <div class="stat-icon red">
                            <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
                        </div>
                    </div>
                </div>

                <div class="content-split-grid">
                    <div class="card">
                        <div class="card-title">Resumen de Recaudación Anual</div>
                        <div style="height: 250px; background: linear-gradient(135deg, #f4f6fa, #e2e8f0); border-radius: 8px; display: flex; align-items: center; justify-content: center; color: var(--text-light); font-size: 13px;">
                            [ Gráfico modernizado de recaudación del ciclo actual ]
                        </div>
                    </div>
                    
                    <div class="card">
                        <div class="card-title">Actividad Reciente</div>
                        <div style="display: flex; flex-direction: column; gap: 12px;">
                            <div style="padding: 10px; border-left: 3px solid var(--accent); background-color: #f7fafc; border-radius: 0 6px 6px 0;">
                                <p style="font-size: 12px; font-weight: 600;">Pago de Contrato #391</p>
                                <p style="font-size: 11px; color: var(--text-light);">Cajero: admin • Hace 5 min</p>
                            </div>
                            <div style="padding: 10px; border-left: 3px solid var(--state-active); background-color: #f7fafc; border-radius: 0 6px 6px 0;">
                                <p style="font-size: 12px; font-weight: 600;">Reconexión Contrato #12</p>
                                <p style="font-size: 11px; color: var(--text-light);">Cajero: admin • Hace 20 min</p>
                            </div>
                            <div style="padding: 10px; border-left: 3px solid var(--state-suspended-adm); background-color: #f7fafc; border-radius: 0 6px 6px 0;">
                                <p style="font-size: 12px; font-weight: 600;">Suspensión Contrato #1405</p>
                                <p style="font-size: 11px; color: var(--text-light);">Cajero: admin • Hace 1 hora</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TAB 2: Usuarios Listados / Buscador -->
            <div class="tab-panel" id="tab-usuarios">
                <div class="card">
                    <div class="card-title">Directorio de Ciudadanos de Tlapa de Comonfort</div>
                    <div class="search-wrapper">
                        <div class="search-input-group">
                            <!-- Search Icon -->
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                            <input type="text" class="form-control" id="search-user" placeholder="Buscar por nombre o calle en Tlapa...">
                        </div>
                        <button class="btn btn-primary">Nuevo Usuario</button>
                    </div>

                    <div class="table-responsive">
                        <table class="modern-table">
                            <thead>
                                <tr>
                                    <th>Folio</th>
                                    <th>Nombre (Anonimizado)</th>
                                    <th>Dirección Localizada (Tlapa)</th>
                                    <th>Teléfono (Lada 757)</th>
                                    <th>Estado</th>
                                    <th>Acción</th>
                                </tr>
                            </thead>
                            <tbody id="user-table-body">
                                <tr class="user-row" data-id="1" data-name="silvia aguirre cabrera" data-addr="constitucion n° 92" data-phone="No registrado" data-state="Activo">
                                    <td>#1</td>
                                    <td style="font-weight: 600; text-transform: capitalize;">silvia aguirre cabrera</td>
                                    <td style="text-transform: capitalize;">constitucion n° 92, col. centro</td>
                                    <td>—</td>
                                    <td><span class="badge badge-active">Activo</span></td>
                                    <td><button class="btn btn-primary" style="height:32px; padding:0 12px; font-size:12px;" onclick="openDetailDrawer(1)">Ver Ficha</button></td>
                                </tr>
                                <tr class="user-row" data-id="7" data-name="griselda antunez callejas" data-addr="josefa ortiz de dominguez n° 76" data-phone="*757 556 7410" data-state="Activo">
                                    <td>#7</td>
                                    <td style="font-weight: 600; text-transform: capitalize;">griselda antunez callejas</td>
                                    <td style="text-transform: capitalize;">josefa ortiz de dominguez n° 76</td>
                                    <td>*757 556 7410</td>
                                    <td><span class="badge badge-active">Activo</span></td>
                                    <td><button class="btn btn-primary" style="height:32px; padding:0 12px; font-size:12px;" onclick="openDetailDrawer(7)">Ver Ficha</button></td>
                                </tr>
                                <tr class="user-row" data-id="8" data-name="angel arturo aparicio vazquez" data-addr="melchor ocampo n° 102" data-phone="757 532 2099" data-state="Lila">
                                    <td>#8</td>
                                    <td style="font-weight: 600; text-transform: capitalize;">angel arturo aparicio vazquez</td>
                                    <td style="text-transform: capitalize;">melchor ocampo n° 102</td>
                                    <td>757 532 2099</td>
                                    <td><span class="badge badge-lila">Sin Contratos</span></td>
                                    <td><button class="btn btn-primary" style="height:32px; padding:0 12px; font-size:12px;" onclick="openDetailDrawer(8)">Ver Ficha</button></td>
                                </tr>
                                <tr class="user-row" data-id="1057" data-name="zenón martínez lópez (duplicado)" data-addr="hidalgo n° 34" data-phone="—" data-state="Suspendido Temporal">
                                    <td>#1057</td>
                                    <td style="font-weight: 600; text-transform: capitalize;">zenón martínez lópez</td>
                                    <td style="text-transform: capitalize;">hidalgo n° 34</td>
                                    <td>—</td>
                                    <td><span class="badge badge-suspended-temp">Duplicado</span></td>
                                    <td><button class="btn btn-primary" style="height:32px; padding:0 12px; font-size:12px;" onclick="openDetailDrawer(1057)">Ver Ficha</button></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- TAB 3: Contratos -->
            <div class="tab-panel" id="tab-contratos">
                <div class="card">
                    <div class="card-title">Buscador y Monitor de Contratos de Agua/Drenaje</div>
                    <div class="search-wrapper">
                        <div class="search-input-group">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                            <input type="text" class="form-control" placeholder="Escribe el número de contrato o usuario...">
                        </div>
                        <button class="btn btn-primary">Nuevo Contrato</button>
                    </div>

                    <div class="table-responsive">
                        <table class="modern-table">
                            <thead>
                                <tr>
                                    <th>No. Contrato</th>
                                    <th>Propietario</th>
                                    <th>Domicilio de la Toma</th>
                                    <th>Tomas</th>
                                    <th>Estado</th>
                                    <th>Acción</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td style="font-weight: 700; color: var(--primary);">#391</td>
                                    <td>Zenón Martínez López</td>
                                    <td>Hidalgo n° 34, Centro</td>
                                    <td>1 toma (Agua/Drenaje)</td>
                                    <td><span class="badge badge-active">Activo</span></td>
                                    <td><button class="btn btn-primary" style="height:32px; padding:0 12px; font-size:12px;">Cobrar / Ver</button></td>
                                </tr>
                                <tr>
                                    <td style="font-weight: 700; color: var(--primary);">#1378</td>
                                    <td>Zenón Martínez López</td>
                                    <td>Comonfort n° 12, Centro</td>
                                    <td>1 toma (Agua)</td>
                                    <td><span class="badge badge-active">Activo</span></td>
                                    <td><button class="btn btn-primary" style="height:32px; padding:0 12px; font-size:12px;">Cobrar / Ver</button></td>
                                </tr>
                                <tr>
                                    <td style="font-weight: 700; color: var(--primary);">#12</td>
                                    <td>Laura Avila Marquez</td>
                                    <td>Constitucion n° 33</td>
                                    <td>1 toma (Agua/Drenaje)</td>
                                    <td><span class="badge badge-suspended-temp">Suspensión Temp.</span></td>
                                    <td><button class="btn btn-primary" style="height:32px; padding:0 12px; font-size:12px;">Cobrar / Ver</button></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- TAB 4: Egresos -->
            <div class="tab-panel" id="tab-egresos">
                <div class="card" style="max-width: 800px; margin: 0 auto;">
                    <div class="card-title">Registro de Salidas de Caja (Egresos)</div>
                    <form onsubmit="alert('Egreso Registrado!'); return false;">
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label" for="egreso-folio">Folio del Recibo/Comprobante</label>
                                <input type="text" class="form-control" id="egreso-folio" placeholder="Ej. A-1502" required style="padding-left:16px;">
                            </div>
                            <div class="form-group">
                                <label class="form-label" for="egreso-monto">Monto ($ MXN)</label>
                                <input type="number" step="0.01" class="form-control" id="egreso-monto" placeholder="0.00" required style="padding-left:16px;">
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="egreso-proveedor">Entregado a / Beneficiario</label>
                            <input type="text" class="form-control" id="egreso-proveedor" placeholder="Nombre completo o Proveedor" required style="padding-left:16px;">
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="egreso-categoria">Concepto General (Categoría)</label>
                            <select class="form-select" id="egreso-categoria">
                                <option value="1">COMPRA DE MATERIAL</option>
                                <option value="2">PAGO DE ENERGÍA ELÉCTRICA (CFE)</option>
                                <option value="3">SUELDOS Y SALARIOS</option>
                                <option value="4">MANTENIMIENTO DE BOMBAS</option>
                                <option value="5">PAPELERÍA Y UTILERÍA</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="egreso-detalle">Detalle del Concepto</label>
                            <textarea class="form-textarea" id="egreso-detalle">RECIBÍ DE LA DIRECCIÓN DE AGUA POTABLE Y ALCANTARILLADO DE TLAPA DE COMONFORT LA CANTIDAD DE $... (PESOS .../100 M.N.) POR CONCEPTO DE: </textarea>
                        </div>

                        <div style="text-align: right; margin-top: 10px;">
                            <button type="submit" class="btn btn-primary">Registrar e Imprimir Comprobante</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Footer Emergency Info -->
            <div class="footer-brand">
                Dirección de Agua Potable y Alcantarillado • Tlapa de Comonfort, Guerrero.<br>
                Instancia de Desarrollo y Pruebas (Aislada: <b>ayd-os</b>) • Soporte e Incidencias: <b>757 146 5083</b>
            </div>
        </div>
    </main>

    <!-- Drawer Panel for details (Ficha) -->
    <div class="drawer-overlay" id="drawer-overlay" onclick="closeDetailDrawer()"></div>
    <div class="drawer" id="detail-drawer">
        <div class="drawer-header">
            <div class="drawer-title">Detalle del Usuario</div>
            <button class="btn-close-drawer" onclick="closeDetailDrawer()">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
        </div>
        
        <div id="drawer-content">
            <!-- Dynamic Content -->
        </div>
    </div>

    <!-- Scripting for Mock Navigation & Drawer -->
    <script>
        // Tab switching logic with wait clock (Loader)
        document.querySelectorAll('.menu-item').forEach(item => {
            item.addEventListener('click', function(e) {
                e.preventDefault();
                
                const targetTab = this.getAttribute('data-tab');
                const pathText = this.getAttribute('data-path');
                const titleText = this.querySelector('a').innerText.trim();
                
                // 1. Show Wait Clock (Reloj de espera)
                const loader = document.getElementById('loader-overlay');
                loader.classList.add('active');
                
                setTimeout(() => {
                    // 2. Switch Active classes
                    document.querySelectorAll('.menu-item').forEach(i => i.classList.remove('active'));
                    this.classList.add('active');
                    
                    document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.remove('active'));
                    document.getElementById(`tab-${targetTab}`).classList.add('active');
                    
                    // 3. Update breadcrumbs and header
                    document.getElementById('breadcrumb-title').innerText = titleText;
                    
                    const pathSpanHTML = pathText.split(' > ').map(p => `<span>${p}</span>`).join('');
                    document.getElementById('breadcrumb-path').innerHTML = pathSpanHTML;
                    
                    // 4. Hide Loader
                    loader.classList.remove('active');
                }, 400); // 400ms visual feedback
            });
        });

        // Search Filter for Users (Tab 2)
        document.getElementById('search-user').addEventListener('input', function() {
            const query = this.value.toLowerCase().trim();
            document.querySelectorAll('.user-row').forEach(row => {
                const name = row.getAttribute('data-name').toLowerCase();
                const addr = row.getAttribute('data-addr').toLowerCase();
                if (name.includes(query) || addr.includes(query)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });

        // Detail Drawer Functions
        function openDetailDrawer(userId) {
            const drawer = document.getElementById('detail-drawer');
            const overlay = document.getElementById('drawer-overlay');
            const content = document.getElementById('drawer-content');
            
            // Fetch row data
            const row = document.querySelector(`.user-row[data-id="${userId}"]`);
            const name = row.getAttribute('data-name');
            const addr = row.getAttribute('data-addr');
            const phone = row.getAttribute('data-phone');
            const state = row.getAttribute('data-state');
            
            let stateBadge = '';
            if (state === 'Activo') stateBadge = '<span class="badge badge-active">Activo</span>';
            else if (state === 'Lila') stateBadge = '<span class="badge badge-lila">Lila (Sin contratos)</span>';
            else stateBadge = '<span class="badge badge-suspended-temp">Duplicado</span>';

            content.innerHTML = `
                <div class="user-avatar" style="width: 70px; height: 70px; font-size: 24px; margin: 0 auto 20px;">
                    ${name.substring(0, 2).toUpperCase()}
                </div>
                <h3 style="text-align: center; font-size: 18px; margin-bottom: 24px; text-transform: capitalize; color: var(--primary);">${name}</h3>
                
                <div class="detail-group">
                    <div class="detail-label">Folio Consecutivo</div>
                    <div class="detail-value">#${userId}</div>
                </div>
                
                <div class="detail-group">
                    <div class="detail-label">Estado Administrativo</div>
                    <div class="detail-value">${stateBadge}</div>
                </div>

                <div class="detail-group">
                    <div class="detail-label">Domicilio Fiscal (Localizado)</div>
                    <div class="detail-value" style="text-transform: capitalize;">${addr}, Centro, Tlapa de Comonfort, Gro.</div>
                </div>

                <div class="detail-group">
                    <div class="detail-label">Teléfono de Contacto</div>
                    <div class="detail-value">${phone}</div>
                </div>

                <div class="detail-group">
                    <div class="detail-label">Contratos Asociados</div>
                    <div class="detail-value">
                        ${userId === 1057 ? '<span style="color:var(--text-light);">Duplicado de Zenón Martínez López (ID #1590)</span>' : '1 Contrato Activo (#391)'}
                    </div>
                </div>
                
                <div style="margin-top: 40px; display: flex; gap: 10px;">
                    <button class="btn btn-primary" style="flex-grow:1;" onclick="alert('Editar Usuario #${userId}')">Editar Datos</button>
                    <button class="btn" style="background:#e2e8f0; color:var(--text-dark);" onclick="closeDetailDrawer()">Cerrar</button>
                </div>
            `;
            
            overlay.classList.add('open');
            drawer.classList.add('open');
        }

        function closeDetailDrawer() {
            document.getElementById('detail-drawer').classList.remove('open');
            document.getElementById('drawer-overlay').classList.remove('open');
        }
    </script>
</body>
</html>

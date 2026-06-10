<?php
require_once('login/usuario.php');
session_start();
if (!isset($_SESSION['usuario'])) {
	print "<script>window.location='login/index.php'</script>";
	exit();
}
header('Content-Type: text/html; charset=UTF-8');

require_once('config/Conexion.php');
$con = new Conexion();
if (!$con->abrirConexion()) {
    die("Error: No se pudo conectar a la base de datos.");
}

// ----------------------------------------------------
// 1. DATA FOR DASHBOARD METRICS (DYNAMIC)
// ----------------------------------------------------
// Total citizens
$res_total_users = $con->q("SELECT COUNT(*) AS qty FROM usuario");
$row_total_users = $con->fetch_array($res_total_users);
$total_users_count = $row_total_users['qty'];

// Active contracts
$res_active_contracts = $con->q("SELECT COUNT(*) AS qty FROM contrato WHERE estado = 1");
$row_active_contracts = $con->fetch_array($res_active_contracts);
$active_contracts_count = $row_active_contracts['qty'];

// Suspended contracts (temp)
$res_susp_temp = $con->q("SELECT COUNT(*) AS qty FROM contrato WHERE estado = 2");
$row_susp_temp = $con->fetch_array($res_susp_temp);
$susp_temp_count = $row_susp_temp['qty'];

// Bajas definitivas (estado = 4)
$res_susp_def = $con->q("SELECT COUNT(*) AS qty FROM contrato WHERE estado = 4");
$row_susp_def = $con->fetch_array($res_susp_def);
$susp_def_count = $row_susp_def['qty'];


// ----------------------------------------------------
// 2. DATA FOR REPORT & CONTRACTS (from reports/reporte_contratos_toma.php)
// ----------------------------------------------------
$anio = isset($_GET['year']) ? intval($_GET['year']) : date('Y');
$where_anio = "";
if (isset($_GET['year'])) {
    $where_anio = " AND YEAR(c.fecha) = $anio ";
}

$tiposdeestado = array(
    1 => "Activo",
    2 => "Suspensión Temporal",
    3 => "Suspensión Administrativa",
    4 => "Suspensión Definitiva"
);

// Procesa el GROUP_CONCAT de tomas de un contrato
if (!function_exists('procesarTomas')) {
    function procesarTomas($tomas_info) {
        if (!$tomas_info) return array('texto' => 'Sin tomas', 'n_agua' => 0, 'n_drenaje' => 0, 'n_tomas' => 0, 'es_comercial' => false);

        $tomas = explode('|', $tomas_info);
        $partes = array();
        $n_agua = 0;
        $n_drenaje = 0;
        $n_tomas = 0;
        $es_comercial = false;

        foreach ($tomas as $t) {
            $d = explode(':', $t);
            if (count($d) < 4) continue;

            $num  = $d[0];
            $tipo = $d[1];
            $agua = $d[2];
            $dren = $d[3];

            $n_tomas++;
            if ($tipo == 1) $es_comercial = true;

            $s = array();
            if ($agua == 1) { $s[] = "Agua";    $n_agua++; }
            if ($dren == 1) { $s[] = "Drenaje"; $n_drenaje++; }

            if (!empty($s)) {
                $partes[] = "T1/T2 " . $num . " (" . ($tipo==1?'Com':'Norm') . "): " . implode("/", $s);
            }
        }

        return array(
            'texto'       => implode("<br>", $partes),
            'n_agua'      => $n_agua,
            'n_drenaje'   => $n_drenaje,
            'n_tomas'     => $n_tomas,
            'es_comercial'=> $es_comercial
        );
    }
}

// Un registro por contrato; agrupación por usuario se hace en PHP
$sql = "SELECT
            c.estado,
            c.numcontrato,
            c.fecha,
            c.domicilio,
            c.tipo as tipo_contrato,
            c.agua as cto_agua_count,
            c.drenaje as cto_drenaje_count,
            u.nombre AS usuario,
            u.noconsecutivo as id_usuario,
            GROUP_CONCAT(CONCAT(ct.num_toma,':',ct.tipo,':',ct.tiene_agua,':',ct.tiene_drenaje)
                ORDER BY ct.num_toma SEPARATOR '|') as tomas_info
        FROM contrato c
        JOIN usuario u ON c.numusuario = u.noconsecutivo
        LEFT JOIN contrato_toma ct ON c.numcontrato = ct.numcontrato
        WHERE 1=1 $where_anio
        GROUP BY c.numcontrato, c.estado, c.fecha, c.domicilio, c.tipo, c.agua, c.drenaje, u.nombre, u.noconsecutivo
        ORDER BY u.nombre, c.numcontrato";

$res = $con->q($sql);

$data    = array();
$totales = array(); // para resumen ejecutivo por estado

while ($row = $con->fetch_array($res)) {
    $est_id  = $row['estado'];
    $user_id = $row['id_usuario'];

    $info_tomas = procesarTomas($row['tomas_info']);

    if ($row['tipo_contrato'] == 1) {
        $tipo_label = 'Comercial';
    } else {
        $tipo_label = $info_tomas['es_comercial'] ? 'Comercial' : 'Normal';
    }

    // Acumular totales para resumen ejecutivo (por estado)
    if (!isset($totales[$est_id][$tipo_label]))    $totales[$est_id][$tipo_label] = 0;
    $totales[$est_id][$tipo_label]++;
    if (!isset($totales[$est_id]['_usuarios']))     $totales[$est_id]['_usuarios'] = array();
    $totales[$est_id]['_usuarios'][$user_id] = true;

    // Agrupar por usuario (sin importar estado)
    if (!isset($data[$user_id])) {
        $data[$user_id] = array(
            'nombre'    => $row['usuario'],
            'contratos' => array()
        );
    }

    $row['tipo']              = ($tipo_label == 'Comercial') ? 1 : 0;
    $row['tipo_texto']        = $tipo_label;
    $row['num_agua']          = $info_tomas['n_agua'];
    $row['num_drenaje']       = $info_tomas['n_drenaje'];
    $row['num_tomas']         = $info_tomas['n_tomas'];
    $row['toma_texto']        = $info_tomas['texto'];
    $row['cto_agua_count']    = intval($row['cto_agua_count']);
    $row['cto_drenaje_count'] = intval($row['cto_drenaje_count']);

    $data[$user_id]['contratos'][] = $row;
}

// Ordenar usuarios: más contratos primero, luego alfabético
uasort($data, function($a, $b) {
    $cA = count($a['contratos']);
    $cB = count($b['contratos']);
    if ($cA != $cB) return $cB - $cA;
    return strcmp($a['nombre'], $b['nombre']);
});

// Calcular max de contratos por usuario (para columnas de la tabla)
$max_ctos = 1;
foreach ($data as $user) {
    if (count($user['contratos']) > $max_ctos) $max_ctos = count($user['contratos']);
}


// ----------------------------------------------------
// 3. DATA FOR CITIZENS DIRECTORY (Dynamic and fully joined)
// ----------------------------------------------------
$sql_citizens = "SELECT 
                    u.noconsecutivo, 
                    u.nombre, 
                    u.domicilio, 
                    u.telefono, 
                    u.id_homonimo_padre, 
                    u.no_localizado, 
                    COUNT(c.numcontrato) as num_contratos 
                 FROM usuario u 
                 LEFT JOIN contrato c ON u.noconsecutivo = c.numusuario 
                 GROUP BY u.noconsecutivo 
                 ORDER BY u.nombre";
$res_citizens = $con->q($sql_citizens);
$citizens_list = array();
while($row_c = $con->fetch_array($res_citizens)) {
    $citizens_list[] = $row_c;
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SADM Tlapa - Portal Glass Premium V4.2.0</title>
    
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
            background: linear-gradient(135deg, #2563eb, #8b5cf6);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            box-shadow: 0 4px 15px rgba(37, 99, 235, 0.3);
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
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
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
            padding: 14px 16px;
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 700;
            color: #64748b;
            text-align: left;
            border-bottom: 2px solid rgba(0,0,0,0.06);
            background: rgba(255,255,255,0.4);
        }

        .glass-table td {
            padding: 16px 16px;
            font-size: 13.5px;
            border-bottom: 1px solid rgba(0,0,0,0.05);
            vertical-align: middle;
        }

        .glass-table tr:hover td {
            background: rgba(255,255,255,0.3);
        }

        /* Status Badge */
        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
        }

        .status-badge.active { background: rgba(16, 185, 129, 0.15); color: #047857; }
        .status-badge.lila { background: rgba(216, 180, 254, 0.35); color: #6d28d9; }
        .status-badge.suspended { background: rgba(245, 158, 11, 0.15); color: #b45309; }
        .status-badge.danger { background: rgba(239, 68, 68, 0.15); color: #b91c1c; }

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
            overflow-y: auto;
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
            transition: var(--transition);
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

        /* ----------------------------------------------------
        * MIGRATED REPORT & CONTRACT DETAILS STYLING
        * --------------------------------------------------- */
        .comercial-tag {
            background: rgba(239, 68, 68, 0.12);
            color: #b91c1c;
            font-weight: bold;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 12px;
            white-space: nowrap;
        }
        
        .normal-tag {
            background: rgba(16, 185, 129, 0.12);
            color: #047857;
            font-weight: bold;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 12px;
            white-space: nowrap;
        }

        .user-name-text {
            text-transform: uppercase;
            font-weight: 700;
            color: #1e293b;
            font-size: 13.5px;
        }

        .counter-badge {
            background: rgba(37, 99, 235, 0.1);
            color: var(--accent-hover);
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            white-space: nowrap;
        }

        .data-warn {
            background: rgba(245, 158, 11, 0.15);
            color: #b45309;
            font-size: 9px;
            font-weight: bold;
            padding: 2px 6px;
            border-radius: 8px;
            cursor: help;
            border: 1px dashed rgba(245,158,11,0.5);
            display: inline-flex;
            align-items: center;
            gap: 3px;
        }

        .cto-card {
            border: 1px solid rgba(255,255,255,0.5);
            border-radius: 12px;
            padding: 12px;
            background: rgba(255,255,255,0.45);
            backdrop-filter: blur(6px);
            -webkit-backdrop-filter: blur(6px);
            font-size: 12px;
            line-height: 1.5;
            box-shadow: 0 4px 12px rgba(0,0,0,0.01);
            transition: var(--transition);
            min-width: 200px;
        }

        .cto-card:hover {
            transform: translateY(-2px);
            background: rgba(255, 255, 255, 0.7);
            border-color: rgba(37, 99, 235, 0.2);
            box-shadow: 0 6px 18px rgba(0, 0, 0, 0.04);
        }

        .cto-header {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
            border-bottom: 1px solid rgba(0,0,0,0.05);
            padding-bottom: 7px;
            margin-bottom: 7px;
        }

        .cto-num {
            font-weight: 800;
            font-size: 13.5px;
            color: var(--primary);
            font-family: 'Outfit', sans-serif;
        }

        .cto-estado-1 {
            background: rgba(16, 185, 129, 0.12);
            color: #047857;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 8px;
            font-weight: bold;
            white-space: nowrap;
        }

        .cto-estado-2 {
            background: rgba(245, 158, 11, 0.12);
            color: #b45309;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 8px;
            font-weight: bold;
            white-space: nowrap;
        }

        .cto-estado-3 {
            background: rgba(249, 115, 22, 0.12);
            color: #c2410c;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 8px;
            font-weight: bold;
            white-space: nowrap;
        }

        .cto-estado-4 {
            background: rgba(239, 68, 68, 0.12);
            color: #b91c1c;
            font-size: 10px;
            padding: 2px 6px;
            border-radius: 8px;
            font-weight: bold;
            white-space: nowrap;
        }

        .cto-meta {
            color: #64748b;
            font-size: 11px;
            margin-top: 4px;
            display: flex;
            align-items: center;
            gap: 4px;
        }

        .cto-domicilio {
            color: #2563eb;
            font-size: 11px;
            margin-top: 4px;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 4px;
        }

        .cto-tomas {
            color: #334155;
            font-size: 11px;
            margin-top: 6px;
            border-top: 1px solid rgba(0,0,0,0.05);
            padding-top: 6px;
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .contract-cell {
            vertical-align: top;
            padding: 10px !important;
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
            <a href="#" class="nav-link" data-tab="contratos" data-path="Inicio > Reportes > Contratos y Tomas">
                <svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                Contratos y Tomas
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

        <!-- TAB 1: Panel (Dashboard) -->
        <div class="tab-panel active" id="tab-dashboard">
            <div class="stat-grid">
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Ciudadanos registrados</div>
                        <div class="stat-val"><?php echo number_format($total_users_count); ?></div>
                    </div>
                    <div class="stat-circle blue">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                    </div>
                </div>
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Contratos Activos</div>
                        <div class="stat-val"><?php echo number_format($active_contracts_count); ?></div>
                    </div>
                    <div class="stat-circle green">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                    </div>
                </div>
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Suspensiones Temp.</div>
                        <div class="stat-val"><?php echo number_format($susp_temp_count); ?></div>
                    </div>
                    <div class="stat-circle yellow">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/></svg>
                    </div>
                </div>
                <div class="glass-stat-card">
                    <div>
                        <div class="stat-title">Bajas Definitivas</div>
                        <div class="stat-val"><?php echo number_format($susp_def_count); ?></div>
                    </div>
                    <div class="stat-circle red">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/></svg>
                    </div>
                </div>
            </div>

            <div class="grid-split">
                <div class="glass-card">
                    <h3 style="margin-bottom:15px; font-family:'Outfit', sans-serif;">Monitor de Ingresos Diarios</h3>
                    <div style="height: 200px; background: rgba(255,255,255,0.4); border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size:12px; color:#64748b;">
                        [ Gráfico lineal de recaudación - Línea Base V4 ]
                    </div>
                </div>
                <div class="glass-card">
                    <h3 style="margin-bottom:15px; font-family:'Outfit', sans-serif;">Caja Rápida</h3>
                    <p style="font-size:13px; color:#64748b; margin-bottom:15px;">Ingresa el folio o número de contrato para procesar cobro rápido:</p>
                    <input type="text" class="input-text" placeholder="Contrato..." style="margin-bottom:10px; padding-left: 15px;">
                    <button class="btn-action" style="width: 100%;">Buscar Deuda</button>
                </div>
            </div>
        </div>

        <!-- TAB 2: Ciudadanos (Real Dynamic Database Data) -->
        <div class="tab-panel" id="tab-usuarios">
            <div class="glass-card">
                <h2 style="font-family:'Outfit', sans-serif; font-size:22px; margin-bottom: 20px;">Directorio de Ciudadanos</h2>
                <div class="search-container">
                    <div class="search-box">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                        <input type="text" class="input-text" id="glass-search" placeholder="Escribe el nombre o calle para filtrar...">
                    </div>
                    <button class="btn-action" onclick="alert('Funcionalidad de agregar ciudadano en el mockup real.')">Agregar Ciudadano</button>
                </div>

                <div style="overflow-x: auto; max-height: 500px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.05);">
                    <table class="glass-table">
                        <thead style="position: sticky; top: 0; z-index: 1;">
                            <tr>
                                <th width="80">ID</th>
                                <th>Nombre Completo</th>
                                <th>Domicilio Localizado</th>
                                <th>Teléfono (Tlapa)</th>
                                <th>Estado / Filtro</th>
                                <th>Acción</th>
                            </tr>
                        </thead>
                        <tbody id="glass-table-body">
                            <?php foreach($citizens_list as $citizen): 
                                $uid_c = $citizen['noconsecutivo'];
                                $uname_c = $citizen['nombre'];
                                $uaddr_c = $citizen['domicilio'];
                                $uphone_c = !empty($citizen['telefono']) ? $citizen['telefono'] : '—';
                                $ucontracts_c = $citizen['num_contratos'];
                                $uhomonim_c = $citizen['id_homonimo_padre'];
                                $unoloc_c = $citizen['no_localizado'];

                                // Determine state badge
                                if ($unoloc_c == 1) {
                                    $badge_class = "suspended";
                                    $badge_text = "No Localizado";
                                } elseif ($ucontracts_c == 0) {
                                    $badge_class = "lila";
                                    $badge_text = "Sin Contratos";
                                } elseif ($uhomonim_c > 0) {
                                    $badge_class = "danger";
                                    $badge_text = "Homónimo (Duplicado)";
                                } else {
                                    $badge_class = "active";
                                    $badge_text = "Activo";
                                }
                            ?>
                            <tr class="glass-row" data-name="<?php echo htmlspecialchars(strtolower($uname_c)); ?>" data-addr="<?php echo htmlspecialchars(strtolower($uaddr_c)); ?>">
                                <td style="font-weight:600; color:var(--accent);">#<?php echo $uid_c; ?></td>
                                <td style="font-weight:600; text-transform:uppercase;"><?php echo htmlspecialchars($uname_c); ?></td>
                                <td style="text-transform:uppercase; color:#475569;"><?php echo htmlspecialchars($uaddr_c); ?></td>
                                <td><?php echo htmlspecialchars($uphone_c); ?></td>
                                <td><span class="status-badge <?php echo $badge_class; ?>"><?php echo $badge_text; ?></span></td>
                                <td>
                                    <button class="btn-action" style="height:32px; padding:0 12px; font-size:12px; border-radius:6px;" 
                                            onclick="openGlassDrawer('<?php echo addslashes($uname_c); ?>', '<?php echo addslashes($uaddr_c); ?>', '<?php echo addslashes($uphone_c); ?>', '<?php echo $ucontracts_c; ?>', '<?php echo $uhomonim_c; ?>', '<?php echo $unoloc_c; ?>', '<?php echo $uid_c; ?>')">
                                        Ver Ficha
                                    </button>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- TAB 3: Contratos & Tomas (Merge of reporte_contratos_toma.php with Glass theme) -->
        <div class="tab-panel" id="tab-contratos">
            
            <!-- Resumen Ejecutivo -->
            <div class="glass-card" style="margin-bottom: 24px;">
                <h3 style="font-family:'Outfit', sans-serif; font-size:18px; margin-bottom:15px; color:var(--primary);">Resumen Ejecutivo de Totales</h3>
                <div style="overflow-x: auto; border-radius: 12px; border: 1px solid rgba(0,0,0,0.05);">
                    <table class="glass-table" style="margin-bottom:0;">
                        <thead>
                            <tr>
                                <th>Estatus del Contrato</th>
                                <th style="text-align: center;">Usuarios</th>
                                <th style="text-align: center;">Contratos Normales</th>
                                <th style="text-align: center;">Contratos Comerciales</th>
                                <th style="text-align: center;">Total Contratos</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $grand_normal    = 0;
                            $grand_comercial = 0;
                            $grand_usuarios  = 0;
                            foreach ($tiposdeestado as $id => $nombre):
                                $n = isset($totales[$id]['Normal'])    ? $totales[$id]['Normal']    : 0;
                                $c = isset($totales[$id]['Comercial']) ? $totales[$id]['Comercial'] : 0;
                                $u = isset($totales[$id]['_usuarios']) ? count($totales[$id]['_usuarios']) : 0;
                                $grand_normal    += $n;
                                $grand_comercial += $c;
                                $grand_usuarios  += $u;
                                if ($n == 0 && $c == 0) continue;
                            ?>
                            <tr>
                                <td style="text-align:left"><strong><?php echo $nombre; ?></strong></td>
                                <td style="text-align:center; color:var(--accent); font-weight:700;"><?php echo $u; ?></td>
                                <td style="text-align:center;"><?php echo $n; ?></td>
                                <td style="text-align:center;"><?php echo $c; ?></td>
                                <td style="text-align:center;"><strong><?php echo ($n + $c); ?></strong></td>
                            </tr>
                            <?php endforeach; ?>
                            <tr style="background:rgba(255,255,255,0.4); font-weight:700;">
                                <td style="text-align:left">TOTAL GENERAL</td>
                                <td style="text-align:center; color:var(--accent);"><?php echo $grand_usuarios; ?></td>
                                <td style="text-align:center;"><?php echo $grand_normal; ?></td>
                                <td style="text-align:center;"><?php echo $grand_comercial; ?></td>
                                <td style="text-align:center; color:#1e293b;"><?php echo ($grand_normal + $grand_comercial); ?></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Detailed Grid Report -->
            <div class="glass-card">
                <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:15px; margin-bottom:20px;">
                    <div>
                        <h2 style="font-family:'Outfit', sans-serif; font-size:22px; color:var(--primary);">Detalle de Contratos y Tomas por Usuario</h2>
                        <p style="font-size:12px; color:#64748b; margin-top:2px;">Ordenado por volumen de contratos. Filtros dinámicos activos.</p>
                    </div>
                    
                    <!-- Year Filter -->
                    <div style="background: rgba(255,255,255,0.3); border: 1px solid var(--glass-border); padding: 8px 15px; border-radius: 12px;">
                        <form method="GET" action="" style="display:inline-flex; align-items:center; gap:8px;">
                            <label class="glass-label" style="white-space:nowrap; margin-bottom:0;">Año apertura:</label>
                            <select name="year" id="yearFilter" class="glass-select" style="height:34px; padding:0 10px; font-size:12px; border-radius:6px;">
                                <option value="">Todos los años</option>
                                <?php for ($y = date('Y'); $y >= 2000; $y--): ?>
                                    <option value="<?php echo $y; ?>" <?php echo (isset($_GET['year']) && intval($_GET['year'])==$y) ? 'selected' : ''; ?>>
                                        <?php echo $y; ?>
                                    </option>
                                <?php endfor; ?>
                            </select>
                            <button type="submit" class="btn-action" style="height:34px; padding:0 12px; font-size:12px; border-radius:6px; box-shadow:none;">Filtrar</button>
                            <?php if (isset($_GET['year'])): ?>
                                <a href="mockup_v4_hybrid.php" style="padding:7px 12px; background:rgba(0,0,0,0.06); border-radius:6px; text-decoration:none; font-size:12px; font-weight:600; color: #475569; border: 1px solid var(--glass-border);">Ver Todos</a>
                            <?php endif; ?>
                        </form>
                    </div>
                </div>

                <!-- Combined Filters bar -->
                <div class="search-container" style="flex-wrap: wrap; gap: 15px; margin-bottom: 20px; align-items: center;">
                    <div class="search-box" style="flex-grow: 1; min-width: 250px;">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                        <input type="text" class="input-text" id="glass-search-report" placeholder="Buscar usuario por nombre..." oninput="applyFilters()">
                    </div>
                    
                    <div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
                        <div style="display:flex; align-items:center; gap:8px;">
                            <label class="glass-label" style="white-space: nowrap; margin-bottom:0;">Estado:</label>
                            <select class="glass-select" id="estadoFilter" onchange="applyFilters()" style="height:38px; padding:0 10px; font-size:13px; border-radius:8px; min-width:150px;">
                                <option value="0">Todos los Estados</option>
                                <?php foreach ($tiposdeestado as $id_est => $nom_est): ?>
                                    <option value="<?php echo $id_est; ?>"><?php echo $nom_est; ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        
                        <div style="display:flex; align-items:center; gap:8px;">
                            <label class="glass-label" style="white-space: nowrap; margin-bottom:0;">Toma/Servicio:</label>
                            <select class="glass-select" id="tomaFilter" onchange="applyFilters()" style="height:38px; padding:0 10px; font-size:13px; border-radius:8px; min-width:200px;">
                                <option value="all">Mostrar Todos</option>
                                <option disabled>── Por Tipo de Toma ──</option>
                                <option value="solo_comercial">Con Toma Comercial</option>
                                <option value="solo_normal">Con Toma Normal</option>
                                <option value="mixto_total">Mixto Normal y Comercial</option>
                                <option disabled>── Por Servicio ──</option>
                                <option value="solo_agua">Solo Agua</option>
                                <option value="solo_drenaje">Solo Drenaje</option>
                                <option disabled>── Por Volumen de Contratos ──</option>
                                <option value="multi_cto">Con 3 o Más Contratos</option>
                                <option value="una_toma">Con Solo Una Toma</option>
                                <option value="cto_dos_tomas">Con 2 o Más Tomas en Contrato</option>
                                <option disabled>── Combinación Exacta ──</option>
                                <option value="caso_1_1">Exactamente 1 Agua + 1 Drenaje</option>
                                <option value="caso_171">Exactamente 1 Agua + 2 Drenaje</option>
                                <option value="caso_560">Exactamente 2 Agua + 1 Drenaje</option>
                                <option value="caso_1309">Exactamente 2 Agua + 2 Drenaje</option>
                            </select>
                        </div>
                        
                        <span id="counter-usuarios" class="counter-badge"><?php echo count($data); ?> usuarios</span>
                        <span id="counter-contratos" class="counter-badge" style="background:rgba(16,185,129,0.1); color:#047857;"><?php
                            $total_ctos_init = 0;
                            foreach ($data as $u) $total_ctos_init += count($u['contratos']);
                            echo $total_ctos_init;
                        ?> contratos</span>
                    </div>
                </div>

                <!-- Scrollable Grid Table -->
                <div style="overflow-x: auto; max-height: 600px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.05);">
                    <table class="glass-table" id="mainTable">
                        <thead style="position: sticky; top: 0; z-index: 1;">
                            <tr>
                                <th width="60" style="text-align: center;">#</th>
                                <th width="280">Usuario</th>
                                <?php for ($k = 1; $k <= $max_ctos; $k++): ?>
                                    <th>Cto. <?php echo $k; ?></th>
                                <?php endfor; ?>
                            </tr>
                        </thead>
                        <tbody>
                        <?php
                        $row_num = 0;
                        foreach ($data as $uid => $user):
                            $row_num++;

                            $has_normal    = false;
                            $has_comercial = false;
                            $total_agua    = 0;
                            $total_drenaje = 0;
                            $total_tomas_fisicas = 0;
                            $estados_usuario = array();

                            foreach ($user['contratos'] as $c) {
                                if ($c['tipo'] == 1) $has_comercial = true;
                                else                 $has_normal    = true;
                                $total_agua          += $c['num_agua'];
                                $total_drenaje       += $c['num_drenaje'];
                                $total_tomas_fisicas += $c['num_tomas'];
                                $estados_usuario[$c['estado']] = true;
                            }

                            $is_mixed          = ($has_normal && $has_comercial);
                            $is_multi_cto      = (count($user['contratos']) >= 3);
                            $is_only_comercial = $has_comercial;
                            $is_only_normal    = $has_normal;
                            $has_cto_dos_tomas = false;
                            foreach ($user['contratos'] as $c) {
                                if ($c['num_tomas'] >= 2) { $has_cto_dos_tomas = true; break; }
                            }

                            $estados_str = implode(',', array_keys($estados_usuario));

                            $data_attrs  = 'data-estados="'.$estados_str.'" ';
                            $data_attrs .= 'data-only-comercial="'.($is_only_comercial?'true':'false').'" ';
                            $data_attrs .= 'data-only-normal="'.($is_only_normal?'true':'false').'" ';
                            $data_attrs .= 'data-is-mixed="'.($is_mixed?'true':'false').'" ';
                            $data_attrs .= 'data-multi-cto="'.($is_multi_cto?'true':'false').'" ';
                            $data_attrs .= 'data-cto-dos-tomas="'.($has_cto_dos_tomas?'true':'false').'" ';
                            $data_attrs .= 'data-num-contratos="'.count($user['contratos']).'"';
                        ?>
                            <tr class="user-row" <?php echo $data_attrs; ?>>
                                <td class="row-index" style="text-align: center; font-weight:700; color:#64748b;"><?php echo $row_num; ?></td>
                                <td class="user-name"><span class="user-name-text"><?php echo htmlspecialchars($user['nombre']); ?></span></td>
                                <?php for ($k = 0; $k < $max_ctos; $k++):
                                    $cto      = isset($user['contratos'][$k]) ? $user['contratos'][$k] : null;
                                    $c_agua   = $cto ? $cto['num_agua']   : 0;
                                    $c_drenaje= $cto ? $cto['num_drenaje'] : 0;
                                    $c_takes  = $cto ? $cto['num_tomas']  : 0;
                                    $c_tipo   = $cto ? $cto['tipo']       : 0;
                                    $c_estado = $cto ? intval($cto['estado']) : 0;
                                    $c_warn_agua    = $cto && ($cto['cto_agua_count']   != $c_agua);
                                    $c_warn_drenaje = $cto && ($cto['cto_drenaje_count']!= $c_drenaje);
                                    $c_dos_tomas    = $cto && ($c_takes >= 2);
                                ?>
                                    <td class="contract-cell"
                                        data-agua="<?php echo $c_agua; ?>"
                                        data-drenaje="<?php echo $c_drenaje; ?>"
                                        data-takes="<?php echo $c_takes; ?>"
                                        data-tipo="<?php echo $c_tipo; ?>"
                                        data-estado="<?php echo $c_estado; ?>"
                                        <?php echo $c_dos_tomas ? ' style="background:rgba(245,158,11,0.04);"' : ''; ?>>
                                        <?php if ($cto):
                                            $tag_class = ($cto['tipo_texto'] == 'Comercial' ? 'comercial-tag' : 'normal-tag');
                                            $est_labels = array(1=>'Activo', 2=>'Susp. Temp', 3=>'Susp. Adm', 4=>'Susp. Def');
                                            $est_label  = isset($est_labels[$c_estado]) ? $est_labels[$c_estado] : 'Est.'.$c_estado;
                                            $est_class  = 'cto-estado-'.$c_estado;
                                        ?>
                                        <div class="cto-card">
                                            <div class="cto-header">
                                                <span class="cto-num" title="Número de contrato">#<?php echo $cto['numcontrato']; ?></span>
                                                <span class="<?php echo $tag_class; ?>"><?php echo $cto['tipo_texto']; ?></span>
                                                <span class="<?php echo $est_class; ?>"><?php echo $est_label; ?></span>
                                                <?php if ($c_dos_tomas): ?>
                                                <span style="background:rgba(245, 158, 11, 0.15); color:#d97706; font-size:9px; padding:2px 6px; border-radius:12px; font-weight:bold; white-space:nowrap;"
                                                      title="Este contrato tiene <?php echo $c_takes; ?> tomas registradas">⚡ <?php echo $c_takes; ?> tomas</span>
                                                <?php endif; ?>
                                                <?php if ($c_warn_agua || $c_warn_drenaje): ?>
                                                <span class="data-warn"
                                                      title="Inconsistencia de datos en la base. Catálogo: agua=<?php echo $cto['cto_agua_count']; ?>/dren=<?php echo $cto['cto_drenaje_count']; ?> vs Tomas: agua=<?php echo $c_agua; ?>/dren=<?php echo $c_drenaje; ?>">⚠️ datos</span>
                                                <?php endif; ?>
                                            </div>
                                            <div class="cto-meta" title="Fecha de apertura">
                                                <!-- Calendar Icon -->
                                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-calendar"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                                                <?php echo $cto['fecha']; ?>
                                            </div>
                                            <div class="cto-domicilio" title="Domicilio del contrato">
                                                <!-- Map-pin Icon -->
                                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-map-pin"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>
                                                <?php echo htmlspecialchars($cto['domicilio']); ?>
                                            </div>
                                            <div class="cto-tomas">
                                                <!-- Droplet Icon inside text -->
                                                <div style="display:flex; align-items:flex-start; gap:4px;">
                                                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-droplet" style="margin-top:2px; flex-shrink:0;"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"></path></svg>
                                                    <div><?php echo $cto['toma_texto']; ?></div>
                                                </div>
                                            </div>
                                        </div>
                                        <?php endif; ?>
                                    </td>
                                <?php endfor; ?>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- TAB 4: Egresos (Caja de egresos glassmorphic form) -->
        <div class="tab-panel" id="tab-egresos">
            <div class="glass-card" style="max-width: 600px; margin: 0 auto;">
                <h2 style="font-family:'Outfit', sans-serif; font-size:20px; margin-bottom: 20px; text-align:center;">Registrar Egreso de Caja</h2>
                <form onsubmit="alert('Egreso Registrado exitosamente en el sistema.'); return false;">
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
            <h3 style="font-family:'Outfit', sans-serif; color:var(--primary); font-size:18px;">Ficha Detallada del Ciudadano</h3>
            <button onclick="closeGlassDrawer()" style="background:none; border:none; cursor:pointer; font-size:18px; color:#64748b;">✕</button>
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
                }, 300);
            });
        });

        // Search filtering for Citizens Directory
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

        // Drawer presentation
        function openGlassDrawer(name, address, phone, contractsCount, homonymId, noLocalizado, id) {
            const content = document.getElementById('glass-drawer-content');
            
            // Build statuses list
            let statusPills = '';
            if (noLocalizado == '1') {
                statusPills += `<span class="status-badge suspended" style="margin-bottom:10px;">No Localizado</span> `;
            }
            if (contractsCount == '0') {
                statusPills += `<span class="status-badge lila" style="margin-bottom:10px;">Sin Contratos Activos</span> `;
            }
            if (homonymId > 0) {
                statusPills += `<span class="status-badge danger" style="margin-bottom:10px;">Homónimo de ID #${homonymId}</span> `;
            }
            if (statusPills === '') {
                statusPills = `<span class="status-badge active" style="margin-bottom:10px;">Perfil Limpio / Activo</span>`;
            }

            content.innerHTML = `
                <div style="text-align:center; margin-bottom:25px; background: rgba(255,255,255,0.4); padding: 20px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.5);">
                    <div style="width:60px; height:60px; border-radius:50%; background:linear-gradient(135deg, #2563eb, #8b5cf6); color:white; display:flex; align-items:center; justify-content:center; font-size:20px; font-weight:700; margin:0 auto 10px; box-shadow: 0 4px 12px rgba(37,99,235,0.25);">
                        ${name.substring(0,2).toUpperCase()}
                    </div>
                    <h4 style="font-family:'Outfit', sans-serif; text-transform:uppercase; font-size:16px; font-weight:700; color:var(--primary);">${name}</h4>
                    <p style="font-size:11px; color:#64748b; margin-top:2px;">ID Consecutivo: #${id}</p>
                </div>
                
                <div style="display:flex; flex-direction:column; gap:16px; font-size:13px;">
                    <div>
                        <span style="color:#64748b; display:block; font-size:10px; text-transform:uppercase; font-weight:700; margin-bottom:3px;">Estados Técnicos</span>
                        <div>${statusPills}</div>
                    </div>
                    <div>
                        <span style="color:#64748b; display:block; font-size:10px; text-transform:uppercase; font-weight:700; margin-bottom:3px;">Dirección Localizada</span>
                        <strong style="text-transform:uppercase; color:#1e293b;">${address ? address : '—'}, Tlapa de Comonfort, Gro.</strong>
                    </div>
                    <div>
                        <span style="color:#64748b; display:block; font-size:10px; text-transform:uppercase; font-weight:700; margin-bottom:3px;">Teléfono registrado</span>
                        <strong style="color:#1e293b;">${phone}</strong>
                    </div>
                    <div>
                        <span style="color:#64748b; display:block; font-size:10px; text-transform:uppercase; font-weight:700; margin-bottom:3px;">Volumen de Contratos</span>
                        <strong style="color:var(--accent); font-size: 14px;">${contractsCount} contrato(s) vinculados</strong>
                    </div>
                </div>
                
                <button class="btn-action" style="width:100%; margin-top:30px;" onclick="alert('Funcionalidad de edición del ciudadano en el mockup real.')">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-right:4px;"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg>
                    Editar Perfil
                </button>
            `;
            document.getElementById('glass-overlay').classList.add('open');
            document.getElementById('glass-drawer').classList.add('open');
        }

        function closeGlassDrawer() {
            document.getElementById('glass-overlay').classList.remove('open');
            document.getElementById('glass-drawer').classList.remove('open');
        }

        // ----------------------------------------------------
        // CLIENT-SIDE REPORT FILTERING (MIGRATED & GLASS OPTIMIZED)
        // ----------------------------------------------------
        function applyFilters() {
            const estadoVal = document.getElementById('estadoFilter').value; // '0' = todos
            const tomaVal   = document.getElementById('tomaFilter').value;   // 'all' = todos
            const searchVal = document.getElementById('glass-search-report').value.toLowerCase().trim();

            const rows = document.querySelectorAll('#mainTable .user-row');
            let visibleUsers     = 0;
            let visibleContracts = 0;

            rows.forEach(row => {
                // Search filter (Username)
                const userName = row.querySelector('.user-name-text').innerText.toLowerCase();
                let passSearch = true;
                if (searchVal !== '') {
                    passSearch = userName.includes(searchVal);
                }
                if (!passSearch) {
                    row.style.display = 'none';
                    return;
                }

                // ── Paso 1: ¿la fila pasa el filtro de estado? ──────────────────
                let passEstado = true;
                if (estadoVal !== '0') {
                    const estados = row.getAttribute('data-estados').split(',');
                    passEstado = estados.indexOf(estadoVal) !== -1;
                }
                if (!passEstado) {
                    row.style.display = 'none';
                    return;
                }

                // ── Paso 2: calcular métricas sobre celdas activas del estado ────
                const cells = row.querySelectorAll('.contract-cell');
                let activeAgua    = 0;
                let activeDrenaje = 0;
                let activeTomas   = 0;  // tomas físicas en celdas activas
                let activeNormal  = false;
                let activeComercial = false;
                let activeCtoDosTomas = false;
                let activeContratos = 0;

                cells.forEach(cell => {
                    if (cell.innerHTML.trim() === '') return;
                    const cEstado = cell.getAttribute('data-estado') || '0';
                    const esActiva = (estadoVal === '0' || cEstado === estadoVal);
                    if (!esActiva) return;

                    const cAgua   = parseInt(cell.getAttribute('data-agua')   || 0);
                    const cDren   = parseInt(cell.getAttribute('data-drenaje') || 0);
                    const cTakes  = parseInt(cell.getAttribute('data-takes')  || 0);
                    const cTipo   = parseInt(cell.getAttribute('data-tipo')   || 0);

                    activeAgua    += cAgua;
                    activeDrenaje += cDren;
                    activeTomas   += cTakes;
                    activeContratos++;
                    if (cTipo === 1) activeComercial = true; else activeNormal = true;
                    if (cTakes >= 2) activeCtoDosTomas = true;
                });

                // ── Paso 3: evaluar filtros estáticos (PHP data-attrs) ───────────
                const onlyComercial = row.getAttribute('data-only-comercial') === 'true';
                const onlyNormal    = row.getAttribute('data-only-normal')    === 'true';
                const isMixed       = row.getAttribute('data-is-mixed')       === 'true';
                const isMultiCto    = row.getAttribute('data-multi-cto')      === 'true';
                const ctoDostomas   = row.getAttribute('data-cto-dos-tomas')  === 'true';

                // ── Paso 4: evaluar filtros dinámicos (calculados sobre celdas activas) ──
                const soloAgua    = (activeAgua > 0 && activeDrenaje === 0);
                const soloDrenaje = (activeDrenaje > 0 && activeAgua === 0);
                const unaToma     = (activeTomas === 1);
                const is1_1       = (activeAgua === 1 && activeDrenaje === 1);
                const is171       = (activeAgua === 1 && activeDrenaje === 2);
                const is560       = (activeAgua === 2 && activeDrenaje === 1);
                const is1309      = (activeAgua === 2 && activeDrenaje === 2);

                // ── Paso 5: aplicar filtro de toma ───────────────────────────────
                let passToma = false;
                if      (tomaVal === 'all')           passToma = true;
                else if (tomaVal === 'solo_comercial') passToma = onlyComercial;
                else if (tomaVal === 'solo_normal')    passToma = onlyNormal;
                else if (tomaVal === 'mixto_total')    passToma = isMixed;
                else if (tomaVal === 'solo_agua')      passToma = soloAgua;
                else if (tomaVal === 'solo_drenaje')   passToma = soloDrenaje;
                else if (tomaVal === 'multi_cto')      passToma = isMultiCto;
                else if (tomaVal === 'una_toma')       passToma = unaToma;
                else if (tomaVal === 'cto_dos_tomas')  passToma = ctoDostomas;
                else if (tomaVal === 'caso_1_1')       passToma = is1_1;
                else if (tomaVal === 'caso_171')       passToma = is171;
                else if (tomaVal === 'caso_560')       passToma = is560;
                else if (tomaVal === 'caso_1309')      passToma = is1309;

                const showRow = passToma;
                row.style.display = showRow ? '' : 'none';

                if (!showRow) return;

                visibleUsers++;
                row.querySelector('.row-index').innerText = visibleUsers;

                // ── Paso 6: resaltado visual por celda ───────────────────────────
                cells.forEach(cell => {
                    if (cell.innerHTML.trim() === '') return;

                    const cTipo   = parseInt(cell.getAttribute('data-tipo')   || 0);
                    const cTakes  = parseInt(cell.getAttribute('data-takes')  || 0);
                    const cEstado = cell.getAttribute('data-estado') || '0';
                    const esActiva = (estadoVal === '0' || cEstado === estadoVal);

                    // Ocultar celdas que no corresponden al filtro de toma
                    let showCell = true;
                    if      (tomaVal === 'solo_comercial' && cTipo !== 1)  showCell = false;
                    else if (tomaVal === 'solo_normal'    && cTipo === 1)  showCell = false;
                    else if (tomaVal === 'solo_agua'      && !esActiva)    showCell = false;
                    else if (tomaVal === 'solo_drenaje'   && !esActiva)    showCell = false;
                    cell.style.display = showCell ? '' : 'none';

                    const ctoCard = cell.querySelector('.cto-card');
                    if (!ctoCard) return;

                    // Reset and apply Glass adjustments
                    ctoCard.style.borderColor = '';
                    ctoCard.style.borderWidth = '';
                    ctoCard.style.opacity     = '';

                    if (!esActiva) {
                        ctoCard.style.opacity = '0.35';
                    } else if (tomaVal === 'mixto_total') {
                        ctoCard.style.borderColor = cTipo === 1 ? '#ef4444' : '#10b981';
                        ctoCard.style.borderWidth = '2px';
                    } else if (tomaVal === 'cto_dos_tomas') {
                        if (cTakes >= 2) {
                            ctoCard.style.borderColor = '#f59e0b';
                            ctoCard.style.borderWidth = '2px';
                        } else {
                            ctoCard.style.opacity = '0.35';
                        }
                    }

                    if (showCell && esActiva) visibleContracts++;
                });
            });

            document.getElementById('counter-usuarios').innerText  = visibleUsers     + ' usuarios';
            document.getElementById('counter-contratos').innerText = visibleContracts + ' contratos';
        }

        window.addEventListener('DOMContentLoaded', function() { applyFilters(); });
    </script>
</body>
</html>
<?php $con->cerrarConexion(); ?>

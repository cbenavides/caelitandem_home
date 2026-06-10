<?php
require_once('login/usuario.php');
session_start();
if (!isset($_SESSION['usuario'])) {
	print "<script>window.location='login/index.php'</script>";
	exit();
}
header('Content-Type: text/html; charset=UTF-8');
?>
<!DOCTYPE HTML>
<html lang="es">

<head>
	<title>Sistema de Recaudación para Servicio de Agua Potable y Alcantarillado</title>
    <style>
        .gear-link { font-size: 24px !important; text-decoration: none !important; cursor: pointer !important; display: inline-block !important; padding: 0 10px !important; line-height: 26px !important; color: #477 !important; background: transparent !important; box-shadow: none !important; vertical-align: top !important; }
        .gear-link:hover { color: #f16a70 !important; background: transparent !important; }
        .version-tag { font-size: 11px !important; font-weight: 600 !important; color: #8a9bb0 !important; background: transparent !important; text-decoration: none !important; vertical-align: top !important; line-height: 26px !important; margin-left: -6px !important; letter-spacing: 0.03em !important; box-shadow: none !important; padding: 0 !important; }
        .version-tag:hover { color: #477 !important; background: transparent !important; }
    </style>
	<meta charset="UTF-8">
	<link rel="stylesheet" type="text/css" href="web-assets/css/paxstyle2.css">
	<script language="javascript" src="includes/js/paxscript.js"></script>
	<script src="web-assets/js/jquery-3.7.1.min.js"></script>
	<script src="web-assets/js/jquery-migrate-3.4.1.min.js"></script>
	<script src="web-assets/js/jqueryform.min.js"></script>
	<script src="web-assets/js/jquery.validate.min.js"></script>
	<script src="web-assets/js/jquery.hotkeys.min.js"></script>
    <script>
        $(document).ready(function() {
            // Soporte para apertura directa de contratos via URL (Deep-linking)

            // Soporte para apertura directa de contratos via URL (Deep-linking)
            <?php if(isset($_GET['numcontrato'])): ?>
                cargaDatosContrato('<?= intval($_GET['numcontrato']) ?>');
            <?php endif; ?>
        });
    </script>
</head>

<body>
	<div id='mensajes'></div>
	<div id='clutter'>
		<ul>
			<li><a href='#' onclick="menu('usuario')">Usuarios</a></li>
			<li><a href='#' onclick="menu('contrato')">Contratos</a></li>
			<li><a href='#' onclick="cargaCargos()">Cargos</a></li>
			<li><a href='#' onclick="gastos()">Egresos</a></li>
			<li><a href='#' onClick="asistencias()">Asistencias</a></li>
			<li><a href='#' onClick="listados()">Listados</a></li>
			<li><a href='#' onClick="contrasenas()">Comité</a></li>
			<?php
			if ($_SESSION['usuario']->getRol() == 1)
				print "<li><a href='#' onClick='registro()'>Registro de Usuarios</a></li>";
			?>
			<li><a href='#' onClick="salir()">Salir</a></li>
			<li><a href='#' onClick="configuracion()" class="gear-link" title="Configuración y Saneamiento">&#9881;</a><a href='index2.php' class="version-tag">V2.0.0</a></li>
		</ul>
	</div>
	<div id='opciones'>
	</div>
	<div id='nara'></div>
	<div id='app'>
		<h1>Bienvenido</h1>
		<hr>
		<img src='web-assets/img/drop.png' align=left border=0><br><br>
		<p><b>Sistema de Agua Potable y Alcantarillado de la Colonia del Maestro</b>.</p><br>
		<div id='tarjeta'>
			<p>Versión 2.0.0; Comite 2026.<br><br>Huajuapan de León, Oaxaca.</p>
		</div>
		<br><br><br><br><br><br>
		<div id='nara'></div>
	</div>
	<div id='nara'></div>
</body>

</html>
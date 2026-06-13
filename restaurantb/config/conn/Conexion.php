<?php
require_once __DIR__ . '/config.php';

class Conexion
{
	public $manejador;
	public $servidor;
	public $usuario;
	public $contrasena;
	public $basedatos;
	public $conexion;
	public $link;
	function __construct()
	{
		$this->manejador = 'mysql';
		$this->servidor = DB_HOST;
		$this->puerto = defined('DB_PORT') ? DB_PORT : null;
		$this->usuario = DB_USER;
		$this->contrasena = DB_PASS;
		$this->conexion = 0;
		$this->basedatos = DB_NAME;
	}
	function establecerDatos($m, $s, $u, $c, $b)
	{
		$this->manejador = $m;
		$this->servidor = $s;
		$this->usuario = $u;
		$this->contrasena = $c;
		$this->basedatos = $b;
	}
	function establecerBD($b)
	{
		$this->basedatos = $b;
	}
	function abrirConexion()
	{
		$port = isset($this->puerto) ? $this->puerto : null;
		$this->link = @mysqli_connect($this->servidor, $this->usuario, $this->contrasena, $this->basedatos, $port);
		if($this->link) {
			mysqli_set_charset($this->link, "utf8mb4");
			@mysqli_query($this->link, "SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''))");
		}
		if (!$this->link) {
			$this->link = @mysqli_connect($this->servidor, $this->usuario, "", $this->basedatos, $port);
			if($this->link) {
				mysqli_set_charset($this->link, "utf8mb4");
				@mysqli_query($this->link, "SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''))");
			}
			if (!$this->link) {
				print "<script>$('#mensajes').html(\"<img src='alerta.png'><br><b>No es posible conectarse a la Base de Datos del sistema.</b><br><br>Intente levantar el servidor <i>MySQL</i> de forma manual<br>ya que de otra forma, el sistema no funcionar&aacute;. Despu&eacute;s, recargue esta p&aacute;gina.\");	$('#mensajes').fadeIn(500,function(){});</script>";
				return 0;
			} else {
				$this->conexion = 1;
				return 1;
			}
		} else {
			$this->conexion = 1;
			return 1;
		}
	}
	function cerrarConexion()
	{
		mysqli_close($this->link);
	}
	function conectarBaseDatos()
	{
		if ($this->conexion == 0)
			$this->abrirConexion();
		if ($this->conexion == 1) {
			$db_selected = @mysqli_select_db($this->link, $this->basedatos);
			if (!$db_selected)
				return 0;
			else {
				@mysqli_set_charset($this->link, "utf8mb4");
				@mysqli_query($this->link, "SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''))");
				return 1;
			}
		}
	}
	function q($query)
	{
		$result = @mysqli_query($this->link, $query);
		// Regla E01: solo llamar mysqli_error si el link es un objeto mysqli válido
		if ($this->link) {
			$err = mysqli_error($this->link);
			if ($err !== '') {
				$this->_logFallback('ERROR', $query, $err);
			}
		}
		return $result;
	}

	public function _logFallback($nivel, $query, $error_msg = null)
	{
		if (!$this->link) return; // No hay donde guardar si no hay link

		// Determinar tipo de query
		$q_trim = ltrim($query);
		$first_word = strtoupper(strtok($q_trim, " \t\n\r"));
		$type_map = ['SELECT'=>'SELECT','INSERT'=>'INSERT','UPDATE'=>'UPDATE','DELETE'=>'DELETE','CALL'=>'CALL'];
		$query_type = isset($type_map[$first_word]) ? $type_map[$first_word] : 'OTHER';

		// Hash CRC32 para agrupar repeticiones
		$query_hash = substr(dechex(crc32($query)), 0, 8);

		// Origen: archivo y línea del caller (skip frames dentro de Conexion)
		$origen = 'unknown';
		$funcion = null;
		$backtrace = debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS, 5);
		foreach ($backtrace as $frame) {
			$file = isset($frame['file']) ? $frame['file'] : '';
			if ($file !== '' && strpos($file, 'Conexion.php') === false) {
				$short = str_replace($_SERVER['DOCUMENT_ROOT'], '', $file);
				$line  = isset($frame['line']) ? $frame['line'] : '';
				$origen = ltrim($short, '/') . ($line ? ":$line" : '');
				if (isset($frame['function']) && $frame['function'] !== 'q') {
					$funcion = (isset($frame['class']) ? $frame['class'] . '::' : '') . $frame['function'];
				}
				break;
			}
		}

		// Contexto de sesión
		$ses_u = isset($_SESSION['usuario']) ? $_SESSION['usuario'] : null;
		$usuario_ses = is_string($ses_u) && $ses_u !== ''
		    ? $ses_u
		    : (is_object($ses_u) && method_exists($ses_u, 'getNombre') ? $ses_u->getNombre() : null);
		$numcontrato = isset($_SESSION['numcontrato']) ? $_SESSION['numcontrato'] : null;

		// Escaped values para INSERT seguro (sin usar $this->q para evitar recursión)
		// Usamos mysqli_real_escape_string si el link está ok, sino fallback a addslashes
		$that = $this;
		$esc_raw = function($v) use ($that) {
			if ($v === null) return 'NULL';
			$ev = ($that->link) ? mysqli_real_escape_string($that->link, $v) : addslashes($v);
			return "'" . $ev . "'";
		};

		$query_text_esc  = $esc_raw($query);
		$error_msg_short = $error_msg ? substr($error_msg, 0, 300) : null;
		$filas = ($query_type !== 'SELECT' && $this->link) ? intval(@mysqli_affected_rows($this->link)) : null;

		$sql = "INSERT INTO fallback_log
			(nivel, origen, funcion, query_type, query_hash, query_text, filas_afect, error_msg, usuario_ses, numcontrato)
			VALUES (
				" . $esc_raw($nivel) . ",
				" . $esc_raw(substr($origen, 0, 120)) . ",
				" . $esc_raw($funcion ? substr($funcion, 0, 80) : null) . ",
				" . $esc_raw($query_type) . ",
				'$query_hash',
				$query_text_esc,
				" . ($filas !== null ? intval($filas) : 'NULL') . ",
				" . $esc_raw($error_msg_short) . ",
				" . $esc_raw($usuario_ses) . ",
				" . $esc_raw($numcontrato) . "
			)";

		@mysqli_query($this->link, $sql);
	}
	function fetch_array($res)
	{
		return @mysqli_fetch_array($res);
	}
	function fetch_assoc($res)
	{
		return @mysqli_fetch_assoc($res);
	}
	function num_rows($res)
	{
		return @mysqli_num_rows($res);
	}
	function insert_id()
	{
		return @mysqli_insert_id($this->link);
	}
	function affected_rows()
	{
		return ($this->link) ? mysqli_affected_rows($this->link) : 0;
	}
	function error()
	{
		return mysqli_error($this->link);
	}
	function free_result($res)
	{
		@mysqli_free_result($res);
	}
	function real_escape_string($string)
	{
		// Regla E01: nunca llamar a mysqli_real_escape_string con link inválido.
		// Si la conexión se perdió, fallback a addslashes para no crashear el caller.
		if ($this->link) {
			return mysqli_real_escape_string($this->link, $string);
		}
		return addslashes((string)$string);
	}
}
?>
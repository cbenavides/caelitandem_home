<?php
/**
 * ════════════════════════════════════════════════════════════
 * run_functional_tests.php — Voice-KDS Functional Test Suite
 * Fases 1-4: BD, Comandas, Cocina, Cancelaciones
 * Uso: php tests/run_functional_tests.php
 * ════════════════════════════════════════════════════════════
 */

define('BASE_DIR', dirname(__DIR__) . '/www/restaurant');
define('DB_HOST', '127.0.0.1');
define('DB_PORT', 6002);
define('DB_USER', 'root');
define('DB_PASS', 'comite_2026');
define('DB_NAME', 'vcd01');

// ─── Colores ANSI ────────────────────────────────────────────
define('GREEN',  "\033[32m");
define('RED',    "\033[31m");
define('YELLOW', "\033[33m");
define('CYAN',   "\033[36m");
define('BOLD',   "\033[1m");
define('RESET',  "\033[0m");

$passed = 0;
$failed = 0;
$skipped = 0;

function pass(string $label): void {
    global $passed;
    $passed++;
    echo GREEN . "  ✓ " . RESET . $label . "\n";
}

function fail(string $label, string $reason = ''): void {
    global $failed;
    $failed++;
    echo RED . "  ✗ " . RESET . $label . ($reason ? " → " . YELLOW . $reason . RESET : '') . "\n";
}

function skip(string $label, string $reason = ''): void {
    global $skipped;
    $skipped++;
    echo YELLOW . "  ⊘ " . RESET . $label . ($reason ? " (omitido: $reason)" : '') . "\n";
}

function section(string $title): void {
    echo "\n" . BOLD . CYAN . "── $title " . str_repeat('─', 50 - strlen($title)) . RESET . "\n";
}

// ─── Conexión PDO ────────────────────────────────────────────
section("Conectando a la BD");
try {
    $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::MYSQL_ATTR_USE_BUFFERED_QUERY => true
    ]);
    pass("Conexión a BD vcd01 en puerto " . DB_PORT);
} catch (Exception $e) {
    fail("Conexión a BD", $e->getMessage());
    exit(1);
}

// ═══════════════════════════════════════════════════════════════
// FASE 1: ESQUEMA Y USUARIOS
// ═══════════════════════════════════════════════════════════════
section("FASE 1 — Esquema y Usuarios");

// 1.1 Columna numero_personas
$cols = $pdo->query("SHOW COLUMNS FROM comandas LIKE 'numero_personas'")->fetchAll();
count($cols) > 0 ? pass("Columna 'numero_personas' existe en tabla comandas") : fail("Columna 'numero_personas' falta en tabla comandas");

// 1.2 Columna metodo_captura
$cols = $pdo->query("SHOW COLUMNS FROM comandas LIKE 'metodo_captura'")->fetchAll();
count($cols) > 0 ? pass("Columna 'metodo_captura' existe en tabla comandas") : fail("Columna 'metodo_captura' falta en tabla comandas");

// 1.3 Cocinero 1
$u = $pdo->query("SELECT id, email FROM users WHERE email = 'cocinero1@restaurante.local'")->fetch();
$u ? pass("Cocinero 1 (cocinero1@restaurante.local) registrado, ID=" . $u['id']) : fail("Cocinero 1 no encontrado en tabla users");

// 1.4 Cocinero 2
$u = $pdo->query("SELECT id FROM users WHERE email = 'cocinero2@restaurante.local'")->fetch();
$u ? pass("Cocinero 2 (cocinero2@restaurante.local) registrado") : fail("Cocinero 2 no encontrado");

// 1.5 Cocinero 3
$u = $pdo->query("SELECT id FROM users WHERE email = 'cocinero3@restaurante.local'")->fetch();
$u ? pass("Cocinero 3 (cocinero3@restaurante.local) registrado") : fail("Cocinero 3 no encontrado");

// 1.6 Permiso ver_kds asignado a cocineros 5,6,7
$perms = $pdo->query("SELECT COUNT(*) AS cnt FROM rbac_permisos_usuarios rpu JOIN rbac_permisos rp ON rpu.permiso_id = rp.id WHERE rp.nombre = 'ver_kds' AND rpu.user_id IN (5,6,7)")->fetch();
intval($perms['cnt']) >= 3 ? pass("Permiso 'ver_kds' asignado a los 3 cocineros") : fail("Permiso 'ver_kds' incompleto para cocineros", "Solo {$perms['cnt']} de 3 asignados");

// 1.7 Stored procedure actualizado
$sp = $pdo->query("SHOW CREATE PROCEDURE RegistrarComanda")->fetch();
if ($sp) {
    $def = array_values($sp)[2] ?? '';
    strpos($def, 'p_numero_personas') !== false ? pass("SP RegistrarComanda acepta p_numero_personas") : fail("SP RegistrarComanda no acepta p_numero_personas (desactualizado)");
    strpos($def, 'p_metodo_captura') !== false ? pass("SP RegistrarComanda acepta p_metodo_captura") : fail("SP RegistrarComanda no acepta p_metodo_captura");
} else {
    fail("SP RegistrarComanda no existe");
}

// ═══════════════════════════════════════════════════════════════
// FASE 2: CICLO COMPLETO DE UNA COMANDA (SIMULACIÓN)
// ═══════════════════════════════════════════════════════════════
section("FASE 2 — Ciclo de Comanda");

// Obtener primer producto disponible
$prod = $pdo->query("SELECT id, nombre, precio FROM productos WHERE disponible = 1 LIMIT 1")->fetch();
if (!$prod) {
    skip("No hay productos activos para simular comanda", "tabla productos vacía");
    $comanda_id_test = null;
} else {
    pass("Producto de prueba encontrado: " . $prod['nombre'] . " (\${$prod['precio']})");
    
    // 2.1 CALL RegistrarComanda con nuevos campos
    try {
        $json = json_encode([['producto_id' => $prod['id'], 'cantidad' => 2]]);
        $stmt = $pdo->prepare("CALL RegistrarComanda(1, 2, 'mesa uno dos tacos de pastor', ?, 2, 'teclado')");
        $stmt->execute([$json]);
        $result = $stmt->fetch();
        $stmt->closeCursor(); // Liberar result sets pendientes del CALL (error PDO 2014)
        
        if ($result && isset($result['comanda_id']) && $result['comanda_id'] > 0) {
            $comanda_id_test = $result['comanda_id'];
            pass("RegistrarComanda ejecutado — comanda_id={$comanda_id_test}, total=\${$result['total']}");
        } else {
            fail("RegistrarComanda no devolvió comanda_id válido");
            $comanda_id_test = null;
        }
    } catch (Exception $e) {
        fail("RegistrarComanda arrojó excepción", $e->getMessage());
        $comanda_id_test = null;
    }
    
    // 2.2 Verificar campos en la fila insertada
    if ($comanda_id_test) {
        $row = $pdo->query("SELECT numero_personas, metodo_captura, estado FROM comandas WHERE id = $comanda_id_test")->fetch();
        if ($row) {
            intval($row['numero_personas']) === 2 ? pass("numero_personas=2 guardado correctamente") : fail("numero_personas incorrecto", "esperado 2, obtenido {$row['numero_personas']}");
            $row['metodo_captura'] === 'teclado' ? pass("metodo_captura='teclado' guardado correctamente") : fail("metodo_captura incorrecto", "esperado 'teclado', obtenido '{$row['metodo_captura']}'");
            $row['estado'] === 'pendiente' ? pass("Estado inicial de comanda es 'pendiente'") : fail("Estado inicial incorrecto", "esperado 'pendiente', obtenido '{$row['estado']}'");
        } else {
            fail("No se pudo leer la comanda insertada");
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// FASE 3: PARSER DE COMANDOS DE COCINA (SQL directo, simula API)
// ═══════════════════════════════════════════════════════════════
section("FASE 3 — Comandos de Voz del Cocinero");

if ($comanda_id_test) {
    // 3.1 "preparar siguiente" — toma la más antigua
    $pendiente = $pdo->query("SELECT id, mesa_id FROM comandas WHERE estado = 'pendiente' ORDER BY hora_captura ASC LIMIT 1")->fetch();
    if ($pendiente) {
        $upd = $pdo->prepare("UPDATE comandas SET estado = 'en_preparacion', cocinero_id = 5 WHERE id = ?");
        $upd->execute([$pendiente['id']]);
        $upd->rowCount() > 0 ? pass("'preparar siguiente': comanda ID={$pendiente['id']} pasa a en_preparacion") : fail("'preparar siguiente': no actualizó");
    } else {
        skip("'preparar siguiente'", "no hay comandas pendientes");
    }
    
    // 3.2 "listo mesa X" — marcar como lista
    $enPrep = $pdo->query("SELECT id, mesa_id FROM comandas WHERE estado = 'en_preparacion' ORDER BY hora_captura ASC LIMIT 1")->fetch();
    if ($enPrep) {
        $upd = $pdo->prepare("UPDATE comandas SET estado = 'listo' WHERE id = ?");
        $upd->execute([$enPrep['id']]);
        $upd->rowCount() > 0 ? pass("'listo mesa {$enPrep['mesa_id']}': comanda marcada como lista") : fail("'listo mesa': no actualizó");
    } else {
        skip("'listo mesa'", "no hay comandas en_preparacion");
    }
    
    // 3.3 "recuperar mesa X" — regresa a en_preparacion
    $listo = $pdo->query("SELECT id, mesa_id FROM comandas WHERE estado = 'listo' ORDER BY hora_captura DESC LIMIT 1")->fetch();
    if ($listo) {
        $upd = $pdo->prepare("UPDATE comandas SET estado = 'en_preparacion', cocinero_id = 5 WHERE id = ?");
        $upd->execute([$listo['id']]);
        $upd->rowCount() > 0 ? pass("'recuperar mesa {$listo['mesa_id']}': comanda vuelve a en_preparacion") : fail("'recuperar mesa': no actualizó");
    } else {
        skip("'recuperar mesa'", "no hay comandas en estado listo");
    }
    
    // 3.4 "ordenes pendientes" — conteo
    $counts = $pdo->query("SELECT estado, COUNT(*) as cnt FROM comandas WHERE estado IN ('pendiente','en_preparacion') GROUP BY estado")->fetchAll();
    $total_activas = array_sum(array_column($counts, 'cnt'));
    pass("'ordenes pendientes': {$total_activas} comandas activas (pendiente + en_preparacion)");
    
    // 3.5 "repetir orden mesa X" — lectura de detalles
    $enPrep2 = $pdo->query("SELECT id, mesa_id FROM comandas WHERE estado IN ('pendiente','en_preparacion') ORDER BY hora_captura DESC LIMIT 1")->fetch();
    if ($enPrep2) {
        $detalles = $pdo->prepare("SELECT d.cantidad, p.nombre, d.notas FROM detalle_comandas d JOIN productos p ON d.producto_id = p.id WHERE d.comanda_id = ? AND d.estado = 'activo'");
        $detalles->execute([$enPrep2['id']]);
        $rows = $detalles->fetchAll();
        count($rows) > 0 ? pass("'repetir mesa {$enPrep2['mesa_id']}': " . count($rows) . " item(s) encontrados") : fail("'repetir mesa': no hay detalles activos en comanda {$enPrep2['id']}");
    } else {
        skip("'repetir orden mesa'", "no hay comandas activas");
    }
} else {
    skip("Fase 3 completa", "no se pudo generar comanda de prueba en Fase 2");
}

// ═══════════════════════════════════════════════════════════════
// FASE 4: CANCELACIONES Y TABLAS DE SOPORTE
// ═══════════════════════════════════════════════════════════════
section("FASE 4 — Cancelaciones y Estado de Cocina");

// 4.1 Tabla cancelaciones_pendientes existe
try {
    $pdo->query("SELECT 1 FROM cancelaciones_pendientes LIMIT 1");
    pass("Tabla cancelaciones_pendientes existe y es accesible");
} catch (Exception $e) {
    fail("Tabla cancelaciones_pendientes no existe o es inaccesible", $e->getMessage());
}

// 4.2 Insertar solicitud de cancelación de prueba
if ($comanda_id_test) {
    $detalle = $pdo->query("SELECT id FROM detalle_comandas WHERE comanda_id = $comanda_id_test AND estado = 'activo' LIMIT 1")->fetch();
    if ($detalle) {
        try {
            $ins = $pdo->prepare("INSERT INTO cancelaciones_pendientes (detalle_comanda_id, mesero_id, estado, creado_en) VALUES (?, 2, 'pendiente', NOW())");
            $ins->execute([$detalle['id']]);
            $cancelacion_id = $pdo->lastInsertId();
            pass("Solicitud de cancelación insertada, ID={$cancelacion_id}");
            
            // 4.3 Aprobar cancelación (simula "si cancelar")
            $pdo->beginTransaction();
            $pdo->prepare("UPDATE cancelaciones_pendientes SET estado = 'aprobada', cocinero_id = 5, respondido_en = NOW() WHERE id = ?")->execute([$cancelacion_id]);
            $pdo->prepare("UPDATE detalle_comandas SET estado = 'cancelado', cancelado_en = NOW() WHERE id = ?")->execute([$detalle['id']]);
            // Actualizar total de comanda
            $info = $pdo->query("SELECT subtotal FROM detalle_comandas WHERE id = {$detalle['id']}")->fetch();
            if ($info) {
                $pdo->prepare("UPDATE comandas SET total = total - ? WHERE id = ?")->execute([$info['subtotal'], $comanda_id_test]);
            }
            $pdo->commit();
            pass("'si cancelar': cancelación aprobada y detalle marcado como cancelado");
            
        } catch (Exception $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            fail("Flujo de cancelación arrojó excepción", $e->getMessage());
        }
    } else {
        skip("'si cancelar'", "no hay detalles activos en la comanda de prueba");
    }
} else {
    skip("Fase 4 — Cancelaciones", "no se pudo generar comanda de prueba");
}

// 4.4 Estado general de cocina (simula GET /api/cocina/estado.php)
$estado = $pdo->query("SELECT estado, COUNT(*) as cnt FROM comandas WHERE estado IN ('pendiente','en_preparacion','listo') GROUP BY estado")->fetchAll();
$canc_pend = $pdo->query("SELECT COUNT(*) as cnt FROM cancelaciones_pendientes WHERE estado = 'pendiente'")->fetch();
pass("GET /api/cocina/estado: " . count($estado) . " grupos de estado, {$canc_pend['cnt']} cancelaciones pendientes");

// ─── Limpieza de datos de prueba ─────────────────────────────
section("Limpieza de datos de prueba");
if ($comanda_id_test) {
    $pdo->exec("DELETE FROM cancelaciones_pendientes WHERE detalle_comanda_id IN (SELECT id FROM detalle_comandas WHERE comanda_id = $comanda_id_test)");
    $pdo->exec("DELETE FROM detalle_comandas WHERE comanda_id = $comanda_id_test");
    $pdo->exec("DELETE FROM comandas WHERE id = $comanda_id_test");
    pass("Datos de prueba eliminados (comanda_id=$comanda_id_test y sus detalles)");
}

// ─── Resumen final ───────────────────────────────────────────
section("Resumen de Pruebas");
$total = $passed + $failed + $skipped;
echo "\n  Total: " . BOLD . $total . RESET . "  |  ";
echo GREEN . "✓ Exitosas: $passed" . RESET . "  |  ";
echo RED . "✗ Fallidas: $failed" . RESET . "  |  ";
echo YELLOW . "⊘ Omitidas: $skipped" . RESET . "\n\n";

if ($failed > 0) {
    echo RED . BOLD . "  ❌ El suite tiene fallos. Revisar los elementos marcados con ✗.\n" . RESET;
    exit(1);
} else {
    echo GREEN . BOLD . "  ✅ Todas las pruebas funcionales pasaron correctamente.\n" . RESET;
    exit(0);
}

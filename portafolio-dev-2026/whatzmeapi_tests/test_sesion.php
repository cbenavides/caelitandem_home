<?php
// test_sesion.php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numero_prueba = $_POST['numero_destino'] ?? null;
$accion = $_POST['accion'] ?? 'consultar';

$client = new ApiTestClient($token);
$isAjax = isset($_POST['ajax']);
$output = [];

function out($title, $data = null, $type = 'info') {
    global $isAjax, $output;
    if ($isAjax) {
        $output[] = ['title' => $title, 'data' => $data, 'type' => $type];
    } else {
        echo "$title\n";
        if ($data) print_r($data);
        echo "\n";
    }
}

$responseData = ['status' => 'success', 'output' => &$output];

try {
    if ($accion === 'cerrar_sesion') {
        out("=== ACCIÓN: Cerrar Sesión de WhatsApp ===");
        $res = $client->request(HTTP_Request2::METHOD_POST, '/cerrar-sesion');
        out("Ejecutando POST /cerrar-sesion...", $res);
        if ($res['status'] != 200) throw new Exception("Fallo el cierre de sesión.");
    } else {
        out("=== Test de APIs de Sesión ===");

        // 1. Suscripción
        $res = $client->request(HTTP_Request2::METHOD_GET, '/suscripcion');
        out("1. Obteniendo Suscripción (/suscripcion)...", $res);

        // 2. Estado
        $res = $client->request(HTTP_Request2::METHOD_GET, '/estado');
        out("2. Obteniendo Estado (/estado)...", $res);

        // 3. Usuario
        $res = $client->request(HTTP_Request2::METHOD_GET, '/usuario');
        out("3. Obteniendo Usuario (/usuario)...", $res);

        // 4. Código QR
        $res = $client->request(HTTP_Request2::METHOD_GET, '/codigo-qr');
        if ($res['status'] == 200 && is_string($res['data'])) {
            out("4. Obteniendo Código QR (/codigo-qr)...", "Código QR recibido (datos binarios/imagen omitidos en pantalla).");
        } else {
            out("4. Obteniendo Código QR (/codigo-qr)...", $res);
        }

        // 5. Verificar Número WhatsApp
        if ($numero_prueba) {
            $res = $client->request(HTTP_Request2::METHOD_GET, '/verificar-numero-whatsapp', null, ['numero' => $numero_prueba]);
            out("5. Verificando Número Destino (/verificar-numero-whatsapp)...", $res);
        }

        out("Pruebas de sesión finalizadas.");
    }
} catch (Exception $e) {
    out("ERROR: " . $e->getMessage(), null, 'error');
    $responseData['status'] = 'error';
    $responseData['message'] = $e->getMessage();
}

if ($isAjax) {
    header('Content-Type: application/json');
    echo json_encode($responseData);
}

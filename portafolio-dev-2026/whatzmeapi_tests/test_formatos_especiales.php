<?php
// test_formatos_especiales.php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numero = $_POST['numero_destino'] ?? null;
$accion = $_POST['accion'] ?? 'sticker';

$client = new ApiTestClient($token);
$client->requireConnection();

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
    if (!$numero) throw new Exception("Se requiere un número destino en la barra superior.");

    switch ($accion) {
        case 'sticker':
            out("=== ACCIÓN: Enviar Sticker ===");
            $stickerUrl = $_POST['sticker_url'] ?? $client->getConfig('test_sticker_url');
            if (empty($stickerUrl)) $stickerUrl = 'https://img-06.stickers.cloud/packs/5df297e3-a7f0-44e0-a6d1-43bdb09b793c/webp/8709a42d-0579-4314-b659-9c2cdb979305.webp';
            
            $body = [
                'numero' => $numero,
                'urlSticker' => $stickerUrl
            ];
            $res = $client->request(HTTP_Request2::METHOD_POST, '/enviar-sticker', $body);
            out("Enviando Sticker (POST /enviar-sticker)...", $res);
            if ($res['status'] != 200) throw new Exception("Error al enviar sticker.");
            break;

        case 'ubicacion':
            out("=== ACCIÓN: Enviar Ubicación GPS ===");
            $latRaw = $_POST['latitud'] ?? '';
            $lngRaw = $_POST['longitud'] ?? '';
            $latitud = is_numeric($latRaw) ? (float)$latRaw : 19.4326;
            $longitud = is_numeric($lngRaw) ? (float)$lngRaw : -99.1332;
            $direccion = !empty($_POST['direccion']) ? $_POST['direccion'] : 'Ciudad de México, CDMX, México';
            
            $body = [
                'numero' => $numero,
                'latitud' => $latitud,
                'longitud' => $longitud,
                'direccion' => $direccion
            ];
            $res = $client->request(HTTP_Request2::METHOD_POST, '/enviar-ubicacion', $body);
            out("Enviando Ubicación GPS (POST /enviar-ubicacion)...", $res);
            if ($res['status'] != 200) throw new Exception("Error al enviar ubicación.");
            break;

        case 'encuesta':
            out("=== ACCIÓN: Enviar Encuesta ===");
            $pregunta = !empty($_POST['pregunta']) ? $_POST['pregunta'] : '¿Cuál es tu canal preferido?';
            $opcionesRaw = !empty($_POST['opciones']) ? $_POST['opciones'] : "WhatsApp, Email, Teléfono, Presencial";
            $opcionesArr = array_map('trim', explode(',', $opcionesRaw));
            $seleccionMultiple = !empty($_POST['seleccion_multiple']);

            $body = [
                'numero' => $numero,
                'encuesta' => [
                    'pregunta' => $pregunta,
                    'opciones' => $opcionesArr,
                    'seleccionMultiple' => $seleccionMultiple
                ]
            ];
            $res = $client->request(HTTP_Request2::METHOD_POST, '/enviar-encuesta', $body);
            out("Enviando Encuesta (POST /enviar-encuesta)...", $res);
            if ($res['status'] != 200) throw new Exception("Error al enviar encuesta.");
            break;

        default:
            throw new Exception("Acción no reconocida: $accion");
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

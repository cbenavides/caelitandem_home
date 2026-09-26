<?php
// test_campanas_masivas.php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numeroPrincipal = $_POST['numero_destino'] ?? null;
$accion = $_POST['accion'] ?? 'mensaje_masivo';

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
    // Preparar lista de números destino
    $numerosRaw = $_POST['numeros_masivos'] ?? '';
    if (!empty($numerosRaw)) {
        $numerosInput = array_map('trim', explode(',', $numerosRaw));
    } else {
        $numerosInput = array_filter([$numeroPrincipal, '5215500000000']);
    }

    // Auto-formatear números de México a 13 dígitos (521XXXXXXXXXX)
    $numerosArr = array_map(function($num) {
        $clean = preg_replace('/[^0-9]/', '', $num);
        if (strlen($clean) === 10) {
            return '521' . $clean;
        }
        return $clean;
    }, $numerosInput);

    if (empty($numerosArr)) throw new Exception("Se requiere al menos un número de destino.");

    $webhookUrl = $_POST['webhook_url'] ?? $client->getConfig('webhook_url');
    
    // Auto-limpiar URL de webhook.site si el usuario pegó la URL de registro con ?token_id=...
    if (preg_match('/webhook\.site\/register\?token_id=([a-f0-9\-]+)/i', $webhookUrl, $matches)) {
        $webhookUrl = 'https://webhook.site/' . $matches[1];
        out("-> Auto-corregida la Webhook URL a su endpoint directo:", ['webhookUrl' => $webhookUrl], 'warning');
    }

    $nombreCampania = $_POST['nombre_campania'] ?? 'Prueba Campaña Septiembre 2026';

    switch ($accion) {
        case 'mensaje_masivo':
            out("=== ACCIÓN: Campaña Masiva de Texto ===");
            $mensaje = $_POST['mensaje_masivo_texto'] ?? '¡Hola! Este es un mensaje de prueba masivo con WhatzMeApi.';

            $body = [
                'numeros' => $numerosArr,
                'mensaje' => $mensaje,
                'webhookUrl' => $webhookUrl,
                'nombreCampania' => $nombreCampania
            ];

            out("Enviando a los siguientes números formateados:", $numerosArr, 'info');
            $res = $client->request(HTTP_Request2::METHOD_POST, '/enviar-mensaje-muchos-contactos', $body);
            out("Enviando Mensaje Masivo (POST /enviar-mensaje-muchos-contactos)...", $res);
            if ($res['status'] != 200) throw new Exception("Error al enviar campaña masiva de texto.");
            break;

        case 'archivo_masivo':
            out("=== ACCIÓN: Campaña Masiva de Archivos ===");
            $urlArchivo = $_POST['url_archivo_masivo'] ?? $client->getConfig('test_pdf_url');
            $nombreArchivo = $_POST['nombre_archivo'] ?? 'documento_prueba.pdf';
            $textoImagen = $_POST['texto_imagen'] ?? 'Catálogo adjunto de prueba.';

            $body = [
                'numeros' => $numerosArr,
                'url' => $urlArchivo,
                'nombrearchivo' => $nombreArchivo,
                'textoimagen' => $textoImagen,
                'webhookUrl' => $webhookUrl,
                'nombreCampania' => $nombreCampania
            ];

            $res = $client->request(HTTP_Request2::METHOD_POST, '/enviar-archivo-muchos-contactos', $body);
            out("Enviando Archivo Masivo (POST /enviar-archivo-muchos-contactos)...", $res);
            if ($res['status'] != 200) throw new Exception("Error al enviar campaña masiva de archivos.");
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

<?php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numero = $_POST['numero_destino'] ?? null;
$caption = $_POST['caption'] ?? 'Archivo desde WebApp';

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

if (!$numero) {
    out("ERROR: Se requiere un número destino.", null, 'error');
    if ($isAjax) { header('Content-Type: application/json'); echo json_encode(['status' => 'error', 'output' => $output]); }
    exit(1);
}

$accion = $_POST['accion'] ?? 'enviar';
$idMensaje = $_POST['id_mensaje'] ?? null;

// Responses payload
$responseData = ['status' => 'success', 'output' => &$output];

try {
    if ($accion === 'enviar') {
        out("=== ACCIÓN: Subir y Enviar Archivo ===");
        $urlAbsoluta = null;
        if (isset($_FILES['archivo_subido']) && $_FILES['archivo_subido']['error'] === UPLOAD_ERR_OK) {
            $uploadDir = __DIR__ . '/uploads/';
            $fileName = time() . '_' . basename($_FILES['archivo_subido']['name']);
            $uploadPath = $uploadDir . $fileName;

            if (move_uploaded_file($_FILES['archivo_subido']['tmp_name'], $uploadPath)) {
                $baseUrl = 'https://caelitandem.lat/mvps/whatzmeapi_tests/uploads/';
                $urlAbsoluta = $baseUrl . $fileName;
                out("-> Archivo guardado en servidor: $urlAbsoluta", null, 'success');
            } else {
                throw new Exception("No se pudo guardar el archivo en $uploadDir.");
            }
        } else {
            throw new Exception("No se recibió ningún archivo o hubo un error en la subida.");
        }

        if ($urlAbsoluta) {
            $endpoint = '/enviar-archivo';
            $body = ['numero' => $numero, 'url' => $urlAbsoluta, 'caption' => $caption];
            $res = $client->request(HTTP_Request2::METHOD_POST, $endpoint, $body);
            out("Enviando Archivo a WhatzMeApi ($endpoint)...", $res);

            if ($res['status'] == 200 && isset($res['data']['idMensaje'])) {
                $responseData['idMensaje'] = $res['data']['idMensaje'];
                out("-> ID del mensaje capturado exitosamente.", ['idMensaje' => $res['data']['idMensaje']], 'success');
            }
        }
    } 
    elseif ($accion === 'eliminar') {
        if (!$idMensaje) throw new Exception("Se requiere un ID de Mensaje para eliminar el archivo.");
        out("=== ACCIÓN: Eliminar Archivo Multimedia ===");
        $resDel = $client->request(HTTP_Request2::METHOD_DELETE, "/eliminar-mensaje/$idMensaje");
        out("Eliminando mensaje (DELETE /eliminar-mensaje/{id})...", $resDel);
        if ($resDel['status'] != 200) throw new Exception("Fallo la eliminación del archivo.");
    }
    else {
        throw new Exception("Acción no reconocida: $accion");
    }

} catch (Exception $e) {
    out("ERROR: " . $e->getMessage(), null, 'error');
    $responseData['status'] = 'error';
    $responseData['message'] = $e->getMessage();
}

out("Prueba de envío de archivo finalizada.");

if ($isAjax) {
    header('Content-Type: application/json');
    echo json_encode($responseData);
}

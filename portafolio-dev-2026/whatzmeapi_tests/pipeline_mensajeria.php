<?php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numero = $_POST['numero_destino'] ?? null;
$accion = $_POST['accion'] ?? 'enviar';
$idMensaje = $_POST['id_mensaje'] ?? null;

$mensajeOriginal = $_POST['mensaje_original'] ?? 'Mensaje Original Interactivo';
$mensajeEditado = $_POST['mensaje_editado'] ?? 'Mensaje Editado Interactivo';

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

// Responses payload
$responseData = ['status' => 'success', 'output' => &$output];

try {
    switch ($accion) {
        case 'enviar':
            if (!$numero) throw new Exception("Se requiere un número destino para enviar.");
            
            out("=== ACCIÓN: Enviar Mensaje ===");
            
            // 1. Calentamiento
            $body = ['numero' => $numero, 'mensaje' => 'Generando interacción previa...'];
            $res = $client->request(HTTP_Request2::METHOD_POST, '/calentar-whatsapps', $body);
            out("1. Calentando número (/calentar-whatsapps)...", $res);
            
            // 2. Enviar Mensaje Original
            $body = ['numero' => $numero, 'mensaje' => $mensajeOriginal];
            $res = $client->request(HTTP_Request2::METHOD_POST, '/enviar-mensaje', $body);
            out("2. Enviando mensaje original (/enviar-mensaje)...", $res);
            
            if ($res['status'] == 200 && isset($res['data']['idMensaje'])) {
                $responseData['idMensaje'] = $res['data']['idMensaje'];
                out("-> ID del mensaje capturado exitosamente.", ['idMensaje' => $res['data']['idMensaje']], 'success');
            } else {
                throw new Exception("Error: No se pudo obtener el idMensaje.");
            }
            break;

        case 'editar':
            if (!$idMensaje) throw new Exception("Se requiere un ID de Mensaje para editar.");
            
            out("=== ACCIÓN: Editar Mensaje ===");
            $bodyEdit = ['mensaje' => $mensajeEditado];
            $resEdit = $client->request(HTTP_Request2::METHOD_PUT, "/editar-mensaje/$idMensaje", $bodyEdit);
            out("Editando mensaje (PUT /editar-mensaje/{id})...", $resEdit);
            if ($resEdit['status'] != 200) throw new Exception("Fallo la edición del mensaje.");
            break;

        case 'eliminar':
            if (!$idMensaje) throw new Exception("Se requiere un ID de Mensaje para eliminar.");
            
            out("=== ACCIÓN: Eliminar Mensaje ===");
            $resDel = $client->request(HTTP_Request2::METHOD_DELETE, "/eliminar-mensaje/$idMensaje");
            out("Eliminando mensaje (DELETE /eliminar-mensaje/{id})...", $resDel);
            if ($resDel['status'] != 200) throw new Exception("Fallo la eliminación del mensaje.");
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

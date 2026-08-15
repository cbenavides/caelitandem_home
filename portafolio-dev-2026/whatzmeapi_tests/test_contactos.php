<?php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numero_prueba = $_POST['numero_destino'] ?? null;

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

$accion = $_POST['accion'] ?? 'agenda';

// Campos opcionales para creación de contacto
$nombre_contacto = $_POST['nombre_contacto'] ?? '';
$apellido_contacto = $_POST['apellido_contacto'] ?? '';

$responseData = ['status' => 'success', 'output' => &$output];

try {
    switch ($accion) {
        case 'agenda':
            out("=== ACCIÓN: Obtener Agenda de Contactos ===");
            $res = $client->request(HTTP_Request2::METHOD_GET, '/contactos');
            out("Ejecutando GET /contactos...", $res);
            if ($res['status'] != 200) throw new Exception("Error al obtener la agenda.");
            break;

        case 'info_foto':
            if (!$numero_prueba) throw new Exception("Se requiere un Número Destino en la barra superior.");
            out("=== ACCIÓN: Obtener Info y Foto de Contacto ===");
            
            $resInfo = $client->request(HTTP_Request2::METHOD_GET, "/contacto/$numero_prueba");
            out("1. Info del Contacto (GET /contacto/{numero})...", $resInfo);
            
            $resFoto = $client->request(HTTP_Request2::METHOD_GET, "/contacto/$numero_prueba/foto");
            out("2. Foto de Perfil (GET /contacto/{numero}/foto)...", $resFoto);
            break;

        case 'crear':
            if (!$numero_prueba || !$nombre_contacto) throw new Exception("Faltan campos: Número, Nombre.");
            out("=== ACCIÓN: Crear/Actualizar Contacto ===");
            
            $jid = $numero_prueba . "@s.whatsapp.net";
            $nombreCompleto = trim("$nombre_contacto $apellido_contacto");
            $body = [
                "jid" => $jid,
                "nombreCompleto" => $nombreCompleto,
                "guardarEnAgenda" => true
            ];
            
            $resCrear = $client->request(HTTP_Request2::METHOD_PUT, "/contacto", $body);
            out("Ejecutando PUT /contacto...", $resCrear);
            if ($resCrear['status'] != 200) throw new Exception("Fallo la creación del contacto.");
            break;

        case 'mapeo':
            if (!$numero_prueba) throw new Exception("Se requiere un Número Destino en la barra superior.");
            out("=== ACCIÓN: Mapeo LID y Número ===");
            
            // 1. Número -> LID
            $resLid = $client->request(HTTP_Request2::METHOD_GET, "/contacto-lid/$numero_prueba");
            out("1. Obtener LID (GET /contacto-lid/{numero})...", $resLid);
            
            if ($resLid['status'] == 200 && isset($resLid['data']['lid'])) {
                $lid = $resLid['data']['lid'];
                // 2. LID -> Número
                $resNum = $client->request(HTTP_Request2::METHOD_GET, "/contacto-numero/$lid");
                out("2. Revertir LID a Número (GET /contacto-numero/{lid})...", $resNum);
            } else {
                out("-> No se pudo obtener el LID para realizar la prueba inversa.", null, "warning");
            }
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

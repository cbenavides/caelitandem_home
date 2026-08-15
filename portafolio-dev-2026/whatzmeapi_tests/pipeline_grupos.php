<?php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numero_participante = $_POST['numero_destino'] ?? null;
$nombre_grupo = $_POST['nombre_grupo'] ?? 'Grupo Test Interactivo';

$accion = $_POST['accion'] ?? 'crear';
$jidGrupo = $_POST['jid_grupo'] ?? null;

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
        case 'crear':
            if (!$numero_participante) throw new Exception("Se requiere un número destino para agregarlo al grupo.");
            
            out("=== ACCIÓN: Crear Grupo ===");
            
            // 1. Obtener Grupos (sólo por mostrar la consulta)
            $resGrupos = $client->request(HTTP_Request2::METHOD_GET, '/grupos');
            out("Obteniendo Grupos Actuales (/grupos)...", $resGrupos);
            
            // 2. Crear Grupo
            $bodyCreate = [
                'nombre' => $nombre_grupo,
                'participantes' => [$numero_participante]
            ];
            $resCreate = $client->request(HTTP_Request2::METHOD_POST, '/grupos', $bodyCreate);
            out("Creando Grupo (POST /grupos)...", $resCreate);
            
            if ($resCreate['status'] == 200 && isset($resCreate['data']['JID'])) {
                $responseData['jidGrupo'] = $resCreate['data']['JID'];
                out("-> JID del Grupo capturado exitosamente.", ['jidGrupo' => $resCreate['data']['JID']], 'success');
            } else {
                throw new Exception("Error: No se pudo obtener el JID del grupo.");
            }
            break;

        case 'configurar':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Configurar Grupo ===");
            $bodyConfig = [
                'soloAdmins' => true,
                'soloAdminsEnviarMensajes' => true
            ];
            $resConfig = $client->request(HTTP_Request2::METHOD_PUT, "/grupo/$jidGrupo/configuracion", $bodyConfig);
            out("Configurando Grupo a Solo Admins (PUT /grupo/{id}/configuracion)...", $resConfig);
            if ($resConfig['status'] != 200) throw new Exception("Fallo la configuración del grupo.");
            break;

        case 'promover':
            if (!$jidGrupo || !$numero_participante) throw new Exception("Se requiere JID del grupo y número del participante.");
            out("=== ACCIÓN: Promover Participante ===");
            $bodyAdmin = [
                'accion' => 'promote',
                'participantes' => [$numero_participante]
            ];
            $resAdmin = $client->request(HTTP_Request2::METHOD_PUT, "/grupo/$jidGrupo/participantes/actualizar", $bodyAdmin);
            out("Promoviendo participante a Admin (PUT /grupo/{id}/participantes/actualizar)...", $resAdmin);
            if ($resAdmin['status'] != 200) throw new Exception("Fallo la promoción de rol.");
            break;

        case 'invitacion':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Link de Invitación ===");
            $resInvite = $client->request(HTTP_Request2::METHOD_GET, "/grupo/$jidGrupo/enlace-invitacion");
            out("Obteniendo Link de Invitación (/grupo/{id}/enlace-invitacion)...", $resInvite);
            if ($resInvite['status'] != 200) throw new Exception("Fallo al obtener link de invitación.");
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

<?php
// pipeline_grupos.php
require_once 'ApiTestClient.php';

$token = $_POST['token'] ?? null;
$numero_participante = $_POST['numero_destino'] ?? null;
$nombre_grupo = $_POST['nombre_grupo'] ?? 'Grupo Test Interactivo';

$accion = $_POST['accion'] ?? 'crear';
$jidGrupo = $_POST['jid_grupo'] ?? null;
$codigoInvitacion = $_POST['codigo_invitacion'] ?? null;

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
    switch ($accion) {
        case 'crear':
            if (!$numero_participante) throw new Exception("Se requiere un número destino para agregarlo al grupo.");
            
            out("=== ACCIÓN: Crear Grupo ===");
            
            // Format participant jid if missing domain
            $participantJid = (strpos($numero_participante, '@') === false) ? $numero_participante . '@s.whatsapp.net' : $numero_participante;

            // 1. Obtener Grupos Actuales
            $resGrupos = $client->request(HTTP_Request2::METHOD_GET, '/grupos', null, ['paginado' => 'false']);
            out("1. Obteniendo Grupos Actuales (GET /grupos)...", $resGrupos);
            
            // 2. Crear Grupo
            $bodyCreate = [
                'nombre' => $nombre_grupo,
                'participantes' => [$participantJid]
            ];
            $resCreate = $client->request(HTTP_Request2::METHOD_POST, '/grupos', $bodyCreate);
            out("2. Creando Grupo (POST /grupos)...", $resCreate);
            
            if ($resCreate['status'] == 200 && (isset($resCreate['data']['JID']) || isset($resCreate['data']['jid']))) {
                $jid = $resCreate['data']['JID'] ?? $resCreate['data']['jid'];
                $responseData['jidGrupo'] = $jid;
                out("-> JID del Grupo capturado exitosamente.", ['jidGrupo' => $jid], 'success');
            } else {
                out("Aviso: Respuesta recibida pero no se obtuvo JID automáticamente.", $resCreate, 'warning');
            }
            break;

        case 'metadata':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Obtener Metadata del Grupo ===");
            $res = $client->request(HTTP_Request2::METHOD_GET, "/grupo/$jidGrupo/metadata");
            out("Obteniendo Metadata (GET /grupo/{id}/metadata)...", $res);
            if ($res['status'] != 200) throw new Exception("Error al obtener metadata.");
            break;

        case 'participantes':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Obtener Lista de Participantes ===");
            $res = $client->request(HTTP_Request2::METHOD_GET, "/grupo/$jidGrupo/participantes");
            out("Obteniendo Participantes (GET /grupo/{id}/participantes)...", $res);
            if ($res['status'] != 200) throw new Exception("Error al obtener lista de participantes.");
            break;

        case 'foto':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Obtener Foto del Grupo ===");
            $res = $client->request(HTTP_Request2::METHOD_GET, "/grupo/$jidGrupo/foto");
            out("Obteniendo Foto de Perfil del Grupo (GET /grupo/{id}/foto)...", $res);
            break;

        case 'configurar':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Configurar Grupo ===");
            $bodyConfig = [
                'asunto' => $nombre_grupo,
                'descripcion' => 'Grupo gestionado vía WhatzMeApi Sandbox 2026',
                'soloAdmins' => true,
                'restringir' => true
            ];
            $resConfig = $client->request(HTTP_Request2::METHOD_PUT, "/grupo/$jidGrupo/configuracion", $bodyConfig);
            out("Configurando Permisos (PUT /grupo/{id}/configuracion)...", $resConfig);
            if ($resConfig['status'] != 200) throw new Exception("Fallo la configuración del grupo.");
            break;

        case 'promover':
            if (!$jidGrupo || !$numero_participante) throw new Exception("Se requiere JID del grupo y número del participante.");
            out("=== ACCIÓN: Promover Participante ===");
            $participantJid = (strpos($numero_participante, '@') === false) ? $numero_participante . '@s.whatsapp.net' : $numero_participante;
            $bodyAdmin = [
                'accion' => 'promote',
                'participantes' => [$participantJid]
            ];
            $resAdmin = $client->request(HTTP_Request2::METHOD_PUT, "/grupo/$jidGrupo/participantes/actualizar", $bodyAdmin);
            out("Promoviendo a Administrador (PUT /grupo/{id}/participantes/actualizar)...", $resAdmin);
            if ($resAdmin['status'] != 200) throw new Exception("Fallo la promoción del rol.");
            break;

        case 'agregar_miembro':
            if (!$jidGrupo || !$numero_participante) throw new Exception("Se requiere JID del grupo y número del participante.");
            out("=== ACCIÓN: Agregar Participante ===");
            $participantJid = (strpos($numero_participante, '@') === false) ? $numero_participante . '@s.whatsapp.net' : $numero_participante;
            $bodyAdd = [
                'participantes' => [$participantJid]
            ];
            $resAdd = $client->request(HTTP_Request2::METHOD_POST, "/grupo/$jidGrupo/participantes/agregar", $bodyAdd);
            out("Agregando Miembro (POST /grupo/{id}/participantes/agregar)...", $resAdd);
            break;

        case 'eliminar_miembro':
            if (!$jidGrupo || !$numero_participante) throw new Exception("Se requiere JID del grupo y número del participante.");
            out("=== ACCIÓN: Eliminar Participante ===");
            $participantJid = (strpos($numero_participante, '@') === false) ? $numero_participante . '@s.whatsapp.net' : $numero_participante;
            $bodyDel = [
                'participantes' => [$participantJid]
            ];
            $resDel = $client->request(HTTP_Request2::METHOD_POST, "/grupo/$jidGrupo/participantes/eliminar", $bodyDel);
            out("Eliminando Miembro (POST /grupo/{id}/participantes/eliminar)...", $resDel);
            break;

        case 'invitacion':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Obtener Link de Invitación ===");
            $resInvite = $client->request(HTTP_Request2::METHOD_GET, "/grupo/$jidGrupo/enlace-invitacion");
            out("Obteniendo Link (GET /grupo/{id}/enlace-invitacion)...", $resInvite);
            if ($resInvite['status'] == 200 && isset($resInvite['data']['codigo'])) {
                $responseData['codigoInvitacion'] = $resInvite['data']['codigo'];
            }
            break;

        case 'info_invitacion':
            $code = $codigoInvitacion ?: $_POST['codigo_invitacion'] ?? 'ABCDE12345';
            out("=== ACCIÓN: Obtener Info de Invitación ===");
            $res = $client->request(HTTP_Request2::METHOD_GET, "/grupo/invitacion/$code");
            out("Consultando Info de Código (GET /grupo/invitacion/{code})...", $res);
            break;

        case 'aceptar_invitacion':
            $code = $codigoInvitacion ?: $_POST['codigo_invitacion'] ?? null;
            if (!$code) throw new Exception("Se requiere un código de invitación válido.");
            out("=== ACCIÓN: Aceptar Invitación a Grupo ===");
            $res = $client->request(HTTP_Request2::METHOD_POST, "/grupo/invitacion/aceptar", ['codigo' => $code]);
            out("Aceptando Invitación (POST /grupo/invitacion/aceptar)...", $res);
            break;

        case 'menciones':
            if (!$jidGrupo || !$numero_participante) throw new Exception("Se requiere JID del grupo y número para mencionar.");
            out("=== ACCIÓN: Enviar Mensaje con Menciones ===");
            $participantJid = (strpos($numero_participante, '@') === false) ? $numero_participante . '@s.whatsapp.net' : $numero_participante;
            $numClean = preg_replace('/[^0-9]/', '', $numero_participante);
            $mensajeText = $_POST['mensaje_mencion'] ?? "Hola @$numClean, mensaje importante de prueba 📢";

            $body = [
                'numero' => $jidGrupo,
                'mensaje' => $mensajeText,
                'menciones' => [$participantJid]
            ];
            $res = $client->request(HTTP_Request2::METHOD_POST, "/grupo/enviar-mensaje-con-menciones", $body);
            out("Enviando Mensaje con Menciones (POST /grupo/enviar-mensaje-con-menciones)...", $res);
            break;

        case 'salir':
            if (!$jidGrupo) throw new Exception("Se requiere el JID del Grupo.");
            out("=== ACCIÓN: Salir del Grupo ===");
            $res = $client->request(HTTP_Request2::METHOD_POST, "/grupo/$jidGrupo/salir");
            out("Saliendo del Grupo (POST /grupo/{id}/salir)...", $res);
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

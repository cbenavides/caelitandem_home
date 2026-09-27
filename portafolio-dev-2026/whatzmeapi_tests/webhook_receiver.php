<?php
// webhook_receiver.php
// Receptor y consulta de notificaciones Webhook para estado de mensajes (sent, delivered, read)

$eventsFile = __DIR__ . '/webhook_events.json';

// Acción GET/POST para consultar o limpiar eventos desde la WebApp
if (isset($_GET['action'])) {
    header('Content-Type: application/json');
    $action = $_GET['action'];

    if ($action === 'list') {
        $events = file_exists($eventsFile) ? json_decode(file_get_contents($eventsFile), true) : [];
        echo json_encode(['status' => 'success', 'events' => $events ?: []]);
        exit;
    }
    
    if ($action === 'clear') {
        file_put_contents($eventsFile, json_encode([]));
        echo json_encode(['status' => 'success', 'message' => 'Historial de eventos de estado limpiado.']);
        exit;
    }
}

// Recepción de Petición Webhook POST desde WhatzMeApi
$rawInput = file_get_contents('php://input');
if (!empty($rawInput)) {
    $data = json_decode($rawInput, true) ?: ['raw' => $rawInput];
    
    $events = file_exists($eventsFile) ? json_decode(file_get_contents($eventsFile), true) : [];
    if (!is_array($events)) $events = [];
    
    $entry = [
        'timestamp' => date('Y-m-d H:i:s'),
        'payload' => $data
    ];
    
    array_unshift($events, $entry); // Insertar al inicio
    $events = array_slice($events, 0, 50); // Mantener últimos 50 eventos
    
    file_put_contents($eventsFile, json_encode($events, JSON_PRETTY_PRINT));
    
    header('Content-Type: application/json');
    echo json_encode(['status' => 'received', 'timestamp' => date('Y-m-d H:i:s')]);
    exit;
}

header('Content-Type: application/json');
echo json_encode(['status' => 'idle', 'message' => 'Webhook Receiver activo. Envíe peticiones POST.']);

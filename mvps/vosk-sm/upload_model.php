<?php
// upload_model.php
// Permite subir el modelo de voz offline individualmente para no superar el límite de POST de 40MB
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($_FILES['modelfile'])) {
        echo json_encode(["status" => "error", "message" => "No file uploaded"]);
        exit;
    }
    
    $file = $_FILES['modelfile'];
    if ($file['error'] !== UPLOAD_ERR_OK) {
        echo json_encode(["status" => "error", "message" => "Upload error code: " . $file['error']]);
        exit;
    }
    
    $targetDir = dirname(__DIR__) . '/web-assets/models';
    if (!is_dir($targetDir)) {
        mkdir($targetDir, 0777, true);
    }
    
    $targetPath = $targetDir . '/vosk-model-small-es-0.42.tar.gz';
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        echo json_encode(["status" => "success", "message" => "Model uploaded successfully to $targetPath"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to move uploaded file"]);
    }
    exit;
}

if (isset($_GET['action']) && $_GET['action'] === 'delete') {
    if (unlink(__FILE__)) {
        echo json_encode(["status" => "success", "message" => "Upload helper deleted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to delete helper"]);
    }
    exit;
}

echo json_encode(["status" => "info", "message" => "Upload helper active. Use POST with 'modelfile'"]);
?>

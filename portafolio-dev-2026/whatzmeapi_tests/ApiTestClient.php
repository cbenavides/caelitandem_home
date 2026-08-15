<?php
// ApiTestClient.php
require_once 'HTTP/Request2.php';

class ApiTestClient {
    private $config;
    private $token;
    
    public function __construct($token = null) {
        $this->config = require 'config.php';
        $this->token = $token ?: ($this->config['token'] ?? null);
    }
    
    public function getConfig($key) {
        return $this->config[$key] ?? null;
    }

    public function request($method, $endpoint, $body = null, $queryParams = []) {
        $url = $this->config['base_url'] . $endpoint;
        
        $params = array_merge(['token' => $this->token], $queryParams);
        $url .= '?' . http_build_query($params);

        $request = new HTTP_Request2($url);
        $request->setMethod($method);
        $request->setConfig([
            'ssl_verify_peer' => false,
            'ssl_verify_host' => false,
            'connect_timeout' => 10,
            'timeout'         => 30
        ]);

        $request->setHeader('Accept', 'application/json');

        if ($body !== null) {
            $request->setHeader('Content-Type', 'application/json');
            $request->setBody(is_array($body) ? json_encode($body) : $body);
        }

        try {
            $response = $request->send();
            $bodyStr = $response->getBody();
            return [
                'status' => $response->getStatus(),
                'data' => json_decode($bodyStr, true) ?: $bodyStr
            ];
        } catch (HTTP_Request2_Exception $e) {
            return [
                'status' => 0,
                'error' => $e->getMessage()
            ];
        }
    }
    
    public function requireConnection() {
        $isAjax = isset($_POST['ajax']) || isset($_GET['ajax']);
        
        if (!$isAjax) echo "Validando estado de la sesión...\n";
        
        $response = $this->request(HTTP_Request2::METHOD_GET, '/estado');
        
        if ($response['status'] !== 200 || !isset($response['data']['respuesta']) || $response['data']['respuesta'] !== 'connected') {
            $errMsg = "ERROR: La sesión de WhatsApp no está conectada o el Token es inválido. Por favor, escanea el QR primero.";
            if ($isAjax) {
                header('Content-Type: application/json');
                echo json_encode(['status' => 'error', 'message' => $errMsg, 'output' => $response]);
            } else {
                echo $errMsg . "\nEstado: " . print_r($response, true) . "\n";
            }
            exit(1);
        }
        if (!$isAjax) echo "OK: Sesión conectada.\n";
    }
}

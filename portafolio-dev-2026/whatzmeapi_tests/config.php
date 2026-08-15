<?php
// config.php
// Configuración centralizada para las pruebas de WhatzMeApi

return [
    'base_url' => 'https://api.whatzmeapi.com/basic',
    'token' => getenv('WHATZMEAPI_TOKEN') ?: 'AQUI_TU_TOKEN',
    
    // Configuración para pruebas de mensajes
    'numero_prueba' => '521234567890', 
    'numeros_masivos' => ['521234567890', '521098765432'],
    'webhook_url' => 'https://webhook.site/test-webhook-url', // Para probar campañas masivas
    
    // Configuración de grupos
    'grupo_nombre' => 'Grupo Test WhatzMeApi ' . date('Y-m-d H:i:s'),
    'grupo_jid_existente' => '521234567890-1234567890@g.us',
    
    // URLs multimedia para pruebas
    'test_image_url' => 'https://d1ih8jugeo2m5m.cloudfront.net/2025/07/whatsapp_business_api.webp',
    'test_pdf_url' => 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    'test_audio_url' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'test_video_url' => 'https://www.w3schools.com/html/mov_bbb.mp4',
    'test_sticker_url' => 'https://img-06.stickers.cloud/packs/5df297e3-a7f0-44e0-a6d1-43bdb09b793c/webp/8709a42d-0579-4314-b659-9c2cdb979305.webp'
];

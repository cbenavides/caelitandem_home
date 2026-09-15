<?php
// docs-dev/migration-laesh/01_seed_catalog.php
// Script de migración: Lee catalog-data.js e inserta en MariaDB

$configPath = __DIR__ . '/../../www/laesh-swbldi/commons/config.php';
$config = require $configPath;
$dbConf = $config['db'];

try {
    $dsn = sprintf("mysql:host=%s;port=%d;dbname=%s;charset=%s", $dbConf['host'], $dbConf['port'], $dbConf['name'], $dbConf['charset']);
    $pdo = new PDO($dsn, $dbConf['user'], $dbConf['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
} catch (Exception $e) {
    die("Error de conexión a DB: " . $e->getMessage() . "\n");
}

$jsPath = __DIR__ . '/../../www/laesh-web-assets-uipv1a/js/catalog-data.js';
if (!file_exists($jsPath)) {
    die("No se encontró el archivo: $jsPath\n");
}

$jsContent = file_get_contents($jsPath);

// Limpiar 'window.laeshCatalogData = ' y el ';' del final
$jsonString = preg_replace('/^window\.laeshCatalogData\s*=\s*/', '', $jsContent);
$jsonString = preg_replace('/;\s*$/', '', trim($jsonString));

$data = json_decode($jsonString, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    die("Error parseando JSON: " . json_last_error_msg() . "\n");
}

// Empezamos la transacción
$pdo->beginTransaction();
try {
    // Limpiar tablas para re-sembrar (Cuidado en prod, pero esto es dev)
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0");
    $pdo->exec("TRUNCATE TABLE cat_estudios");
    $pdo->exec("TRUNCATE TABLE cat_categorias");
    $pdo->exec("TRUNCATE TABLE cat_gabinetes");
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1");

    echo "Tablas limpiadas.\n";

    $ordenGabinete = 1;
    $ordenCategoria = 1;
    
    // Suponemos que $data es un array de catálogos o gabinetes.
    // Analizando catalog-data.js, parece que laeshCatalogData es un array cuyo primer elemento es el catálogo principal.
    $catalogoPrincipal = $data[0]; 
    
    if (!isset($catalogoPrincipal['categorias'])) {
        throw new Exception("Formato inesperado: no se encontró 'categorias' en la raíz.");
    }

    foreach ($catalogoPrincipal['categorias'] as $grupo) {
        // En la UI, a veces los llaman grupos, categorias o gabinetes.
        // Insertamos como Categoria
        $stmtCat = $pdo->prepare("INSERT INTO cat_categorias (nombre, orden) VALUES (?, ?)");
        $stmtCat->execute([$grupo['nombre'], $ordenCategoria++]);
        $catId = $pdo->lastInsertId();
        
        echo "Insertada Categoría: {$grupo['nombre']} (ID: $catId)\n";

        if (isset($grupo['estudios'])) {
            foreach ($grupo['estudios'] as $est) {
                // Parseamos pruebas incluidas, si es un array o string
                $pruebasTexto = '';
                if (isset($est['pruebas_incluidas'])) {
                    if (is_array($est['pruebas_incluidas'])) {
                        $pruebasTexto = implode("\n", $est['pruebas_incluidas']);
                    } else {
                        $pruebasTexto = $est['pruebas_incluidas'];
                    }
                }

                $stmtEst = $pdo->prepare("
                    INSERT INTO cat_estudios 
                    (clave, nombre, muestra, contenedor, tiempo, categoria_id, preparacion, pruebas_incluidas) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ");
                
                $stmtEst->execute([
                    $est['clave'] ?? null,
                    $est['nombre'],
                    $est['muestra'] ?? null,
                    $est['contenedor'] ?? null,
                    $est['tiempo'] ?? null,
                    $catId,
                    $est['preparacion'] ?? null,
                    $pruebasTexto
                ]);
                $estCounter++;
            }
        }
    }

    // 4. Sembrar Gabinetes por defecto (Desde Mock anterior)
    $gabinetesDefault = [
        ['nombre' => 'Rayos X', 'orden' => 1],
        ['nombre' => 'Ultrasonido', 'orden' => 2],
        ['nombre' => 'Laboratorio', 'orden' => 3]
    ];
    $stmtG = $pdo->prepare("INSERT INTO cat_gabinetes (nombre, orden) VALUES (?, ?)");
    foreach ($gabinetesDefault as $g) {
        $stmtG->execute([$g['nombre'], $g['orden']]);
    }
    
    // Y un par de subgabinetes
    $stmtS = $pdo->prepare("INSERT INTO cat_subgabinetes (gabinete_id, nombre, orden) VALUES (?, ?, ?)");
    $stmtS->execute([2, 'Abdomen', 1]); // Ultrasonido -> Abdomen
    $stmtS->execute([2, 'Pelvis', 2]);  // Ultrasonido -> Pelvis
    $stmtS->execute([3, 'Hematología', 1]); // Laboratorio -> Hematología

    // Y un par de I. Gabinetes
    $stmtI = $pdo->prepare("INSERT INTO cat_igabinetes (nombre, orden) VALUES (?, ?)");
    $stmtI->execute(['I. Rayos X', 1]);
    $stmtI->execute(['I. Ultrasonido', 2]);

    $catCounter = $ordenCategoria - 1;

    $pdo->commit();

    echo "✅ Sembrado de Gabinetes completado.\n";
    echo "============================================\n";
    echo "¡Migración y Seeding completados exitosamente!\n";
    echo "Total Categorías: $catCounter\n";
    echo "Total Estudios: $estCounter\n";
} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "❌ ERROR FATAL: " . $e->getMessage() . "\n";
    exit(1);
}

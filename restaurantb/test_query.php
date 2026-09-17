<?php
require_once __DIR__ . '/www/laesh-swbldi/commons/commons.php';
$db = Flight::db();
$stmt = $db->query("SELECT id, nombre FROM cat_gabinetes WHERE nombre LIKE '%Uro%'");
$gabs = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "Gabinetes:\n";
print_r($gabs);

foreach ($gabs as $g) {
    $stmt2 = $db->prepare("SELECT count(*) as cnt, subgabinete_id FROM rel_estudio_gabinete WHERE gabinete_id = ? GROUP BY subgabinete_id");
    $stmt2->execute([$g['id']]);
    echo "Estudios para gabinete " . $g['id'] . ":\n";
    print_r($stmt2->fetchAll(PDO::FETCH_ASSOC));
}

<?php
// /legacy/inventory.php - Endpoint JSON de inventario (solo lectura)
header('Content-Type: application/json; charset=utf-8');

$mysqli = @new mysqli('127.0.0.1', 'root', '', 'cafe_aurora');
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['error' => 'DB connection failed', 'detail' => $mysqli->connect_error], JSON_UNESCAPED_UNICODE);
    exit;
}

// Intenta leer de 'inventory', si no existe, cae a 'products'
$items = [];
$q1 = $mysqli->query("SHOW TABLES LIKE 'inventory'");
if ($q1 && $q1->num_rows > 0) {
    $sql = "SELECT id, name, stock FROM inventory ORDER BY id";
} else {
    $sql = "SELECT id, name, stock FROM products ORDER BY id";
}

$res = $mysqli->query($sql);
if ($res) {
    while ($row = $res->fetch_assoc()) {
        $items[] = [
            'id'    => (int)$row['id'],
            'name'  => $row['name'],
            's

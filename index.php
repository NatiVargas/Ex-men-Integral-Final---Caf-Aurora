<?php
// index.php - Página principal de Café Aurora

$servername = "localhost";
$username = "root";  // tu usuario de XAMPP
$password = "";      // tu contraseña de XAMPP
$dbname = "cafe_aurora";

// Crear conexión
$conn = new mysqli($servername, $username, $password, $dbname);

// Revisar conexión
if ($conn->connect_error) {
    die("Conexión fallida: " . $conn->connect_error);
}

// Consulta ejemplo
$sql = "SELECT * FROM productos";
$result = $conn->query($sql);
?>
<!DOCTYPE html>
<html>
<head>
    <title>Café Aurora</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <h1>Bienvenido a Café Aurora</h1>
    <ul>
        <?php
        if ($result->num_rows > 0) {
            while($row = $result->fetch_assoc()) {
                echo "<li>" . $row["nombre"] . " - " . $row["precio"] . "</li>";
            }
        } else {
            echo "<li>No hay productos</li>";
        }
        $conn->close();
        ?>
    </ul>

    <script src="scripts.js"></script>
</body>
</html>

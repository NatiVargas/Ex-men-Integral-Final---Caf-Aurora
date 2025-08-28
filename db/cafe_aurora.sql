CREATE DATABASE IF NOT EXISTS cafe_aurora;
USE cafe_aurora;

CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    precio DECIMAL(5,2) NOT NULL
);

INSERT INTO productos (nombre, precio) VALUES 
('Café Americano', 1.50),
('Capuchino', 2.50),
('Espresso', 1.75);

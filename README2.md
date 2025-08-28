\# Café Aurora – Entrega examen



\## Requisitos

\- Ubuntu 24.04

\- XAMPP (MySQL en `/opt/lampp`)

\- Nginx como reverse proxy con TLS

\- PHP 8.3 + php8.3-fpm + php8.3-mysql



\## Pasos clave

1\. Certificado self-signed en `/etc/nginx/tls/self.{crt,key}`

2\. Sitio Nginx `cafe-aurora.conf` con:

&nbsp;  - redirección 80→443

&nbsp;  - `/legacy/\*` → Apache:8080

&nbsp;  - `/api/\*`    → Apache:8080 (microcache 1s)

&nbsp;  - PHP por `fastcgi\_pass unix:/var/run/php/php8.3-fpm.sock`

3\. MySQL (XAMPP): BD `cafe\_aurora` con `products`, `orders`, `order\_items`, etc.

4\. API:

&nbsp;  - `api/products.php` → listado de productos (JSON)

&nbsp;  - `api/orders.php` y `?order\_id=1` → órdenes (JSON)

5\. Frontend `index.php` consulta directa a MySQL (host `127.0.0.1`).

6\. Evidencias en `~/evidence` (ab, curl, dumps).



\## Comandos útiles

```bash

sudo systemctl status nginx php8.3-fpm

sudo /opt/lampp/lampp start




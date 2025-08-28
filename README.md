# Café Aurora – Entrega examen

## 1) Infra local
- **XAMPP** (Apache/MariaDB) en 8080.
- **Nginx** como reverse proxy TLS (gzip + microcache).
- **PHP-FPM 8.3** sirviendo `index.php`.

Rutas (vía Nginx):
- `https://localhost/index.php` → PHP leyendo BD `cafe_aurora`.
- `https://localhost/legacy/inventory.php` → JSON “legado”.
- `https://localhost/api/*` → proxy a XAMPP (8080) con microcache.
- `https://localhost/k8s/catalog|orders|customers` → NodePort de Minikube.

## 2) Kubernetes (Minikube)
- Deployments: `catalog`, `orders`, `customers` (imagen `hashicorp/http-echo`).
- Services: **NodePort** (ya mapeados en Nginx en `/k8s/*`).
- (Opcional) Ingress (`k8s/ingress.yaml`) si prefieres no usar NodePorts.
- (Opcional) HPA de ejemplo (`k8s/hpa.yaml`).

## 3) Nginx
- `nginx/cafe-aurora.conf` → vhost TLS + PHP-FPM + `/legacy` + `/api` + `/k8s/*`.
- `nginx/gzip.conf` → compresión gzip.
- `nginx/cache.conf` → microcache + variables `map`.

## 4) Cómo levantar (resumen)
```bash
# Minikube
minikube start
# Aplica manifests (NodePorts):
kubectl apply -f k8s/catalog.yaml
kubectl apply -f k8s/orders.yaml
kubectl apply -f k8s/customers.yaml
# (Opcional) Ingress
# minikube addons enable ingress
# kubectl apply -f k8s/ingress.yaml

# Nginx (en el servidor)
sudo nginx -t && sudo systemctl reload nginx

5) Probar
# PHP
curl -k https://localhost/index.php

# API legacy (XAMPP)
curl -k https://localhost/legacy/inventory.php

# K8s vía NodePort (a través de Nginx)
curl -k https://localhost/k8s/catalog
curl -k https://localhost/k8s/orders
curl -k https://localhost/k8s/customers

6) Notas

index.php usa mysqli con host 127.0.0.1 (TCP) y usuario root sin password (como XAMPP por defecto).

Ajusta certificados TLS si cambias server_name.




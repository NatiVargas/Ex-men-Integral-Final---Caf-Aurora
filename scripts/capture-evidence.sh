#!/usr/bin/env bash
set -euo pipefail

# === Parámetros / rutas ===
OUT_DIR="${1:-$HOME/evidence}"
TS="$(date +'%Y%m%d-%H%M%S')"
RUN_DIR="$OUT_DIR/run-$TS"
mkdir -p "$RUN_DIR"

echo ">> Guardando evidencias en: $RUN_DIR"

# === Sistema / versiones ===
{
  echo "# Fechayhora"
  date -Is
  echo
  echo "# Versiones"
  uname -a || true
  nginx -v 2>&1 || true
  php -v || true
  /opt/lampp/lampp status || true
  echo
  echo "# Servicios"
  systemctl --no-pager --full status nginx || true
  systemctl --no-pager --full status php8.3-fpm || true
} > "$RUN_DIR/system_and_services.txt"

# === Nginx config efectiva y pruebas gzip ===
{
  echo "# nginx -t"
  sudo nginx -t || true
  echo
  echo "# grep gzip on"
  grep -R "^[[:space:]]*gzip[[:space:]]\+on;" -n /etc/nginx 2>&1 || true
  echo
  echo "# Conf sitio cafe-aurora"
  sudo cat /etc/nginx/sites-available/cafe-aurora.conf || true
  echo
  echo "# Conf gzip"
  sudo cat /etc/nginx/conf.d/gzip.conf || true
  echo
  echo "# Conf microcache"
  sudo cat /etc/nginx/conf.d/cache.conf || true
} > "$RUN_DIR/nginx_config.txt"

# Pruebas gzip (cabeceras)
{
  echo "== /api/products.php =="
  curl -k -I -H 'Accept-Encoding: gzip' https://localhost/api/products.php || true
  echo
  echo "== /legacy/inventory.php =="
  curl -k -I -H 'Accept-Encoding: gzip' https://localhost/legacy/inventory.php || true
} > "$RUN_DIR/gzip_headers.txt"

# Prueba microcache (dos hits seguidos a /api/products.php)
{
  echo "Primer request (espera MISS)"
  curl -k -D - -o /dev/null https://localhost/api/products.php 2>/dev/null | grep -i 'x-cache\|status' || true
  echo
  echo "Segundo request inmediato (debería HIT)"
  curl -k -D - -o /dev/null https://localhost/api/products.php 2>/dev/null | grep -i 'x-cache\|status' || true
} > "$RUN_DIR/microcache_check.txt"

# === Endpoints locales principales ===
{
  echo "== index.php (PHP + BD) =="
  curl -k -sS -D "$RUN_DIR/index_headers.txt" https://localhost/index.php | head -n 50 || true
  echo
  echo "== legacy/inventory.php (JSON legado) =="
  curl -k -sS -D "$RUN_DIR/legacy_headers.txt" https://localhost/legacy/inventory.php | head -n 100 || true
} > "$RUN_DIR/local_endpoints_preview.txt"

# === Kubernetes / Minikube ===
{
  echo "# minikube ip"
  minikube ip || true
  echo
  echo "# nodos"
  kubectl get nodes -o wide || true
  echo
  echo "# pods (all namespaces)"
  kubectl get pods -A -o wide || true
  echo
  echo "# services (default)"
  kubectl get svc -o wide || true
  echo
  echo "# deployments"
  kubectl get deploy -o wide || true
} > "$RUN_DIR/k8s_state.txt"

# Curl directo a los NodePort (si existen) y vía Nginx (/k8s/*)
MINIKUBE_IP="$(minikube ip 2>/dev/null || echo '192.168.49.2')"

# Detectar puertos de NodePort (si están en 80:PORT/TCP)
PORT_CATALOG="$(kubectl get svc catalog    -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || true)"
PORT_ORDERS="$(kubectl get svc orders     -o jsonpath='{.spec.ports[0].nodePort}'  2>/dev/null || true)"
PORT_CUSTOM="$(kubectl get svc customers  -o jsonpath='{.spec.ports[0].nodePort}'  2>/dev/null || true)"

{
  echo "# Curl directo a NodePorts"
  if [[ -n "${PORT_CATALOG:-}" ]]; then
    echo "catalog -> http://${MINIKUBE_IP}:${PORT_CATALOG}"
    curl -sS "http://${MINIKUBE_IP}:${PORT_CATALOG}" || true
    echo; echo
  fi
  if [[ -n "${PORT_ORDERS:-}" ]]; then
    echo "orders  -> http://${MINIKUBE_IP}:${PORT_ORDERS}"
    curl -sS "http://${MINIKUBE_IP}:${PORT_ORDERS}" || true
    echo; echo
  fi
  if [[ -n "${PORT_CUSTOM:-}" ]]; then
    echo "customers -> http://${MINIKUBE_IP}:${PORT_CUSTOM}"
    curl -sS "http://${MINIKUBE_IP}:${PORT_CUSTOM}" || true
    echo; echo
  fi

  echo "# Curl vía Nginx reverse proxy (/k8s/*)"
  echo "https://localhost/k8s/catalog"
  curl -k -sS https://localhost/k8s/catalog || true
  echo; echo "https://localhost/k8s/orders"
  curl -k -sS https://localhost/k8s/orders || true
  echo; echo "https://localhost/k8s/customers"
  curl -k -sS https://localhost/k8s/customers || true
  echo
} > "$RUN_DIR/k8s_curls.txt"

# === Logs breves ===
sudo tail -n 200 /var/log/nginx/error.log     > "$RUN_DIR/nginx_error_tail.txt" 2>/dev/null || true
sudo tail -n 200 /var/log/nginx/access.log    > "$RUN_DIR/nginx_access_tail.txt" 2>/dev/null || true
sudo tail -n 200 /var/log/php8.3-fpm.log      > "$RUN_DIR/phpfpm_tail.txt"       2>/dev/null || true

# === Opcional: snapshot BD (si XAMPP MySQL está arriba) ===
if /opt/lampp/lampp status 2>/dev/null | grep -qi "MySQL.*running"; then
  echo "Haciendo mysqldump de cafe_aurora (opcional)…"
  if command -v /opt/lampp/bin/mysqldump >/dev/null 2>&1; then
    /opt/lampp/bin/mysqldump \
      --socket=/opt/lampp/var/mysql/mysql.sock \
      -u root cafe_aurora > "$RUN_DIR/cafe_aurora_backup.sql" 2>/dev/null || true
  fi
fi

# === Paquete comprimido ===
tar -czf "$OUT_DIR/evidence-$TS.tar.gz" -C "$OUT_DIR" "run-$TS" 2>/dev/null || true
echo ">> Listo. Paquete: $OUT_DIR/evidence-$TS.tar.gz"


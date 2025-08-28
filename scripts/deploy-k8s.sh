#!/bin/bash
set -e

# === Variables ===
OUT_DIR="${1:-$HOME/evidence}"
TS="$(date +'%Y%m%d-%H%M%S')"
RUN_DIR="$OUT_DIR/run-$TS"
mkdir -p "$RUN_DIR"

echo ">> Desplegando en Kubernetes (Minikube) en: $RUN_DIR"

# Aplicar los archivos YAML (catalog, orders, customers)
echo "Aplicando archivos YAML de servicios..."
kubectl apply -f ~/cafe-aurora/k8s/catalog.yaml > "$RUN_DIR/catalog_apply.txt" 2>&1
kubectl apply -f ~/cafe-aurora/k8s/orders.yaml  > "$RUN_DIR/orders_apply.txt" 2>&1
kubectl apply -f ~/cafe-aurora/k8s/customers.yaml > "$RUN_DIR/customers_apply.txt" 2>&1

# Verificar los servicios y NodePorts
{
  echo "# Servicios NodePort"
  kubectl get svc -o wide || true
  echo
  echo "# Pods en ejecución"
  kubectl get pods -o wide || true
} > "$RUN_DIR/k8s_status.txt"

# Aplicar el Ingress
echo "Aplicando Ingress para servicios /k8s/* ..."
kubectl apply -f ~/cafe-aurora/k8s/ingress.yaml > "$RUN_DIR/ingress_apply.txt" 2>&1

# Verificar los servicios NodePort y el Ingress (minikube)
MINIKUBE_IP="$(minikube ip)"
{
  echo "# Accediendo a los servicios vía Ingress y NodePorts"
  echo "Accediendo a /k8s/catalog:"
  curl -k "https://localhost/k8s/catalog" || true
  echo "Accediendo a /k8s/orders:"
  curl -k "https://localhost/k8s/orders" || true
  echo "Accediendo a /k8s/customers:"
  curl -k "https://localhost/k8s/customers" || true
  echo
  echo "Accediendo a NodePorts directamente desde Minikube..."
  kubectl get svc | grep -E "catalog|orders|customers" | while read svc_line; do
    SERVICE_NAME=$(echo $svc_line | awk '{print $1}')
    NODE_PORT=$(echo $svc_line | awk '{print $5}' | cut -d':' -f2)
    echo "Accediendo a $SERVICE_NAME en http://$MINIKUBE_IP:$NODE_PORT"
    curl -sS "http://$MINIKUBE_IP:$NODE_PORT" || true
  done
} > "$RUN_DIR/k8s_curls.txt"

# Log de errores de Nginx (últimos 200)
echo "Obteniendo logs de Nginx (últimos 200) ..."
sudo tail -n 200 /var/log/nginx/error.log > "$RUN_DIR/nginx_error_log.txt" 2>/dev/null || true

# === Paquete comprimido ===
tar -czf "$OUT_DIR/evidence-$TS.tar.gz" -C "$OUT_DIR" "run-$TS" 2>/dev/null || true
echo ">> Listo. Paquete: $OUT_DIR/evidence-$TS.tar.gz"

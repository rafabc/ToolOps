#!/usr/bin/env bash


source ../../../../scripts/colors.sh
source ../../../../scripts/msg.sh
source ../../../../scripts/symbols.sh
source ../../../../scripts/operations.sh
source ../../../../scripts/docker.sh
source ../../../../scripts/setup-semver.sh
source ../../../../scripts/git.sh
source ../../../../scripts/builders/build-tool.sh
source ../../../../scripts/kubernetes.sh
source ../../../../scripts/spinner.sh




# --- Configuración ---
IMAGE_NAME="solace-direct-message-app"
DEPLOYMENT_FILE="deployment.yml"
NAMESPACE="solace"

# --- Gestión de Rutas ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"


cd "$PROJECT_ROOT"

msg_task "🚀 Iniciando docker build y deployment de app $IMAGE_NAME"

# 1. Construcción de la imagen (Contexto en la raíz del proyecto)
msg "🛠  Construyendo imagen: $IMAGE_NAME..."
docker build -t $IMAGE_NAME:latest -f "$SCRIPT_DIR/Dockerfile" . &>/dev/null

if [ $? -ne 0 ]; then
    msg_ko "❌ Error: La construcción de la imagen falló."
    exit 1
fi


# 3. Aplicar el despliegue en Kubernetes
msg "☸️ Desplegando en Kubernetes (archivo: $DEPLOYMENT_FILE)..."
kubectl apply -f "$SCRIPT_DIR/$DEPLOYMENT_FILE" &>/dev/null


# 5. Verificar estado
msg "⏳ Esperando a que el pod esté listo..."
wait_pod_running "solace-direct-message-tcp"

msg_ok "✅ ¡Proceso completado!"
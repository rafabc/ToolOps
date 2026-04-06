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

export VERBOSE=0


msg_task "🚀 Iniciando docker build y deployment"

# --- Configuración ---
IMAGE_NAME_PRODUCDER="producer-queue-garanted-tcp-smf"
IMAGE_NAME_CONSUMER="consumer-queue-garanted-tcp-smf"
DEPLOYMENT_FILE="deployment.yml"
NAMESPACE="solace"


# Comprueba si el namespace existe usando el comando "kubectl get namespace"
msg "Cambio a namespace $NAMESPACE"
kubectl get namespace "$NAMESPACE" &>/dev/null


# Si el comando no devuelve un error, el namespace existe
if [ $? -eq 0 ]; then
    kubectl config set-context --current --namespace=$NAMESPACE &>/dev/null
else
    msg_warn_idented "Namespace $NAMESPACE no existe - se corta el proceso"
    exit 1
fi


msg "Limpiando despliegue previo (si existe)..."
msg_info "start delete $IMAGE_NAME_PRODUCDER and  $IMAGE_NAME_CONSUMER deployment"
kubectl delete -f deployment.yml  &>/dev/null & spinner  $! "Waiting delete deployment.yml"


echo
msg_check_success "Deployment $IMAGE_NAME_PRODUCDER and  $IMAGE_NAME_CONSUMER deleted successfully" ""


# --- Gestión de Rutas ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"


cd "$PROJECT_ROOT"


# 1. Construcción de la imagen (Contexto en la raíz del proyecto)
msg "🛠  Construyendo imagen: $IMAGE_NAME_PRODUCDER..."

if [ "$VERBOSE" -eq 0 ]; then
    docker build -t $IMAGE_NAME_PRODUCDER:latest -f "$SCRIPT_DIR/dockerfile.producer" . &>/dev/null
else
    docker build -t $IMAGE_NAME_PRODUCDER:latest -f "$SCRIPT_DIR/dockerfile.producer" . 
fi

if [ $? -ne 0 ]; then
    msg_ko "Error: La construcción de la imagen $IMAGE_NAME_PRODUCDER falló."
    exit 1
fi


# 2. Construcción de la imagen consumer
msg "🛠  Construyendo imagen: $IMAGE_NAME_CONSUMER..."
if [ "$VERBOSE" -eq 0 ]; then
    docker build -t $IMAGE_NAME_CONSUMER:latest -f "$SCRIPT_DIR/dockerfile.consumer" . &>/dev/null
else
    docker build -t $IMAGE_NAME_CONSUMER:latest -f "$SCRIPT_DIR/dockerfile.consumer" . 
fi

if [ $? -ne 0 ]; then
    msg_ko "Error: La construcción de la imagen $IMAGE_NAME_CONSUMER falló."
    exit 1
fi


# 3. Aplicar el despliegue en Kubernetes
msg "☸️  Desplegando en Kubernetes (archivo: $DEPLOYMENT_FILE)..."
kubectl apply -f "$SCRIPT_DIR/$DEPLOYMENT_FILE" &>/dev/null


# 5. Verificar estado
msg "⏳ Esperando a que el pod esté listo..."
wait_pod_running "$IMAGE_NAME_PRODUCDER" 
wait_pod_running "$IMAGE_NAME_CONSUMER"

msg_ok "✅ ¡Proceso completado!"
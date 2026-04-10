

function check_svc_status() {
    NAMESPACE=$1
    SERVICE_NAME=$2
    msg "CHECKING SERVICE" "$SERVICE_NAME STATUS"
    SERVICE=$(kubectl get svc -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$SERVICE" ]; then
        msg_error "❌ No service found for $SERVICE_NAME in namespace $NAMESPACE"
        return 1
    else
        msg_check_success "✅ Service $SERVICE_NAME found in namespace $NAMESPACE"
    fi


    ENDPOINTS=$(kubectl get endpoints $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}')

    if [ -z "$ENDPOINTS" ]; then
        msg_check_fail "⚠️ El servicio existe pero NO tiene pods listos (0 Endpoints)"
    else
        msg_check_success "🚀 El servicio está activo y tiene endpoints en: $ENDPOINTS"
    fi

    EXTERNAL_IP=""
    TIMEOUT=4
    SECONDS_ELAPSED=0
    SLEEP_INTERVAL=2


    while [ -z "$EXTERNAL_IP" ]; do
        # Intentamos obtener tanto hostname como ip (por si usas AWS o Bare Metal/GCP)
        EXTERNAL_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}')
        
        if [ -z "$EXTERNAL_IP" ]; then
            if [ "$SECONDS_ELAPSED" -ge "$TIMEOUT" ]; then
                msg_warn "Timeout: Service $SERVICE_NAME does not have an External IP after ${TIMEOUT}s"
                break
            fi
            
            sleep "$SLEEP_INTERVAL"
            ((SECONDS_ELAPSED+=SLEEP_INTERVAL))
        else 
            msg_check_success "🌐 External IP found: $EXTERNAL_IP"
        fi
    done

    if [ "$VERBOSE" = "1" ] || [ "$VERBOSE" = "true" ]; then
        kubectl get svc $SERVICE -n $NAMESPACE
    fi
}


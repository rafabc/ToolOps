




function check_confluent() {

    SERVICE_NAME="confluent"
    NAMESPACE="confluent"

    msg "Check $SERVICE_NAME status"
    POD=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME -o jsonpath='{.items[0].metadata.name}')
    STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    if [ "$STATUS" == "Running" ]; then
        msg_check_success "POD $POD Status: $STATUS"
    else
        msg_check_fail "POD $POD Status: $STATUS"
    fi

    if kubectl get svc $SERVICE_NAME -n $NAMESPACE >/dev/null 2>&1; then
        msg_check_success "✅ El servicio $SERVICE_NAME esta operativo"
    else
        msg_check_fail "❌ El servicio $SERVICE_NAME no fue encontrado."
    fi

    ENDPOINTS=$(kubectl get endpoints $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}')

    if [ -z "$ENDPOINTS" ]; then
        msg_check_fail "⚠️ El servicio existe pero NO tiene pods listos (0 Endpoints)"
    else
        msg_check_success "🚀 El servicio está activo y tiene endpoints en: $ENDPOINTS"
    fi


    EXTERNAL_IP=""
    while [ -z "$EXTERNAL_IP" ]; do
        EXTERNAL_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        [ -z "$EXTERNAL_IP" ] && sleep 5
    done

    msg_check_success "🌐 El LoadBalancer está listo en: $EXTERNAL_IP"

}   
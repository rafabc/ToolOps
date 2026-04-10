function check_pod_status() {
    NAMESPACE=$1
    POD_NAME=$2

    msg "CHECKING POD" "$POD_NAME STATUS"
    
    # 1. Identificar el Pod
    #POD=$(kubectl get pods -n "$NAMESPACE" -l "app=$POD_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    POD=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep "^$POD_NAME" | awk '{print $1}' | head -n 1)

    if [ -z "$POD" ]; then
        msg_error "No pod found for $POD_NAME in namespace $NAMESPACE"
        return 1
    fi

    # 2. Extraer metadatos extendidos en una sola llamada (más eficiente)
    JSON_DATA=$(kubectl get pod "$POD" -n "$NAMESPACE" -o json)
    STATUS=$(echo "$JSON_DATA" | jq -r '.status.phase')
    POD_IP=$(echo "$JSON_DATA" | jq -r '.status.podIP')
    READY=$(echo "$JSON_DATA" | jq -r '.status.containerStatuses[0].ready')
    RESTARTS=$(echo "$JSON_DATA" | jq -r '.status.containerStatuses[0].restartCount')
    AGE=$(echo "$JSON_DATA" | jq -r '.metadata.creationTimestamp')
    
    # 3. Detectar si el último cierre fue por falta de memoria (OOMKill)
    EXIT_REASON=$(echo "$JSON_DATA" | jq -r '.status.containerStatuses[0].lastState.terminated.reason // "None"')

    # Formatear salida principal
    MSG_STR="POD: $POD | Status: $STATUS | Ready: $READY | IP: $POD_IP"
    
    if [ "$STATUS" == "Running" ] && [ "$READY" == "true" ]; then
        msg_check_success "$MSG_STR"
        msg_check_success "AGE" "Created at: $AGE"
        msg_check_success "RESTARTS" "Restart Count: $RESTARTS"
    else
        msg_check_fail "$MSG_STR"
        [ "$EXIT_REASON" != "None" ] && msg_error "Last Termination Reason: $EXIT_REASON"
        msg_info "pls check pod logs with: kubectl logs $POD -n $NAMESPACE"
    fi

    # 4. métricas de consumo
    TOP_OUTPUT=$(kubectl top pod "$POD" -n "$NAMESPACE" --no-headers 2>/dev/null)
    if [ -n "$TOP_OUTPUT" ]; then
        msg_check_success "METRICS" "$TOP_OUTPUT"
    else
        msg_warn "Metrics not ready yet (wait 60s for Metric Server)"
    fi

    # 5. Modo Verbose: Solo eventos importantes (Warnings)
    if [ "$VERBOSE" = "1" ] || [ "$VERBOSE" = "true" ]; then
        msg_check_success "VERBOSE" "Recent Warning Events for $POD:"
        # Filtramos solo por Warnings para no saturar la consola
        WARNINGS=$(kubectl get events -n "$NAMESPACE" --field-selector involvedObject.name="$POD",type=Warning -o custom-columns=REASON:.reason,MESSAGE:.message --no-headers | head -n 5)
        if [ -z "$WARNINGS" ]; then
            msg_check_success "VERBOSE" "No warnings found in events."
        else
            msg_warn "WARNINGS" "$WARNINGS"
        fi
    fi
}

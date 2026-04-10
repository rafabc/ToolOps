

function check_pvc_status() {
    local NAMESPACE=$1
    local PVC_NAME=$2
    # Ajustado para alinear con el texto después de [INFO]
    local INDENT="                   " 

    msg "CHECKING PVC" "$PVC_NAME STATUS"

    PVC=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | grep "$PVC_NAME" | awk '{print $1}' | head -n 1)

    if [ -z "$PVC" ]; then
        msg_error "❌ No PVC found for $PVC_NAME in namespace $NAMESPACE"
        return 1
    else
        msg_check_success "✅ PVC $PVC found in namespace $NAMESPACE"
    fi

    STATUS=$(kubectl get pvc "$PVC" -n "$NAMESPACE" -o jsonpath='{.status.phase}')

    if [ "$STATUS" == "Bound" ]; then
        msg_check_success "🚀 PVC is Bound and ready to use"
    else
        msg_check_fail "PVC is in status: $STATUS"        
        msg_info "📋 Kubernetes Describe Output:"
        kubectl describe pvc "$PVC" -n "$NAMESPACE" | sed "s/^/$INDENT/"

        msg_info "📌 Recent Events:"
        kubectl get events -n "$NAMESPACE" \
            --field-selector involvedObject.name="$PVC" \
            --sort-by=.metadata.creationTimestamp | sed "s/^/$INDENT/"

        msg_info "📦 StorageClass details:"
        SC=$(kubectl get pvc "$PVC" -n "$NAMESPACE" -o jsonpath='{.spec.storageClassName}')
        msg_info_idented "StorageClass: $SC"
        if [ -n "$SC" ]; then
            kubectl describe storageclass "$SC" 2>/dev/null | sed "s/^/$INDENT/" || echo "${INDENT}Error: StorageClass '$SC' not found."
        else
            msg_warn "⚠️ No StorageClass defined for this PVC"
        fi
    fi

    if [ "$VERBOSE" = "1" ] || [ "$VERBOSE" = "true" ]; then
        msg "YAML VIEW" "Full manifest for $PVC"
        kubectl get pvc "$PVC" -n "$NAMESPACE" -o yaml | sed "s/^/$INDENT/"
    fi
}
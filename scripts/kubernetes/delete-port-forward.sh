


function delete_port_forward() {
    local SVC_NAME=$1
    
    # Limpiamos el nombre por si el usuario pasa "svc/keycloak" o solo "keycloak"
    # Esto elimina el prefijo "svc/" si existe para buscar de forma más flexible
    local SEARCH_TERM=${SVC_NAME#svc/}

    echo
    msg_info "CLEANING PORT-FORWARD Services: $SVC_NAME"

    # 1. Buscamos la línea que contiene 'port-forward' y el nombre del servicio
    # 2. Extraemos el PID (segunda columna)
    local PIDS=$(ps -ef | grep "kubectl port-forward" | grep "$SVC_NAME" | grep -v grep | awk '{print $2}')

    if [ -z "$PIDS" ]; then
        msg_warn_idented "No active port-forward found for service: $SVC_NAME"
    else
        for PID in $PIDS; do
            msg_info_idented "Terminating port-forward (PID: $PID)..."
            kill -9 "$PID" &>/dev/null
            
            if [ $? -eq 0 ]; then
                msg_check_success_idented " Port-forward for $SVC_NAME (PID: $PID) closed."
            else
                msg_error_idented "Could not kill process $PID"
            fi
        done
    fi
}

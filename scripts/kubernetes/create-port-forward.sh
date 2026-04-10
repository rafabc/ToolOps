# Port forwards a Kubernetes service to a local port.
# Usage: port_forward <namespace> <resource_type> <resource_name> <local_port>:<remote_port>
#
# Arguments:
#   PORT_FORWARD - The local port to forward to.
#   PORT - The remote port on the Kubernetes service.
#   SERVICE - The name of the Kubernetes service to forward.
#
# Example: port_forward default svc/my-service 8080:80
function port_forward() {

    PORT_FORWARD=$1
    PORT=$2
    SERVICE=$3
    echo
    msg "Enviando puerto" "$PORT del servicio $SERVICE al puerto local" "$PORT_FORWARD"
    msg "PORT FORWARD SVC" "$SERVICE $PORT_FORWARD:$PORT"
    msg "Cheking port forward in use"
    PID_PORT=$(lsof -i :$PORT_FORWARD | awk '{print $2}' | tail -1)

    if [ "$VERBOSE" -eq 0 ]; then
        lsof -i tcp:$PORT_FORWARD &>/dev/null
    else
        lsof -i tcp:$PORT_FORWARD
    fi

    if [ $? -eq 0 ]; then
        msg_info "PID_PORT $PID_PORT para port forward $PORT_FORWARD de $SERVICE localizado, se procede a matarlo"
        kill -9 $PID_PORT
    else
        msg_warn "PID_PORT $PID_PORT de $PORT_FORWARD no existe, el puerto esta libre para su uso"
    fi
    
    if [ "$VERBOSE" -eq 0 ]; then
        kubectl port-forward svc/$SERVICE $PORT_FORWARD:$PORT >/dev/null 2>&1 &
        disown

    else
        kubectl port-forward svc/$SERVICE $PORT_FORWARD:$PORT &
        disown &>/dev/null
    fi
    msg_check_success "Port forward iniciado para $SERVICE en puerto local $PORT_FORWARD al puerto remoto $PORT\n"
}

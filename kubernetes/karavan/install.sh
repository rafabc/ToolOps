#!/bin/bash

function install_karavan() {

    NAMESPACE="karavan"

    create_namespace $NAMESPACE

    apply_resources "karavan.yml"

    sleep 5 & spinner $! "Waiting pod running"


    #port_forward 8899 80 karavan

    PID_PORT_KARAVAN=$(lsof -i :8899 | awk '{print $2}' | tail -1)
    PUERTO_KARAVAN=8899
    lsof -i tcp:$PUERTO_KARAVAN &>/dev/null
    if [ $? -eq 0 ]; then
        msg_info_idented "PID_PORT_KARAVAN $PID_PORT_KARAVAN localizado, se procede a matarlo"
        kill -9 $PID_PORT_KARAVAN
    else
        msg_warn_idented "PID_PORT_KARAVAN $PID_PORT_KARAVAN no existe, dashabord ya desconectado port forward"
    fi

    kubectl -n karavan port-forward svc/karavan 8899:80 & disown

}

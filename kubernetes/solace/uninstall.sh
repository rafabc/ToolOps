#!/bin/bash

function uninstall_solace() {

    NAMESPACE="solace"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    msg_info "Cambio a namespace solace"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        kubectl config set-context --current --namespace=solace &>/dev/null
    else
        msg_warn_idented "Namespace $NAMESPACE no existe - se continua el proceso de borrado"
    fi

    msg_info "start delete solace.yml"
    kubectl delete -f solace.yml  &>/dev/null & spinner  $! "Waiting delete solace.yml"

   # delete_namespace solace || echo "Namespace finalizer process not found"
   # kubectl delete namespace solace  & spinner  $! "Waiting delete namespace"

    kill_port_forward 8080
    kill_port_forward 8008
    kill_port_forward 9000
    kill_port_forward 1443
}

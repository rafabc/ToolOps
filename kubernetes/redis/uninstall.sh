#!/bin/bash

function uninstall_redis() {

    NAMESPACE="redis"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    msg_info "Cambio a namespace redis"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        kubectl config set-context --current --namespace=redis &>/dev/null
    else
        msg_warn_idented "Namespace $NAMESPACE no existe - se continua el proceso de borrado"
    fi

    msg_info "start delete redis.yml"
    kubectl delete -f redis.yml  &>/dev/null & spinner  $! "Waiting delete redis.yml"


}

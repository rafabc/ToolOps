#!/bin/bash

function uninstall_n8n() {

    NAMESPACE="n8n"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    msg_info "Cambio a namespace n8n"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        kubectl config set-context --current --namespace=n8n &>/dev/null
    else
        msg_warn_idented "Namespace $NAMESPACE no existe - se continua el proceso de borrado"
    fi

    msg_info "start delete n8n.yml"
    kubectl delete -f n8n.yml  &>/dev/null & spinner  $! "Waiting delete n8n.yml"

    kubectl get crd -oname | grep --color=never 'n8n' | xargs kubectl delete


}
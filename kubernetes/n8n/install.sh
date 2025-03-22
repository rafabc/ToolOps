#!/bin/bash

function install_n8n() {


    NAMESPACE="n8n"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        msg_info_idented "Namespace $NAMESPACE localizado, no es necesaria su creacion"
    else
        msg_warn_idented "Namespace $NAMESPACE no existe - se procede a su creacion"
        kubectl create namespace $NAMESPACE
    fi


    msg "Cambio a namespace $NAMESPACE"
    kubectl config set-context --current --namespace=$NAMESPACE &>/dev/null



    msg "Ejecutando kube apply"
    kubectl apply -f n8n.yml #&>/dev/null
    check_operation $? "kube apply"




    PORT=5678
    PID_PORT=$(lsof -i :$PORT | awk '{print $2}' | tail -1)
    lsof -i tcp:$PORT &>/dev/null
    if [ $? -eq 0 ]; then
        msg_info_idented "PID_PORT $PID_PORT localizado, se procede a matarlo"
        kill -9 $PID_PORT
    else
        msg_warn_idented "PID_PORT $PID_PORT no existe, ya desconectado port forward"
    fi

    sleep 3

    kubectl -n n8n port-forward "svc/n8n" $PORT:$PORT


}
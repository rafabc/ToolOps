#!/bin/bash

function install_redis() {

    NAMESPACE="redis"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        msg_info_idented "Namespace $NAMESPACE localizado, no es necesaria su creacion"
    else
        msg_warn_idented "Namespace $NAMESPACE no existe - se procede a su creacion"
        kubectl create namespace redis
    fi


    msg "Cambio a namespace redis"
    kubectl config set-context --current --namespace=redis &>/dev/null

    kubectl apply -f redis.yml # &>/dev/null


    PID_PORT_REDISINSIGHT=$(lsof -i :8001 | awk '{print $2}' | tail -1)
    PUERTO_REDISINSIGHT=8001
    lsof -i tcp:$PUERTO_REDISINSIGHT &>/dev/null
    if [ $? -eq 0 ]; then
        msg_info_idented "PID_PORT_REDISINSIGHT $PID_PORT_REDISINSIGHT localizado, se procede a matarlo"
        kill -9 $PID_PORT_REDISINSIGHT
    else
        msg_warn_idented "PID_PORT_REDISINSIGHT $PID_PORT_REDISINSIGHT no existe, dashabord ya desconectado port forward"
    fi


    kubectl -n redis port-forward svc/redisinsight 5540:5540
}

#!/bin/bash

function install_solace() {


    kill_port_forward 8080
    kill_port_forward 8008
    kill_port_forward 9000
    kill_port_forward 1443

    NAMESPACE="solace"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        msg_info "Namespace $NAMESPACE localizado, no es necesaria su creacion"
    else
        msg_warn "Namespace $NAMESPACE no existe - se procede a su creacion"
        kubectl create namespace solace
    fi

    msg "Cambio a namespace solace"
    kubectl config set-context --current --namespace=solace &>/dev/null

    msg "Ejecutando kube apply"
    kubectl apply -f solace.yml &>/dev/null
    check_operation $? "kube apply"

    POD=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^solace')

    kubectl get pod $POD

    kubectl wait --for=condition=ContainersReady pod/$POD --timeout=3m & spinner $! "Waiting for condition container ready"

    kubectl get pod $POD
    msg_info "Forwarding port 8080"
    kubectl -n solace port-forward svc/solace 8080:8080 &

    msg_info "Forwarding port 8008"
    kubectl -n solace port-forward svc/solace 8008:8008 &

    msg_info "Forwarding port 9000"
    kubectl -n solace port-forward svc/solace 9000:9000 &


    msg_info "Forwarding port 1443"
    kubectl -n solace port-forward svc/solace 1443:1443 &

}

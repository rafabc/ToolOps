#!/usr/bin/env bash

function install_confluent() {

  #  export TUTORIAL_HOME="https://raw.githubusercontent.com/confluentinc/confluent-kubernetes-examples/master/quickstart-deploy/kraft-quickstart"

    kubectl create namespace confluent
    kubectl config set-context --current --namespace confluent

    helm repo add confluentinc https://packages.confluent.io/helm

    helm repo update

    helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes


    msg_info "Pods"
    kubectl get pods

    msg_info "Apply"
    kubectl apply -f confluent.yml

    msg_info "port forward"
    kubectl port-forward controlcenter-0 9021:9021

}

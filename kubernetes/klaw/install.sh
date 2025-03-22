#!/usr/bin/env bash

function install_klaw() {

  #  export TUTORIAL_HOME="https://raw.githubusercontent.com/confluentinc/confluent-kubernetes-examples/master/quickstart-deploy/kraft-quickstart"

    kubectl create namespace klaw
    kubectl config set-context --current --namespace klaw


    msg_info "Apply"
    kubectl apply -f klaw.yml


    POD_KLAW_CORE=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^klaw-core')
    POD_KLAW_CLUSTER_API=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^klaw-cluster-api')

    msg_info "port forward POD_KLAW_CORE 9097"
    kubectl port-forward $POD_KLAW_CORE 9097:9097 &>/dev/null

}

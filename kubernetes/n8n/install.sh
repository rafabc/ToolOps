#!/bin/bash

function install_n8n() {


    NAMESPACE="n8n"

    create_namespace $NAMESPACE

    apply_resources "n8n.yml"

    POD=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^n8n')
    kubectl get pod $POD
    kubectl wait --for=condition=ContainersReady pod/$POD --timeout=3m & spinner $! "Waiting for condition container ready"

    port_forward "5678" "5678" n8n

}
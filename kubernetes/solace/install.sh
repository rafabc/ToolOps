#!/bin/bash

function install_solace() {


    NAMESPACE="solace"
    create_namespace $NAMESPACE

    apply_resources "solace.yml"
    POD=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^solace')
    kubectl get pod $POD
    kubectl wait --for=condition=ContainersReady pod/$POD --timeout=3m & spinner $! "Waiting for condition container ready"

    port_forward "8080" "8080" solace
    port_forward "8008" "8008" solace
    port_forward "9000" "9000" solace
    port_forward "1443" "1443" solace

}

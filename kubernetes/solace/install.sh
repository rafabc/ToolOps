#!/bin/bash

function install_solace() {

    NAMESPACE="solace"
    create_namespace $NAMESPACE

    apply_resources "solace.yml"
    
    msg "Waiting for Solace pods to be running..."
    wait_pod_running "solace"
    msg "Waiting for Solace Discovery Agent pod to be running..."
    wait_pod_running "solace-discovery-agent"


    #Port forwarding SOLACE
    port_forward "8088" "8080" solace
    port_forward "8008" "8008" solace
    port_forward "9000" "9000" solace
    port_forward "1443" "1443" solace
    port_forward "5555" "55555" solace


    #INSTALL SOLACE SCHEMA REGISTRY
    cd solace-schema-registry
    apply_resources "solace-schema-registry.yml"
    msg "Waiting for Solace Schema Registry pods to be running..."
    wait_pod_running "solace-schema-registry"

    #Port forwarding SOLACE SCHEMA REGISTRY
    port_forward "8080" "8080" schema-registry-ui
    port_forward "8081" "8081" schema-registry
    port_forward "3000" "3000" idp

}

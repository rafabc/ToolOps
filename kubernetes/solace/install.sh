#!/bin/bash

function install_solace() {

    NAMESPACE="solace"
    create_namespace $NAMESPACE

    apply_resources "solace.yml"
    
    wait_pod_running "solace"

    port_forward "8080" "8080" solace
    port_forward "8008" "8008" solace
    port_forward "9000" "9000" solace
    port_forward "1443" "1443" solace

}

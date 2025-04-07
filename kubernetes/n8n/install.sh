#!/bin/bash

function install_n8n() {


    NAMESPACE="n8n"

    create_namespace $NAMESPACE

    apply_resources "n8n.yml"

    wait_pod_running "n8n"

    port_forward "5678" "5678" n8n

}
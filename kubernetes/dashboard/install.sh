#!/bin/bash

function install_kubernetes_dashboard() {

    NAMESPACE="kubernetes-dashboard"
    create_namespace $NAMESPACE

    apply_resources "kubernetes-dashboard.yml"
    
    msg "Waiting for kubernetes-dashboard pods to be running..."
    wait_pod_running "kubernetes-dashboard"

    port_forward "9090" "9090" kubernetes-dashboard & disown

}

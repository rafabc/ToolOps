#!/bin/bash

function install_karavan() {

    NAMESPACE="karavan"

    create_namespace $NAMESPACE

    apply_resources "karavan.yml"

    wait_pod_running "karavan"

    port_forward "8899" "80" karavan

}

#!/bin/bash

function install_karavan() {

    NAMESPACE="karavan"

    create_namespace $NAMESPACE

    apply_resources "karavan.yml"

    sleep 5 & spinner $! "Waiting pod running"

    port_forward "8899" "80" karavan

}

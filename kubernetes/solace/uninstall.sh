#!/bin/bash

function uninstall_solace() {

    NAMESPACE="solace"
    delete_resources $NAMESPACE solace.yml

    msg_info "start delete solace-schema-registry.yml"
    kubectl delete -f ./solace-schema-registry/solace-schema-registry.yml  &>/dev/null & spinner  $! "Waiting delete solace-schema-registry.yml"

    delete_namespace solace || echo "Namespace finalizer process not found"
    # kubectl delete namespace solace  & spinner  $! "Waiting delete namespace"

}

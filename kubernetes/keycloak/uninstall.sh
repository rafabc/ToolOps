#!/bin/bash

function uninstall_keycloak() {

    NAMESPACE="keycloak"

    delete_resources $NAMESPACE keycloak.yml
    echo
    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"
    
    delete_port_forward keycloak


}

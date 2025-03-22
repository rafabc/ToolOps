#!/bin/bash

function uninstall_keycloak() {


    msg "Cambio a namespace keycloak"
    kubectl config set-context --current --namespace=keycloak &>/dev/null
    kubectl delete -f keycloak.yml # &>/dev/null

    delete_namespace keycloak || echo "Namespace finalizer process not found"
    kubectl delete namespace keycloak  & spinner  $! "Waiting delete namespace"

}

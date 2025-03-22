#!/bin/bash

function uninstall_camelk() {

    
    msg "Cambio a namespace camel-k "
    kubectl config set-context --current --namespace=camel-k  &>/dev/null

    kubectl delete -f camelk.yml
    msg "Borramos los kits de integracion de posibles ejecuciones previas"
    integration_kits=$(kubectl get integrationkits -n camel-k -o jsonpath='{.items[*].metadata.name}')
    echo
    for kit in $integration_kits; do
        kubectl delete ik $kit -n camel-k &>/dev/null
    done
    kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^camel-k' | xargs kubectl delete clusterrole
    kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^camel-k' | xargs kubectl delete clusterrolebinding

    kamel uninstall
    kubectl get pods,crds,subscriptions --all-namespaces | grep camel-k

    delete_namespace camel-k || echo "Namespace finalizer process not found"
    kubectl delete namespace camel-k & spinner $! "Waiting delete namespace"

}

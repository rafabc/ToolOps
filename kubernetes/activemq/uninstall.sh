#!/bin/bash

function uninstall_activemq() {

    
    msg "Cambio a namespace active-mq "
    kubectl config set-context --current --namespace=active-mq  &>/dev/null

    kubectl delete -f activemq.yml
    msg "Borramos los kits de integracion de posibles ejecuciones previas"

    kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^active-mq "' | xargs kubectl delete clusterrole
    kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^active-mq "' | xargs kubectl delete clusterrolebinding

    kamel uninstall
    kubectl get pods,crds,subscriptions --all-namespaces | grep active-mq

    delete_namespace active-mq || echo "Namespace finalizer process not found"
    kubectl delete namespace active-mq & spinner $! "Waiting delete namespace"

}

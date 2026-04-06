#!/bin/bash

function uninstall_activemq() {

    
    msg "Cambio a namespace active-mq "
    kubectl config set-context --current --namespace=active-mq  &>/dev/null

    kubectl delete -f activemq.yml
    msg "Borramos los kits de integracion de posibles ejecuciones previas"

    kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^active-mq "' | xargs kubectl delete clusterrole
    kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^active-mq "' | xargs kubectl delete clusterrolebinding


    msg_info "start delete custom resources definition (crds)"
    kubectl get crd -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep 'active-mq' | xargs kubectl delete crd  &>/dev/null  & spinner  $! "Waiting delete crds"
    kubectl get pods,subscriptions --all-namespaces | grep active-mq

    delete_namespace active-mq || echo "Namespace finalizer process not found"

}

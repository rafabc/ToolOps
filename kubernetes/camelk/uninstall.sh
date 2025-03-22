#!/bin/bash

function uninstall_camelk() {

        echo
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


        kubectl delete -f namespace.yml # &>/dev/null

}
#!/usr/bin/env bash

function uninstall_klaw() {

    msg_info "Cambio a namespace klaw"
    kubectl config set-context --current --namespace=klaw &>/dev/null


   # test2 & spinner  $!


    msg_info "start delete custom resources definition (crds)"
    kubectl get crd -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep 'klaw' | xargs kubectl delete crd  &>/dev/null  & spinner  $! "Waiting delete crds"

    msg_info "start delete klaw.yml"
    kubectl delete -f klaw.yml  &>/dev/null & spinner  $! "Waiting delete klaw.yml"


    delete_namespace klaw || echo "Namespace finalizer process not found"
    kubectl delete namespace klaw  & spinner  $! "Waiting delete namespace"

}

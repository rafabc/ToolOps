#!/usr/bin/env bash

function uninstall_confluent() {

    msg_info "Cambio a namespace confluent"
    kubectl config set-context --current --namespace=confluent &>/dev/null


   # test2 & spinner  $!


    msg_info "start delete custom resources definition (crds)"
    kubectl get crd -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep 'confluent' | xargs kubectl delete crd  &>/dev/null  & spinner  $! "Waiting delete crds"

    msg_info "start delete confluent.yml"
    kubectl delete -f confluent.yml  &>/dev/null & spinner  $! "Waiting delete confluent.yml"

    msg_info "start uninstall confluent-operator"
    helm uninstall confluent-operator  &>/dev/null & spinner  $! "Waiting helm uninstall operator"
    msg_check_success "confluent operator"


    delete_namespace confluent || echo "Namespace finalizer process not found"
    kubectl delete namespace confluent  & spinner  $! "Waiting delete namespace"

}

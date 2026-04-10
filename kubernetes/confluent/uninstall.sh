#!/usr/bin/env bash

function uninstall_confluent() {
 
    NAMESPACE="confluent"
    delete_resources $NAMESPACE confluent.yml

    msg_info "start uninstall confluent-operator"
    helm uninstall confluent-operator  &>/dev/null & spinner  $! "Waiting helm uninstall operator"
    echo
    msg_check_success "confluent operator deleted"

    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"

    delete_port_forward controlcenter
    delete_port_forward kafka
}

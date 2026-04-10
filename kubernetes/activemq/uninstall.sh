#!/bin/bash

function uninstall_activemq() {

    NAMESPACE="active-mq"
    
    delete_resources $NAMESPACE activemq.yml
    echo
    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"

    delete_port_forward active-mq
}

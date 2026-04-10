#!/bin/bash

function uninstall_camelk() {

    NAMESPACE="camel-k"
    
    delete_resources $NAMESPACE camelk.yml
    echo
    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"

}

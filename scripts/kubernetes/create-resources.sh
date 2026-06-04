#!/bin/bash

# Applies Kubernetes resource configurations using kubectl.
# This function should contain the logic to apply manifests or resource files
# to a Kubernetes cluster. Ensure that kubectl is configured with the correct
# context and permissions before invoking this function.
function create_resources() {
    RESOURCES_FILE="$1"
    NAMESPACE="$2"
    
    clear
    echo
    msg_task "Creating resources for $NAMESPACE"

    create_namespace $NAMESPACE

    msg "EXEC KUBECTL APPLY" "$RESOURCES_FILE"
    echo

    if [ "$VERBOSE" -eq 0 ]; then
        ERROR_MSG=$(kubectl apply -f "$RESOURCES_FILE" 2>&1 >/dev/null)
        if [ $? -ne 0 ]; then
            msg "ERROR" "Fallo al aplicar recursos: $ERROR_MSG"
            exit 1
        fi
    else
        if ! kubectl apply -f "$RESOURCES_FILE"; then
            msg "ERROR" "El comando kubectl falló."
            exit 1
        fi
    fi
}


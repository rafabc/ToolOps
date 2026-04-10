#!/bin/bash


# Creates a new Kubernetes namespace.
# Usage: create_namespace <namespace_name>
# Arguments:
#   namespace_name - The name of the namespace to create.
# Example:
#   create_namespace my-namespace
function create_namespace() {

    NAMESPACE=$1


    msg "Checking namespace $NAMESPACE"

    if [ "$VERBOSE" -eq 0 ]; then
        kubectl get namespace "$NAMESPACE" &>/dev/null
        NS=$?
    else
        kubectl get namespace "$NAMESPACE"
        NS=$?
    fi

    if [ $NS -eq 0 ]; then
        msg "Namespace $NAMESPACE localizado, no es necesaria su creacion"
    else
        msg_warn "Namespace $NAMESPACE no existe - se procede a su creacion"
        msg "Applying $NAMESPACE namespace"

        if [ ! -f namespace.yml ]; then
            msg_warn "El fichero namespace.yml no existe en $PWD"
            return 1
        fi

        if [ "$VERBOSE" -eq 0 ]; then
            kubectl apply -f namespace.yml &>/dev/null
        else
            kubectl apply -f namespace.yml
        fi
    fi


    STATUS=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)

    if [ -z "$STATUS" ]; then
        msg "❌ El namespace '$NAMESPACE' no existe."
        exit 1
    fi

    if [ "$STATUS" = "Terminating" ]; then
        msg "⚠️  El namespace '$NAMESPACE' está en estado TERMINATING."
        exit 0
    else
        msg "✅ El namespace '$NAMESPACE' está en estado: $STATUS"
    fi

    msg "Cambiando a namespace $NAMESPACE"
    if [ "$VERBOSE" -eq 0 ]; then
        kubectl config set-context --current --namespace=$NAMESPACE &>/dev/null
    else
        kubectl config set-context --current --namespace=$NAMESPACE
    fi
}

#!/bin/bash

# Deletes a specified Kubernetes namespace.
# Usage: delete_namespace <namespace>
# Arguments:
#   <namespace> - The name of the Kubernetes namespace to delete.
# This function will attempt to delete the given namespace using kubectl.
function delete_namespace() {

    #FUNCIONA
    # get namespace info to check why cant delete <-- see apiservice here (message)
    # kubectl get namespace confluent -o json | jq 'del(.spec.finalizers[] | select("kubernetes"))'
    # kubectl get apiservice
    # kubectl delete apiservice <apiservice-name>

    NAMESPACE=$1

    msg_info "Comienzo proceso borrado namespace $NAMESPACE"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        msg_info_idented "Namespace $NAMESPACE localizado, se procede al borrado"
    else
        msg_warn_idented "Namespace $NAMESPACE no existe"
        return
    fi

    set -eo pipefail

    msg_info_idented "set eo"

    die() {
        echo "$*" 1>&2
        exit 1
    }

    need() {
        msg_info_idented "Checking Which $1"
        which "$1" &>/dev/null || die "Binary '$1' is missing but required"
    }

    # checking pre-reqs
    need "jq"
    need "curl"
    need "kubectl"

    PROJECT="$1"
    shift

    msg_info_idented "Checking namespace"

    test -n "$PROJECT" || die "Missing arguments: kill-ns <namespace>"

    kubectl proxy &>/dev/null &
    PROXY_PID=$!

    killproxy() {
        # echo $PROXY_PID
        kill $PROXY_PID
    }
    trap killproxy EXIT

    sleep 1 # give the proxy a second

    msg_info_idented "killing namespace"


    if kubectl get ns "$PROJECT" >/dev/null 2>&1; then
        STATUS=$(kubectl get ns "$PROJECT" -o jsonpath='{.status.phase}')
        if [ "$STATUS" = "Terminating" ]; then
            msg_info_idented "⚠️  Namespace $PROJECT está en estado Terminating"
            kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --ignore-not-found -n "$PROJECT"

        elif [ "$STATUS" = "Active" ]; then
            msg_info_idented "✅ Namespace $PROJECT está activo procedemos a eliminarlo"
            # kubectl get namespace "$PROJECT" -o json | jq 'del(.spec.finalizers[] | select("kubernetes"))' | curl -s -k -H "Content-Type: application/json" -X PUT -o /dev/null --data-binary @- http://localhost:8001/api/v1/namespaces/$PROJECT/finalize && msg_info_idented "Killed namespace: $PROJECT"
     
     
            # Ejecutamos el borrado
            kubectl delete namespace "$NAMESPACE" --timeout=30s &>/dev/null

            # Guardamos el resultado del comando anterior
            EXIT_CODE=$?
            echo
            if [ $EXIT_CODE -eq 0 ]; then
                # Si es 0, el comando de borrado se envió y completó con éxito
                msg_check_success_idented "Namespace $NAMESPACE eliminado correctamente"
            elif [ $EXIT_CODE -eq 1 ]; then
                # A veces kubectl devuelve 1 si el recurso ya no existía (NotFound)
                msg_check_success_idented "Namespace $NAMESPACE ya no existe o fue eliminado"
            else
                # Si es otro código, hubo un error real o un timeout
                msg_error_idented "Error al intentar eliminar el namespace $NAMESPACE (Código: $EXIT_CODE)"
                
                msg_info_idented "Forzando limpieza de finalizers en el namespace..."
                kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type merge &>/dev/null
            fi

        else
            msg_info_idented "❌ Namespace $PROJECT no existe"
        fi
    else
        msg_info_idented "namespace killed"
    fi

    # proxy will get killed by the trap

}

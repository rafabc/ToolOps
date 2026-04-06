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

    msg_info_idented "pre delete"

    # kubectl delete namespace $NAMESPACE &>/dev/null

    msg_info_idented "delete namespace"

    set -eo pipefail

    msg_info_idented "set eo"

    die() {
        echo "$*" 1>&2
        exit 1
    }

    need() {
        msg_info_idented "Which $1"
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

            msg_info_idented "Borrando todos los recursos en namespace $PROJECT ..."

            kubectl api-resources --verbs=list --namespaced -o name \
            | while read resource; do
                msg_info_idented "Eliminando $resource en $PROJECT"
                kubectl delete "$resource" -n $PROJECT --all --ignore-not-found &>/dev/null
            done

            REMAINING=$(kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get -n "$PROJECT" --ignore-not-found)

            if [ -z "$REMAINING" ]; then
                msg_info_idented "✅ Namespace $PROJECT está completamente vacío - ya se puede eliminar"
                kubectl delete namespace $NAMESPACE &>/dev/null
            else
                msg_info_idented "❌ Aún quedan recursos en $PROJECT:"
                msg_info_idented "$REMAINING"
            fi
        elif [ "$STATUS" = "Active" ]; then
            msg_info_idented "✅ Namespace $PROJECT está activo procedemos a eliminarlo"
            # kubectl get namespace "$PROJECT" -o json | jq 'del(.spec.finalizers[] | select("kubernetes"))' | curl -s -k -H "Content-Type: application/json" -X PUT -o /dev/null --data-binary @- http://localhost:8001/api/v1/namespaces/$PROJECT/finalize && msg_info_idented "Killed namespace: $PROJECT"
            kubectl delete namespace $NAMESPACE &>/dev/null
        else
            msg_info_idented "❌ Namespace $PROJECT no existe"
        fi
    else
        msg_info_idented "namespace killed"
    fi

    # proxy will get killed by the trap

    # kubectl delete namespace $NAMESPACE &>/dev/null
}



# Executes a specified Kubernetes action.
# 
# This function is intended to perform a Kubernetes-related operation.
# The specific action and its parameters should be provided when calling the function.
#
# Usage:
#   exec_kube_action <action> [args...]
#
# Arguments:
#   <action>   The Kubernetes action to execute (0, 1, 2).
#   [args...]  Additional arguments to pass to the kubectl command.
#
# Example:
#   exec_kube_action 1 confluent
function exec_kube_action() {

    ACTION=$1
    TOOL=$2

    case "$ACTION" in
    0)
        kube_apply $TOOL
        ;;
    1)
        kube_delete $TOOL
        ;;
    2)
        kube_check $TOOL "$@"
        ;;
    esac
}



# Applies Kubernetes manifests using kubectl.
# Usage: kube_apply <manifest_file>
# Arguments:
#   manifest_file - Path to the Kubernetes manifest file to apply.
# This function wraps the kubectl apply command for convenience.
function kube_apply() {
    TOOL=$1

    if [ "$VERBOSE" -eq 1 ]; then
        msg "APPLY $TOOL"
        msg $PWD
    fi

    case "$TOOL" in
    0) # ************************* KUBERNETES DASHBOARD ******************************
        install_kubernetes_dashboard
        ;;
    1) # ************************* ACTIVE MQ **************************
        install_activemq
        ;;
    2) # ****************************** CAMEL K ***********************************
        install_camelk
        ;;
    3) # ****************************** REDIS ******************************
        install_redis
        ;;
    4) # ****************************** LINKERD ******************************
        #create_namespace "linkerd" --> La instalacion del cliente por defecto crea el mismo el namespace linkerd
        install_linkerd
        ;;
    5) # ************************* KEYCLOAK ******************************
        install_keycloak
        ;;
    6) # ****************************** CONFLUENT ******************************
        install_confluent
        ;;
    7) # ********************************* KLAW ********************************
        install_klaw
        ;;
    8) # ******************************** KARAVAN ******************************
        install_karavan
        ;;
    9) # ******************************** SOLACE *******************************
        install_solace
        ;;
    10) # ******************************** N8N *********************************
        install_n8n
        ;;
    11) # ******************************* ISTIO ********************************
        #install_istio
        install_istio_with_helm
        ;;
    12) # ******************************* EVENT CATALOG ************************
        install_event_catalog_helm
        ;;
    13) # ******************************* KAFBAT UI ************************
        install_kafbat_helm
        ;;

    esac

}



# Deletes Kubernetes resources using kubectl.
# Usage: kube_delete  <tool_num>
# Arguments:
#   tool_num - The number of the tool to delete.
# Example:
#   kube_delete 1
function kube_delete() {
    TOOL=$1
    case "$TOOL" in
    0)
        # ************************* KUBERNETES DASHBOARD ******************************
        kubectl delete -f *
        ;;
    1)
        # ************************* ACTIVE MQ **************************
        uninstall_activemq
        ;;
    2)
        # ****************************** CAMEL K ***********************************
        uninstall_camelk
        ;;
    3)
        # ****************************** REDIS ******************************
        uninstall_redis
        ;;
    4)
        uninstall_emojivoto
        uninstall_linkerd_viz
        uninstall_linkerd

        # kubectl delete -f namespace.yml &>/dev/null
        echo
        ;;

    5)
        uninstall_keycloak
        ;;
    6)
        echo
        msg "Desinstalamos Confluent"
        uninstall_confluent
        ;;
    7)
        echo
        msg "Desinstalamos klaw"
        uninstall_klaw
        ;;
    8)
        echo
        msg "Desinstalamos Karavan"
        uninstall_karavan
        ;;
    9)
        echo
        msg "Desinstalamos Solace"
        uninstall_solace
        ;;
    10) # ******************************** N8N *******************************
        uninstall_n8n
        ;;
    11) # ****************************** ISTIO *******************************
        uninstall_istio
        ;;
    12) # ****************************** EVENT CATALOG ************************
        uninstall_event_catalog
        ;;
    esac
}


# -----------------------------------------------------------------------------
# kube_check
#
# Description:
#   Checks the status of a Kubernetes application.
#
# Usage:
#   kube_check tool_num [-v]
#
# Arguments:
#   tool_num - The number of the tool to check.
#
# Outputs:
#   Prints status or diagnostic information about the Kubernetes cluster.
#
# -----------------------------------------------------------------------------
function kube_check() {
    TOOL=$1
    VERBOSE=false

    for arg in "$@"; do
        if [ "$arg" == "-v" ]; then
            msg "VERBOSE mode enabled"
            VERBOSE=true
        fi
    done

    case "$TOOL" in
    0)
        msg "Check Kubernetes Dashboard status"
        DASHBOARD_POD=$(kubectl get pods -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $DASHBOARD_POD -n kubernetes-dashboard -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Kubernetes Dashboard $DASHBOARD_POD Status: $STATUS"
        else
            msg_check_fail "POD Kubernetes Dashboard $DASHBOARD_POD Status: $STATUS"
        fi
        ;;
    1)
        check_activemq
        ;;
    2)
        NAMESPACE="camel-k"
        msg "Check Integration Platforms status"
        integration_platforms=$(kubectl get integrationplatforms -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
        for platform in $integration_platforms; do
            STATUS=$(kubectl get integrationplatform $platform -n $NAMESPACE -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Ready" ]; then
                msg_check_success "La plataforma de integracion $platform esta lista y en estado: $STATUS"
            else
                msg_check_fail "La plataforma de integracion $platform no esta lista. Estado actual: $STATUS"
            fi
        done

        msg "Check Integration Kits status"
        integration_kits=$(kubectl get ik -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
        for kit in $integration_kits; do
            STATUS=$(kubectl get integrationkit $kit -n $NAMESPACE -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Ready" ]; then
                msg_check_success "El Integrationkit $kit esta lista y en estado: $STATUS"
            fi
            if [ "$STATUS" == "Build Running" ]; then
                msg_info "El Integrationkit $kit esta en estado: $STATUS"
            fi
            if [ "$STATUS" == "Build Submitted" ]; then
                msg_info "El Integrationkit $kit esta en estado: $STATUS"
            fi
            if [ "$STATUS" == "Error" ]; then
                msg_check_fail "El Integrationkit $kit no esta lista. Estado actual: $STATUS"
                XERROR=$(kubectl get integrationkit $kit -n $NAMESPACE -o jsonpath='{.status.failure.reason}')
                msg_info_idented "$XERROR"
                msg_info_idented "Check error with this command: kubectl get integrationkit $kit -n $NAMESPACE -o json"

                if [[ $XERROR == *"$failure while building project"* ]]; then

                    CAMELOPERATOR=$(kubectl get pods | grep camel-k-operator | awk '{print $1}')
                    LOG=$(kubectl logs $CAMELOPERATOR | grep "camel-k.maven.build" | grep -A60 $kit | grep -m1 -A6 "BUILD FAILURE" | sed -E 's/(\\")//g' | tr -d '\n' | sed 's/\\//g') #  | jq 'del(.stacktrace)' | sed -E 's/(\\")//g' | sed 's/\\//g'  #| sed -E 's/("msg":")([^"]*)(")/\1\2\3/g'
                    if [ "$VERBOSE" = true ]; then
                        msg_info_idented "log info"
                        echo
                        echo "$LOG" | jq -r .msg
                    fi
                fi
            fi
        done

        msg "Check Integrations status"
        integrations=$(kubectl get integrations -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
        for int in $integrations; do
            STATUS=$(kubectl get integration $int -n $NAMESPACE -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Running" ]; then
                msg_check_success "La integracion $int esta lista y en estado: $STATUS"
            else
                if [ "$STATUS" == "Building Kit" ]; then
                    msg_info "Integracion $int en fase de construccion"
                fi
                if [ "$STATUS" == "Deploying" ]; then
                    msg_info "Integracion $int en fase de despliegue"
                fi
                if [ "$STATUS" == "Error" ]; then
                    msg_check_fail "La integracion $int ha fallado. Estado actual: $STATUS"
                    msg_info_idented "Checking conditions"
                    conditions=$(kubectl get integrations $int -n $NAMESPACE -o jsonpath='{.status.conditions}')

                    num_elements=$(echo "$conditions" | jq length)

                    for ((i = 1; i <= num_elements; i++)); do
                        condition=$(echo "$conditions" | jq ".[$i-1]")
                        status=$(echo "$condition" | jq -r '.status')
                        type=$(echo "$condition" | jq -r '.type')
                        message=$(echo "$condition" | jq -r '.message')

                        if [ "$status" == "True" ]; then
                            msg_check_success_idented "Condition $type OK"
                        else
                            msg_check_fail_idented "Condition $type KO $status $message"
                        fi

                    done
                fi
                if [ "$STATUS" != "Deploying" ] && [ "$STATUS" != "Error" ] && [ "$STATUS" != "Building Kit" ]; then
                    msg_info "Estado no analizado: $STATUS"
                fi
            fi
        done
        ;;
   
    3)
        msg "Check Redis status"
        REDIS_POD=$(kubectl get pods -n redis -l app=redis -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $REDIS_POD -n redis -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Redis $REDIS_POD Status: $STATUS"
        else
            msg_check_fail "POD Redis $REDIS_POD Status: $STATUS"
        fi
        ;;
    4)
        msg "Check Linkerd status"
        linkerd check --verbose
        ;;
    5)
        msg "Check Keycloak status"
        KEYCLOAK_POD=$(kubectl get pods -n keycloak -l app=keycloak -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $KEYCLOAK_POD -n keycloak -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Keycloak $KEYCLOAK_POD Status: $STATUS"
        else
            msg_check_fail "POD Keycloak $KEYCLOAK_POD Status: $STATUS"
        fi
        ;;
    6)
        check_confluent
        ;;
     7)
        msg "Check Klaw status"
        KLAW_POD=$(kubectl get pods -n klaw -l app=klaw -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $KLAW_POD -n klaw -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Klaw $KLAW_POD Status: $STATUS"
        else
            msg_check_fail "POD Klaw $KLAW_POD Status: $STATUS"
        fi
        ;;
     8)
        msg "Check Karavan status"
        KARAVAN_POD=$(kubectl get pods -n karavan -l app=karavan -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $KARAVAN_POD -n karavan -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Karavan $KARAVAN_POD Status: $STATUS"
        else
            msg_check_fail "POD Karavan $KARAVAN_POD Status: $STATUS"
        fi
        ;;
     9)
        check_solace
        ;;
     10)
        msg "Check n8n status"
        N8N_POD=$(kubectl get pods -n n8n -l app=n8n -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kub    ectl get pod $N8N_POD -n n8n -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD n8n $N8N_POD Status: $STATUS"
        else
            msg_check_fail "POD n8n $N8N_POD Status: $STATUS"
        fi
        ;;
     11)
        msg "Check Istio status"
        istioctl verify-install --set profile=demo
        ;;
     12)
        msg "Check Event Catalog status"
        EVENT_CATALOG_POD=$(kubectl get pods -n event-catalog -l app=event-catalog -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $EVENT_CATALOG_POD -n event-catalog -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Event Catalog $EVENT_CATALOG_POD Status: $STATUS"
        else
            msg_check_fail "POD Event Catalog $EVENT_CATALOG_POD Status: $STATUS"
        fi
        ;;
     13)
        msg "Check Kafbat UI status"
        KAFBAT_POD=$(kubectl get pods -n kafbat -l app=kafbat-ui -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $KAFBAT_POD -n kafbat -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Kafbat UI $KAFBAT_POD Status: $STATUS"
        else
            msg_check_fail "POD Kafbat UI $KAFBAT_POD Status: $STATUS"
        fi
        ;;
    esac
}


# Applies Kubernetes resource configurations using kubectl.
# This function should contain the logic to apply manifests or resource files
# to a Kubernetes cluster. Ensure that kubectl is configured with the correct
# context and permissions before invoking this function.
function apply_resources() {
    RESOURCES_FILE=$1
    msg "EXEC KUBECTL APPLY" "$RESOURCES_FILE"
    echo
    if [ "$VERBOSE" -eq 0 ]; then
        kubectl apply -f $RESOURCES_FILE &>/dev/null
    else
        kubectl apply -f $RESOURCES_FILE
    fi
}

function delete_resources() {
    RESOURCES=$1
    msg "DELETEING RESOURCES" "$RESOURCES"

    echo
    if [ "$VERBOSE" -eq 1 ]; then
        msg "CLUSTER ROLES"
        kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" 
        kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete clusterrole

        msg "CLUSTER ROLE BINDINGS"
        kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete clusterrolebinding

        msg "ROLE BINDINGS"
        kubectl get rolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get rolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete rolebinding

        msg "CRON JOBS"
        kubectl get cj -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" 
        kubectl get cj -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete cj

        msg "SERVICE ACCOUNTS"
        kubectl get serviceaccounts -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get serviceaccounts -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete serviceaccounts

        msg "DEPLOYMENTS"
        kubectl get deployments -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get deployments -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete deployments

        msg "REPLICA SETS"
        kubectl get rs -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get rs -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete rs

        msg "CONFIG MAPS"
        kubectl get cm -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get cm -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete cm

        msg "SECRETS"
        kubectl get secrets -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get secrets -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete secrets

        msg "SERVICES"
        kubectl get svc -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get svc -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete svc

        msg "PODS"
        kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES"
        kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete pods


        kubectl delete -f $RESOURCES &>/dev/null
    else
        kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete clusterrole
        kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete clusterrolebinding
        kubectl get rolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete rolebinding
        kubectl get cj -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete cj
        kubectl get serviceaccounts -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete serviceaccounts
        kubectl get deployments -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete deployments
        kubectl get rs -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete rs
        kubectl get cm -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete cm
        kubectl get secrets -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete secrets
        kubectl get svc -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete svc
        kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$RESOURCES" | xargs kubectl delete pods
        kubectl delete -f $RESOURCES
    fi

}

# Port forwards a Kubernetes service to a local port.
# Usage: port_forward <namespace> <resource_type> <resource_name> <local_port>:<remote_port>
#
# Arguments:
#   PORT_FORWARD - The local port to forward to.
#   PORT - The remote port on the Kubernetes service.
#   SERVICE - The name of the Kubernetes service to forward.
#
# Example: port_forward default svc/my-service 8080:80
function port_forward() {

    PORT_FORWARD=$1
    PORT=$2
    SERVICE=$3
    echo
    msg "Enviando puerto" "$PORT del servicio $SERVICE al puerto local" "$PORT_FORWARD"
    msg "PORT FORWARD SVC" "$SERVICE $PORT_FORWARD:$PORT"
    msg "Cheking port forward in use"
    PID_PORT=$(lsof -i :$PORT_FORWARD | awk '{print $2}' | tail -1)

    if [ "$VERBOSE" -eq 0 ]; then
        lsof -i tcp:$PORT_FORWARD &>/dev/null
    else
        lsof -i tcp:$PORT_FORWARD
    fi

    if [ $? -eq 0 ]; then
        msg_info "PID_PORT $PID_PORT para port forward $PORT_FORWARD de $SERVICE localizado, se procede a matarlo"
        kill -9 $PID_PORT
    else
        msg_warn "PID_PORT $PID_PORT de $PORT_FORWARD no existe, el puerto esta libre para su uso"
    fi
    
    if [ "$VERBOSE" -eq 0 ]; then
        kubectl port-forward svc/$SERVICE $PORT_FORWARD:$PORT >/dev/null 2>&1 &
        disown

    else
        kubectl port-forward svc/$SERVICE $PORT_FORWARD:$PORT &
        disown &>/dev/null
    fi
    msg_check_success "Port forward iniciado para $SERVICE en puerto local $PORT_FORWARD al puerto remoto $PORT\n"
}


# Waits for a Kubernetes pod to reach the "Running" state.
# Usage: wait_pod_running <namespace> <pod_name>
# Arguments:
#   pod_name  - The name of the pod to wait for.
# The function polls the pod status and waits until it is "Running".
function wait_pod_running() {
    POD_NAME=$1
    msg "WAITING POD RUNNING" "$POD_NAME"
    #POD=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$POD_NAME")
    POD=$(kubectl get pods -o name | grep "^pod/$POD_NAME" | head -1)

     if [ -z "$POD" ]; then
        msg_error "No pod found for $POD_NAME"
        return 1
    fi

    if [ "$VERBOSE" -eq 0 ]; then
        kubectl get pod $POD >/dev/null &>/dev/null
    else
        kubectl get pod $POD
    fi


    READY=$(kubectl get $POD -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].status}')

    if [ "$READY" = "True" ]; then
        msg_check_success "POD READY" "$POD_NAME is in ContainersReady=True state" 
        return 0
    fi

    kubectl wait --for=condition=ContainersReady $POD --timeout=3m &
    spinner $! "Waiting for condition container ready"
    WAIT_RC=$?
    READY=$(kubectl get $POD -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].status}')

    if [ "$WAIT_RC" -eq 0 ] && [ "$READY" = "True" ]; then
        STATE=$(kubectl get $POD -o jsonpath='{range .status.containerStatuses[*]} {range .state.waiting}{.reason}{end} {range .state.running}Running{end} {range .state.terminated}{.reason}{end} {end}')
        msg_check_success "POD READY STATE ->" "$STATE" "$POD_NAME is in ContainersReady=True state"
    else
        msg_info "Pod $POD_NAME failed to reach ready state within timeout. Current status:"
        msg_info_idented "Current READY status: $READY y WAIT_RC: $WAIT_RC"
        msg_check_fail "POD NOT READY" "$POD failed to reach ready state"
        kubectl get $POD
        return 1
    fi
}


function check_pod_status() {
    NAMESPACE=$1
    POD_NAME=$2

    msg "CHECKING POD" "$POD_NAME STATUS"
    
    # 1. Identificar el Pod
    #POD=$(kubectl get pods -n "$NAMESPACE" -l "app=$POD_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    POD=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep "^$POD_NAME" | awk '{print $1}' | head -n 1)

    if [ -z "$POD" ]; then
        msg_error "No pod found for $POD_NAME in namespace $NAMESPACE"
        return 1
    fi

    # 2. Extraer metadatos extendidos en una sola llamada (más eficiente)
    JSON_DATA=$(kubectl get pod "$POD" -n "$NAMESPACE" -o json)
    STATUS=$(echo "$JSON_DATA" | jq -r '.status.phase')
    POD_IP=$(echo "$JSON_DATA" | jq -r '.status.podIP')
    READY=$(echo "$JSON_DATA" | jq -r '.status.containerStatuses[0].ready')
    RESTARTS=$(echo "$JSON_DATA" | jq -r '.status.containerStatuses[0].restartCount')
    AGE=$(echo "$JSON_DATA" | jq -r '.metadata.creationTimestamp')
    
    # 3. Detectar si el último cierre fue por falta de memoria (OOMKill)
    EXIT_REASON=$(echo "$JSON_DATA" | jq -r '.status.containerStatuses[0].lastState.terminated.reason // "None"')

    # Formatear salida principal
    MSG_STR="POD: $POD | Status: $STATUS | Ready: $READY | IP: $POD_IP"
    
    if [ "$STATUS" == "Running" ] && [ "$READY" == "true" ]; then
        msg_check_success "$MSG_STR"
        msg_check_success "AGE" "Created at: $AGE"
        msg_check_success "RESTARTS" "Restart Count: $RESTARTS"
    else
        msg_check_fail "$MSG_STR"
        [ "$EXIT_REASON" != "None" ] && msg_error "Last Termination Reason: $EXIT_REASON"
        msg_info "pls check pod logs with: kubectl logs $POD -n $NAMESPACE"
    fi

    # 4. métricas de consumo
    TOP_OUTPUT=$(kubectl top pod "$POD" -n "$NAMESPACE" --no-headers 2>/dev/null)
    if [ -n "$TOP_OUTPUT" ]; then
        msg_check_success "METRICS" "$TOP_OUTPUT"
    else
        msg_warn "Metrics not ready yet (wait 60s for Metric Server)"
    fi

    # 5. Modo Verbose: Solo eventos importantes (Warnings)
    if [ "$VERBOSE" = "1" ] || [ "$VERBOSE" = "true" ]; then
        msg_check_success "VERBOSE" "Recent Warning Events for $POD:"
        # Filtramos solo por Warnings para no saturar la consola
        WARNINGS=$(kubectl get events -n "$NAMESPACE" --field-selector involvedObject.name="$POD",type=Warning -o custom-columns=REASON:.reason,MESSAGE:.message --no-headers | head -n 5)
        if [ -z "$WARNINGS" ]; then
            msg_check_success "VERBOSE" "No warnings found in events."
        else
            msg_warn "WARNINGS" "$WARNINGS"
        fi
    fi
}

function check_svc_status() {
    NAMESPACE=$1
    SERVICE_NAME=$2
    msg "CHECKING SERVICE" "$SERVICE_NAME STATUS"
    SERVICE=$(kubectl get svc -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')

    if [ -z "$SERVICE" ]; then
        msg_error "❌ No service found for $SERVICE_NAME in namespace $NAMESPACE"
        return 1
    else
        msg_check_success "✅ Service $SERVICE_NAME found in namespace $NAMESPACE"
    fi


    ENDPOINTS=$(kubectl get endpoints $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}')

    if [ -z "$ENDPOINTS" ]; then
        msg_check_fail "⚠️ El servicio existe pero NO tiene pods listos (0 Endpoints)"
    else
        msg_check_success "🚀 El servicio está activo y tiene endpoints en: $ENDPOINTS"
    fi

    EXTERNAL_IP=""
    TIMEOUT=4
    SECONDS_ELAPSED=0
    SLEEP_INTERVAL=2


    while [ -z "$EXTERNAL_IP" ]; do
        # Intentamos obtener tanto hostname como ip (por si usas AWS o Bare Metal/GCP)
        EXTERNAL_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}')
        
        if [ -z "$EXTERNAL_IP" ]; then
            if [ "$SECONDS_ELAPSED" -ge "$TIMEOUT" ]; then
                msg_warn "Timeout: Service $SERVICE_NAME does not have an External IP after ${TIMEOUT}s"
                break
            fi
            
            sleep "$SLEEP_INTERVAL"
            ((SECONDS_ELAPSED+=SLEEP_INTERVAL))
        else 
            msg_check_success "🌐 External IP found: $EXTERNAL_IP"
        fi
    done

    if [ "$VERBOSE" = "1" ] || [ "$VERBOSE" = "true" ]; then
        kubectl get svc $SERVICE -n $NAMESPACE
    fi
}



function check_pvc_status() {
    local NAMESPACE=$1
    local PVC_NAME=$2
    # Ajustado para alinear con el texto después de [INFO]
    local INDENT="                   " 

    msg "CHECKING PVC" "$PVC_NAME STATUS"

    PVC=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | grep "$PVC_NAME" | awk '{print $1}' | head -n 1)

    if [ -z "$PVC" ]; then
        msg_error "❌ No PVC found for $PVC_NAME in namespace $NAMESPACE"
        return 1
    else
        msg_check_success "✅ PVC $PVC found in namespace $NAMESPACE"
    fi

    STATUS=$(kubectl get pvc "$PVC" -n "$NAMESPACE" -o jsonpath='{.status.phase}')

    if [ "$STATUS" == "Bound" ]; then
        msg_check_success "🚀 PVC is Bound and ready to use"
    else
        msg_check_fail "PVC is in status: $STATUS"        
        msg_info "📋 Kubernetes Describe Output:"
        kubectl describe pvc "$PVC" -n "$NAMESPACE" | sed "s/^/$INDENT/"

        msg_info "📌 Recent Events:"
        kubectl get events -n "$NAMESPACE" \
            --field-selector involvedObject.name="$PVC" \
            --sort-by=.metadata.creationTimestamp | sed "s/^/$INDENT/"

        msg_info "📦 StorageClass details:"
        SC=$(kubectl get pvc "$PVC" -n "$NAMESPACE" -o jsonpath='{.spec.storageClassName}')
        msg_info_idented "StorageClass: $SC"
        if [ -n "$SC" ]; then
            kubectl describe storageclass "$SC" 2>/dev/null | sed "s/^/$INDENT/" || echo "${INDENT}Error: StorageClass '$SC' not found."
        else
            msg_warn "⚠️ No StorageClass defined for this PVC"
        fi
    fi

    if [ "$VERBOSE" = "1" ] || [ "$VERBOSE" = "true" ]; then
        msg "YAML VIEW" "Full manifest for $PVC"
        kubectl get pvc "$PVC" -n "$NAMESPACE" -o yaml | sed "s/^/$INDENT/"
    fi
}
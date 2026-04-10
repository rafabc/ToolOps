#!/bin/bash


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
        # ************************* KUBERNETES DASHBOARD *****************************
        kubectl delete -f *
        ;;
    1)
        # ************************* ACTIVE MQ **************************************** 
        uninstall_activemq
        ;;
    2)
        # ****************************** CAMEL K *************************************
        uninstall_camelk
        ;;
    3)
        # ****************************** REDIS ***************************************
        uninstall_redis
        ;;
    4)
        # ****************************** LINKERD *************************************
        uninstall_emojivoto
        uninstall_linkerd_viz
        uninstall_linkerd
        ;;

    5)
        # ****************************** KEYCLOAK ************************************
        uninstall_keycloak
        ;;
    6)
        # ****************************** CONFLUENT ***********************************
        uninstall_confluent
        ;;
    7)
        # ********************************* KLAW ************************************* 
        uninstall_klaw
        ;;
    8)
        # ********************************* KARAVAN **********************************
        uninstall_karavan
        ;;
    9)
        # ********************************* SOLACE ***********************************
        uninstall_solace
        ;;
    10) 
        # ********************************** N8N *************************************
        uninstall_n8n
        ;;
    11) 
        # ********************************* ISTIO ************************************
        uninstall_istio
        ;;
    12) 
        # ****************************** EVENT CATALOG *******************************
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
        check_kube_dashboard
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





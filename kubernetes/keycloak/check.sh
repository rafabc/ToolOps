#!/bin/bash


function check_keycloak() {

    clear
    NAMESPACE="keycloak"

    msg_task "Checking $NAMESPACE Status"
    echo

    POD_NAME="keycloak"
    SERVICE_NAME="keycloak"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo
    

}   
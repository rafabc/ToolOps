



function check_solace() {

    clear
    NAMESPACE="solace"

    msg_task "Checking $NAMESPACE Status"
    echo

    POD_NAME="solace"
    SERVICE_NAME="solace"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo
    
    POD_NAME="solace-discovery-agent"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    
    POD_NAME="solace-schema-registry"
    SERVICE_NAME="schema-registry"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo 

    POD_NAME="solace-schema-registry-ui"
    SERVICE_NAME="schema-registry-ui"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo 

    POD_NAME="postgres"
    SERVICE_NAME="postgres"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo 

    POD_NAME="idp"
    SERVICE_NAME="idp"
    PVC_NAME="idp-data"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo
    check_pvc_status $NAMESPACE $PVC_NAME

}   




function check_kube_dashboard() {

    clear
    NAMESPACE="kubernetes-dashboard"

    msg_task "Checking $NAMESPACE Status"
    echo

    POD_NAME="kubernetes-dashboard"
    SERVICE_NAME="kubernetes-dashboard"
    check_pod_status $NAMESPACE $POD_NAME
    echo
    check_svc_status $NAMESPACE $SERVICE_NAME
    echo
    

}   
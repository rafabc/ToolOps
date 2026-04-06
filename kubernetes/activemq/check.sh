


function check_activemq() {

    SERVICE_NAME="active-mq"
    NAMESPACE="active-mq"

    check_pod_status $NAMESPACE $SERVICE_NAME
    check_svc_status $NAMESPACE $SERVICE_NAME

}   
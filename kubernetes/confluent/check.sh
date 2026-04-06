




function check_confluent() {

    NAMESPACE="confluent"
    SERVICE_NAME="kafka"

    check_pod_status $NAMESPACE $SERVICE_NAME
    check_svc_status $NAMESPACE $SERVICE_NAME


}   
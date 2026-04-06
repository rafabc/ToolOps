function install_kafbat_helm() {

    NAMESPACE="kafbat"
    create_namespace $NAMESPACE

    if [ "$VERBOSE" -eq 1 ]; then
        msg_info "Pods"
        kubectl get pods
    fi

    helm repo add kafka-ui https://kafbat.github.io/helm-charts
    helm repo update
    helm install kafka-ui kafka-ui/kafka-ui --set envs.config.KAFKA_CLUSTERS_0_NAME=local --set envs.config.KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:9092

   # wait_pod_running "eventcatalog"

    port_forward "8987" "80" kafka-ui

}

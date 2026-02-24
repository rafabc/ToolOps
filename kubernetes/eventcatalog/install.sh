


function install_event_catalog_helm() {


	NAMESPACE="event-catalog"
	create_namespace $NAMESPACE

    if [ "$VERBOSE" -eq 1 ]; then
		msg_info "Pods"
		kubectl get pods
	fi


    helm repo add oso-devops https://osodevops.github.io/helm-charts/

    helm repo update

    helm install eventcatalog oso-devops/eventcatalog -n $NAMESPACE -f ./values.yaml --set defaultRevision=default


    wait_pod_running "eventcatalog"

	port_forward "8080" "80" eventcatalog

}
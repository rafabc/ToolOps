#!/usr/bin/env bash

function install_confluent() {

	#  export TUTORIAL_HOME="https://raw.githubusercontent.com/confluentinc/confluent-kubernetes-examples/master/quickstart-deploy/kraft-quickstart"

	NAMESPACE="confluent"
	create_namespace $NAMESPACE

	if ! command -v helm &>/dev/null; then
		msg_warn "Helm could not be found, please install Helm before start."
		exit 1
	else
		if ! helm repo list | grep -q 'confluentinc'; then
			helm repo add confluentinc https://packages.confluent.io/helm
			helm repo update
		else
			msg_info "Helm repo confluentinc already exists."
		fi

		if [ "$VERBOSE" -eq 0 ]; then
			helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes \
				--namespace $NAMESPACE \
				--set namespaced=false \
				--set image.pullChecks.enabled=falses &>/dev/null
		else
			helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes \
				--namespace $NAMESPACE \
				--set namespaced=false \
				--set image.pullChecks.enabled=false
		fi
	fi


	if [ "$VERBOSE" -eq 1 ]; then
		msg_info "Pods"
		kubectl get pods
	fi

	apply_resources "confluent.yml"

	wait_pod_running "kraftcontroller-0"

	wait_pod_running "kafka-0"

	wait_pod_running "controlcenter-0"

	port_forward "9021" "9021" controlcenter

	port_forward "9092" "9092" kafka-0-internal
	port_forward "9093" "9092" kafka-1-internal
	port_forward "9094" "9092" kafka-2-internal

	port_forward "8082" "8082" kafkarestproxy-0-internal
	
	port_forward "8088" "8088" ksqldb-0-internal

	port_forward "8081" "8081" schemaregistry-0-internal

	port_forward "8083" "8083" connect-0-internal
	

}

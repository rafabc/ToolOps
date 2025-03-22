#!/usr/bin/env bash

function install_confluent() {

	#  export TUTORIAL_HOME="https://raw.githubusercontent.com/confluentinc/confluent-kubernetes-examples/master/quickstart-deploy/kraft-quickstart"

	NAMESPACE="confluent"

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
			helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes &>/dev/null
		else
			helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes
		fi
	fi

	create_namespace $NAMESPACE

	if [ "$VERBOSE" -eq 1 ]; then
		msg_info "Pods"
		kubectl get pods
	fi

	apply_resources "confluent.yml"

	port_forward "9021" "9021" controlcenter

}

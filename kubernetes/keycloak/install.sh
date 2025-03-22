#!/usr/bin/env bash

function install_keycloak() {

	NAMESPACE="keycloak"

	create_namespace $NAMESPACE

	if [ "$VERBOSE" -eq 1 ]; then
		msg_info "Pods"
		kubectl get pods
	fi

	apply_resources "keycloak.yml"

	port_forward "8765" "8080" keycloak

}

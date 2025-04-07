#!/usr/bin/env bash


# USER: artemis   
# PSWD: artemis


function install_activemq() {

	NAMESPACE="active-mq"

	create_namespace $NAMESPACE

	if [ "$VERBOSE" -eq 1 ]; then
		msg_info "Pods"
		kubectl get pods
	fi

	apply_resources "activemq.yml"

	wait_pod_running "active-mq"

	port_forward "8228" "8161" active-mq #dashboard  #OJO NO SE PUEDE REDIRIGIR EL PUERTO 8161 ES EL DE DOCKER DESKTOP
	port_forward "8338" "1883" active-mq   #OJO NO SE PUEDE REDIRIGIR EL PUERTO 1883 ES EL DE DOCKER DESKTOP

	port_forward "8448" "61616" active-mq #openwire
	port_forward "8558" "61613" active-mq  #stomp
	port_forward "8668" "5672" active-mq #amqp

}	

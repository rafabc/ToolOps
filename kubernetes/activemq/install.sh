#!/usr/bin/env bash


# USER: artemis   
# PSWD: artemis


function install_activemq() {

	NAMESPACE="active-mq"
	START=$(date +%s.%N)
	create_resources "activemq.yml" $NAMESPACE
	msg "Waiting for ActiveMQ pods to be running..."
	wait_pod_running "active-mq"

	port_forward "8228" "8161" active-mq #dashboard  #OJO NO SE PUEDE REDIRIGIR EL PUERTO 8161 ES EL DE DOCKER DESKTOP
	port_forward "8338" "1883" active-mq   #OJO NO SE PUEDE REDIRIGIR EL PUERTO 1883 ES EL DE DOCKER DESKTOP

	port_forward "8448" "61616" active-mq #openwire
	port_forward "8558" "61613" active-mq  #stomp
	port_forward "8668" "5672" active-mq #amqp

	msg_ok "ActiveMQ installed successfully"

}	

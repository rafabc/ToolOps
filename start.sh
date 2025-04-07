#!/usr/bin/env bash

source ./scripts/menu.sh
source ./scripts/azure.sh
source ./scripts/colors.sh
source ./scripts/msg.sh
source ./scripts/symbols.sh
source ./scripts/operations.sh
source ./scripts/docker.sh
source ./scripts/setup-semver.sh
source ./scripts/yarn.sh
source ./scripts/git.sh
source ./scripts/builders/build-tool.sh


source ./scripts/kubernetes.sh
source ./scripts/spinner.sh

source ./kubernetes/activemq/install.sh
source ./kubernetes/activemq/uninstall.sh

source ./kubernetes/linkerd/install.sh
source ./kubernetes/linkerd/uninstall.sh

source ./kubernetes/keycloak/install.sh
source ./kubernetes/keycloak/uninstall.sh

source ./kubernetes/confluent/install.sh
source ./kubernetes/confluent/uninstall.sh

source ./kubernetes/camelk/install.sh
source ./kubernetes/camelk/uninstall.sh

source ./kubernetes/klaw/install.sh
source ./kubernetes/klaw/uninstall.sh

source ./kubernetes/karavan/install.sh
source ./kubernetes/karavan/uninstall.sh

source ./kubernetes/redis/install.sh
source ./kubernetes/redis/uninstall.sh

source ./kubernetes/solace/install.sh
source ./kubernetes/solace/uninstall.sh

source ./kubernetes/n8n/install.sh
source ./kubernetes/n8n/uninstall.sh

source ./kubernetes/istio/install.sh
source ./kubernetes/istio/uninstall.sh



if [[ "$1" == "-v" ]]; then
    export VERBOSE=1
    msg "RUNNING IN" "VERBOSE MODE"
    sleep 2
else
    export VERBOSE=0
fi



launch_menu_platform
platform_selected=$?





#MENU DOCKER COMPOSE TOOLS
# This function executes a specific action using Docker Compose.
# It is intended to be used within the ToolOps project.
# Usage:
#   execute_compose_tool_action
function execute_compose_tool_action() {

    launch_menu_tool_actions
    action_selected=$?

    case "$tool_selected" in
    0)
        #pre tested 6.2.0
        export CONFLUENT_VERSION="7.3.0"
        cd compose/confluent
        msg "TOOL SELECTED CONFLUENT WITH ACTION $action_selected"
        sleep 1
        exec_tool_action $action_selected
        ;;
    1)
        cd compose/jenkins
        msg "TOOL SELECTED JENKINS WITH ACTION $action_selected"
        sleep 1
        exec_tool_action $action_selected
        docker-compose exec jenkins apt update
        docker-compose exec jenkins apt install jq -y
        ;;
    2)
        cd compose/gitlab
        msg "TOOL SELECTED GITLAB WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    3)
        cd compose/wso2/4.1.0
        msg "TOOL SELECTED WSO2 WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    4)
        cd compose/nexus
        msg "TOOL SELECTED NEXUS WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    5)
        cd compose/mailhog
        msg "TOOL SELECTED MAILHOG WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    6)
        cd compose/redis
        msg "TOOL SELECTED REDIS WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    7)
        cd compose/flink
        msg "TOOL SELECTED FLINK WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    8)
        cd compose/prometheus
        msg "TOOL SELECTED PROMETHEUS WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    9)
        cd compose/klaw
        msg "TOOL SELECTED KLAW WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    esac
}



#MENU KUBERNETES TOOLS
# This function executes a specific action using the Kubernetes tool.
# It is intended to be used within the start.sh script located at ./ToolOps/.
# Usage:
#   execute_kube_tool_action
# No parameters are required.
function execute_kube_tool_action() {

    case "$tool_selected" in
    0)
        cd kubernetes/dashboard
        msg "TOOL SELECTED" "KUBERNETES DASHBOARD" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    1)
        cd kubernetes/activemq
        msg "TOOL SELECTED" "ACTIVE MQ (ARTEMIS)" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    2)
        cd kubernetes/camelk
        msg "TOOL SELECTED" "CAMEL-K" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    3)
        cd kubernetes/redis
        msg "TOOL SELECTED" "REDIS" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    4)
        cd kubernetes/linkerd
        msg "TOOL SELECTED" "LINKERD" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    5)
        cd kubernetes/keycloak
        msg "TOOL SELECTED" "KEYCLOAK" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    6)
        cd kubernetes/confluent
        msg "TOOL SELECTED" "CONFLUENT" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    7)
        cd kubernetes/klaw
        msg "TOOL SELECTED" "KLAW" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    8)
        cd kubernetes/karavan
        msg "TOOL SELECTED" "KARAVAN" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    9)
        cd kubernetes/solace
        msg "TOOL SELECTED" "SOLACE" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    10)
        cd kubernetes/n8n
        msg "TOOL SELECTED" "N8N" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    11)
        cd kubernetes/istio
        msg "TOOL SELECTED" "ISTIO" "WITH ACTION $action_selected IN tool $tool_selected"
        ;;
    esac
}


#PLATFROM DOCKER COMPOSE
if [ "$platform_selected" -eq 0 ]; then
    msg "Platform selected is DOCKER COMPOSE"
    sleep 1
    launch_menu_compose_tools
    tool_selected=$?
    execute_compose_tool_action
fi


#PLATFROM KUBERNETES
if [ "$platform_selected" -eq 1 ]; then
    msg "Platform selected is KUBERNETES ON PREMISES"
    #sleep 1
    launch_menu_kube_tools
    tool_selected=$?

    execute_kube_tool_action $tool_selected
    #sleep 1
    launch_menu_kube_actions
    action_selected=$?
    #echo "ACTION SELECTED $action_selected"
    #sleep 1
    exec_kube_action $action_selected $tool_selected  "$@"
fi
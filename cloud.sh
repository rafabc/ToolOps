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


launch_menu_cloud
cloud_selected=$?

if [ $cloud_selected -eq 0 ]; then
    launch_menu_aws_tools
    tool_selected=$?
fi

if [ $cloud_selected -eq 1 ]; then
    msg "$cloud_selected AZURE"
fi

if [ $cloud_selected -eq 2 ]; then
    msg "$cloud_selected GCP"
fi



launch_menu_tool_actions
action_selected=$?

# AWS TOOLS
if [ $cloud_selected -eq 0 ]; then

    case "$tool_selected" in
    0)
        cd cloud/aws/dynamodb
        echo "TOOL SELECTED DYNAMODB WITH ACTION $action_selected"
        exec_tool_action $action_selected
        ;;
    1)
        cd cloud/aws/sqs
        echo "TOOL SELECTED SQS WITH ACTION $action_selected"
        exec_tool_action $action_selected
        sleep 10
        ;;
    esac

fi

# launch_menu_cloud_tools
# tool_selected=$?

# launch_menu_cloud_actions
# action_selected=$?

#!/usr/bin/env bash

function exec_tool_action() {

    ACTION=$1


    msg "EXECUTING ACTION $ACTION"
    sleep 2

    case "$ACTION" in
        0)
            docker_compose_up
            ;;
        1)
            docker_compose_up
            ;;
        2)
            docker_compose_stop
            ;;
        3)
            docker_compose_restart
            ;;
        4)
            docker_compose_down
            ;;            
        5)
            docker_compose_delete
            ;;
        6)
            docker_compose_run
            ;;

    esac
}

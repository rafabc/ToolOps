#!/usr/bin/env bash

FIXED_LENGTH=50

function launch_menu_platform() {
    clear
    msg_task "Select destination platform"
    printf "\n%s$GREEN_BOLD%s"
    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  DOCKER COMPOSE")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  KUBERNETES ON PREMISES")
    
    # OPT2="%s$GREEN_BOLD%s %2s %s$ARROW%s KUBERNETES ON PREMISES  %29s"

    options=("$OPT1" "$OPT2")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
    #echo "        value = ${options[$choice]}"
    return $choice
}




function launch_menu_compose_tools() {

    clear
    msg_task "Select product to deploy with docker compose"
    printf "\n%s$GREEN_BOLD%s"
    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  CONFLUENT")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  JENKINS")
    OPT3=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  GITLAB")
    OPT4=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  WSO2")
    OPT5=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  NEXUS")
    OPT6=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  MAILHOG")
    OPT7=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  REDIS")
    OPT8=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  FLINK")
    OPT9=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  PROMETHEUS")
    OPT10=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  KLAW")

    # OPT2="%s$GREEN_BOLD%s %2s %s$ARROW%s JENKINS          "
    # OPT3="%s$GREEN_BOLD%s %2s %s$ARROW%s GITLAB            "
    # OPT4="%s$GREEN_BOLD%s %2s %s$ARROW%s WSO2       "
    # OPT5="%s$GREEN_BOLD%s %2s %s$ARROW%s NEXUS     "
    # OPT6="%s$GREEN_BOLD%s %2s %s$ARROW%s MAILHOG     "
    # OPT7="%s$GREEN_BOLD%s %2s %s$ARROW%s REDIS     "
    # OPT8="%s$GREEN_BOLD%s %2s %s$ARROW%s FLINK     "
    # OPT9="%s$GREEN_BOLD%s %2s %s$ARROW%s PROMETHEUS     "
    # OPT10="%s$GREEN_BOLD%s %2s %s$ARROW%s KLAW     "

    options=("$OPT1" "$OPT2" "$OPT3" "$OPT4" "$OPT5" "$OPT6" "$OPT7" "$OPT8" "$OPT9" "$OPT10")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
    echo "        value = ${options[$choice]}"
    return $choice

}


function launch_menu_cloud() {

    clear
    msg_task "Select cloud"
    printf "\n%s$GREEN_BOLD%s"
    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  AWS")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  AZURE")
    OPT3=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  GCP")

    options=("$OPT1" "$OPT2" "$OPT3")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
    echo "        value = ${options[$choice]}"
    return $choice

}

function launch_menu_aws_tools() {

    clear
    msg_task "Select aws tool"
    printf "\n%s$GREEN_BOLD%s"

    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  DYNAMODB")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  SQS")

    options=("$OPT1" "$OPT2")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
    echo "        value = ${options[$choice]}"
    return $choice

}


function launch_menu_tool_actions() {
    clear
    msg_task "Select compose action"
    printf "\n%s$CYAN_BOLD%s"
    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  BUILD & UP")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  START")
    OPT3=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  STOP")
    OPT4=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  RESTART")
    OPT5=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  DOWN")
    OPT6=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  DELETE")
    OPT7=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  RUN SERVICE")

    options=("$OPT1" "$OPT2" "$OPT3" "$OPT4" "$OPT5" "$OPT6" "$OPT7")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
    #echo "        value = ${options[$choice]}"
    return $choice
}



function launch_menu_kube_tools() {

    clear
    msg_task "Select tool to deploy in kubernetes"
    printf "\n%s$GREEN_BOLD%s"
    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  FREE PLACE")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  KUBERNETES DASHOBOARD")
    OPT3=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  CAMEL K")
    OPT4=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  REDIS")
    OPT5=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  LINKERD")
    OPT6=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  KEYCLOAK")
    OPT7=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  CONFLUENT")
    OPT8=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  KLAW")
    OPT9=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  KARAVAN")
    OPT10=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  SOLACE")
    OPT11=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  N8N")
    OPT12=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  ISTIO")

    options=("$OPT1" "$OPT2" "$OPT3" "$OPT4" "$OPT5" "$OPT6" "$OPT7" "$OPT8" "$OPT9" "$OPT10" "$OPT11" "$OPT12")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
   # echo "        value = ${options[$choice]}"
    return $choice

}


function launch_menu_kube_actions() {
    clear
    msg_task "Select product action"
    printf "\n%s$CYAN_BOLD%s"
    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  APPLAY")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  DELETE")
    OPT3=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  CHECK STATUS")
    # OPT4=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  RESTART")
    # OPT5=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  DOWN")
    # OPT6=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  DELETE")
    # OPT7=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  RUN SERVICE")


    options=("$OPT1" "$OPT2" "$OPT3")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
    #echo "        value = ${options[$choice]}"
    return $choice
}


function launch_menu_semver_version() {
    clear
    msg_task "Select semver action to start build"
    printf "\n%s$BLUE_BOLD%s"

    OPT1=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  PATCH (parche)")
    OPT2=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  MINOR (minor version)")
    OPT3=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  MAJOR (major version)")
    OPT4=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  RELEASE (release version)")
    OPT5=$(printf "%-${FIXED_LENGTH}s$GREEN_BOLD%s %2s" "%4s$ARROW  PREREL (same actual version)")

    options=("$OPT1" "$OPT2" "$OPT3" "$OPT4" "$OPT5")
    select_option "${options[@]}"
    choice=$?
    printf "%s$RESET%s\n"
    #echo "        value = ${options[$choice]}"
    return $choice
}

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option() {

    # little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on() { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to() { printf "$ESC[$1;${2:-1}H"; }
    print_option() { printf "   $1 "; }
    print_selected() { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row() {
        IFS=';' read -sdR -p $'\E[6n' ROW COL
        echo ${ROW#*[}
    }
    key_input() {
        read -s -n3 key 2>/dev/null >&2
        if [[ $key = $ESC[A ]]; then echo up; fi
        if [[ $key = $ESC[B ]]; then echo down; fi
        if [[ $key = "" ]]; then echo enter; fi
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
        enter) break ;;
        up)
            ((selected--))
            if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi
            ;;
        down)
            ((selected++))
            if [ $selected -ge $# ]; then selected=0; fi
            ;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

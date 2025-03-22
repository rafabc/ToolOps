#!/bin/bash

URLBASE='localhost:3000/api'
#URLBASE='http://dependencias-des.ineco.es/api'
BASICAUTH=$(echo -n "admin:admin" | base64)
TOKEN=''
ENVIRONMENT='1000'
#ENVIRONMENT='1'

OK="\u2714"
ERROR="\u2718"
export ARROW="\u25ba"
export ARROW2="\u27a4"

RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
CYAN="\e[0;36m"
PURPLE="\e[0;35m"

RED_BOLD="\e[1;31m"
GREEN_BOLD="\e[1;32m"
YELLOW_BOLD="\e[1;33m"
BLUE_BOLD="\e[1;34m"
PURPLE_BOLD="\e[1;35m"
CYAN_BOLD="\e[1;36m"

RED_BACK="\e[41m"
GREEN_BACK="\e[42m"
YELLOW_BACK="\e[43m"
BLUE_BACK="\e[44m"
PURPLE_BACK="\e[45m"
CYAN_BACK="\e[46m"

RED_HIGH="\e[0;91m"
GREEN_HIGH="\e[0;92m"
YELLOW_HIGH="\e[0;93m"
BLUE_HIGH="\e[0;94m"
PURPLE_HIGH="\e[0;95m"
CYAN_HIGH="\e[0;96m"

RESET="\e[0m"

START=$(date +%s)
END=$(date +%s)

RUNTIME=$((END - START))

function msg_ok() {
    printf "%s$GREEN%s-------------------------------------------------------------------------------\n"
    printf "%s$GREEN%s %s$OK%s  %s$1%s in %s$PURPLE_HIGH%s %s$((END - START)) sg\n"
    printf "%s$GREEN%s-------------------------------------------------------------------------------%s$RESET%s\n"
}

function msg_ko() {
    printf "%s$RED%s-------------------------------------------------------------------------------\n"
    printf "%s$RED%s %s$ERROR%s $1\n"
    printf "%s$RED%s-------------------------------------------------------------------------------%s$RESET%s\n"
}

function msg_task() {
    printf "\n%s$YELLOW%s-------------------------------------------------------------------------------\n"
    printf "%s$YELLOW%s %s$ARROW%s $1\n"
    printf "%s$YELLOW%s-------------------------------------------------------------------------------%s$RESET%s\n"
}

function check_operation() {
    STATUS=$1
    END=$(date +%s)
    if [ $STATUS -eq 0 ]; then
        msg_ok "$2 executed success"
    else
        msg_ko "$2 fail operation"
    #	exit 1
    fi
}

START=$(date +%s)
msg_task 'Login admin user'
TOKEN=$(curl --location --request GET $URLBASE/users/login/basic \
    --header "Content-type: application/json" \
    --header "Accept: application/json" \
    --header "Authorization: Basic $BASICAUTH" | grep -Po '"token": *\K"[^"]*"')

TOKEN="${TOKEN%\"}"
TOKEN="${TOKEN#\"}"

echo "AUTH: $TOKEN"
check_operation $? "Login"

TOTALAPPS=0
TOTALSUCCESS=0
TOTALFAIL=0
FAILAPPS=''

function exec_load_curl() {
    printf "%s$PURPLE%s Launching Curl - INPUT: APP:$1  REPO:$2%s$RESET%s\n"
    ((TOTALAPPS++))
    UPDATE=$(curl --location --request POST $URLBASE/applications/update \
        --header "x-auth-token: $TOKEN" \
        --header "Content-type: application/json" \
        --header "Accept: application/json" \
        --data-raw '{"application": "'$1'", "version": "0.0.1", "path": "PRINCIPAL", "lang": "2", "id_environment": '$ENVIRONMENT', "repo": {"name": "'$2'"} }' | grep -Po '"update": *\K"[^"]*"')

    UPDATE="${UPDATE%\"}"
    UPDATE="${UPDATE#\"}"

    if [ "$UPDATE" = "success" ]; then
        printf "%s$GREEN_BACK%s % 32s$UPDATE % 38o\n"
        ((TOTALSUCCESS++))
        return 0
    else
        printf "%s$RED_BACK%s % 32s$UPDATE % 41o\n"
        ((TOTALFAIL++))
        FAILAPPS="$FAILAPPS $1"
        return 1
    fi
}

input="apps.txt"
while IFS= read -r line; do
    #echo "$APP"
    START=$(date +%s)
    APP=$(echo $line | sed -e 's/\r//g')
    ACTIVE=$(echo $line | cut -d '|' -f1)
    REPONAME=$(echo $line | cut -d '|' -f2)
    REPONAME=$(echo $REPONAME | sed -e 's/\r//g')
    msg_task "Carga aplicacion $APP"
    exec_load_curl $ACTIVE $REPONAME
    check_operation $? "Resuldato $APP $UPDATEAPP"

done <"$input"

printf "%s$CYAN_BACK%s % 6s TOTAL APPS ANALYZED: $TOTALAPPS % 48o\n"
printf "%s$GREEN_BACK%s % 6s TOTAL APPS SUCCESS: $TOTALSUCCESS % 48o\n"
printf "%s$RED_BACK%s % 6s TOTAL APPS FAIL: $TOTALFAIL % 48o\n"
printf "%s$BLUE_BACK%s % 6s FAIL APPS: $FAILAPPS  % 52o\n%s$RESET%s\n"

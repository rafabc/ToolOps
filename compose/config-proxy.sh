source ./scripts/colors.sh
source ./scripts/msg.sh
source ./scripts/symbols.sh
source ./scripts/operations.sh


PROXY_IP=1.1.1.1


if [ "$1" = "on" ]; then
    msg_task "Setting up git proxy"
    git config advice.diverging false
    export GIT_CURL_VERBOSE=1
    git config --global merge.commit no
    git config --global merge.ff no
    git config --global pull.ff no
    git config --global http.proxy $PROXY_IP:8080
    git config --global https.proxy $PROXY_IP:8080
    check_operation $? "Proxy enabled"

    export HTTP_PROXY=http://$PROXY_IP:8080
    export HTTPS_PROXY=http://$PROXY_IP:8080

    msg_task "Setting up VPN proxy for MAC"
    networksetup -setwebproxy "Wi-fi" $PROXY_IP 8080
    networksetup -setsecurewebproxy "Wi-fi" $PROXY_IP 8080
    check_operation $? "VPN Proxy enabled"

    networksetup -setairportpower en0 off
    sleep 2
    networksetup -setairportpower en0 on
fi

if [ "$1" = "off" ]; then
    msg_task "Setting down git proxy"
    git config advice.diverging true
    export GIT_CURL_VERBOSE=0
    git config --global --unset merge.commit
    git config --global --unset merge.ff
    git config --global --unset pull.ff
    git config --global --unset http.proxy 
    git config --global --unset https.proxy
    check_operation $? "Proxy disabled"

    export HTTP_PROXY=
    export HTTPS_PROXY=

    msg_task "Setting down VPN proxy for MAC"
    networksetup -setwebproxystate "Wi-fi" off
    networksetup -setsecurewebproxystate "Wi-fi" off
    check_operation $? "VPN Proxy disabled"

    networksetup -setairportpower en0 off
    sleep 2
    networksetup -setairportpower en0 on
fi


msg_task "Checking proxy status"
networksetup -getwebproxy "Wi-Fi"
check_operation $? "VPN Proxy status checked"

msg_task "Checking secure proxy status"
networksetup -getsecurewebproxy "Wi-Fi"
check_operation $? "VPN secure Proxy status checked"






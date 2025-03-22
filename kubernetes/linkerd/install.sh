#!/usr/bin/env bash

function install_linkerd() {

    msg_task "Install Linkerd Cli"
    curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
    msg_info "Add Linkerd command to PATH"
    export PATH=$HOME/.linkerd2/bin:$PATH
    msg_info "Linkerd added to PATH - Command only available inside script runtime"
    linkerd version
    #VALIDATE KUBE CLUSTER PRE INSTALL
    msg_info "Checking linkerd --pre"
    linkerd check --pre
    check_operation $? "Linkerd cli installed"

    #INSTALL LINKERD
    msg_task "Install linkerd"
    linkerd install --crds | kubectl apply -f -
    linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
    check_operation $? "Linkerd installed"

    apply_resources "linkerd.yml"
    linkerd check
    check_operation $? "Linkerd apply"

    install_emojivoto
    install_viz
}


function install_emojivoto() {
    #INSTALL DEMO APP
    msg_task "Installing emojivoto"
    curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
    #kubectl -n emojivoto port-forward svc/web-svc 8080:80
    kubectl get -n emojivoto deploy -o yaml | linkerd inject - | kubectl apply -f -
    msg_info "Checking emojivoto"
    linkerd -n emojivoto check --proxy
    check_operation $? "emojivoto apply"
}

function install_viz() {
    #EXPLORE LINKERD
    msg_info "Install VIZ"
    linkerd viz install | kubectl apply -f - # install the on-cluster metrics stack
    msg_info "Checking linkerdv VIZ"
    linkerd viz check
    msg_info "Launching VIZ Dashboard"
    linkerd viz dashboard &
}

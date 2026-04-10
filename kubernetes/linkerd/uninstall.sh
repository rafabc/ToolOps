#!/usr/bin/env bash

function uninstall_linkerd() {

    NAMESPACE="linkerd"

    msg_task "Start process uninstall $NAMESPACE"
    msg_info "Cambio a namespace $NAMESPACE"
    kubectl config set-context --current --namespace=$NAMESPACE &>/dev/null

    msg_info "Desinstalamos extension Jaeger"
    linkerd jaeger uninstall | kubectl delete -f -
    msg_info "Desinstalamos extension multicluster"
    linkerd multicluster uninstall | kubectl delete -f -

    msg_info "Desinstalamos Linkerd Control plane"
    linkerd uninstall | kubectl delete -f -


    delete_resources $NAMESPACE linkerd.yml
    echo
    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"



    msg_info "Matamos proceso dashboard linkerd"

    PID_PORT_DASHBOARD=$(lsof -i :50750 | awk '{print $2}' | tail -1)
    PUERTO_DASHBOARD=50750
    lsof -i tcp:$PUERTO_DASHBOARD &>/dev/null
    if [ $? -eq 0 ]; then
        msg_info_idented "PID_PORT_DASHBOARD $PID_PORT_DASHBOARD localizado, se procede a matarlo"
        kill -9 $PID_PORT_DASHBOARD
    else
        msg_warn_idented "PID_PORT_DASHBOARD $PID_PORT_DASHBOARD no existe, dashabord ya desconectado port forward"
    fi
    check_operation $? "Linkerd uninstall"
}

function uninstall_linkerd_viz() {
    msg_task "Start process uninstall linkerd viz"

    msg_info "Cambio a namespace linkerd-viz"
    kubectl config set-context --current --namespace=linkerd-viz &>/dev/null

    msg_info "Add Linkerd command to PATH"
    export PATH=$HOME/.linkerd2/bin:$PATH
    msg_check_success "Linkerd added to PATH - Command only available inside script runtime"
    
    msg_info "Desintalamos Linkerd viz"
    linkerd viz uninstall | kubectl delete -f -

    msg_info "Desintalamos namespace linkerd-viz"
    delete_namespace linkerd-viz || echo "Namespace finalizer process not found"
    check_operation $? "Linkerd viz uninstall"
}

function uninstall_emojivoto() {
    NAMESPACE="emojivoto"

    delete_resources $NAMESPACE emojivoto.yml
    echo
    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"
    check_operation $? "emojivoto uninstall"
}

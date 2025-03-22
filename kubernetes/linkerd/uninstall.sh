#!/usr/bin/env bash

function uninstall_linkerd() {
    msg_task "Start process uninstall linkerd"
    msg_info "Cambio a namespace linkerd"
    kubectl config set-context --current --namespace=linkerd &>/dev/null

    msg_info "Desinstalamos extension Jaeger"
    linkerd jaeger uninstall | kubectl delete -f -
    msg_info "Desinstalamos extension multicluster"
    linkerd multicluster uninstall | kubectl delete -f -

    msg_info "Desinstalamos Linkerd Control plane"
    linkerd uninstall | kubectl delete -f -

    #kubectl delete cm linkerd-config

    msg_info "Desintalamos Linkerd via delete linkerd.yml"
    kubectl delete -f linkerd.yml

    kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete clusterrole
    kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete clusterrolebinding
    kubectl get rolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete rolebinding
    kubectl delete -n kube-system rolebinding linkerd-linkerd-viz-tap-auth-reader
    kubectl get serviceaccounts -n emojivoto | cut -d ' ' -f 1 | tail -1 | xargs kubectl delete serviceaccount -n linkerd
    kubectl get serviceaccounts -n emojivoto | cut -d ' ' -f 1 | tail -1 | xargs kubectl delete serviceaccount -n emojivoto

    msg_info "Desintalamos validacion webhooks"
    kubectl get ValidatingWebhookConfigurations -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete ValidatingWebhookConfiguration
    msg_info "Desintalamos mutating webhooks"
    kubectl get MutatingWebhookConfigurations -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete MutatingWebhookConfiguration

    kubectl get cj -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete cj
    kubectl get serviceaccounts -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete serviceaccounts
    kubectl get deployments -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete deployments
    kubectl get rs -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete rs
    kubectl get cm -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete cm
    kubectl get secrets -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete secrets
    kubectl get svc -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete svc
    kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^linkerd' | xargs kubectl delete pods
    
    msg_info "Desintalamos namespace linkerd"
    delete_namespace linkerd || echo "Namespace finalizer process not found"

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

    # kubectl get pod -o yaml | linkerd uninject - | kubectl apply -f -

    check_operation $? "Linkerd viz uninstall"
}

function uninstall_emojivoto() {
    msg_task "Start process uninstall emojivoto"
    msg_info "Cambio a namespace emojivoto"
    kubectl config set-context --current --namespace=emojivoto &>/dev/null

    curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml | kubectl delete -f -

    msg_info "Desintalamos namespace emojivoto"
    delete_namespace emojivoto || echo "Namespace finalizer process not found"
    check_operation $? "emojivoto uninstall"
}

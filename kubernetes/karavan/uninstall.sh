#!/bin/bash

function uninstall_karavan() {

    msg "Cambio a namespace karavan"
    kubectl config set-context --current --namespace=karavan &>/dev/null
    kubectl delete -f karavan.yml # &>/dev/null


    delete_resources "karavan"

    delete_namespace karavan || echo "Namespace finalizer process not found"
    kubectl delete namespace karavan  & spinner  $! "Waiting delete namespace"
}

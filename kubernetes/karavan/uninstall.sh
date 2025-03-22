#!/bin/bash

function uninstall_karavan() {


    msg "Cambio a namespace karavan"
    kubectl config set-context --current --namespace=karavan &>/dev/null
    kubectl delete -f karavan.yml # &>/dev/null

}

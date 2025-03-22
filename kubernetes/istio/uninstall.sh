#!/bin/bash

function uninstall_istio() {

    NAMESPACE="istio"

    helm ls -n istio-system

    helm delete istio-ingress -n istio-ingress
    kubectl delete namespace istio-ingress
    helm delete istiod -n istio-system

    helm delete istio-base -n istio-system
    kubectl delete namespace istio-system
    kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete


}

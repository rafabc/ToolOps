#!/bin/bash

function uninstall_event_catalog() {

    msg "Uninstalling eventcatalog"

    NAMESPACE="event-catalog"

    helm ls -n $NAMESPACE


    helm delete eventcatalog -n $NAMESPACE
    kubectl delete namespace $NAMESPACE


    kubectl get crd -oname | grep --color=never 'eventcatalog' | xargs kubectl delete


}

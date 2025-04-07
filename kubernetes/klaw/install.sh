#!/usr/bin/env bash

function install_klaw() {

    NAMESPACE="klaw"

    create_namespace $NAMESPACE

    apply_resources "klaw.yml"

    POD_KLAW_CORE=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^klaw-core')
    POD_KLAW_CLUSTER_API=$(kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep '^klaw-cluster-api')

    wait_pod_running "klaw-core"

    port_forward "9097" "9097" klaw-core

    #USER=superadmin
    #PASSWORD=welcometoklaw

}

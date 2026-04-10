#!/bin/bash

function uninstall_redis() {

    NAMESPACE="redis"

    delete_resources $NAMESPACE redis.yml
    echo
    delete_namespace $NAMESPACE || echo "Namespace finalizer process not found"

    delete_port_forward redis
}
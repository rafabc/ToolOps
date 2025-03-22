#!/bin/bash

function install_redis() {

    NAMESPACE="redis"

    create_namespace $NAMESPACE

    apply_resources redis.yml

    port_forward "6379" "6379" redis
    port_forward "5540" "5540" redisinsight

}
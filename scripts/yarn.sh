#!/bin/bash


function yarn_build() {
    IMAGE=$1
    VERSION=$2
    START=$(date +%s)
    msg_task "Packing code - launching yarn build for $IMAGE version" $VERSION
    #yarn build
    
    check_operation $? "yarn build"
}
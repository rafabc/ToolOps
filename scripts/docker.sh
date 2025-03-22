#!/usr/bin/env bash

function docker_stop() {
    IMAGE=$1
    START=$(date +%s)
    msg_task "Stopping $IMAGE container"
    docker stop $(docker ps -a | grep $IMAGE | awk '{print $1;}')
    check_operation_no_break $? "docker stop $IMAGE previous container"
}

function docker_remove() {
    IMAGE=$1
    START=$(date +%s)
    msg_task "Removing $IMAGE container"
    docker rm $(docker ps -a | grep $IMAGE | awk '{print $1;}')
    check_operation_no_break $? "docker rm $IMAGE previous container"
}

function docker_build() {
    IMAGE=$1
    VERSION=$2
    START=$(date +%s)
    msg_task "Building new image $IMAGE" "$VERSION in $PWD"
    echo docker build --tag $IMAGE:$VERSION -f ./docker/dockerfile .
    docker build --force-rm=true --no-cache=true --build-arg DB_EDITION=ee --tag $IMAGE:$VERSION -f ./docker/dockerfile .
    check_operation $? "docker build $IMAGE $VERSION"
}

function docker_run() {
    IMAGE=$1
    VERSION=$2
    CONTAINER_NAME=$3
    PORTIN=$4
    PORTOUT=$5
    PORTIN2=$6
    PORTOUT2=$7
    ENVIRONMENT_VARS=($@)


    echo "numero de variables de entorno antes unset:" ${#ENVIRONMENT_VARS[*]}

    unset ENVIRONMENT_VARS[0]
    unset ENVIRONMENT_VARS[1]
    unset ENVIRONMENT_VARS[2]
    unset ENVIRONMENT_VARS[3]
    unset ENVIRONMENT_VARS[4]
    unset ENVIRONMENT_VARS[5]
    unset ENVIRONMENT_VARS[6]

    START=$(date +%s)

    msg_task "Running new $IMAGE container version" $VERSION
    echo "numero de variables de entorno:" ${#ENVIRONMENT_VARS[*]}
    

    [[ ! -z "$PORTOUT2" ]] && {
        echo "docker run -d --name $CONTAINER_NAME --network=confluent_default -dit --restart always -p $PORTOUT:$PORTIN -p $PORTOUT2:$PORTIN2 ${ENVIRONMENT_VARS[*]} $IMAGE:$VERSION"
        docker run -d --name $CONTAINER_NAME -dit --network=confluent_default --restart always -p $PORTOUT:$PORTIN -p $PORTOUT2:$PORTIN2 ${ENVIRONMENT_VARS[@]} $IMAGE:$VERSION
    } || {
        echo "docker run -d --name $CONTAINER_NAME -dit --restart always -p $PORTOUT:$PORTIN ${ENVIRONMENT_VARS[*]} $IMAGE:$VERSION"
        docker run -d --name $CONTAINER_NAME  -dit --network=confluent_default --restart always -p $PORTOUT:$PORTIN  ${ENVIRONMENT_VARS[@]} $IMAGE:$VERSION
    }

    
    check_operation $? "docker run"
}

function docker_tag() {
    IMAGE=$1
    VERSION=$2
    REPOSITORIE=$3
    START=$(date +%s)
    msg_task "Tag image $REPOSITORIE$IMAGE" $VERSION
    docker tag $IMAGE:$VERSION $REPOSITORIE$IMAGE:$VERSION
    check_operation $? "Tag $REPOSITORIE$IMAGE:$VERSION"
}

function docker_push() {
    IMAGE=$1
    VERSION=$2
    REPOSITORIE=$3
    START=$(date +%s)
    msg_task "Push image $REPOSITORIE$IMAGE version" $VERSION
    docker push $REPOSITORIE$IMAGE:$VERSION
    check_operation $? "Push image $REPOSITORIE$IMAGE $VERSION"
}


function docker_create_network() {
    docker network create -d bridge sb-network
}


function docker_compose_up() {
    msg_task "docker compose up" 
    #docker_create_network
    docker-compose up --build -d
    check_operation $? "docker compose up"
}

function docker_compose_start() {
    msg_task "docker compose run" 
    docker-compose run
    check_operation $? "docker compose run"
}

function docker_compose_stop() {
    msg_task "docker compose stop" 
    docker-compose stop
    check_operation $? "docker compose stop"
}

function docker_compose_restart() {
    msg_task "docker compose restart" 
    docker-compose restart
    check_operation $? "docker compose restart"
}


function docker_compose_down() {
    msg_task "docker compose down" 
    docker-compose down -v
    check_operation $? "docker compose down"
}

function docker_compose_delete() {
    msg_task "docker compose rm -v" 
    docker-compose rm -f -v
    check_operation $? "docker compose rm -v"
}


function docker_compose_run() {
    msg_task "docker compose run" 
    msg "Enter service name to be executed - example: 'sql-client' to run Apache Flink Sql Client"
    read ARG
    docker-compose run $ARG
    check_operation $? "docker compose run $ARG"
}
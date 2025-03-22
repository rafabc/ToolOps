#!/bin/bash

function install_camelk() {

    create_namespace "camel-k"

    install_kamel_client

    install_registry

    install_camelk_operator

    apply_resources "camelk.yml"

    check_installed_resources



    #&  BUILD INTEGRATION FROM IMAGE

    #BUIOD CON DOCKER NO ES VALIDO - SE TIENE QUE CONSTRUIR CON KAMEL  RUN PARA QUE LA GESTIONE EL OPERADOR
    #docker build -t host.docker.internal:5000/integration-from-image .
    #docker tag integration-from-image host.docker.internal:5000/integration-from-image:1.0.0

    #kamel run --name dbtoredis --image host.docker.internal:5000/dbtoredis integration.yml

    # msg "namespace actual: $(kubectl config view --minify --output 'jsonpath={..namespace}')"

}


function install_kamel_client() {
    msg "Cheking requirements"
    if brew list | grep kamel &>/dev/null; then
        msg_check_success "Cliente Camel K (kamel) se encuentra disponible en el sistema"
    else
        msg "Instalando kamel..."
        brew install kamel
    fi
}


function install_registry() {

    DAEMON_JSON="/Users/$(whoami)/.docker/daemon.json"
    INSECURE_REGISTRY="host.docker.internal:5000"

    if grep -q "$INSECURE_REGISTRY" "$DAEMON_JSON"; then
        msg_check_success "El registro inseguro $INSECURE_REGISTRY esta configurado correctamente en daemon.json"
    else
        msg_warn_idented "El registro inseguro $INSECURE_REGISTRY no esta configurado en daemon.json"
        msg_info "Agregando el registro inseguro $INSECURE_REGISTRY a daemon.json"
        jq '."insecure-registries" |= . + ["'"$INSECURE_REGISTRY"'"]' "$DAEMON_JSON" | sudo tee tmp.$$.json >/dev/null
        sudo mv tmp.$$.json "$DAEMON_JSON"
        msg_info "Reiniciando el servicio Docker para aplicar los cambios"
        brew services restart docker
    fi

    CONTAINER_NAME="registry"
    if docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
        msg_check_success "El contenedor $CONTAINER_NAME se esta ejecutando correctamente"
    else
        msg_info "El contenedor $CONTAINER_NAME no está en ejecucion. Se lanzara ahora."
        msg_info "docker run -d -p 5000:5000 --restart=always --name registry registry:2"
        docker run -d -p 5000:5000 --restart=always --name registry registry:2
    fi

}

function install_camelk_operator() {

    OPERATOR_NAME="camel-k-operator"
    # Comprueba si el operador está desplegado
    if kubectl get deployment "$OPERATOR_NAME" &>/dev/null; then
        msg_check_success "El operador $OPERATOR_NAME esta instalado correctamente"
    else
        msg_info "El operador $OPERATOR_NAME no esta desplegado. Instalando..."
        #Instalacion del operador
        #kamel install --olm=true --registry http://host.docker.internal:5000 --registry-insecure true --force #&>/dev/null
        #kubectl create -f https://operatorhub.io/install/camel-k.yaml
        kubectl apply -k github.com/apache/camel-k/install/overlays/kubernetes/descoped?ref=v2.6.0 --server-side

        msg_check_success "El operador $OPERATOR_NAME se ha instalado correctamente."
    fi

}


function check_installed_resources() {

    msg "Cheking resource created - updated"

    #TODO: convertir a bucles for por tipo de objeto y validar unitariamente
    # Comprueba si la plataforma de integracion camel-k esta creada
    INTEGRATION_PLATFORM="camel-k"
    if kubectl get integrationplatforms | grep "$INTEGRATION_PLATFORM" &>/dev/null; then
        msg_check_success "Recurso IntegrationPlatform se ha creado correctamente"
    else
        msg_check_fail "Recurso IntegrationPlatform no se ha creado"
    fi

    # Comprueba si el kit de integracion camel-kit esta creado
    INTEGRATION_KIT="camel-kit"
    if kubectl get ik | grep "$INTEGRATION_KIT" &>/dev/null; then
        msg_check_success "Recurso IntegrationKit $INTEGRATION_KIT se ha creado correctamente"
    else
        msg_check_fail "Recurso IntegrationKit $INTEGRATION_KIT no se ha creado"
    fi

    # DB TO REDIS NO SE PUEDE CREAR NO ESTA SOPORTADO POR QUARKUS
    # #& NO SE PUEDE USAR REDIS CON CAMEL-K VER ENLACE https://github.com/apache/camel-k/issues/4283
    # INTEGRATION="dbtoredis"
    # if kubectl get integrations | grep "$INTEGRATION" &>/dev/null; then
    #     msg_check_success "Recurso Integration $INTEGRATION se ha creado correctamente"
    # else
    #     msg_check_fail "Recurso Integration $INTEGRATION no se ha creado"
    # fi

    # Comprueba si la integracion esta creada
    INTEGRATION="camelk-integration-db"
    if kubectl get integrations | grep "$INTEGRATION" &>/dev/null; then
        msg_check_success "Recurso Integration $INTEGRATION se ha creado correctamente"
    else
        msg_check_fail "Recurso Integration $INTEGRATION no se ha creado"
        kubectl get integrations
    fi

    # Comprueba si el kamelet events-kamelet se ha creada
    KAMELET="events-source"
    if kubectl get kamelets | grep "$KAMELET" &>/dev/null; then
        msg_check_success "Recurso Kamelet $KAMELET se ha creado correctamente"
    else
        msg_check_fail "Recurso Kamelet $KAMELET no se ha creado"
    fi

}

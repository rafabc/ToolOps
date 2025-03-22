#!/bin/bash

function install_istio() {

    NAMESPACE="istio"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        msg_info_idented "Namespace $NAMESPACE localizado, no es necesaria su creacion"
    else
        msg_warn_idented "Namespace $NAMESPACE no existe - se procede a su creacion"
        kubectl create namespace $NAMESPACE
    fi

    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 sh -
    cd istio-1.22.0
    export PATH=$PWD/bin:$PATH

    istioctl install --set profile=demo -y

    msg "Cambio a namespace $NAMESPACE"
    kubectl config set-context --current --namespace=$NAMESPACE &>/dev/null

    kubectl label namespace istio istio-injection=enabled

    kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    kubectl get services
    kubectl get pods
    #& Verify everything is working correctly up to this point. Run this command to see if the app is running inside the cluster and serving HTML pages by checking for the page title in the response
    kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

    #& Associate this application with the Istio gateway:
    kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

    #& Ensure that there are no issues with the configuration:
    istioctl analyze

    kubectl apply -f samples/addons
    kubectl rollout status deployment/kiali -n istio-system


    PORT=3000
    PID_PORT=$(lsof -i :$PORT | awk '{print $2}' | tail -1)
    lsof -i tcp:$PORT &>/dev/null
    if [ $? -eq 0 ]; then
        msg_info_idented "PID_PORT $PID_PORT de puerto $PORT localizado, se procede a matarlo"
        kill -9 $PID_PORT
    else
        msg_warn_idented "PID_PORT $PID_PORT no existe, ya desconectado port forward"
    fi

    PORT=16685
    PID_PORT=$(lsof -i :$PORT | awk '{print $2}' | tail -1)
    lsof -i tcp:$PORT &>/dev/null
    if [ $? -eq 0 ]; then
        msg_info_idented "PID_PORT $PID_PORT de puerto $PORT localizado, se procede a matarlo"
        kill -9 $PID_PORT
    else
        msg_warn_idented "PID_PORT $PID_PORT no existe, ya desconectado port forward"
    fi

    PORT=9080
    PID_PORT=$(lsof -i :$PORT | awk '{print $2}' | tail -1)
    lsof -i tcp:$PORT &>/dev/null
    if [ $? -eq 0 ]; then
        msg_info_idented "PID_PORT $PID_PORT de puerto $PORT localizado, se procede a matarlo"
        kill -9 $PID_PORT
    else
        msg_warn_idented "PID_PORT $PID_PORT no existe, ya desconectado port forward"
    fi

    sleep 3

    istioctl dashboard kiali & \
    kubectl -n istio-system port-forward "svc/grafana" 3000:3000 & \
    kubectl -n istio-system port-forward "svc/tracing" 16685:80 & \
    kubectl -n istio port-forward "svc/productpage" $PORT:$PORT & \
    for i in $(seq 1 200); do curl -s -o /dev/null "http://localhost:9080/productpage"; done


}

#FUNNCIONA
function install_istio_with_helm() {

    #docker login previously needed

    docker login

    curl https://registry-1.docker.io/v2/

    helm repo add istio https://istio-release.storage.googleapis.com/charts
    helm repo update

    kubectl create namespace istio-system
    helm install istio-base istio/base -n istio-system --set defaultRevision=default

    helm ls -n istio-system

    helm install istiod istio/istiod -n istio-system --wait

    helm ls -n istio-system

    helm status istiod -n istio-system

    kubectl get deployments -n istio-system --output wide

    kubectl create namespace istio-ingress
    helm install istio-ingress istio/gateway -n istio-ingress --wait

    helm show values istio/gateway

}

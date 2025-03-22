#!/bin/bash

function create_namespace() {

    NAMESPACE=$1

    if [ "$VERBOSE" -eq 0 ]; then
        kubectl get namespace "$NAMESPACE" &>/dev/null
        NS=$?
    else
        kubectl get namespace "$NAMESPACE"
        NS=$?
    fi

    if [ $NS -eq 0 ]; then
        msg "Namespace $NAMESPACE localizado, no es necesaria su creacion"
    else
        msg_warn "Namespace $NAMESPACE no existe - se procede a su creacion"
        msg "Applying $NAMESPACE namespace"

       if [ ! -f namespace.yml ]; then
            msg_warn "El fichero namespace.yml no existe"
            return 1
        fi

        if [ "$VERBOSE" -eq 0 ]; then
            kubectl apply -f namespace.yml &>/dev/null
        else
            kubectl apply -f namespace.yml
        fi
    fi

    msg "Cambio a namespace $NAMESPACE"
    if [ "$VERBOSE" -eq 0 ]; then
        kubectl config set-context --current --namespace=$NAMESPACE &>/dev/null
    else
        kubectl config set-context --current --namespace=$NAMESPACE
    fi

}


function delete_namespace() {

    #FUNCIONA
    # get namespace info to check why cant delete <-- see apiservice here (message)
    # kubectl get namespace confluent -o json | jq 'del(.spec.finalizers[] | select("kubernetes"))'
    # kubectl get apiservice
    # kubectl delete apiservice <apiservice-name>

    NAMESPACE=$1

    msg_info "Comienzo proceso borrado namespace $NAMESPACE"

    # Comprueba si el namespace existe usando el comando "kubectl get namespace"
    kubectl get namespace "$NAMESPACE" &>/dev/null

    # Si el comando no devuelve un error, el namespace existe
    if [ $? -eq 0 ]; then
        msg_info_idented "Namespace $NAMESPACE localizado, se procede al borrado"
    else
        msg_warn_idented "Namespace $NAMESPACE no existe"
        return
    fi

    msg_info_idented "pre delete"

    # kubectl delete namespace $NAMESPACE &>/dev/null

    msg_info_idented "delete namespace"

    set -eo pipefail

    msg_info_idented "set eo"

    die() {
        echo "$*" 1>&2
        exit 1
    }

    need() {
        msg_info_idented "Which $1"
        which "$1" &>/dev/null || die "Binary '$1' is missing but required"
    }

    # checking pre-reqs
    need "jq"
    need "curl"
    need "kubectl"

    PROJECT="$1"
    shift

    msg_info_idented "Checking namespace"

    test -n "$PROJECT" || die "Missing arguments: kill-ns <namespace>"

    kubectl proxy &>/dev/null &
    PROXY_PID=$!

    killproxy() {
        echo $PROXY_PID
        kill $PROXY_PID
    }
    trap killproxy EXIT

    sleep 1 # give the proxy a second

    msg_info_idented "killing namespace"

    kubectl get namespace "$PROJECT" -o json | jq 'del(.spec.finalizers[] | select("kubernetes"))' | curl -s -k -H "Content-Type: application/json" -X PUT -o /dev/null --data-binary @- http://localhost:8001/api/v1/namespaces/$PROJECT/finalize && msg_info_idented "Killed namespace: $PROJECT"

    msg_info_idented "namespace killed"
    # proxy will get killed by the trap
}

function exec_kube_action() {

    ACTION=$1
    TOOL=$2

    case "$ACTION" in
    0)
        kube_apply $TOOL
        ;;
    1)
        kube_delete $TOOL
        ;;
    2)
        kube_check $TOOL "$@"
        ;;
    esac
}

function kube_apply() {
    TOOL=$1

    if [ "$VERBOSE" -eq 1 ]; then
        msg "APPLY $TOOL"
        msg $PWD
    fi

    case "$TOOL" in
    0) # ************************* FREE PLACE ******************************
        ./apply.sh
        sleep 3
        ./port-forward-db.sh
        ;;
    1) # ************************* KUBERNETES DASHBOARD **************************
        kubectl apply -f *
        sleep 3
        kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard 9090:9090 &
        disown
        ;;
    2) # ****************************** CAMEL K ***********************************
        install_camelk
        ;;
    3) # ****************************** REDIS ******************************
        install_redis
        ;;
    4) # ****************************** LINKERD ******************************
        #create_namespace "linkerd" --> La instalacion del cliente por defecto crea el mismo el namespace linkerd
        install_linkerd
        ;;
    5) # ************************* KEYCLOAK ******************************
        install_keycloak
        ;;
    6) # ****************************** CONFLUENT ******************************
        install_confluent
        ;;
    7) # ********************************* KLAW ********************************
        install_klaw
        ;;
    8) # ******************************** KARAVAN ******************************
        install_karavan
        ;;
    9) # ******************************** SOLACE *******************************
        install_solace
        ;;
    10) # ******************************** N8N *********************************
        install_n8n
        ;;
    11) # ******************************* ISTIO ********************************
        #install_istio
        install_istio_with_helm
        ;;
    esac

}

function kube_delete() {
    TOOL=$1
    case "$TOOL" in
    0) # ************************* FREEE PLACE ******************************
        echo
        kubectl delete -f *
        ;;
    1) # ************************* KUBERNETES DASHBOARD **************************
        echo
        kubectl delete -f *
        ;;
    2) # ****************************** CAMEL K ***********************************
        uninstall_camelk
        ;;
    3) # ****************************** REDIS ******************************
        uninstall_redis
        ;;
    4)

        uninstall_emojivoto
        uninstall_linkerd_viz
        uninstall_linkerd

        # kubectl delete -f namespace.yml &>/dev/null
        echo
        ;;

    5)
        uninstall_keycloak
        ;;
    6)
        echo
        msg "Desinstalamos Confluent"
        uninstall_confluent
        ;;
    7)
        echo
        msg "Desinstalamos klaw"
        uninstall_klaw
        ;;
    8)
        echo
        msg "Desinstalamos Karavan"
        uninstall_karavan
        ;;
    9)
        echo
        msg "Desinstalamos Solace"
        uninstall_solace
        ;;
    10) # ******************************** N8N *******************************
        echo "n8n"
        uninstall_n8n
        ;;
    11) # ****************************** ISTIO *******************************
        echo "Istio"
        uninstall_istio
        ;;
    esac
}

function kube_check() {
    TOOL=$1
    VERBOSE=false

    for arg in "$@"; do
        if [ "$arg" == "-v" ]; then
            msg "VERBOSE mode enabled"
            VERBOSE=true
        fi
    done

    case "$TOOL" in
    0)
        kubectl ****
        ;;
    1)
        msg "Check Kubernetes Dashboard status"
        DASHBOARD_POD=$(kubectl get pods -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard -o jsonpath='{.items[0].metadata.name}')
        STATUS=$(kubectl get pod $DASHBOARD_POD -n kubernetes-dashboard -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Running" ]; then
            msg_check_success "POD Kubernetes Dashboard $DASHBOARD_POD Status: $STATUS"
        else
            msg_check_fail "POD Kubernetes Dashboard $DASHBOARD_POD Status: $STATUS"
        fi
        ;;
    2)
        NAMESPACE="camel-k"
        msg "Check Integration Platforms status"
        integration_platforms=$(kubectl get integrationplatforms -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
        for platform in $integration_platforms; do
            STATUS=$(kubectl get integrationplatform $platform -n $NAMESPACE -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Ready" ]; then
                msg_check_success "La plataforma de integracion $platform esta lista y en estado: $STATUS"
            else
                msg_check_fail "La plataforma de integracion $platform no esta lista. Estado actual: $STATUS"
            fi
        done

        msg "Check Integration Kits status"
        integration_kits=$(kubectl get ik -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
        for kit in $integration_kits; do
            STATUS=$(kubectl get integrationkit $kit -n $NAMESPACE -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Ready" ]; then
                msg_check_success "El Integrationkit $kit esta lista y en estado: $STATUS"
            fi
            if [ "$STATUS" == "Build Running" ]; then
                msg_info "El Integrationkit $kit esta en estado: $STATUS"
            fi
            if [ "$STATUS" == "Build Submitted" ]; then
                msg_info "El Integrationkit $kit esta en estado: $STATUS"
            fi
            if [ "$STATUS" == "Error" ]; then
                msg_check_fail "El Integrationkit $kit no esta lista. Estado actual: $STATUS"
                XERROR=$(kubectl get integrationkit $kit -n $NAMESPACE -o jsonpath='{.status.failure.reason}')
                msg_info_idented "$XERROR"
                msg_info_idented "Check error with this command: kubectl get integrationkit $kit -n $NAMESPACE -o json"

                if [[ $XERROR == *"$failure while building project"* ]]; then

                    CAMELOPERATOR=$(kubectl get pods | grep camel-k-operator | awk '{print $1}')
                    LOG=$(kubectl logs $CAMELOPERATOR | grep "camel-k.maven.build" | grep -A60 $kit | grep -m1 -A6 "BUILD FAILURE" | sed -E 's/(\\")//g' | tr -d '\n' | sed 's/\\//g') #  | jq 'del(.stacktrace)' | sed -E 's/(\\")//g' | sed 's/\\//g'  #| sed -E 's/("msg":")([^"]*)(")/\1\2\3/g'
                    if [ "$VERBOSE" = true ]; then
                        msg_info_idented "log info"
                        echo
                        echo "$LOG" | jq -r .msg
                    fi
                fi
            fi
        done

        msg "Check Integrations status"
        integrations=$(kubectl get integrations -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
        for int in $integrations; do
            STATUS=$(kubectl get integration $int -n $NAMESPACE -o jsonpath='{.status.phase}')
            if [ "$STATUS" == "Running" ]; then
                msg_check_success "La integracion $int esta lista y en estado: $STATUS"
            else
                if [ "$STATUS" == "Building Kit" ]; then
                    msg_info "Integracion $int en fase de construccion"
                fi
                if [ "$STATUS" == "Deploying" ]; then
                    msg_info "Integracion $int en fase de despliegue"
                fi
                if [ "$STATUS" == "Error" ]; then
                    msg_check_fail "La integracion $int ha fallado. Estado actual: $STATUS"
                    msg_info_idented "Checking conditions"
                    conditions=$(kubectl get integrations $int -n $NAMESPACE -o jsonpath='{.status.conditions}')

                    num_elements=$(echo "$conditions" | jq length)

                    for ((i = 1; i <= num_elements; i++)); do
                        condition=$(echo "$conditions" | jq ".[$i-1]")
                        status=$(echo "$condition" | jq -r '.status')
                        type=$(echo "$condition" | jq -r '.type')
                        message=$(echo "$condition" | jq -r '.message')

                        if [ "$status" == "True" ]; then
                            msg_check_success_idented "Condition $type OK"
                        else
                            msg_check_fail_idented "Condition $type KO $status $message"
                        fi

                    done
                fi
                if [ "$STATUS" != "Deploying" ] && [ "$STATUS" != "Error" ] && [ "$STATUS" != "Building Kit" ]; then
                    msg_info "Estado no analizado: $STATUS"
                fi
            fi
        done
        ;;
    esac
}


function apply_resources() {
    RESOURCES_FILE=$1
    msg "EXEC KUBECTL APPLY" "$RESOURCES_FILE"
    echo
    if [ "$VERBOSE" -eq 0 ]; then
        kubectl apply -f $RESOURCES_FILE &>/dev/null
    else
        kubectl apply -f $RESOURCES_FILE
    fi
}


function port_forward() {
    
    PORT_FORWARD=$1
    PORT=$2
    SERVICE=$3

    msg "PORT FORWARD SVC" "$SERVICE $PORT_FORWARD:$PORT"
    msg "Cheking port forward in use"
    PID_PORT=$(lsof -i :$PORT_FORWARD | awk '{print $2}' | tail -1)

    if [ "$VERBOSE" -eq 0 ]; then
        lsof -i tcp:$PORT_FORWARD &>/dev/null
    else
        lsof -i tcp:$PORT_FORWARD
    fi
    
    if [ $? -eq 0 ]; then
        msg_info "PID_PORT $PID_PORT de $SERVICE localizado, se procede a matarlo"
        kill -9 $PID_PORT
    else
        msg_warn "PID_PORT $PID_PORT de $PORT_FORWARD no existe, dashabord ya desconectado port forward"
    fi

    echo
    if [ "$VERBOSE" -eq 0 ]; then
        kubectl port-forward svc/$SERVICE $PORT_FORWARD:$PORT & disown &>/dev/null
    else
        kubectl port-forward svc/$SERVICE $PORT_FORWARD:$PORT & disown
    fi
}
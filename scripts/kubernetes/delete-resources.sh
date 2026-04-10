#!/bin/bash

# delete_resources
#   Elimina los recursos de Kubernetes asociados a un namespace.
#   Se cambia al namespace indicado y borra los CRDs relacionados, además de
#   todos los recursos namespaced disponibles. En caso de timeout, intenta
#   limpiar los finalizers y forzar el borrado de los recursos atascados.
#
#   Parámetros:
#     $1 - Namespace de Kubernetes a procesar.
#     $2 - Manifiestos YAML para eliminar.
#
#   Dependencias:
#     kubectl, funciones auxiliares msg_info, msg_warn_idented, spinner.
function delete_resources() {

    NAMESPACE=$1
    MANIFESTS=$2

    clear
    msg_task "Uninstalling $NAMESPACE resources"
    echo

    msg_info "Cambio a namespace $NAMESPACE "
    kubectl config set-context --current --namespace=$NAMESPACE  &>/dev/null

    msg_info "start delete $MANIFESTS"
    kubectl delete -f $MANIFESTS &>/dev/null & spinner  $! "Waiting delete manifest $MANIFESTS"
    echo
    msg_info "start delete custom resources definition (crds)"
    kubectl get crd -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep $NAMESPACE | xargs kubectl delete crd  &>/dev/null  & spinner  $! "Waiting delete crds"
    echo

    msg_info "Deleting resources for $NAMESPACE"
    kubectl api-resources --verbs=list --namespaced -o name | while read resource; do
        msg_info_idented "Eliminando $resource en $NAMESPACE"
        
        # Intentamos el borrado normal con un timeout corto
        if ! kubectl delete "$resource" -n "$NAMESPACE" --all --ignore-not-found --timeout=10s &>/dev/null; then
            
            # Si falla (posible timeout), buscamos los recursos que aún existen y forzamos los finalizers
            msg_warn_idented "Timeout en $resource. Forzando borrado vía finalizers..."
            
            # Obtenemos la lista de nombres de los recursos que se quedaron "colgados"
            STUCK_RESOURCES=$(kubectl get "$resource" -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
            
            for item in $STUCK_RESOURCES; do
                msg_warn_idented "  -> Parcheando finalizers de $item..."
                
                # Aplicamos el patch para limpiar finalizers
                kubectl patch "$resource" "$item" -n "$NAMESPACE" \
                    --type merge \
                    -p '{"metadata":{"finalizers":null}}' &>/dev/null
                    
                # Un último intento de borrado tras quitar finalizers
                kubectl delete "$resource" "$item" -n "$NAMESPACE" --grace-period=0 --force &>/dev/null
            done
        fi
    done


    if [ "$VERBOSE" -eq 1 ]; then
        msg "CLUSTER ROLES"
        kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" 
        kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete clusterrole

        msg "CLUSTER ROLE BINDINGS"
        kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete clusterrolebinding

        msg "ROLE BINDINGS"
        kubectl get rolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get rolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete rolebinding

        msg "CRON JOBS"
        kubectl get cj -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" 
        kubectl get cj -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete cj

        msg "SERVICE ACCOUNTS"
        kubectl get serviceaccounts -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get serviceaccounts -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete serviceaccounts

        msg "DEPLOYMENTS"
        kubectl get deployments -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get deployments -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete deployments

        msg "REPLICA SETS"
        kubectl get rs -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get rs -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete rs

        msg "CONFIG MAPS"
        kubectl get cm -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get cm -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete cm

        msg "SECRETS"
        kubectl get secrets -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get secrets -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete secrets

        msg "SERVICES"
        kubectl get svc -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get svc -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete svc

        msg "PODS"
        kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE"
        kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete pods

    else
        kubectl get clusterroles -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete clusterrole &>/dev/null
        kubectl get clusterrolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete clusterrolebinding &>/dev/null
        kubectl get rolebindings -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete rolebinding &>/dev/null
        kubectl get cj -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete cj &>/dev/null
        kubectl get serviceaccounts -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete serviceaccounts &>/dev/null
        kubectl get deployments -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete deployments &>/dev/null
        kubectl get rs -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete rs &>/dev/null
        kubectl get cm -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete cm &>/dev/null
        kubectl get secrets -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete secrets &>/dev/null
        kubectl get svc -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete svc &>/dev/null
        kubectl get pods -o=jsonpath='{range .items[*]}{@.metadata.name}{"\n"}{end}' | grep "^$NAMESPACE" | xargs kubectl delete pods &>/dev/null
    fi
}
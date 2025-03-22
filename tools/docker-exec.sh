

TARGET=$1
CONTAINER=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "$TARGET")
echo "Loading container $CONTAINER"

kubectl exec -it $CONTAINER bash
IP=$(netsh interface ip show config name="Wi-Fi" | findstr "IP Address" | awk '{print $3;}')

echo "local ip:" $IP

HAZELCAST_VERSION=5.2.1-slim
MANAGEMENT_CENTER_VERSION=5.2.0

function docker_stop() {
    IMAGE=$1
    docker stop $(docker ps -a | grep $IMAGE | awk '{print $1;}')
}
function docker_remove() {
    IMAGE=$1
    docker rm $(docker ps -a | grep $IMAGE | awk '{print $1;}')
}

docker_stop hazelcast1
docker_stop hazelcast2
docker_stop hazelcast-management-center
docker_remove hazelcast1
docker_remove hazelcast2
docker_remove hazelcast-management-center

docker run -m 512m -d --name="hazelcast1" -e HZ_NETWORK_PUBLICADDRESS=$IP:5701 -p 5701:5701 hazelcast/hazelcast:$HAZELCAST_VERSION
docker run -m 512m -d --name="hazelcast2" -e HZ_NETWORK_PUBLICADDRESS=$IP:5702 -p 5702:5701 hazelcast/hazelcast:$HAZELCAST_VERSION
docker run -m 512m -d --name="hazelcast3" -e HZ_NETWORK_PUBLICADDRESS=$IP:5703 -p 5703:5701 hazelcast/hazelcast:$HAZELCAST_VERSION
#-v PATH_TO_PERSISTENT_FOLDER:/data  --> volumen para persistir data en disco

docker run -d --name="hazelcast-management-center" \
    -e MC_ADMIN_USER=admin \
    -e MC_ADMIN_PASSWORD=mancenter1243 \
    -e MC_DEFAULT_CLUSTER_MEMBERS=$IP \
    -p 8083:8080 hazelcast/management-center:$MANAGEMENT_CENTER_VERSION


#-e MC_INIT_CMD="./mc-conf.sh cluster add -H=/data -ma $IP:5701 -cn dev" \
#
        #  --env MC_DEFAULT_CLUSTER=my-cluster \
        #  --env MC_DEFAULT_CLUSTER_MEMBERS=192.168.0.10,192.168.0.11 \
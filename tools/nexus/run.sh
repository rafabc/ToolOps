
docker build --rm=true --tag=sonatype/nexus3 .
docker run -d -p 8084:8081 --name nexus sonatype/nexus3
curl http://localhost:8084/


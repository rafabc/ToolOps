# Usa una imagen base de OpenJDK 17
FROM adoptopenjdk:17-jdk

# Usa una imagen base de OpenJDK
FROM openjdk:11-jdk

# Copia tu archivo YAML de definición de integración
COPY integration.yml /workspace/integration.yml

# Descarga el controlador JDBC de PostgreSQL
RUN wget -O /usr/local/lib/postgresql.jar https://jdbc.postgresql.org/download/postgresql-42.2.19.jar

RUN apt update

# Define el comando de inicio de la integración Camel-K
CMD ["kamel", "run", "--name", "integration-from-image", "--image", "host.docker.internal:5000/integration-from-image", "/workspace/integration.yml"]

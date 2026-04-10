# Guía Completa de Instalación de Solace con Event Management Agent

## Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Requisitos Previos](#requisitos-previos)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Instalación de Solace](#instalación-de-solace)
5. [Configuración del Event Management Agent](#configuración-del-event-management-agent)
6. [Integración con Solace Event Portal](#integración-con-solace-event-portal)
7. [Descubrimiento de Eventos](#descubrimiento-de-eventos)
8. [Verificación y Validación](#verificación-y-validación)
9. [Troubleshooting](#troubleshooting)
10. [Referencias](#referencias)

---

## Descripción General

### ¿Qué es Solace?

Solace es una plataforma de mensajería empresarial que proporciona capacidades de publicación-suscripción (Pub/Sub) en tiempo real, permitiendo la comunicación asíncrona entre aplicaciones, servicios y datos en ambientes distribuidos. Solace ofrece:

- **Mensajería confiable y de baja latencia**: Garantiza entrega de mensajes con mínimo retardo
- **Soporte para múltiples protocolos**: AMQP, MQTT, REST, WebSocket, JMS
- **Event Streaming**: Capacidades de procesamiento de eventos en tiempo real
- **Escalabilidad**: Desde arquitecturas simples hasta complejos sistemas distribuidos

### ¿Qué es el Event Management Agent?

El **Event Management Agent** es un servicio que actúa como intermediario entre Solace y el **Solace Event Portal**. Sus funciones principales incluyen:

- **Descubrimiento Automático de Eventos**: Escanea y detecta automáticamente los eventos disponibles en el broker Solace
- **Inventario Dinámico**: Mantiene un registro actualizado de todos los eventos, tópicos y conexiones
- **Mapeo de Dependencias**: Identifica las relaciones entre productores y consumidores de eventos
- **Sincronización con Event Portal**: Exporta el inventario de eventos hacia el Solace Event Portal para visualización y gestión centralizada

### Caso de Uso

Esta configuración es ideal para organizaciones que necesitan:

- Visibilidad completa de los eventos en sus brokers Solace
- Gestión centralizada de eventos a través del Event Portal
- Auditoría y gobernanza de arquitecturas event-driven
- Descubrimiento automático de APIs asincrónicas y esquemas de eventos

---

## Requisitos Previos

### Requisitos de Hardware

- **CPU**: Mínimo 2 cores, recomendado 4+ cores
- **Memoria RAM**: Mínimo 4 GB, recomendado 8+ GB
- **Almacenamiento**: Mínimo 20 GB disponibles
- **Red**: Conectividad de red estable, acceso a Internet para Event Portal Cloud

### Requisitos de Software

#### Kubernetes
- **Versión**: Kubernetes 1.20 o superior
- **Acceso**: Credenciales kubeconfig configuradas
- **Permisos**: Capacidad de crear namespaces y recursos (Deployments, Services, ConfigMaps)

```bash
# Verificar versión de Kubernetes
kubectl version --client

# Verificar acceso al cluster
kubectl cluster-info
```

#### Docker (opcional, para construcción local)
- **Versión**: Docker 20.10 o superior
- Se requiere si va a construir imágenes personalizadas

#### Herramientas CLI
- **kubectl**: Cliente de línea de comandos para Kubernetes (v1.20+)
- **helm**: Gestor de paquetes para Kubernetes (v3.0+) - opcional
- **bash**: Shell de línea de comandos

#### Credenciales de Solace
- **Cuenta en Solace Cloud** (si utiliza SolaceCloud)
  - URL del Event Portal
  - Organization ID
  - Runtime Agent ID
  - Gateway ID
  - Credenciales de usuario del gateway
- **Acceso a Solace Event Portal**: Para visualizar los eventos descubiertos

### Red y Conectividad

```bash
# Puertos requeridos (hacia Solace y Event Portal)
- Solace Broker: 8080 (HTTP), 55443 (SEMP over TLS)
- Event Portal Gateway: 55443 (TLS)
- Event Management Agent: 8180 (intra-cluster)
- Proxy (si es aplicable): 8443
- Generar certificado: openssl s_client -showcerts -connect prod-us-evmr.messaging.solace.cloud:55443 </dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /Volumes/PROJECTS/KYNDRYL/ToolOps/kubernetes/solace/solace_full_chain.crt

# Verificar conectividad
curl -v http://solace.solace.svc.cluster.local:8080
curl -v https://prod-us-evmr.messaging.solace.cloud:55443
```

---

## Arquitectura del Sistema

### Componentes Principales

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                      │
│                                                             │
│  ┌──────────────────────────┐    ┌──────────────────────┐   │
│  │  Solace Namespace        │    │  Event Management    │   │
│  │  ┌────────────────────┐  │    │  Agent               │   │
│  │  │ Solace Broker Pod  │  │    │ ┌──────────────────┐ │   │
│  │  │ - PubSubPlus       │◄─┼────┼─┤ EMA Service      │ │   │
│  │  │ - Port: 8080       │  │    │ │ Port: 8180       │ │   │
│  │  │ - SEMP API         │  │    │ │ H2 Database      │ │   │
│  │  └────────────────────┘  │    │ └──────────────────┘ │   │
│  │                          │    │                      │   │
│  │  ConfigMaps:             │    │  ConfigMap:          │   │
│  │  - ema-config            │    │  - ema-config        │   │
│  │  - solace-agent-certs    │    │  - solace-agent-     │   │
│  │                          │    │    certs             │   │
│  └──────────────────────────┘    └──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         │                                    │
         │                                    │
         ▼                                    ▼
   ┌──────────────────┐         ┌────────────────────────┐
   │ Solace Cloud     │         │ Event Portal Cloud     │
   │ (SEMP API)       │         │ (REST API)             │
   │                  │◄────────┤ Gateway at:            │
   │ prod-us-evmr     │ TCPS    │ tcps://prod-us-evmr... │
   │ Messaging        │ 55443   │                        │
   └──────────────────┘         └────────────────────────┘
```

### Flujo de Datos

1. **Descubrimiento** → Event Management Agent escanea Solace SEMP API
2. **Inventario** → Agent almacena eventos en base de datos H2
3. **Reporte** → Agent envía eventos descubiertos hacia Event Portal Gateway
4. **Visualización** → Event Portal muestra eventos en dashboard web

---

## Instalación de Solace

### Paso 1: Crear el Namespace

```bash
# Navegar al directorio de Solace
cd /Volumes/PROJECTS/KYNDRYL/ToolOps/kubernetes/solace

# Crear namespace de Solace
kubectl create namespace solace

# Verificar creación del namespace
kubectl get ns solace
```

### Paso 2: Desplegar Recursos de Solace

El despliegue se realiza a través del script `install.sh`:

```bash
# Hacer el script ejecutable
chmod +x install.sh

# Ejecutar la instalación desde el script principal de ToolOps
# O ejecutar directamente
./install.sh
```

#### Archivo `solace.yml` - Estructura y Componentes

El archivo `solace.yml` contiene toda la configuración necesaria:

**1. ConfigMap para Event Management Agent (`ema-config`)**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ema-config
  namespace: solace
data:
  ema.yml: |
    # Configuración de la aplicación Spring Boot
```

**2. ConfigMap para Certificados SSL (`solace-agent-certs`)**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: solace-agent-certs
  namespace: solace
data:
  solace.crt: |
    # Certificado SSL para TLS
```

### Paso 3: Verificar Despliegue de Solace

```bash
# Ver pods en ejecución
kubectl get pods -n solace
kubectl get pods -n solace -w  # Watch mode para monitoreo en tiempo real

# Ver logs de Solace
kubectl logs -n solace -l app=solace --tail=100
kubectl logs -n solace -l app=solace -f  # Follow mode

# Describir deployment de Solace
kubectl describe deployment solace -n solace
```

### Paso 4: Acceso al Solace Management Console

El script `install.sh` realiza port-forwarding automático:

```bash
# Puerto 8080: HTTP Management UI
http://localhost:8080

# Puerto 8008: SEMP API
http://localhost:8008

# Puerto 9000: Cliente AMQP
# Puerto 55555 (forwarded a 5555): Cliente MQTT

# Credenciales por defecto
usuario: admin
contraseña: admin
```

---

## Configuración del Event Management Agent

### Descripción de la Configuración

El Event Management Agent se configura mediante el ConfigMap `ema-config` en el archivo `solace.yml`. A continuación se detalla cada sección:

#### 1. Configuración de SpringDoc (OpenAPI)

```yaml
springdoc:
  packages-to-scan: com.solace.maas.ep.event.management.agent.scanManager.rest
  api-docs:
    path: /docs/event-management-agent
  swagger-ui:
    path: /event-management-agent/swagger-ui.html
```

**Propósito**: Expone la especificación OpenAPI (Swagger) del agent
- **Acceso**: `http://localhost:8180/event-management-agent/swagger-ui.html`
- **Documentación**: `http://localhost:8180/docs/event-management-agent`

#### 2. Configuración del Servidor

```yaml
server:
  port: 8180
```

El agent corre en puerto 8180 (interno al cluster). Desde fuera, es accesible vía port-forward o Ingress.

#### 3. Configuración de Spring Boot

```yaml
spring:
  servlet:
    multipart:
      max-file-size: ${MAX_FILE_SIZE:5MB}
      max-request-size: ${MAX_REQUEST_SIZE:5MB}
  datasource:
    url: jdbc:h2:file:./data/cache;DB_CLOSE_ON_EXIT=FALSE
    username: sa
    driver-class-name: org.h2.Driver
    password: 7mauFTCZJ3
  jpa:
    hibernate:
      ddl-auto: create-drop  # Recrear esquema en cada inicio
    defer-datasource-initialization: true
  main:
    allow-bean-definition-overriding: true
```

**Detalles**:
- **Base de datos**: H2 embebida (archivo en `/data/cache`)
- **Usuario BD**: `sa` (System Administrator)
- **Contraseña**: `7mauFTCZJ3`
- **Auto DDL**: `create-drop` significa que el esquema se crea y elimina en cada reinicio

#### 4. Configuración de Apache Camel

```yaml
camel:
  main:
    use-mdc-logging: true
```

Apache Camel es el motor de integración. MDC logging ayuda en el debug distribuido.

#### 5. Configuración de Kafka (Cliente)

```yaml
kafka:
  client:
    config:
      reconnections:
        max-backoff:
          value: 1000
          unit: milliseconds
        backoff:
          value: 50
          unit: milliseconds
      connections:
        max-idle:
          value: 10000
          unit: milliseconds
        request-timeout:
          value: 5000
          unit: milliseconds
        timeout:
          value: 60000
          unit: milliseconds
```

**Propósito**: Si el agent necesita integrarse con Kafka como parte de la arquitectura event-driven.

#### 6. Configuración de Event Portal (CRUCIAL)

```yaml
eventPortal:
  organizationId: ${EP_ORGANIZATION_ID:0o7cua87oz4}
  runtimeAgentId: ${EP_RUNTIME_AGENT_ID:aax11tpdxqr}
  gateway:
    id: g527g4hnak7
    name: US East EVMR
    messaging:
      standalone: false
      rtoSession: false
      enableHeartbeats: true
      testHeartbeats: true
      connections:
      - name: eventPortalGateway
        url: ${EP_GATEWAY_URL:tcps://prod-us-evmr.messaging.solace.cloud:55443}
        authenticationType: ${EP_GATEWAY_AUTH:basicAuthentication}
        msgVpn: ${EP_GATEWAY_MSGVPN:us-east-evmr}
        ssl:
          trustStore: /etc/ssl/certs/solace.crt
          trustStoreType: PEM
          validateCertificate: false
        users:
        - clientName: client_aax11tpdxqr
          username: ${EP_GATEWAY_USERNAME:org-0o7cua87oz4-b2dpd4apk26-aax11tpdxqr}
          password: B6zDufV5-JaBeZD^1vt8^bi}
          name: messaging1
        proxyEnabled: ${SOLACE_PROXY_ENABLED:false}
        proxyType: ${SOLACE_PROXY_TYPE:http}
        proxyHost: ${SOLACE_PROXY_HOST:localhost}
        proxyPort: ${SOLACE_PROXY_PORT:8443}
        proxyUsername: ${SOLACE_PROXY_USERNAME:}
        proxyPassword: ${SOLACE_PROXY_PASSWORD:}
      topicPrefix: ${EP_TOPIC_PREFIX:sc/ep/runtime}
```

**Parámetros Clave**:
- `organizationId`: ID único de la organización en Solace Cloud (obtener de Event Portal)
- `runtimeAgentId`: ID del agent en la organización
- `gateway.id`: Identificador del gateway en Event Portal
- `gateway.url`: Endpoint TCPS del Event Portal Cloud
- `msgVpn`: Virtual Private Network en el broker de evento
- `ssl.trustStore`: Ubicación del certificado SSL (montado como ConfigMap)
- `users.username`: Credencial para conectarse al gateway
- `users.password`: Contraseña de conexión (debe ser segura)
- `enableHeartbeats`: Mantener conexión activa con heartbeats
- `proxyEnabled`: Activar si hay proxy corporativo

#### 7. Configuración de Plugins - Conexión a Solace

```yaml
plugins:
  resources:
  - id: diw76klraeu
    type: solace
    name: SOL_BROKER
    connections:
    - name: SOL_BROKER
      url: http://solace.solace.svc.cluster.local:8080
      properties:
      - name: msgVpn
        value: default
      - name: sempPageSize
        value: 100
      authentication:
      - properties:
        - name: type
          value: basicAuthentication
        protocol: semp
        credentials:
        - source: ENVIRONMENT_VARIABLE
          operations:
          - name: ALL
          properties:
          - name: username
            value: admin
          - name: password
            value: admin
```

**Explicación**:
- `id: diw76klraeu`: Identificador único del plugin
- `type: solace`: Tipo de plugin (Solace broker)
- `name: SOL_BROKER`: Nombre del broker
- `url`: Dirección de Solace dentro del cluster Kubernetes
- `msgVpn: default`: Virtual Private Network por defecto
- `sempPageSize: 100`: Tamaño de página para API SEMP (número de elementos por página)
- `authentication.protocol: semp`: Protocolo SEMP (Solace Element Management Protocol)
- `credentials.source: ENVIRONMENT_VARIABLE`: Las credenciales provienen de variables de entorno

### Modificar Configuración

Para cambiar la configuración, edite el ConfigMap:

```bash
# Editar el ConfigMap
kubectl edit configmap ema-config -n solace

# O aplicar cambios desde archivo
kubectl apply -f solace.yml

# Después de cambios, reiniciar el pod del agent
kubectl rollout restart deployment solace-discovery-agent -n solace
```

---

## Integración con Solace Event Portal

### Requisitos en Solace Cloud

Antes de proceder, debe preparar su ambiente en Solace Cloud:

1. **Acceder a Solace Cloud**
   - URL: https://console.solace.cloud
   - Iniciar sesión con credenciales

2. **Crear Organización (si no existe)**
   - Dirigirse a "Organization" → "Settings"
   - Anotar `Organization ID`

3. **Registrar Runtime Agent**
   - Ir a "Agents" → "Runtime Agents"
   - Click en "Create Runtime Agent"
   - Anotar el `Runtime Agent ID`

4. **Configurar Gateway**
   - Ir a "Gateways" → "Event Portal Gateways"
   - Crear un nuevo gateway o usar uno existente
   - Anotar `Gateway ID` y `Gateway URL`
   - Crear usuario del gateway (obtener credenciales)

### Variables de Entorno Requeridas

Crear un archivo `.env` o establecer las variables en el Deployment de Kubernetes:

```bash
# Identifiers
EP_ORGANIZATION_ID=0o7cua87oz4
EP_RUNTIME_AGENT_ID=aax11tpdxqr
EP_GATEWAY_URL=tcps://prod-us-evmr.messaging.solace.cloud:55443
EP_GATEWAY_MSGVPN=us-east-evmr
EP_GATEWAY_USERNAME=org-0o7cua87oz4-b2dpd4apk26-aax11tpdxqr
EP_GATEWAY_PASSWORD=B6zDufV5-JaBeZD^1vt8^bi}
EP_GATEWAY_AUTH=basicAuthentication
EP_TOPIC_PREFIX=sc/ep/runtime

# Proxy (opcional)
SOLACE_PROXY_ENABLED=false
SOLACE_PROXY_TYPE=http
SOLACE_PROXY_HOST=proxy.empresa.com
SOLACE_PROXY_PORT=8443
SOLACE_PROXY_USERNAME=usuario
SOLACE_PROXY_PASSWORD=contraseña

# Tamaño de archivos
MAX_FILE_SIZE=10MB
MAX_REQUEST_SIZE=10MB
```

### Establecer Variables en Kubernetes

```bash
# Opción 1: Actualizar ConfigMap
kubectl set env configmap/ema-config \
  -n solace \
  EP_ORGANIZATION_ID=tu_org_id \
  EP_RUNTIME_AGENT_ID=tu_agent_id \
  EP_GATEWAY_URL=tcps://tu-gateway-url:55443 \
  ...

# Opción 2: Usar Secrets para datos sensibles
kubectl create secret generic ep-credentials \
  -n solace \
  --from-literal=username=tu_usuario \
  --from-literal=password=tu_contraseña

# Opción 3: Editar el ConfigMap directamente
kubectl edit configmap ema-config -n solace
```

---

## Descubrimiento de Eventos

### Cómo Funciona el Descubrimiento Automático

El Event Management Agent realiza un escaneo periódico de Solace para:

1. **Enumerar Topics**: Obtiene lista de todos los tópicos del broker
2. **Analizar Flujos**: Identifica productores y consumidores
3. **Extraer Metadatos**: Recopila información de eventos publicados
4. **Normalizar**: Convierte la información a un formato estándar
5. **Enviar a Event Portal**: Reporta el inventario hacia la nube

### Iniciar Descubrimiento Manual

```bash
# Acceder a Swagger UI del agent
kubectl port-forward svc/solace-discovery-agent 8180:8180 -n solace

# Visitar: http://localhost:8180/event-management-agent/swagger-ui.html

# Buscar endpoint de descubrimiento:
POST /agent/scan
GET /agent/scan/status
GET /agent/scan/results
```

### Respuesta Esperada

```json
{
  "scanId": "scan-123456789",
  "status": "IN_PROGRESS",
  "startTime": "2024-01-22T10:00:00Z",
  "topics": 42,
  "queues": 15,
  "clientProfiles": 8,
  "events": []
}
```

### Verificar Eventos Descubiertos

```bash
# Ver logs de descubrimiento
kubectl logs -n solace deployment/solace-discovery-agent -f

# Buscar en logs
kubectl logs -n solace deployment/solace-discovery-agent | grep -i "event\|discovery\|topic"

# Acceder a base de datos H2
kubectl port-forward svc/solace-discovery-agent 9090:9090 -n solace
# Visitar: http://localhost:9090/h2-console
# JDBC URL: jdbc:h2:file:./data/cache
# Usuario: sa
# Contraseña: 7mauFTCZJ3
```

### Visualizar en Event Portal

1. Acceder a **Solace Cloud Console**
2. Ir a **Event Portal** → **Events**
3. Los eventos descubiertos aparecerán bajo:
   - **Organization**: La que registró el agent
   - **Runtime**: Con el nombre del agent registrado
   - **Events Tab**: Listará todos los eventos y tópicos

---

## Verificación y Validación

### Checklist de Instalación

- [ ] Namespace `solace` creado correctamente
- [ ] Pod `solace` en estado `Running`
- [ ] Pod `solace-discovery-agent` en estado `Running`
- [ ] ConfigMaps montados correctamente
- [ ] Certificados SSL accesibles
- [ ] Port-forwarding funcionando
- [ ] Solace Management UI accesible (puerto 8080)
- [ ] Event Management Agent UI accesible (puerto 8180)
- [ ] Conectividad con Event Portal Gateway confirmada
- [ ] Eventos descubiertos en Event Portal

### Verificación de Conectividad

#### 1. Validar Acceso a Solace Broker

```bash
# Desde dentro del cluster
kubectl exec -it deployment/solace -n solace -- bash
curl -u admin:admin http://localhost:8080/api/v2/about

# Desde localhost (con port-forward)
kubectl port-forward svc/solace 8080:8080 -n solace
curl -u admin:admin http://localhost:8080/api/v2/about
```

#### 2. Validar Acceso a Event Portal Gateway

```bash
# Desde dentro del agent pod
kubectl exec -it deployment/solace-discovery-agent -n solace -- bash

# Test de conectividad TLS
curl -v --cacert /etc/ssl/certs/solace.crt \
  tcps://prod-us-evmr.messaging.solace.cloud:55443
```

#### 3. Verificar Base de Datos H2

```bash
# Crear acceso a consola H2
kubectl port-forward svc/solace-discovery-agent 9090:9090 -n solace

# Conectar desde navegador
# URL: http://localhost:9090/h2-console
# Driver: org.h2.Driver
# JDBC URL: jdbc:h2:file:./data/cache
# Usuario: sa
# Contraseña: 7mauFTCZJ3

# Ejecutar query de prueba
SELECT * FROM DISCOVERED_EVENTS LIMIT 10;
SELECT * FROM TOPICS LIMIT 10;
```

### Monitoreo de Logs

```bash
# Logs de Solace Broker
kubectl logs -n solace deployment/solace --tail=100 -f

# Logs de Event Management Agent
kubectl logs -n solace deployment/solace-discovery-agent --tail=100 -f

# Ver eventos con mayor contexto
kubectl logs -n solace deployment/solace-discovery-agent -f | grep -E "ERROR|WARN|discovered"

# Exportar logs a archivo
kubectl logs -n solace deployment/solace-discovery-agent > solace-agent.log
```

---

## Troubleshooting

### Problema: Pod de Solace no inicia

**Síntoma**: `kubectl get pods -n solace` muestra status `CrashLoopBackOff`

**Causas posibles**:
1. Insuficiente memoria en nodo
2. PersistentVolume no disponible
3. Problemas en la imagen base

**Solución**:
```bash
# Ver eventos del pod
kubectl describe pod solace-xxxxx -n solace

# Ver logs detallados
kubectl logs solace-xxxxx -n solace --previous

# Aumentar recursos
kubectl set resources deployment/solace -n solace \
  --limits=memory=8Gi,cpu=4 \
  --requests=memory=4Gi,cpu=2
```

### Problema: Event Management Agent no se conecta a Solace

**Síntoma**: Logs muestran `Connection refused` o `timeout`

**Causas posibles**:
1. Solace broker aún no está listo
2. Configuración de URL incorrecta
3. Credenciales inválidas

**Solución**:
```bash
# Verificar que Solace está running
kubectl get pods -n solace

# Probar conectividad
kubectl exec -it deployment/solace-discovery-agent -n solace -- bash
curl -u admin:admin http://solace.solace.svc.cluster.local:8080/api/v2/about

# Revisar configuración del plugin
kubectl get configmap ema-config -n solace -o yaml | grep -A 10 "plugins:"
```

### Problema: No hay eventos en Event Portal

**Síntoma**: Event Portal muestra "No events discovered"

**Causas posibles**:
1. Credenciales de Event Portal incorrectas
2. Runtime Agent ID no registrado
3. Descubrimiento no se ha ejecutado
4. Topicos no publicados correctamente

**Solución**:
```bash
# Validar credenciales en Event Portal
# Verificar Organization ID y Runtime Agent ID en Solace Cloud Console

# Forzar nuevo descubrimiento
kubectl exec -it deployment/solace-discovery-agent -n solace -- bash
curl -X POST http://localhost:8180/agent/scan

# Monitorear resultado
curl http://localhost:8180/agent/scan/results

# Ver logs de sincronización con Event Portal
kubectl logs -n solace deployment/solace-discovery-agent -f | grep -i "event\|portal\|gateway"
```

### Problema: Certificado SSL inválido

**Síntoma**: Errores de validación SSL, `CERTIFICATE_VERIFY_FAILED`

**Causas posibles**:
1. Certificado expirado
2. Certificado no montado correctamente
3. TrustStore no apunta al certificado correcto

**Solución**:
```bash
# Verificar certificado en ConfigMap
kubectl get configmap solace-agent-certs -n solace -o yaml

# Verificar que está montado correctamente
kubectl exec -it deployment/solace-discovery-agent -n solace -- ls -la /etc/ssl/certs/

# Ver fecha de expiración del certificado
kubectl exec -it deployment/solace-discovery-agent -n solace -- \
  openssl x509 -in /etc/ssl/certs/solace.crt -text -noout | grep "Not"

# Si el certificado está expirado, actualizar el ConfigMap
kubectl create configmap solace-agent-certs \
  --from-file=/ruta/al/nuevo/certificado.crt \
  -n solace --dry-run=client -o yaml | kubectl apply -f -
```

### Problema: Conexión intermitente con Event Portal

**Síntoma**: Logs muestran desconexiones periódicas, reconnection attempts

**Causas posibles**:
1. Problema de red intermitente
2. Timeout configurado muy bajo
3. Proxy corporativo interferiendo

**Solución**:
```bash
# Aumentar timeouts en configuración
kubectl edit configmap ema-config -n solace
# Aumentar:
# - request-timeout: 5000 → 10000
# - timeout: 60000 → 120000
# - max-backoff: 1000 → 5000

# Si hay proxy, configurar parámetros
proxyEnabled: true
proxyType: http
proxyHost: proxy.empresa.com
proxyPort: 8443

# Reiniciar agent
kubectl rollout restart deployment/solace-discovery-agent -n solace
```

### Problema: Insuficientes permisos para ejecutar comandos

**Síntoma**: `Error: deployments.apps is forbidden: User "system:serviceaccount:default:default" cannot create resource "deployments"`

**Solución**:
```bash
# Crear service account con permisos
kubectl create serviceaccount solace-admin -n solace

# Crear cluster role binding
kubectl create clusterrolebinding solace-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=solace:solace-admin

# Usar el service account
kubectl set serviceaccount deployment/solace solace-admin -n solace
```

### Acceso a métricas y debugging

```bash
# Obtener estado del cluster
kubectl top nodes
kubectl top pods -n solace

# Acceder a métricas específicas
kubectl get hpa -n solace  # Horizontal Pod Autoscaler
kubectl get pvc -n solace  # Persistent Volume Claims

# Debugging avanzado
kubectl debug pod/solace-xxxxx -n solace -it --image=ubuntu

# Obtener eventos del cluster relacionados con el namespace
kubectl get events -n solace --sort-by='.lastTimestamp'
```

---

## Mantenimiento y Operaciones

### Backups

```bash
# Backup de ConfigMaps
kubectl get configmap -n solace -o yaml > solace-configmaps-backup.yaml

# Backup de base de datos H2
kubectl exec deployment/solace-discovery-agent -n solace -- \
  tar czf /tmp/db-backup.tar.gz ./data/cache

kubectl cp solace/solace-discovery-agent-xxxxx:/tmp/db-backup.tar.gz ./db-backup.tar.gz
```

### Actualización de Configuración

```bash
# Sin downtime
kubectl patch configmap ema-config -n solace --type merge \
  -p '{"data":{"ema.yml":"[nueva configuración]"}}'

# Con rolling restart
kubectl rollout restart deployment/solace-discovery-agent -n solace
kubectl rollout status deployment/solace-discovery-agent -n solace
```

### Limpiar y Desinstalar

```bash
# Desinstalar (usar script si existe)
./uninstall.sh

# O manualmente
kubectl delete namespace solace

# Verificar eliminación
kubectl get ns solace
```

---

## Referencias

### Documentación Oficial
- [Solace PubSub+ Cloud](https://docs.solace.com/Cloud/)
- [Solace Event Portal](https://docs.solace.com/Solace-Cloud/Event-Portal/)
- [Event Management Agent Documentation](https://github.com/SolaceProducts/event-management-agent)
- [SEMP API Reference](https://docs.solace.com/API-Developer-Online-Ref-Documentation/swagger-ui.html)

### Protocolos Soportados
- **AMQP 1.0**: Advanced Message Queuing Protocol
- **MQTT 3.1.1 / 5.0**: Message Queuing Telemetry Transport
- **SMQP**: Solace Message Queue Protocol (protocolo propietario)
- **REST**: HTTP/HTTPS APIs
- **WebSocket**: Comunicación bidireccional web
- **JMS 1.1 / 2.0**: Java Message Service

### Puertos por Defecto

| Servicio | Puerto | Protocolo | Descripción |
|----------|--------|-----------|-------------|
| SMF | 55555 | TCP/TLS | Solace Message Format |
| SEMP | 8080 | HTTP | Solace Element Management Protocol |
| SEMP | 1443 | HTTPS | SEMP seguro |
| MQTT | 1883 | TCP | MQTT no seguro |
| MQTT | 8883 | TLS | MQTT seguro |
| AMQP | 5672 | TCP | AMQP no seguro |
| AMQP | 5671 | TLS | AMQP seguro |
| REST | 9000 | HTTP | REST API |
| REST | 1443 | HTTPS | REST seguro |
| Web UI | 8080 | HTTP | Management Console |
| Swagger | 8180 | HTTP | Event Agent Swagger UI |

### Conceptos Clave

**Topic**: Nombre jerárquico de un canal de mensajes
```
empresa/departamento/sistema/evento
ejemplo: finance/accounting/erp/invoice-created
```

**Queue**: Buffer de mensajes persistente para un consumidor

**Connection**: Enlace entre cliente y broker

**Client Profile**: Definición de permisos y capacidades de clientes

**Virtual Private Network (VPN)**: Partición lógica del broker con usuarios y ACLs independientes

**SEMP**: Protocolo para administración remota del broker

**Event Portal**: Catálogo centralizado de eventos y esquemas en la nube

---

## Apéndice: Comandos Útiles Rápidos

```bash
# ===== INFORMACIÓN =====
kubectl get all -n solace
kubectl get events -n solace --sort-by='.lastTimestamp'
kubectl get pv,pvc -n solace

# ===== LOGS Y DEBUG =====
kubectl logs -n solace -l app=solace -f --all-containers=true
kubectl logs -n solace deployment/solace-discovery-agent --all-containers=true
kubectl logs -n solace deployment/solace-discovery-agent -c solace-agent -f
kubectl tail solace/solace-discovery-agent  # si tiene plugin tail instalado

# ===== PORT-FORWARD =====
kubectl port-forward -n solace svc/solace 8080:8080
kubectl port-forward -n solace deployment/solace-discovery-agent 8180:8180

# ===== EXEC Y SHELL =====
kubectl exec -it deployment/solace -n solace -- bash
kubectl exec -it deployment/solace-discovery-agent -n solace -- sh

# ===== REINICIAR Y ROLLOUT =====
kubectl rollout restart deployment/solace -n solace
kubectl rollout status deployment/solace -n solace
kubectl rollout undo deployment/solace -n solace

# ===== ESCALAR Y RECURSOS =====
kubectl scale deployment solace --replicas=2 -n solace
kubectl set resources deployment solace --limits=memory=16Gi -n solace

# ===== CONFIGURACIÓN =====
kubectl get cm -n solace
kubectl describe cm ema-config -n solace
kubectl edit cm ema-config -n solace
kubectl apply -f solace.yml --record -n solace

# ===== LIMPIEZA =====
kubectl delete pod --field-selector=status.phase=Failed -n solace
kubectl delete pod --field-selector=status.phase=Succeeded -n solace
```

---

**Última actualización**: Enero 22, 2024  
**Versión**: 1.0  
**Autor**: Solace Event Management Team

---


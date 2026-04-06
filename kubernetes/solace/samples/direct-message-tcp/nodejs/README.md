# direct-topic-subscriber

Este directorio contiene dos ejemplos mínimos que muestran cómo conectar con un broker Solace
usando la librería `solclientjs`: un productor que publica un mensaje DIRECT (no garantizado)
y un consumidor que se suscribe a topics y procesa mensajes entrantes.

Este ejemplo NO usa colas → si el consumer no está conectado, el mensaje se pierde.

Este caso DIRECT MESSAGE no es posible visualizar los topics desde el Broker Manager
Solo se puede consultar información relacionada al trafico desde la sección de clientes

**Archivos**

+ `producer-topic-tcp-no-garanted.js`: Script productor. Establece una sesión TCP hacia el broker
  (`tcp://localhost:5555` por defecto), construye un mensaje con un payload JSON y lo envía al topic
  `orders/europe/spain/created` usando `MessageDeliveryModeType.DIRECT`. `DIRECT` indica entrega
  best-effort (sin persistencia ni ack). El script registra la conexión, envía el mensaje y captura
  errores de conexión.
- `consumer-topic-tcp.js`: Script consumidor. Crea una sesión, se suscribe al topic wildcard
  `orders/europe/spain/>`, y maneja eventos de suscripción y de llegada de mensajes. Cuando recibe
  un mensaje extrae el `BinaryAttachment` (o el `SdtContainer` si está presente) y lo imprime junto
  con el topic de destino. También maneja reconexiones simples y eventos de desconexión/errores.

  Qué hace este consumidor exactamente:
	-	✔ Se conecta por tcp
	-	✔ Se suscribe a un topic con wildcard -> "orders/europe/spain/>"
	-	✔ Consume mensajes direct
	-	❌ No hay persistencia
	-	❌ No hay ACK
	-	❌ No hay redelivery

  El consumidor al conectar usa dos subscripciones una implicita y otra explicita

  - Implicita: subscripción de sistema - automatica del cliente se usa para:
    - Controlde la sesión
    - Para eventos tipo SMF
    - Para mantener Keep Alive
  - Explicita: Es la que se crea al ejecutar la línea de código "session.subscribe(...)", si esta línea se elimina desde el broker manager seguira apareciendo una conexión


**Requisitos**

- Node.js instalado.
- Dependencia `solclientjs` en `package.json` (instálala con `npm install solclientjs`).
- Broker Solace accesible en la URL configurada (por defecto `tcp://localhost:5555`).

**Ejemplos de ejecución**

```bash
# Instalar dependencia (si no existe)
npm install solclientjs

# En una terminal: iniciar el consumidor
node consumer-topic-tcp.js

# En otra terminal: ejecutar el productor (envía un único mensaje)
node producer-topic-tcp-no-garanted.js
```


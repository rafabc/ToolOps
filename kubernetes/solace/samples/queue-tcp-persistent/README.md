# queue-garanted

Carpeta con ejemplos de productor/consumidor usando colas durables en Solace (entrega garantizada).

Descripción general

Estos scripts muestran cómo enviar mensajes persistentes a una cola durable (`Q.INPUT`) y cómo
consumirlos con confirmación manual (client ACK). A diferencia de los ejemplos por topic,
aquí se usa una cola durable que garantiza la entrega y permite que el broker mantenga mensajes
hasta que un consumidor los procese y confirme.

#### IMPORTANTE --> Si la cola no existe el script la crea via SEMP API

Archivos

- `producer-queue.js`
  - Crea una sesión TCP contra el broker (por defecto `tcp://localhost:5555`) y, al conectarse,
    envía hasta 90 mensajes a la cola durable `Q.INPUT` con `MessageDeliveryModeType.PERSISTENT`.
  - Cada mensaje incluye un `BinaryAttachment` con texto simple: `Mensaje número N`.
  - Envía un mensaje cada 500 ms; al terminar desconecta la sesión.
  - Maneja eventos: `REJECTED_MESSAGE_ERROR`, `CONNECT_FAILED_ERROR` y `DISCONNECTED`.
  - Usa `clientName: 'producer-queue-nodejs'` y reintentos de conexión configurados.

- `consumer-queue.js`
  - Crea una sesión y, al conectarse, crea un `MessageConsumer` sobre la cola durable `Q.INPUT`.
  - El consumidor usa `MessageConsumerAcknowledgeMode.CLIENT`, por lo que el handler debe llamar
    a `message.acknowledge()` después de procesar el mensaje (esto implementa la confirmación
    manual para garantizar que el broker no elimine el mensaje hasta que sea ACKed).
  - Extrae el payload con `message.getBinaryAttachment().toString()` y lo imprime, luego envía el ACK.
  - Maneja el evento `CONNECT_FAILED_ERROR` e imprime cuando se conecta correctamente.

Requisitos

- Node.js instalado.
- `solclientjs` disponible en el proyecto (`npm install solclientjs`).
- Broker Solace que tenga definida la cola durable `Q.INPUT` y permisos del usuario para enviar/consumir.

Ejecución

1. Instalar la dependencia si hace falta:

```bash
npm install solclientjs
```

2. En una terminal arrancar el consumidor:

```bash
node consumer-queue.js
```

3. En otra terminal ejecutar el productor (envía hasta 90 mensajes):

```bash
node producer-queue.js
```

Consideraciones y buenas prácticas

- Delivery Mode: `PERSISTENT` + cola durable garantiza que los mensajes sobreviven a reinicios
  del broker y se entregan de forma fiable; sin embargo esto requiere configuración de la cola
  y recursos en el broker.
- Acknowledge: usar `CLIENT` acknowledge da control al consumidor para confirmar mensajes
  después de procesarlos. Si el consumidor falla sin enviar el ACK, el broker podrá redeliver.
- Gestión de errores: `producer-queue.js` captura excepciones en `session.send` y escucha
  `REJECTED_MESSAGE_ERROR`; en producción conviene implementar reintentos y backoff.
- Clean shutdown: el productor espera 1s tras finalizar envíos antes de `session.disconnect()` para
  dar tiempo a que los mensajes salgan. En consumidores más complejos considera `consumer.stop()` y
  `session.disconnect()` ordenados.
- Seguridad/configuración: no expongas credenciales en claro; parametriza URL, VPN, usuario y
  contraseña por variables de entorno o un archivo de configuración.

Posibles mejoras

- Añadir variables de entorno para `url`, `vpnName`, `userName`, `password` y `queueName`.
- Añadir parsing JSON en payloads y `contentType` en los mensajes (`application/json`).
- Añadir tests simples o un `package.json` con scripts `start:producer` y `start:consumer`.

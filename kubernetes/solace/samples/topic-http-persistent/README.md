# producer-topic-http (HTTP persistent topic producer)

Este script envía mensajes a un topic de Solace usando la API HTTP de publicación.
Es un productor simple que publica una serie de mensajes con delivery mode `persistent`,
lo que solicita al broker que trate los mensajes como garantizados (persistidos según la
configuración del broker/cola/replicación).

Importante

- Solace no permite el consumo directo por http en modo pulling, es decir no se puede lanzar un get para recuperar un mensaje
- Para leer mensajes por http Solace implementa RDP (Rest Delivery Point) que hace push a un endpoint 

Resumen del comportamiento

- Envía `NUM_MESSAGES` mensajes (por defecto 20) al topic definido en la constante `topic`.
- Publica usando peticiones HTTP POST a la URL construida como `http://<host>:<port>/topic/<topic>`.
- Cada petición incluye cabeceras Solace específicas para indicar modo de entrega y metadatos,
  y autenticación Basic HTTP con `username`/`password` embebidos en la variable `auth`.
- Hay un retardo `DELAY_MS` (por defecto 200 ms) entre envíos.
- El script imprime por consola el status HTTP de cada publicación y finalmente termina el
  proceso con `process.exit(0)`.

Variables clave en el script

- `NUM_MESSAGES`: número total de mensajes a enviar.
- `DELAY_MS`: milisegundos de espera entre mensajes.
- `host`, `port`, `topic`: destino del publisher; la URL final es `http://host:port/topic/topic`.
- `username`, `password`: credenciales usadas para autenticación Basic.
- `auth`: cabecera `Authorization: Basic <base64>` calculada a partir de `username:password`.

Encabezados HTTP usados en la publicación

- `Content-Type: text/plain`: indica el tipo de contenido enviado en el body.
- `Solace-Delivery-Mode: persistent`: instruye al endpoint de Solace a tratar el mensaje como
  persistente (garantizado) en la medida de la configuración del broker.
- `Solace-Message-Type: text` y `Solace-Client-Name`: metadatos adicionales para el broker.
- `Authorization: Basic <...>`: autenticación HTTP básica.
- `Content-Length`: longitud del body en bytes (se calcula con `Buffer.byteLength`).

Funcionamiento interno

- `postMessage(index)`: construye el body como `Mensaje ${index + 1}` y realiza un `fetch`
  `POST` a la URL con las cabeceras indicadas. Retorna el `response.status`.
- `run()`: itera desde 0 hasta `NUM_MESSAGES - 1`, llama a `postMessage` esperando su resultado,
  muestra el estado y duerme `DELAY_MS` entre envíos. Captura errores de conexión y, en el
  bloque `finally`, llama a `process.exit(0)` para terminar el proceso.

Requisitos y licencia de runtime

- Node.js con soporte global para `fetch` (Node 18+). Si usas una versión anterior, instala y
  usa `node-fetch` o un cliente HTTP equivalente.
- Acceso a un endpoint de Solace HTTP Pub/Sub configurado en `host:port` y con el topic disponible.

Ejemplo de ejecución

```bash
# Ejecutar directamente
node producer-topic-http.js

# Modificar parámetros en el archivo (host/port/topic) o adaptar el script para leer variables
# de entorno y luego ejecutar.
```



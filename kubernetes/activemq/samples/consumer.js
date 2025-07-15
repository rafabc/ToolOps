const rhea = require('rhea');

// Configuración de conexión al broker
const connectionOptions = {
  host: 'localhost',      // Cambia si estás usando Amazon MQ o Docker
  port: 5672,             // Puerto AMQP estándar de Artemis
  username: 'artemis',      // Credenciales del broker
  password: 'artemis'
};

// Nombre de la address o queue a consumir
const queueName = 'XP';  // Debe existir en el broker (ANYCAST o MULTICAST)

const connection = rhea.connect(connectionOptions);

// Abrir un receptor para la queue deseada
connection.open_receiver(queueName);

// Evento al recibir un mensaje
connection.on('message', function (context) {
  const msg = context.message;
  console.log('Mensaje recibido:');
  console.log(JSON.stringify(msg.body, null, 2));
  
  // Confirmar recepción si es necesario (ack implícito por defecto en AMQP 1.0)
  context.delivery.accept();
});

// Manejo de errores
connection.on('receiver_error', function (context) {
  console.error('❌ Error en el receptor:', context.receiver.error);
});

connection.on('connection_error', function (context) {
  console.error('❌ Error de conexión:', context.connection.error);
});

connection.on('disconnected', function () {
  console.log('🔌 Conexión cerrada');
});
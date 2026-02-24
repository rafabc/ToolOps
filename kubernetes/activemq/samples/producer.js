const rhea = require('rhea');

const connectionOptions = {
  host: 'localhost',         // Dirección del broker
  port: 5672,                // Puerto AMQP de Artemis
  username: 'artemis',         // Usuario Artemis
  password: 'artemis',         // Contraseña Artemis
};

const queueName = 'XP'; // Nombre de la cola o topic

const connection = rhea.connect(connectionOptions);

connection.open_sender(queueName);

connection.on('sendable', function (context) {
  const message = {
    body: {
      nombre: 'mensaje de prueba',
      timestamp: new Date().toISOString(),
    },
    group_id: "grupoA"
  };

  console.log(`➡️  Enviando mensaje a ${queueName}`);
  context.sender.send(message);
  connection.close();
});

connection.on('accepted', function (context) {
  console.log('✅ Mensaje aceptado por el broker');
});

connection.on('rejected', function (context) {
  console.error('❌ Mensaje rechazado');
});

connection.on('connection_error', function (context) {
  console.error('❌ Error en la conexión', context.connection.get_error());
});

connection.on('disconnected', function () {
  console.log('🔌 Conexión cerrada');
});
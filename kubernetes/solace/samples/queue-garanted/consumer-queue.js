const solace = require('solclientjs');

const queueName = 'Q.INPUT';

solace.SolclientFactory.init({
  profile: solace.SolclientFactoryProfiles.version10,
});

const session = solace.SolclientFactory.createSession({
  url: 'tcp://localhost:5555',
  vpnName: 'default',
  userName: 'admin',
  password: 'admin',
  clientName: 'consumer-queue-nodejs',
});

session.on(solace.SessionEventCode.UP_NOTICE, () => {
  console.log('✅ Conectado al broker');

  const queue = solace.SolclientFactory.createDurableQueueDestination(queueName);

  const consumer = session.createMessageConsumer({
    queueDescriptor: queue,
    acknowledgeMode: solace.MessageConsumerAcknowledgeMode.CLIENT,
  });

  // ✅ ÚNICO evento obligatorio
  consumer.on(solace.MessageConsumerEventName.MESSAGE, (message) => {
    const payload = message.getBinaryAttachment()?.toString();
    console.log(`← Mensaje recibido: ${payload}`);

    message.acknowledge();
    console.log('✔️ ACK');
  });

  consumer.start();
});

session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, (err) => {
  console.error('❌ Error de sesión:', err);
});

session.connect();
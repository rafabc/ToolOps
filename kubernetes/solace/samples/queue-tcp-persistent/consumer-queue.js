const solace = require('solclientjs');

const queueName = 'Q.INPUT';

solace.SolclientFactory.init({
    profile: solace.SolclientFactoryProfiles.version10,
});

const session = solace.SolclientFactory.createSession({
    url: 'tcp://localhost:5555',
    vpnName: 'default',
    userName: 'default',
    password: 'default',
    clientName: 'consumer-queue-nodejs',
});

session.on(solace.SessionEventCode.UP_NOTICE, () => {
    console.log('✅ Conectado al broker');

    const queue = solace.SolclientFactory.createDurableQueueDestination(queueName);

    const consumer = session.createMessageConsumer({
        queueDescriptor: queue,
        acknowledgeMode: solace.MessageConsumerAcknowledgeMode.CLIENT,
    });

    // ESCUCHA ERRORES ESPECÍFICOS DEL CONSUMIDOR
    consumer.on(solace.MessageConsumerEventName.CONNECT_FAILED_ERROR, (error) => {
        console.error('❌ El consumidor no pudo conectarse a la cola:', error.toString());
    });

    // consumer.on(solace.MessageConsumerEventName.UP_NOTICE, () => {
    //     console.log('🚀 Consumidor está listo y escuchando la cola');
    // });

    // ✅ ÚNICO listener soportado
    consumer.on(solace.MessageConsumerEventName.MESSAGE, (message) => {
        console.log('← Mensaje recibido:', message.getBinaryAttachment()?.toString());
        message.acknowledge();
    });

    consumer.connect();
});

session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, (err) => {
    console.error('❌ Error de sesión:', err);
});

session.connect();
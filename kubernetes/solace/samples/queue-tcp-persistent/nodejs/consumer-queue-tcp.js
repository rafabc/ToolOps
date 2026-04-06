const solace = require('solclientjs');

const queueName = 'Q.INPUT';

solace.SolclientFactory.init({
    profile: solace.SolclientFactoryProfiles.version10,
});


const SOLACE_URL = process.env.SOLACE_URL || 'tcp://localhost:5555';

const session = solace.SolclientFactory.createSession({
    url: SOLACE_URL,
    vpnName: 'default',
    userName: 'admin',
    password: 'admin',
    clientName: 'consumer-queue-garanted-tcp-smf',
    transportProperties: {
        noDelay: true // Deshabilita el algoritmo de Nagle para enviar paquetes lo antes posible
    }
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



    // ÚNICO listener soportado
    consumer.on(solace.MessageConsumerEventName.MESSAGE, (message) => {

        const ahora = new Date();

        // Formato de hora completa con milisegundos
        const horaLog = ahora.toLocaleTimeString('es-ES', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            fractionalSecondDigits: 3,
            hour12: false
        });

        console.log(`[${horaLog}] 📨 Mensaje recibido ID: ${message.getApplicationMessageId()} - Contenido: ${message.getBinaryAttachment()?.toString()}`);
        message.acknowledge();
    });

    consumer.connect();
});

session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, (err) => {
    console.error('❌ Error de sesión:', err);
});

session.connect();
const solace = require('solclientjs');

// Configuración básica
const config = {
    url: 'tcp://localhost:5555',        // ej: wss://mr-xyz.messaging.solace.cloud:443
    vpnName: 'default',
    userName: "admin",
    password: "admin",
    reconnectRetries: 3,
    clientName: 'consumer-orders-nodejs'
};

solace.SolclientFactory.init({
    profile: solace.SolclientFactoryProfiles.version10
});

const session = solace.SolclientFactory.createSession(config);

// Eventos de sesión
session.on(solace.SessionEventCode.UP_NOTICE, () => {
    console.log('✅ Conectado a Solace (Consumer)');

    // Suscripción a topic
    session.subscribe(
        solace.SolclientFactory.createTopic('orders/europe/spain/>'),
        true,   // subscribe
        true,   // await confirmation
        10000
    );
});

session.on(solace.SessionEventCode.SUBSCRIPTION_OK, (event) => {
    console.log('📡 Suscrito correctamente:', event.correlationKey);
});

session.on(solace.SessionEventCode.MESSAGE, (message) => {
    const payload = message.getBinaryAttachment()
        ? message.getBinaryAttachment().toString()
        : message.getSdtContainer()?.getValue();

    console.log('📨 Mensaje recibido');
    console.log('Topic:', message.getDestination().getName());
    console.log('Payload:', payload);
});

// Manejo de errores
session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, err => {
    console.error('❌ Error de conexión:', err);
});

session.on(solace.SessionEventCode.DISCONNECTED, () => {
    console.log('🔌 Desconectado');
});

// Conectar
session.connect();
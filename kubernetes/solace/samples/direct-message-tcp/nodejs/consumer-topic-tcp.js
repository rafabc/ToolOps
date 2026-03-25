const solace = require('solclientjs');


solace.SolclientFactory.init({
    profile: solace.SolclientFactoryProfiles.version10
});


// Definimos la URL: Prioridad a la variable de entorno, si no existe, usa localhost
const SOLACE_URL = process.env.SOLACE_URL || 'tcp://localhost:5555';

const session = solace.SolclientFactory.createSession({
    url: SOLACE_URL,
    vpnName: 'default',
    userName: process.env.BROKER_USER || 'admin',
    password: process.env.BROKER_PASSWORD || 'admin',
    clientName: 'consumer-direct-message-tcp-smf-nodejs'
});





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

    const ahora = new Date();
    const horaLog = ahora.toLocaleTimeString('es-ES', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        fractionalSecondDigits: 3,
        hour12: false
    });

    console.log(`[${horaLog}] 📨 Mensaje recibido ID: ${message.getApplicationMessageId()} - Contenido: ${message.getBinaryAttachment()?.toString()}`);
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
const solace = require('solclientjs');

// Configuración
const host = 'ws://localhost:8008'; // O el puerto que tengas configurado para Web Messaging
const vpn = 'default';
const username = 'admin';
const password = 'admin';
const topicName = 'ws/orders/created';
const NUM_MESSAGES = 50;

// Inicializar la factoría de Solace
const factoryProps = new solace.SolclientFactoryProperties();
factoryProps.profile = solace.SolclientFactoryProfiles.version10;
solace.SolclientFactory.init(factoryProps);

async function run() {
    const session = solace.SolclientFactory.createSession({
        url: host,
        vpnName: vpn,
        userName: username,
        password: password,
    });

    // Promesa para manejar la conexión
    const connect = () => new Promise((resolve, reject) => {
        session.on(solace.SessionEventCode.UP_NOTICE, resolve);
        session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, reject);
        session.connect();
    });

    try {
        console.log(`🚀 Conectando a Solace en ${host}...`);
        await connect();
        console.log('✅ Sesión conectada.');

        const topic = solace.SolclientFactory.createTopicDestination(topicName);

        for (let i = 1; i <= NUM_MESSAGES; i++) {
            const messageText = `Orden #${i} creada a las ${new Date().toISOString()}`;
            const msg = solace.SolclientFactory.createMessage();
            
            msg.setDestination(topic);
            msg.setBinaryAttachment(messageText);
            msg.setDeliveryMode(solace.MessageDeliveryModeType.PERSISTENT);

            session.send(msg);
            console.log(`→ Mensaje ${i} enviado al topic: ${topicName}`);

            // Pequeña pausa opcional
            await new Promise(r => setTimeout(r, 50));
        }

        console.log('🏁 Todos los mensajes han sido enviados.');
        
        // Esperar un momento para asegurar que el buffer de red se vacíe
        setTimeout(() => {
            session.disconnect();
            console.log('👋 Desconectado. Proceso finalizado.');
            process.exit(0);
        }, 1000);

    } catch (error) {
        console.error('❌ Error en la sesión:', error.toString());
        process.exit(1);
    }
}

run();
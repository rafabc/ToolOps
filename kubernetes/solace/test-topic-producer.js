const solace = require('solclientjs');

const topicName = 'my/topic/http'; // nombre del topic
const vpnName = 'default';
const username = 'test';
const password = 'test';
const hostUrl = 'ws://localhost:8008';

solace.SolclientFactory.init({
  profile: solace.SolclientFactoryProfiles.version10,
});

console.log('Funciones disponibles en SolclientFactory:', Object.keys(solace.SolclientFactory));

const session = solace.SolclientFactory.createSession({
  url: hostUrl,
  vpnName: vpnName,
  userName: username,
  password: password,
  connectRetries: 3,
  reconnectRetries: 3,
});

session.on(solace.SessionEventCode.UP_NOTICE, () => {
  console.log('✅ Conectado al broker Solace');

  const dest = solace.SolclientFactory.createTopicDestination(topicName);

  let count = 0;
  const maxMessages = 30;

  const intervalId = setInterval(() => {
    if (count >= maxMessages) {
      clearInterval(intervalId);
      // Espera un poco para asegurar envío antes de desconectar
      setTimeout(() => {
        session.disconnect();
      }, 1000);
      return;
    }

    const message = solace.SolclientFactory.createMessage();
    message.setDestination(dest);
    message.setDeliveryMode(solace.MessageDeliveryModeType.DIRECT); // para topic normalmente DIRECT
    message.setBinaryAttachment(`Mensaje número ${count + 1}`);

    try {
      session.send(message);
      console.log(`→ Mensaje ${count + 1} enviado al topic ${topicName}`);
      count++;
    } catch (e) {
      console.error('Error enviando mensaje:', e);
    }
  }, 500); // 500 ms entre envíos
});

session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, () => {
  console.error('❌ Error al conectar con el broker Solace.');
});

session.on(solace.SessionEventCode.DISCONNECTED, () => {
  console.log('🔌 Sesión desconectada.');
});

session.connect();
const solace = require('solclientjs');

const queueName = 'Q.INPUT';


solace.SolclientFactory.init({
	profile: solace.SolclientFactoryProfiles.version10,
});

console.log('Funciones disponibles en SolclientFactory:', Object.keys(solace.SolclientFactory));

const session = solace.SolclientFactory.createSession({
	url: 'tcp://localhost:5555',
	vpnName: 'default',
	userName: 'admin',
	password: 'admin',
	connectRetries: 3,
	reconnectRetries: 3,
	clientName: 'producer-queue-nodejs',
});

session.on(solace.SessionEventCode.UP_NOTICE, () => {
	console.log('✅ Conectado al broker Solace');

	const dest = solace.SolclientFactory.createDurableQueueDestination(queueName);

	let count = 0;
	const maxMessages = 90;

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
		message.setDeliveryMode(solace.MessageDeliveryModeType.PERSISTENT);
		message.setBinaryAttachment(`Mensaje número ${count + 1}`);

		try {
			session.send(message);
			console.log(`→ Mensaje ${count + 1} enviado a ${queueName}`);
			count++;
		} catch (e) {
			console.error('Error enviando mensaje:', e);
		}
	}, 500); // 500 ms entre envíos
});

session.on(solace.SessionEventCode.REJECTED_MESSAGE_ERROR, (event) => {
  console.error('❌ Mensaje rechazado por el broker', event);
});

session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, () => {
	console.error('❌ Error al conectar con el broker Solace.');
});

session.on(solace.SessionEventCode.DISCONNECTED, () => {
	console.log('🔌 Sesión desconectada.');
});

session.connect();
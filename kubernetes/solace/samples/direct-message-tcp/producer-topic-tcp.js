/**
This script initializes the Solace JavaScript client, creates a session to a broker, and publishes a single non‑persistent (direct) message to a topic. 
At the top the SolclientFactory is initialized with profile version10 — this is required once before using the API. Then a session object is created 
with connection parameters (TCP URL, VPN, username, password).
Event handlers are attached to the session. On UP_NOTICE the code logs a successful connection, builds a message via SolclientFactory.createMessage(), 
sets its destination to the topic 'orders/europe/spain/created', attaches a JSON payload as a binary Buffer, marks the message delivery mode 
as DIRECT (non‑guaranteed, no persistence/ack), sends the message with session.send(msg), and logs that the message was sent. A separate handler 
logs connection failures on CONNECT_FAILED_ERROR. Finally session.connect() starts the connection handshake.
Gotchas and small notes: init() must be called before creating sessions; DIRECT delivery means best‑effort (no guarantee) so use PERSISTENT if you need guaranteed delivery. 
Building payloads with Buffer.from(JSON.stringify(...)) is fine but consider setting a content-type header or using application-level framing if consumers expect typed messages. 
Also consider adding handlers for DISCONNECTED, SUBSCRIPTION_ERROR or API_ERROR, and explicitly disconnecting the session when work is done to free resources.
Suggested minimal improvements: add error handling around session.send (or check returned status), call session.disconnect() after send if this is a one‑shot producer, 
and set message properties (e.g., contentType) so consumers can parse the payload reliably.
 */


const solace = require('solclientjs');
const { setTimeout } = require('node:timers/promises');

// OBLIGATORIO
solace.SolclientFactory.init({
	profile: solace.SolclientFactoryProfiles.version10
});

const session = solace.SolclientFactory.createSession({
	url: 'tcp://localhost:5555',
	vpnName: 'default',
	userName: 'admin',
	password: 'admin',
	clientName: 'producer-orders-nodejs'
});

const TOTAL_MESSAGES = 200000;

session.on(solace.SessionEventCode.UP_NOTICE, async () => {
	console.log('✅ Conectado a Solace (producer)');

	console.log(`Enviando ${TOTAL_MESSAGES} mensajes a topic 'orders/europe/spain/created'...`);
	console.time('Timpo total envío');

	for (let index = 0; index < TOTAL_MESSAGES; index++) {

		const msg = solace.SolclientFactory.createMessage();
		msg.setDestination(
			solace.SolclientFactory.createTopic('orders/europe/spain/created')
		);

		msg.setBinaryAttachment(Buffer.from(JSON.stringify({
			orderId: index,
			status: 'CREATED'
		})));

		msg.setDeliveryMode(solace.MessageDeliveryModeType.DIRECT);

		session.send(msg);
		//console.log(`🚀 Mensaje ${index} enviado`);
		if (index % 500 === 0) {
			await setTimeout(1); // Un pequeño respiro cada 500 mensajes
		}
	}
	console.timeEnd('Timpo total envío');
	session.disconnect();
	return;

});

// session.on(solace.SessionEventCode.BUFFER_RELEASED, () => {
// 	console.log('🔄 Buffer liberado, listo para enviar más mensajes')
// });


session.on(solace.SessionEventCode.DISCONNECTED, () => {
	console.log('🔌 Producer desconectado');
	process.exit(0);
});

session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, err => {
	console.error('❌ Error conexión producer:', err);
	process.exit(1);
});

session.connect();
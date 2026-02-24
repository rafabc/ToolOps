const solace = require('solclientjs');
const http = require('http');
const https = require('https');

/* ==========================
   CONFIGURACIÓN
   ========================== */

const SEMP_CONFIG = {
	host: 'localhost',
	port: 8088,
	vpn: 'default',
	username: 'admin',
	password: 'admin',
	useHttps: false
};

const queueName = 'Q.INPUT';

/* ==========================
   SEMP: asegurar existencia de cola
   ========================== */

function ensureQueueExists(queueName, config) {

	console.log('🔧 Asegurando existencia de la cola mediante SEMP...');

	const protocol = config.useHttps ? https : http;
	const authHeader = 'Basic ' + Buffer.from(
		`${config.username}:${config.password}`
	).toString('base64');

	const basePath = `/SEMP/v2/config/msgVpns/${encodeURIComponent(config.vpn)}/queues`;

	return new Promise((resolve, reject) => {

		const encodedQueueName = encodeURIComponent(queueName);

		/* -------- 1️⃣ GET: comprobar si existe -------- */

		const getOptions = {
			host: config.host,
			port: config.port,
			path: `${basePath}/${encodedQueueName}`,
			method: 'GET',
			headers: {
				'Authorization': authHeader,
				'Accept': 'application/json'
			}
		};

		const getReq = protocol.request(getOptions, res => {
			let body = '';

			res.on('data', chunk => body += chunk);
			res.on('end', () => {

				// ✅ Cola existe
				if (res.statusCode === 200) {
					console.log(`✅ La cola "${queueName}" ya existe`);
					resolve({ created: false });
					return;
				}

				// ⚠️ SEMP v2: 400 + error.code = 6 => NO EXISTE
				if (res.statusCode === 400) {
					try {
						const parsed = JSON.parse(body);
						if (parsed?.meta?.error?.code === 6) {
							console.log(`⚠️ La cola "${queueName}" no existe, creando...`);
							createQueue();
							return;
						}
					} catch (e) {
						reject(new Error('❌ Error parseando respuesta SEMP'));
						return;
					}
				}

				reject(new Error(`❌ Error comprobando cola: HTTP ${res.statusCode}`));
			});
		});

		getReq.on('error', reject);
		getReq.end();

		/* -------- 2️⃣ POST: crear cola -------- */
		function createQueue() {
			const body = JSON.stringify({
				queueName: queueName,
				accessType: "exclusive",
				maxMsgSpoolUsage: 100,
				permission: "modify-topic",
				ingressEnabled: true,
				egressEnabled: true
			});

			const postOptions = {
				host: config.host,
				port: config.port,
				path: basePath,
				method: 'POST',
				headers: {
					'Authorization': authHeader,
					'Accept': 'application/json',
					'Content-Type': 'application/json',
					'Content-Length': Buffer.byteLength(body)
				}
			};

			const postReq = protocol.request(postOptions, postRes => {
				let postBody = '';
				postRes.on('data', chunk => postBody += chunk);
				postRes.on('end', () => {
					if (postRes.statusCode === 201 || postRes.statusCode === 200) {
						console.log(`🎉 Cola "${queueName}" creada correctamente`);
						resolve({ created: true });
					} else {
						reject(new Error(`❌ Error creando cola: HTTP ${postRes.statusCode} - ${postBody}`));
					}
				});
			});

			postReq.on('error', reject);
			postReq.write(body); // <-- Antes decía postData
			postReq.end();       // <-- Antes decía req.end()
		}


	});
}

/* ==========================
   SOLACE CLIENT
   ========================== */

solace.SolclientFactory.init({
	profile: solace.SolclientFactoryProfiles.version10,
});

const session = solace.SolclientFactory.createSession({
	url: 'tcp://localhost:5555',
	vpnName: 'default',
	userName: 'admin',
	password: 'admin',
	connectRetries: 3,
	reconnectRetries: 3,
	clientName: 'producer-queue-nodejs',
	publisherProperties: {
		acknowledgeMode: solace.MessagePublisherAcknowledgeMode.PER_MESSAGE,
	},
});

let count = 0;

session.on(solace.SessionEventCode.UP_NOTICE, () => {
	console.log('✅ Conectado al broker Solace');

	const dest = solace.SolclientFactory.createDurableQueueDestination(queueName);

	const maxMessages = 90;

	const intervalId = setInterval(() => {
		if (count >= maxMessages) {
			clearInterval(intervalId);
			setTimeout(() => session.disconnect(), 1000);
			return;
		}

		const message = solace.SolclientFactory.createMessage();
		message.setDestination(dest);
		message.setDeliveryMode(
			solace.MessageDeliveryModeType.PERSISTENT
		);
		message.setBinaryAttachment(`Mensaje número ${count + 1}`);
		message.setCorrelationKey(`${count + 1}`);

		try {
			session.send(message);
			console.log(`→ Mensaje ${count + 1} enviado a ${queueName}`);
			count++;
		} catch (e) {
			console.error('❌ Error enviando mensaje:', e);
		}
	}, 500);
});

session.on(
	solace.SessionEventCode.ACKNOWLEDGED_MESSAGE,
	event => console.log(
		'✔ ACK recibido. CorrelationKey:',
		event.correlationKey
	)
);

session.on(
	solace.SessionEventCode.REJECTED_MESSAGE_ERROR,
	event => console.error('❌ Mensaje rechazado', event)
);

session.on(
	solace.SessionEventCode.CONNECT_FAILED_ERROR,
	() => console.error('❌ Error al conectar con Solace')
);

session.on(
	solace.SessionEventCode.DISCONNECTED,
	() => console.log('🔌 Sesión desconectada')
);

/* ==========================
   MAIN
   ========================== */

(async () => {
	try {
		const result = await ensureQueueExists(queueName, SEMP_CONFIG);
		if (result.created) {
			console.log('⏳ Esperando sincronización del Broker...');
			await new Promise(r => setTimeout(r, 2000)); // 2 segundos de respiro
		}
		console.log('🚀 Cola asegurada, conectando productor...');
		session.connect();
	} catch (err) {
		console.error("Fallo crítico:", err.message);
	}
})();
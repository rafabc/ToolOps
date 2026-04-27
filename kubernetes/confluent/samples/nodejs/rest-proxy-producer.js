const http = require('http'); // Cambia a 'https' si tu proxy usa SSL

// --- CONFIGURACIÓN ---
const CONFIG = {
	host: 'localhost',
	port: 8082,
	topic: 'orders-topic',
	rps: 30,
	durationSeconds: 60,
	contentType: 'application/vnd.kafka.json.v2+json'
};

const totalRequests = CONFIG.rps * CONFIG.durationSeconds;
let sentRequests = 0;
let completedRequests = 0;

// Cuerpo del mensaje para el REST Proxy de Confluent
const getPayload = (id) => JSON.stringify({
	records: [{ value: { id, timestamp: Date.now(), msg: "Hola Confluent" } }]
});

const sendRequest = (id) => {
	const data = getPayload(id);

	const options = {
		hostname: CONFIG.host,
		port: CONFIG.port,
		path: `/topics/${CONFIG.topic}`,
		method: 'POST',
		headers: {
			'Content-Type': CONFIG.contentType,
			'Content-Length': data.length
		}
	};

	const req = http.request(options, (res) => {
		res.on('data', () => { }); // Consumir respuesta
		res.on('end', () => {
			completedRequests++;
		});
	});

	req.on('error', (e) => console.error(`Error en req ${id}: ${e.message}`));
	req.write(data);
	req.end();
};

// --- LÓGICA DE CONTROL ---
console.log(`Iniciando envío: ${CONFIG.rps} RPS durante ${CONFIG.durationSeconds}s...`);

const startTime = Date.now();

const interval = setInterval(() => {
	// Enviamos una ráfaga para mantener el promedio de RPS
	for (let i = 0; i < CONFIG.rps; i++) {
		if (sentRequests < totalRequests) {
			sentRequests++;
			sendRequest(sentRequests);
		} else {
			clearInterval(interval);
			break;
		}
	}

	if (sentRequests >= totalRequests) {
		const totalTime = (Date.now() - startTime) / 1000;
		console.log(`\nFinalizado envío de ${sentRequests} peticiones en ${totalTime.toFixed(2)}s.`);
	}
}, 1000); // Se ejecuta cada segundo enviando la ráfaga de 30

// Reporte de progreso cada 5 segundos
setInterval(() => {
	if (completedRequests < totalRequests) {
		console.log(`Progreso: ${completedRequests}/${totalRequests} peticiones completadas...`);
	}
}, 5000).unref();
const solace = require('solclientjs'); // Asegúrate de usar 'solclientjs' si es tu alias
const http = require('http');
const https = require('https');
const { setTimeout } = require('node:timers/promises');

/* ==========================
   CONFIGURACIÓN Y MEMORIA
   ========================== */
// Usamos un Map para que cada mensaje "recuerde" su propia hora de salida
const seguimientoMensajes = new Map();

const queueName = 'Q.INPUT';


const SEMP_HOST = process.env.SEMP_URL || 'localhost';
const SEMP_PORT = process.env.SEMP_PORT || 8088;

const SEMP_CONFIG = {
    host: SEMP_HOST,
    port: SEMP_PORT,
    vpn: 'default',
    username: process.env.SEMP_USER ||'admin',
    password: process.env.SEMP_PASSWORD ||'admin',
    useHttps: false
};

/* ==========================
   SOLACE CLIENT INIT
   ========================== */
solace.SolclientFactory.init({
    profile: solace.SolclientFactoryProfiles.version10,
});

const SOLACE_URL = process.env.SOLACE_URL || 'tcp://localhost:5555';
const session = solace.SolclientFactory.createSession({
    url: SOLACE_URL,
    vpnName: 'default',
    userName: process.env.BROKER_USER ||'admin',
    password: process.env.BROKER_PASSWORD ||'admin',
    connectRetries: 3,
    reconnectRetries: 3,
    clientName: 'producer-queue-garanted-tcp-smf',
    publisherProperties: {
        acknowledgeMode: solace.MessagePublisherAcknowledgeMode.PER_MESSAGE,
		adWindowSize: 1 // <--- Solo 1 mensaje en vuelo a la vez
    },
	transportProperties: {
        noDelay: true // Deshabilita el algoritmo de Nagle para enviar paquetes lo antes posible
    }
});

/* ==========================
   SEMP: ASEGURAR COLA
   ========================== */
function ensureQueueExists(queueName, config) {
    console.log('🔧 Verificando cola mediante SEMP...');
    const protocol = config.useHttps ? https : http;
    const authHeader = 'Basic ' + Buffer.from(`${config.username}:${config.password}`).toString('base64');
    const basePath = `/SEMP/v2/config/msgVpns/${encodeURIComponent(config.vpn)}/queues`;

    return new Promise((resolve, reject) => {
        const encodedQueueName = encodeURIComponent(queueName);
        const getOptions = {
            host: config.host, port: config.port,
            path: `${basePath}/${encodedQueueName}`,
            method: 'GET',
            headers: { 'Authorization': authHeader, 'Accept': 'application/json' }
        };

        const getReq = protocol.request(getOptions, res => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    console.log(`✅ La cola "${queueName}" ya existe`);
                    resolve({ created: false });
                } else if (res.statusCode === 400 || res.statusCode === 404) {
                    createQueue();
                } else {
                    reject(new Error(`❌ Error SEMP: ${res.statusCode}`));
                }
            });
        });

        function createQueue() {
            const body = JSON.stringify({
                queueName: queueName,
                accessType: "exclusive",
                maxMsgSpoolUsage: 100,
                ingressEnabled: true,
                egressEnabled: true
            });
            const postOptions = {
                host: config.host, port: config.port, path: basePath, method: 'POST',
                headers: {
                    'Authorization': authHeader, 'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(body)
                }
            };
            const postReq = protocol.request(postOptions, postRes => {
                postRes.on('end', () => resolve({ created: true }));
            });
            postReq.write(body);
            postReq.end();
        }
        getReq.on('error', reject);
        getReq.end();
    });
}

/* ==========================
   LÓGICA DE ENVÍO
   ========================== */
let count = 1;

session.on(solace.SessionEventCode.UP_NOTICE, () => {
    console.log('✅ Conectado al broker Solace');
    const dest = solace.SolclientFactory.createDurableQueueDestination(queueName);
    const maxMessages = 90000;

    const intervalId = setInterval(() => {
        if (count >= maxMessages) {
            clearInterval(intervalId);
            setTimeout(1000).then(() => session.disconnect());
            return;
        }

        const id = `${count}`;
        const message = solace.SolclientFactory.createMessage();
        message.setDestination(dest);
        message.setDeliveryMode(solace.MessageDeliveryModeType.PERSISTENT);
        message.setCorrelationKey(id);
        message.setApplicationMessageId(id);

        try {
            // CAPTURA DE TIEMPOS ÚNICA PARA ESTE MENSAJE
            const tInicio = performance.now();
            const hInicio = new Date().toLocaleTimeString('es-ES', {
                hour: '2-digit', minute: '2-digit', second: '2-digit',
                fractionalSecondDigits: 3, hour12: false
            });

            // Guardamos en el Map usando el ID como clave
            seguimientoMensajes.set(id, { tInicio, hInicio });

            message.setBinaryAttachment(`Msg ${id} - Enviado: ${hInicio}`);
            session.send(message);
            count++;
        } catch (e) {
            console.error('❌ Error enviando:', e);
        }
    }, 50);
});

/* ==========================
   EVENTO ACK (CORREGIDO)
   ========================== */
session.on(solace.SessionEventCode.ACKNOWLEDGED_MESSAGE, async (event) => {
    // 1. Capturamos el momento exacto de la recepción (Fin)
    const tFin = performance.now();
    const hLog = new Date().toLocaleTimeString('es-ES', {
        hour: '2-digit', minute: '2-digit', second: '2-digit',
        fractionalSecondDigits: 3, hour12: false
    });

    // 2. Recuperamos los datos que guardamos al enviar ESTE id específico
    const meta = seguimientoMensajes.get(event.correlationKey);

    if (meta) {
        const latencia = (tFin - meta.tInicio).toFixed(2);
        console.log(`[${hLog}] ✔ ACK OK. ID: ${event.correlationKey} | Envío Real: ${meta.hInicio} | Latencia: ${latencia} ms`);
        seguimientoMensajes.delete(event.correlationKey);
    }
});

/* ==========================
   GESTIÓN DE ERRORES Y ARRANQUE
   ========================== */
session.on(solace.SessionEventCode.REJECTED_MESSAGE_ERROR, e => console.error('❌ Rechazado', e));
session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, () => console.error('❌ Error de conexión'));
session.on(solace.SessionEventCode.DISCONNECTED, () => console.log('🔌 Desconectado'));

(async () => {
    try {
        await ensureQueueExists(queueName, SEMP_CONFIG);
        console.log('🚀 Iniciando sesión...');
        session.connect();
    } catch (err) {
        console.error("Fallo crítico: " + err.message);
        console.log(err);
    }
})();
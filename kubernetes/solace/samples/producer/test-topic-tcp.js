const http = require('http');
const solace = require('solclientjs').debug;

// CONFIGURACIÓN
const config = {
    solaceHost: "localhost",
    solacePort: 8080,
    vpnName: "default",
    userName: "admin",
    password: "admin",
    queueName: "Q.XAMPLE.TEST.TCP",
    topicName: "mi/app/evento/test",
    smfURL: "tcp://localhost:5555"
};

// Función auxiliar HTTP POST
function httpPost(path, body) {
    return new Promise((resolve, reject) => {
        const auth = Buffer.from(`${config.userName}:${config.password}`).toString('base64');
        const options = {
            hostname: config.solaceHost,
            port: config.solacePort,
            path: path,
            method: 'POST',
            headers: {
                'Authorization': `Basic ${auth}`,
                'Content-Type': 'application/json'
            }
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(data);
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });

        req.on('error', reject);
        req.write(JSON.stringify(body));
        req.end();
    });
}

// Función auxiliar HTTP GET
function httpGet(path) {
    return new Promise((resolve, reject) => {
        const auth = Buffer.from(`${config.userName}:${config.password}`).toString('base64');
        const options = {
            hostname: config.solaceHost,
            port: config.solacePort,
            path: path,
            method: 'GET',
            headers: {
                'Authorization': `Basic ${auth}`,
                'Accept': 'application/json'
            }
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(JSON.parse(data));
                } else if (res.statusCode === 404) {
                    resolve(null); // no existe
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });

        req.on('error', reject);
        req.end();
    });
}

// Crear queue solo si no existe
async function createQueueIfNotExist() {
    const pathGet = `/SEMP/v2/config/msgVpns/${config.vpnName}/queues/${config.queueName}`;
    console.log(`[SEMP] Verificando si la queue ${config.queueName} existe...`);
    try {
        const existingQueue = await httpGet(pathGet);
        if (existingQueue) {
            console.log(`[SEMP] La queue ${config.queueName} ya existe`);
            return;
        }
    } catch (error) {
        console.error(`[SEMP] Error al verificar la queue: ${error.message}`);
    }

    const pathPost = `/SEMP/v2/config/msgVpns/${config.vpnName}/queues`;
    const body = {
        queueName: config.queueName,
        permission: "consume",
        ingressEnabled: true,
        egressEnabled: true
    };
    console.log(`[SEMP] Creando la queue ${config.queueName}...`);
    await httpPost(pathPost, body);
    console.log(`[SEMP] Queue ${config.queueName} creada`);
}

// Añadir suscripción de Topic solo si no existe
async function addSubscriptionIfNotExist() {
    const pathGetSubs = `/SEMP/v2/config/msgVpns/${config.vpnName}/queues/${config.queueName}/subscriptions`;
    const existingSubs = await httpGet(pathGetSubs);

    const topicAlreadySubscribed = existingSubs?.data?.some(sub => sub.subscriptionTopic === config.topicName);
    if (topicAlreadySubscribed) {
        console.log(`[SEMP] La suscripción al topic ${config.topicName} ya existe`);
        return;
    }

    const pathPost = `/SEMP/v2/config/msgVpns/${config.vpnName}/queues/${config.queueName}/subscriptions`;
    const body = {
        subscriptionTopic: config.topicName
    };
    await httpPost(pathPost, body);
    console.log(`[SEMP] Suscripción al topic ${config.topicName} añadida`);
}

// Conectar cliente Solace y producir 10 mensajes
function connectSolace() {
    solace.SolclientFactory.init();

    const session = solace.SolclientFactory.createSession({
        url: config.smfURL,
        vpnName: config.vpnName,
        userName: config.userName,
        password: config.password
    });

    session.on(solace.SessionEventCode.UP_NOTICE, () => {
        console.log("[Solace] Conectado");

        // Producción de 10 mensajes
        const topic = solace.SolclientFactory.createTopic(config.topicName);
        for (let i = 1; i <= 10; i++) {
            const message = solace.SolclientFactory.createMessage();
            message.setDestination(topic);
            message.setBinaryAttachment(Buffer.from(`Mensaje ${i}`));
            message.setDeliveryMode(solace.MessageDeliveryModeType.DIRECT);

            // Asignar partition key
            // Usando ApplicationMessageId para simular partition key
            message.setApplicationMessageId(`pk-${i}`);
            session.send(message);
            console.log(`[Producer] Mensaje ${i} enviado con partition key pk-${i}`);
        }
    });

    session.on(solace.SessionEventCode.DISCONNECTED, () => {
        console.log("[Solace] Desconectado");
    });

    session.connect();
}

// Ejecutar todo
async function run() {
    try {
        await createQueueIfNotExist();
        await addSubscriptionIfNotExist();
        connectSolace();
    } catch (err) {
        console.error("Error:", err.message);
    }
}

run();
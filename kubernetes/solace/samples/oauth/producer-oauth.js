const http = require('http');
const solace = require('solclientjs').debug;

// CONFIGURACIÓN
const config = {
    solaceHost: "localhost",
    solacePort: 8088,
    vpnName: "default",
    userName: "admin",       
    password: "admin",
    queueName: "Q.INPUT2",
    topicName: "mi/app/evento/test",
    smfURL: "tcp://localhost:5555",
    

    keycloakHost: "localhost",
    keycloakPort: 8765,
    realm: "master",
    clientId: "solace-broker",
    clientSecret: "S5S3ypuZA9BVmtjxtzYmirvJg5CEQipw"
};



function getAccessToken() {
    return new Promise((resolve, reject) => {
        const payload = new URLSearchParams({
            grant_type: 'client_credentials',
            client_id: config.clientId,
            client_secret: config.clientSecret
        }).toString();

        const options = {
            hostname: config.keycloakHost,
            port: config.keycloakPort,
            path: `/realms/${config.realm}/protocol/openid-connect/token`,
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(payload)
            }
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    const json = JSON.parse(data);
                    resolve(json.access_token);
                } else {
                    reject(new Error(`Error obteniendo token de Keycloak: HTTP ${res.statusCode} - ${data}`));
                }
            });
        });

        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}

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

function httpGet(path) {
    return new Promise((resolve, reject) => {
        const auth = Buffer.from(`${config.userName}:${config.password}`).toString('base64');
        const options = {
            hostname: config.solaceHost,
            port: config.solacePort,
            path: path,
            method: 'GET',
            headers: {
                'Authorization': `Basic ${auth}`
            }
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    console.log(`✅ GET 200 en ${path}`);
                    resolve(JSON.parse(data)); // Parseado directamente a JSON para evaluar la respuesta
                } else if (res.statusCode === 404) {
                    console.warn(`⚠️  QUEUE O SUSCRIPCIÓN NO EXISTE: ${path}`);   
                    resolve(null);
                } else {
                    console.error(`Error HTTP ${res.statusCode} en ${path}: ${data}`);
                    reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                }
            });
        });

        req.on('error', reject);
        req.end();
    });
}

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

/**
 * Conectar cliente Solace utilizando el Token JWT de Keycloak
 */
function connectSolace(jwtToken) {
    solace.SolclientFactory.init();

    const session = solace.SolclientFactory.createSession({
        url: config.smfURL,
        vpnName: config.vpnName,
        authenticationScheme: solace.AuthenticationScheme.OAUTH2,
        accessToken: jwtToken,
        allowInsecureWwAuthWithNonSecureTransport: true
    });

    session.on(solace.SessionEventCode.UP_NOTICE, () => {
        console.log("[Solace] Conectado exitosamente usando JWT de Keycloak");

        const topic = solace.SolclientFactory.createTopic(config.topicName);
        for (let i = 1; i <= 10; i++) {
            const message = solace.SolclientFactory.createMessage();
            message.setDestination(topic);
            message.setBinaryAttachment(Buffer.from(`Mensaje ${i}`));
            message.setDeliveryMode(solace.MessageDeliveryModeType.DIRECT);

            message.setApplicationMessageId(`pk-${i}`);
            session.send(message);
            console.log(`[Producer] Mensaje ${i} enviado con partition key pk-${i}`);
        }
    });

    session.on(solace.SessionEventCode.DISCONNECTED, () => {
        console.log("[Solace] Desconectado");
    });
    
    session.on(solace.SessionEventCode.LOGIN_FAILURE, (sessionEvent) => {
        console.error("[Solace] Error de autenticación (JWT inválido o rechazado):", sessionEvent.toString());
    });

    session.connect();
}

// Ejecutar todo
async function run() {
    try {
        // 1. Validar e infraestructura vía SEMP (Basic Auth)
        await createQueueIfNotExist();
        await addSubscriptionIfNotExist();
        
        // 2. Obtener el Token dinámico de Keycloak
        console.log("[Keycloak] Solicitando token de acceso...");
        const jwtToken = await getAccessToken();
        console.log("[Keycloak] Token obtenido correctamente");

        // 3. Conectar cliente de mensajería (OAuth2 JWT)
        connectSolace(jwtToken);
    } catch (err) {
        console.error("Error general en la ejecución:", err.message);
    }
}

run();
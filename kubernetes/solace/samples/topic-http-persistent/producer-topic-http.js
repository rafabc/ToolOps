const NUM_MESSAGES = 20;
const DELAY_MS = 200;
const host = 'localhost';
const port = 9000;
const topic = 'demo/http';
const url = `http://${host}:${port}/topic/${topic}`;

const username = 'admin';
const password = 'admin';
const auth = Buffer.from(`${username}:${password}`).toString('base64');

// Función para pausar la ejecución
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function postMessage(index) {
    const body = `Mensaje ${index + 1}`;

    // Aquí guardamos el resultado directamente en una variable
    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'text/plain',
            'Solace-Delivery-Mode': 'persistent',
			'Solace-Message-Type': 'text',
			'Solace-Client-Name': 'producer-http-persistent',
            'Authorization': `Basic ${auth}`,
			'Content-Length': Buffer.byteLength(body).toString()
        },
        body: body
    });

    // Retornamos el status para usarlo en la función principal
    return response.status;
}

async function run() {
    try {
        for (let i = 0; i < NUM_MESSAGES; i++) {
            // Recibimos el resultado en una variable
            const status = await postMessage(i);
            
            console.log(`→ Mensaje ${i + 1} enviado. Status: ${status}`);

            if (i < NUM_MESSAGES - 1) {
                await sleep(DELAY_MS);
            }
        }
        console.log('✅ Proceso terminado.');
    } catch (error) {
        console.error('❌ Error de conexión:', error.message);
    } finally {
        // Esto libera la terminal inmediatamente
        process.exit(0);
    }
}

run();
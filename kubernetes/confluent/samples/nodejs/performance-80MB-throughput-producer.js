const { Kafka, ErrorCodes } = require('kafkajs');

// --- CONFIGURACIÓN ---
const TOPIC = 'test_throughput';
const MESSAGE_SIZE = 83886080; // 80MB
const DURATION = 60;           // 1 minuto en segundos

const kafka = new Kafka({
    clientId: 'throughput-tester',
    brokers: ['localhost:9092'], // Ajusta a tus brokers
    /* 
       Ajustes de reintentos y timeouts pesados para evitar que el cliente 
       desconecte si el broker tarda en procesar el bloque de 80MB
    */
    connectionTimeout: 10000,
    requestTimeout: 60000,
});

// --- MÉTRICAS ---
const latencies = [];

// Helper para calcular percentiles (reemplazo de numpy.percentile)
function getPercentile(arr, percentile) {
    if (arr.length === 0) return 0;
    const sorted = [...arr].sort((a, b) => a - b);
    const index = (percentile / 100) * (sorted.length - 1);
    const lower = Math.floor(index);
    const upper = Math.ceil(index);
    const weight = index - lower;
    if (upper >= sorted.length) return sorted[lower];
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
}

const formatNum = (num) => num.toLocaleString('en-US', { maximumFractionDigits: 2 });

async function runTest() {
    // Inicializar el productor
    const producer = kafka.producer({
        // Forzamos a que no intente agrupar lotes internos en JS duro
        maxInFlightRequests: 1
    });

    await producer.connect();

    console.log("Generando payload de 80MB en memoria...");
    const payload = Buffer.alloc(MESSAGE_SIZE, 'x');

    console.log(`--- Iniciando test (Duración: ${DURATION}s) ---`);
    console.log(`Enviando mensajes de ${formatNum(MESSAGE_SIZE / (1024 * 1024))} MB con kafkajs...`);

    const startTest = Date.now();
    const endTest = startTest + (DURATION * 1000);
    let aborted = false;

    // Capturar cierre controlado para desconectar el productor limpiamente
    const handleShutdown = async () => {
        if (aborted) return;
        aborted = true;
        console.log("\nPrueba finalizada. Desconectando productor...");
        await producer.disconnect();
        printReport(startTest);
        process.exit(0);
    };

    process.on('SIGINT', handleShutdown);
    process.on('SIGTERM', handleShutdown);

    try {
        // En kafkajs dependemos de un control asíncrono secuencial
        while (Date.now() < endTest && !aborted) {
            const startTime = Date.now();

            // Enviar el mensaje masivo de forma asíncrona pero secuencial
            await producer.send({
                topic: TOPIC,
                messages: [
                    { value: payload }
                ],
            });

            // Si llegó aquí, el broker confirmó la recepción (Equivalente al delivery_report)
            const latency = Date.now() - startTime;
            latencies.push(latency);
        }

        // Si el tiempo se cumple de forma natural
        await handleShutdown();

    } catch (err) {
        console.error(`\nError crítico durante el envío: ${err.message}`);
        await producer.disconnect();
    }
}

function printReport(startTest) {
    const totalTime = (Date.now() - startTest) / 1000;

    // --- CÁLCULO DE RESULTADOS ---
    if (latencies.length > 0) {
        const avgThroughput = latencies.length / totalTime;
        const avgLatency = latencies.reduce((a, b) => a + b, 0) / latencies.length;
        const p95Latency = getPercentile(latencies, 95);

        console.log("\n" + "=".repeat(40));
        console.log("         INFORME DE RENDIMIENTO (kafkajs)");
        console.log("=".repeat(40));
        console.log(`Mensajes confirmados: ${formatNum(latencies.length)}`);
        console.log(`Tiempo total:         ${totalTime.toFixed(2)} s`);
        console.log("-".repeat(40));
        console.log(`Throughput Medio:     ${avgThroughput.toFixed(2)} msg/s`);
        console.log(`Throughput MB/s:      ${((latencies.length * MESSAGE_SIZE) / (1024 * 1024) / totalTime).toFixed(2)} MB/s`);
        console.log("-".repeat(40));
        console.log(`Latencia Media:       ${avgLatency.toFixed(2)} ms`);
        console.log(`Latencia P95:         ${p95Latency.toFixed(2)} ms`);
        console.log("=".repeat(40));
    } else {
        console.log("\nNo se pudieron confirmar mensajes. Verifica los logs del broker.");
    }
}

// Ejecutar la prueba
runTest().catch(console.error);
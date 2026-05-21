const Kafka = require('node-rdkafka');

// --- CONFIGURACIÓN ---
const KAFKA_CONFIG = {
    'metadata.broker.list': 'localhost:9092', // En rdkafka es metadata.broker.list en vez de bootstrap.servers
    'client.id': 'throughput-tester',
    
    // --- AJUSTES PARA MENSAJES GRANDES (80MB+) ---
    'message.max.bytes': 90000000, 
    'queue.buffering.max.messages': 10, 
    'queue.buffering.max.kbytes': 900000, // Límite de KB en cola (necesario en rdkafka)
    'linger.ms': 0,             
    'batch.num.messages': 1,
    
    // Habilitar el callback de entrega de mensajes
    'dr_cb': true 
};

const TOPIC = 'test_throughput';
const MESSAGE_SIZE = 83886080; // 80MB
const DURATION = 60;           // 1 minuto en segundos

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

// Helper para formatear números con comas
const formatNum = (num) => num.toLocaleString('en-US', { maximumFractionDigits: 2 });

function runTest() {
    const producer = new Kafka.Producer(KAFKA_CONFIG);

    // Conectar al broker
    producer.connect();

    producer.on('ready', () => {
        console.log("Generando payload de 80MB en memoria...");
        // Asignación directa en memoria por performance, igual que el b'x' de Python
        const payload = Buffer.alloc(MESSAGE_SIZE, 'x');

        console.log(`--- Iniciando test (Duración: ${DURATION}s) ---`);
        console.log(`Enviando mensajes de ${formatNum(MESSAGE_SIZE / (1024 * 1024))} MB a: ${KAFKA_CONFIG['metadata.broker.list']}`);

        const startTest = Date.now();
        const endTest = startTest + (DURATION * 1000);

        // Configurar el Delivery Report (Equivalente al on_delivery de Python)
        producer.on('delivery-report', (err, report) => {
            if (err) {
                console.error(`Error de entrega: ${err.message}`);
                return;
            }
            // Recuperamos el timestamp que guardamos en la opacidad del mensaje
            const startTime = report.opaque;
            const latency = Date.now() - startTime;
            latencies.push(latency);
        });

        // Bucle de envío principal
        const sendLoop = () => {
            while (Date.now() < endTest) {
                try {
                    const currentTime = Date.now();
                    
                    // Producir mensaje. Pasamos currentTime en el parámetro 'opaque' 
                    // para recuperarlo en el callback de entrega.
                    producer.produce(
                        TOPIC,
                        null,             // Partición automática
                        payload,          // Buffer
                        null,             // Key opcional
                        currentTime,      // Timestamp del mensaje
                        currentTime       // Opaque (Metadato devuelto en el delivery-report)
                    );

                } catch (err) {
                    // Equivalente al BufferError de Python (ERR__QUEUE_FULL = -184)
                    if (err.code === Kafka.CODES.ERRORS.ERR__QUEUE_FULL) {
                        // BACKPRESSURE: La cola interna está llena. 
                        // Pausamos el bucle síncrono 100ms mediante el event loop para desahogar la red.
                        setTimeout(sendLoop, 100);
                        return; 
                    }
                    console.error(`Error inesperado al producir: ${err.message}`);
                }
            }

            // Tiempo cumplido -> Finalizar proceso
            finishTest(startTest);
        };

        // Iniciar el loop
        sendLoop();
    });

    producer.on('event.error', (err) => {
        console.error(`Error en el cliente Kafka: ${err.message}`);
    });

    function finishTest(startTest) {
        const totalTime = (Date.now() - startTest) / 1000;
        console.log(`\nTiempo cumplido. Procesando mensajes restantes en cola de red...`);

        // flush espera que se vacíe la cola interna antes de desconectar
        producer.flush(10000, (err) => {
            producer.disconnect();

            // --- CÁLCULO DE RESULTADOS ---
            if (latencies.length > 0) {
                const avgThroughput = latencies.length / totalTime;
                const avgLatency = latencies.reduce((a, b) => a + b, 0) / latencies.length;
                const p95Latency = getPercentile(latencies, 95);

                console.log("\n" + "=".repeat(40));
                console.log("         INFORME DE RENDIMIENTO");
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
                console.log("\nNo se recibieron confirmaciones del broker. Revisa los límites del servidor.");
            }
        });
    }
}

// Capturar interrupción (Ctrl+C)
process.on('SIGINT', () => {
    console.log("\nPrueba cancelada por el usuario.");
    process.exit(0);
});

runTest();
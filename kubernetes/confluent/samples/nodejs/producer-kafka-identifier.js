const { Kafka } = require('kafkajs');

const kafka = new Kafka({
    clientId: 'load-test-producer',
    brokers: ['localhost:9092', 'localhost:9093', 'localhost:9094'],
});

const producer = kafka.producer();
const admin = kafka.admin();

const TOTAL_MESSAGES = 1_000_000;
const BATCH_SIZE = 500;          // ajusta según rendimiento
const DELAY_MS = 50;            // delay entre batches

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const run = async () => {
    try {
        await producer.connect();
        await admin.connect();

        console.log('✅ Connected to Kafka');
        console.log(`🚀 Sending ${TOTAL_MESSAGES} messages...\n`);

        const metadata = await admin.fetchTopicMetadata({
            topics: ['orders-topic'],
        });

        const cluster = await admin.describeCluster();

        let batchNumber = 0;

        for (let i = 0; i < TOTAL_MESSAGES; i += BATCH_SIZE) {
            batchNumber++;

            const messages = [];

            for (let j = 0; j < BATCH_SIZE && (i + j) < TOTAL_MESSAGES; j++) {
                const event = {
                    id: i + j,
                    type: 'ORDER_CREATED',
                    payload: {
                        orderId: Math.floor(Math.random() * 100000),
                        amount: Math.random() * 100,
                    },
                    timestamp: new Date().toISOString(),
                };

                messages.push({
                    key: String(1),
                    value: JSON.stringify(event),
                });
            }

            const response = await producer.send({
                topic: 'orders-topic',
                acks: -1,
                messages,
            });

            const partitionsUsed = [...new Set(response.map(r => r.partition))];

            console.log(`\n📦 Batch ${batchNumber}`);
            console.log(`➡️  Partitions used: ${partitionsUsed.join(', ')}`);

            partitionsUsed.forEach(partition => {
                const partitionMeta = metadata.topics[0].partitions.find(
                    p => p.partitionId === partition
                );

                const leaderId = partitionMeta.leader;

                const broker = cluster.brokers.find(
                    b => b.nodeId === leaderId
                );

                console.log(
                    `   📍 Partition ${partition} → Broker ${broker.host}:${broker.port} (id=${leaderId})`
                );
            });

            console.log(`✅ Progress: ${Math.min(i + BATCH_SIZE, TOTAL_MESSAGES)}/${TOTAL_MESSAGES}`);

            // Delay entre batches
            await sleep(DELAY_MS);
        }

        console.log('\n🎉 All messages sent');

    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        await producer.disconnect();
        await admin.disconnect();
        console.log('🔌 Disconnected');
    }
};

run();
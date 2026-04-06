const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'mi-consumidor',
  brokers: ['localhost:9092'],
});

const consumer = kafka.consumer({ groupId: 'grupo-demo' });

const run = async () => {
  await consumer.connect();
  await consumer.subscribe({
    topic: 'topic-demo-particiones',
    fromBeginning: true // cambia a false si no quieres leer mensajes antiguos
  });

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      const valor = message.value.toString();
      const headers = Object.fromEntries(
        Object.entries(message.headers || {}).map(([key, value]) => [
          key,
          value?.toString()
        ])
      );

      console.log(`📥 Mensaje recibido: ${valor}`);
      console.log(`📎 Headers:`, headers);
      console.log(`🕒 Timestamp: ${new Date(Number(message.timestamp)).toISOString()}`);
      console.log(`📌 Partition: ${partition}, Offset: ${message.offset}`);
      console.log('--------------------------------------');
    }
  });
};

run().catch(e => {
  console.error('Error en el consumidor:', e);
  process.exit(1);
});
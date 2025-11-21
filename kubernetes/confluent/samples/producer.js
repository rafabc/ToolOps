const { Kafka } = require('kafkajs');
const { execSync } = require('child_process');

function getContainerIP(containerName) {
  try {
    const cmd = `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${containerName}`;
    return execSync(cmd).toString().trim();
  } catch (err) {
    console.error(`Error obteniendo IP de ${containerName}:`, err);
    return null;
  }
}

// Obtener IP del contenedor (opcional para Docker en Linux/macOS)
const brokerIP = getContainerIP('broker') || 'localhost';
console.log('🧠 IP de broker:', brokerIP);

const kafka = new Kafka({
  clientId: 'productor-demo-json',
  brokers: [`localhost:29092`],
});

const producer = kafka.producer();
const admin = kafka.admin();

const run = async () => {
  await producer.connect();
  await admin.connect();

  console.log('✅ Productor y Admin conectados');

  const metadata = await admin.fetchTopicMetadata();
  const visibleTopics = metadata.topics.filter(topic =>
    !topic.name.startsWith('__') && !topic.name.startsWith('_confluent')
  );

  const filteredMetadata = {
    clusterId: metadata.clusterId,
    topics: visibleTopics,
    brokers: metadata.brokers,
  };

  console.log('📦 Metadatos del clúster Kafka (filtrados):');
  console.log(JSON.stringify(filteredMetadata, null, 2));

  const mensaje = {
    evento: 'usuario_creado',
    usuario: {
      id: 123,
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
    },
    timestamp: new Date().toISOString(),
  };

  const resultado = await producer.send({
    topic: 'topic-demo-particiones',
    messages: [
      {
        key: JSON.stringify({ id: 'asdf', nombre: 'Juan Pérez' }),
        value: JSON.stringify(mensaje),
        headers: {
          origen: 'nodejs',
          prioridad: 'alta',
          'x-id-correlation': 'abc-123',
        },
      },
    ],
  });

  console.log('✅ JSON enviado a Kafka:', JSON.stringify(resultado, null, 2));

  await producer.disconnect();
  await admin.disconnect();
  console.log('🔌 Productor y Admin desconectados');
};

run().catch((e) => {
  console.error('❌ Error en Kafka:', e);
});
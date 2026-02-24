from kafka import KafkaProducer
import json

# Configura el broker y el topic
KAFKA_BROKER = 'localhost:29092'
TOPIC = 'mi-topic'

try:
    # Crea el productor Kafka con menor timeout de conexión
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=lambda v: json.dumps(v).encode('utf-8'),
        request_timeout_ms=5000,
        metadata_max_age_ms=5000
    )

    # Mensaje a enviar
    mensaje = {
        'evento': 'HolaKafka',
        'timestamp': '2025-07-07T21:00:00'
    }

    print("Enviando mensaje...")

    # Envía el mensaje
    future = producer.send(TOPIC, mensaje)

    # Espera confirmación
    result = future.get(timeout=5)
    print(f'Mensaje enviado a {result.topic}:{result.partition} offset {result.offset}')

except Exception as e:
    print(f'Error al enviar el mensaje: {e}')

finally:
    producer.close()
import time
from confluent_kafka import Consumer, KafkaError, TopicPartition

# --- CONFIGURACIÓN ---
KAFKA_CONFIG = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'performance-consumer-group',
    'auto.offset.reset': 'earliest', # Empezar desde el principio del tópico
    'enable.auto.commit': True,
    'fetch.min.bytes': 1000000,      # Optimización: esperar a tener 1MB de datos para pedir
    'linger.ms': 50
}

TOPIC = 'test_throughput'

def run_consumer():
    c = Consumer(KAFKA_CONFIG)
    c.subscribe([TOPIC])

    print(f"--- Consumidor Iniciado ---")
    print(f"Escuchando tópico: {TOPIC}. Presiona Ctrl+C para detener y ver informe.")

    msg_count = 0
    total_bytes = 0
    start_time = time.time()
    
    try:
        while True:
            msg = c.poll(1.0) # Esperar 1 segundo por mensajes

            if msg is None:
                continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    continue
                else:
                    print(f"Error: {msg.error()}")
                    break

            # Procesamiento de métricas
            msg_count += 1
            total_bytes += len(msg.value())

            # Mostrar progreso cada 50,000 mensajes
            if msg_count % 50000 == 0:
                elapsed = time.time() - start_time
                print(f"Recibidos: {msg_count:,} mensajes | TPS actual: {msg_count/elapsed:.2f} msg/s")

    except KeyboardInterrupt:
        pass
    finally:
        end_time = time.time()
        total_duration = end_time - start_time
        
        # --- INFORME FINAL ---
        if msg_count > 0:
            avg_throughput = msg_count / total_duration
            avg_mb_s = (total_bytes / (1024 * 1024)) / total_duration
            
            print("\n" + "="*40)
            print("      RESUMEN DEL CONSUMIDOR")
            print("="*40)
            print(f"Mensajes procesados: {msg_count:,}")
            print(f"Tiempo total:        {total_duration:.2f} s")
            print("-" * 40)
            print(f"Throughput medio:    {avg_throughput:.2f} msg/s")
            print(f"Velocidad de datos:  {avg_mb_s:.2f} MB/s")
            print("="*40)
        
        c.close()

if __name__ == "__main__":
    run_consumer()
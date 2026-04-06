import time
import random
import string
import numpy as np
from confluent_kafka import Producer

# --- CONFIGURACIÓN ---
KAFKA_CONFIG = {
    'bootstrap.servers': 'localhost:9092',
    'client.id': 'latency-tester',
    'acks': 1,                    # 1 es suficiente para medir latencia - no esperamos a que el mensaje sea replicado
    'linger.ms': 0,               # Enviar lo antes posible
    'batch.num.messages': 1,      # Evitar acumulación de mensajes para medir latencia real
    'queue.buffering.max.messages': 1000000
}

TOPIC = 'test_latency'
MESSAGE_SIZE = 1024 
DURATION = 60       
TARGET_TPS = 5000   # 5k msg/s 

latencies = []

def delivery_report(err, msg, start_time):
    if err is None:
        # Aquí medimos el tiempo real de ida y vuelta
        latencies.append((time.time() - start_time) * 1000)

def run_latency_test():
    p = Producer(KAFKA_CONFIG)
    payload = ''.join(random.choices(string.ascii_letters + string.digits, k=MESSAGE_SIZE)).encode('utf-8')
    
    print(f"--- Pruebas lantencia: {TARGET_TPS} msg/s ---")
    
    start_test = time.time()
    end_test = start_test + DURATION
    inter_message_delay = 1.0 / TARGET_TPS

    try:
        while time.time() < end_test:
            send_start = time.time()
            
            # Capturamos el tiempo justo antes de entrar a la cola de Kafka
            p.produce(TOPIC, payload, on_delivery=lambda err, msg, st=send_start: delivery_report(err, msg, st))
            
            p.poll(0) # Procesar callbacks de forma no bloqueante

            while (time.time() - send_start) < inter_message_delay:
                pass

        print("\nPrueba terminada. Esperando confirmaciones ack...")
        p.flush(timeout=10)

    except KeyboardInterrupt:
        pass

    total_duration = time.time() - start_test
    
    if latencies:
        print("\n" + "="*40)
        print("       RESULTADOS DE LATENCIA REAL")
        print("="*40)
        print(f"Mensajes:          {len(latencies):,}")
        print(f"TPS Promedio:      {len(latencies)/total_duration:.2f} msg/s")
        print("-" * 40)
        print(f"Latencia Mínima:   {min(latencies):.2f} ms")
        print(f"Latencia Media:    {np.mean(latencies):.2f} ms")
        print(f"Latencia P95:      {np.percentile(latencies, 95):.2f} ms")
        print("="*40)

if __name__ == "__main__":
    run_latency_test()
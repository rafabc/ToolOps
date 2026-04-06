import time
import random
import string
import numpy as np
from confluent_kafka import Producer

# --- CONFIGURACIÓN ---
KAFKA_CONFIG = {
    'bootstrap.servers': 'localhost:9092', # Ajusta a tu broker
    'client.id': 'throughput-tester',
    # Control de buffer para evitar bloqueos de memoria
    'queue.buffering.max.messages': 500000, 
    'linger.ms': 10,             # Agrupa mensajes para mejorar throughput
    'batch.num.messages': 10000,  # Tamaño del lote

    # # 1. Configuración de Seguridad SSL/TLS
    # 'security.protocol': 'SASL_SSL',      
    # 'ssl.ca.location': '/ruta/a/ca-cert.pem', 
    
    # # 2. Configuración de Autenticación SASL 
    # 'sasl.mechanism': 'PLAIN',            
    # 'sasl.username': 'tu_usuario',
    # 'sasl.password': 'tu_contraseña',

}

TOPIC = 'test_throughput'
MESSAGE_SIZE = 1024 # 1KB
DURATION = 60       # 1 minuto en segundos

# --- MÉTRICAS ---
latencies = []
total_msg_sent = 0

def delivery_report(err, msg, start_time):
    """Callback ejecutado tras la confirmación del Broker"""
    if err is not None:
        pass
    else:
        latency = (time.time() - start_time) * 1000
        latencies.append(latency)

def generate_payload(size):
    """Genera un string aleatorio de 10KB"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=size)).encode('utf-8')

def run_test():
    p = Producer(KAFKA_CONFIG)
    payload = generate_payload(MESSAGE_SIZE)
    
    print(f"--- Iniciando test (Duración: {DURATION}s) ---")
    print(f"Enviando mensajes de {MESSAGE_SIZE/1024}KB a: {KAFKA_CONFIG['bootstrap.servers']}")
    
    start_test = time.time()
    end_test = start_test + DURATION
    sent_count = 0

    try:
        while time.time() < end_test:
            current_time = time.time()
            try:
                # Intentar enviar mensaje
                p.produce(
                    TOPIC, 
                    payload, 
                    on_delivery=lambda err, msg, st=current_time: delivery_report(err, msg, st)
                )
                sent_count += 1
                
                # Servir eventos cada N mensajes para liberar el stack de callbacks
                if sent_count % 1000 == 0:
                    p.poll(0)

            except BufferError:
                # BACKPRESSURE: El buffer local está lleno. 
                # Esperamos a que Kafka procese lo pendiente antes de seguir.
                p.poll(0.1) 
                continue 

        print(f"\nTiempo cumplido. Procesando {p.flush()} mensajes restantes en cola...")
        p.flush() # Esperar confirmación de los últimos mensajes enviados

    except KeyboardInterrupt:
        print("\nPrueba cancelada por el usuario.")

    total_time = time.time() - start_test
    
    # --- CÁLCULO DE RESULTADOS ---
    if latencies:
        avg_throughput = len(latencies) / total_time
        avg_latency = np.mean(latencies)
        p95_latency = np.percentile(latencies, 95)
        
        print("\n" + "="*40)
        print("         INFORME DE RENDIMIENTO")
        print("="*40)
        print(f"Mensajes confirmados: {len(latencies):,}")
        print(f"Tiempo total:         {total_time:.2f} s")
        print("-" * 40)
        print(f"Throughput Medio:     {avg_throughput:.2f} msg/s")
        print(f"Throughput MB/s:      {(avg_throughput * MESSAGE_SIZE) / (1024*1024):.2f} MB/s")
        print("-" * 40)
        print(f"Latencia Media:       {avg_latency:.2f} ms")
        print(f"Latencia P95:         {p95_latency:.2f} ms")
        print("="*40)
    else:
        print("\nNo se recibieron confirmaciones del broker. Revisa la conexión.")

if __name__ == "__main__":
    run_test()
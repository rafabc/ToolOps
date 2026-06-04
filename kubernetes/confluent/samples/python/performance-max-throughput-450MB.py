import time
import random
import string
import numpy as np
from confluent_kafka import Producer

# --- CONFIGURACIÓN ---
KAFKA_CONFIG = {
    'bootstrap.servers': 'localhost:9092', # Ajusta a tu broker
    'client.id': 'throughput-tester',
    # Control estricto de buffer para alta velocidad
    'queue.buffering.max.messages': 1000000, 
    'linger.ms': 20,              # Aumentado ligeramente para mejorar la eficiencia de empaquetado a 450MB/s
    'batch.num.messages': 20000,  # Lotes más grandes ideales para mensajes de 20KB
    
    # IMPORTANTE: Desactivar los ACKS si solo buscas rendimiento puro, 
    # o mantener 'all' si quieres medir latencia real de persistencia.
    'acks': '1' 
}

TOPIC = 'test_throughput'
MESSAGE_SIZE = 20 * 1024 # Cambiado a 20 KB exactos
DURATION = 10       

# --- CÁLCULO DE LÍMITES (THROTTLING) ---
MAX_THROUGHPUT_MB = 450
# Límite matemático: 23040 msg/s. Aplicamos un margen del 3% (factor 0.97) 
# para absorber las cabeceras del protocolo Kafka y TCP sin pasarnos de los 450MB/s en red.
MAX_MSG_PER_SECOND = int((MAX_THROUGHPUT_MB * 1024 * 1024 / MESSAGE_SIZE) * 0.97)
BATCH_TARGET = int(MAX_MSG_PER_SECOND / 10) # Dividimos el segundo en 10 ventanas de 100ms

# --- MÉTRICAS ---
# NOTA: Almacenar millones de floats en una lista de Python satura la RAM a estas tasas.
# Mantenemos las latencias pero ojo con duraciones de test muy largas.
latencies = []

def delivery_report(err, msg, start_time):
    """Callback ejecutado tras la confirmación del Broker"""
    if err is None:
        latency = (time.time() - start_time) * 1000
        latencies.append(latency)

def generate_payload(size):
    """Genera un string aleatorio del tamaño indicado (fijado una sola vez)"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=size)).encode('utf-8')

def run_test():
    p = Producer(KAFKA_CONFIG)
    payload = generate_payload(MESSAGE_SIZE) # Se genera una única vez fuera del bucle
    
    print(f"--- Iniciando test controlado (Duración: {DURATION}s) ---")
    print(f"Mensaje: {MESSAGE_SIZE/1024:.1f} KB | Límite objetivo: {MAX_MSG_PER_SECOND} msg/s (~{MAX_THROUGHPUT_MB} MB/s)")
    
    start_test = time.time()
    end_test = start_test + DURATION
    sent_count = 0

    try:
        while time.time() < end_test:
            cycle_start = time.time()
            
            # Enviar una ráfaga controlada (ventana de 100ms)
            for _ in range(BATCH_TARGET):
                current_time = time.time()
                try:
                    p.produce(
                        TOPIC, 
                        payload, 
                        on_delivery=lambda err, msg, st=current_time: delivery_report(err, msg, st)
                    )
                    sent_count += 1

                except BufferError:
                    # Si el búfer local se llena, liberamos eventos inmediatamente
                    p.poll(0.01)
                    break # Rompe la ráfaga actual para recalcular tiempos y aplicar backpressure
            
            # Procesar eventos acumulados en la librería nativa de C
            p.poll(0)
            
            # --- CONTROL DE VELOCIDAD (THROTTLING) ---
            elapsed = time.time() - cycle_start
            target_duration = 0.1 # Cada ráfaga debería tardar 100ms en el escenario ideal
            
            if elapsed < target_duration:
                # Si el bucle fue más rápido que el límite de throughput, pausamos el hilo
                time.sleep(target_duration - elapsed)

        print(f"\nTiempo cumplido. Procesando {p.flush()} mensajes restantes en cola...")
        p.flush()

    except KeyboardInterrupt:
        print("\nPrueba cancelada por el usuario.")

    total_time = time.time() - start_test
    
    # --- CÁLCULO DE RESULTADOS ---
    if latencies:
        avg_throughput = len(latencies) / total_time
        avg_latency = np.mean(latencies)
        p95_latency = np.percentile(latencies, 95)
        p99_latency = np.percentile(latencies, 99)
        
        print("\n" + "="*40)
        print("         INFORME DE RENDIMIENTO (20KB)")
        print("="*40)
        print(f"Mensajes confirmados: {len(latencies):,}")
        print(f"Tiempo total:         {total_time:.2f} s")
        print("-" * 40)
        print(f"Throughput Medio:     {avg_throughput:.2f} msg/s")
        print(f"Throughput MB/s:      {(avg_throughput * MESSAGE_SIZE) / (1024*1024):.2f} MB/s")
        print("-" * 40)
        print(f"Latencia Media:       {avg_latency:.2f} ms")
        print(f"Latencia P95:         {p95_latency:.2f} ms")
        print(f"Latencia P99:         {p99_latency:.2f} ms")
        print("="*40)
    else:
        print("\nNo se recibieron confirmaciones del broker. Revisa la conectividad o los ACKs.")

if __name__ == "__main__":
    run_test()
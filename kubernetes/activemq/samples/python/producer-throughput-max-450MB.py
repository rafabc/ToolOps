import time
import random
import string
import numpy as np
import stomp
import threading

# --- CONFIGURACIÓN ---
AMQ_CONFIG = {
    'host': 'localhost',
    'port': 61613,
    'user': 'artemis',
    'password': 'artemis',
    # 'ca_certs': '/ruta/a/ca.pem' 
}

QUEUE_NAME = '/queue/test_async_ssl'
MESSAGE_SIZE = 20 * 1024 # Cambiado a 20 KB exactos
DURATION = 10            # Ajustado a 10s para consistencia con la prueba anterior
MAX_IN_FLIGHT = 50000    # Incrementado para dar margen al pipeline a 450MB/s

# --- CÁLCULO DE LÍMITES (THROTTLING) ---
MAX_THROUGHPUT_MB = 450
# Límite matemático: 23.040 msg/s. Aplicamos un margen del 4% (factor 0.96)
# El protocolo STOMP (texto plano) añade más cabeceras por mensaje que Kafka.
MAX_MSG_PER_SECOND = int((MAX_THROUGHPUT_MB * 1024 * 1024 / MESSAGE_SIZE) * 0.96)
BATCH_TARGET = int(MAX_MSG_PER_SECOND / 10) # Dividimos el segundo en ventanas de 100ms

# --- MÉTRICAS Y CONTROL ---
latencies = []
start_times = {}
lock = threading.Lock()
semaphore = threading.BoundedSemaphore(MAX_IN_FLIGHT)

class AsyncThroughputListener(stomp.ConnectionListener):
    def on_receipt(self, frame):
        receipt_id = frame.headers.get('receipt-id')
        now = time.time()
        with lock:
            if receipt_id in start_times:
                latency = (now - start_times[receipt_id]) * 1000
                latencies.append(latency)
                del start_times[receipt_id]
                semaphore.release()

    def on_error(self, frame):
        print(f"\n[ERROR BROKER] {frame.body}")

def generate_payload(size):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=size)).encode('utf-8')

def run_test():
    conn = stomp.Connection(
        [(AMQ_CONFIG['host'], AMQ_CONFIG['port'])],
        heartbeats=(0, 0) # Sin heartbeats para evitar ruido en el throughput
    )
    
    conn.set_listener('async_listener', AsyncThroughputListener())
    conn.connect(AMQ_CONFIG['user'], AMQ_CONFIG['password'], wait=True)

    payload = generate_payload(MESSAGE_SIZE)
    print(f"--- Iniciando Test Throughput Controlado (ActiveMQ) ---")
    print(f"Mensaje: {MESSAGE_SIZE/1024:.1f} KB | Límite objetivo: {MAX_MSG_PER_SECOND} msg/s (~{MAX_THROUGHPUT_MB} MB/s)")
    print(f"Ventana de envío (In-Flight Max): {MAX_IN_FLIGHT} mensajes")

    start_test = time.time()
    end_test = start_test + DURATION
    sent_count = 0

    try:
        while time.time() < end_test:
            cycle_start = time.time()
            
            # Enviar una ráfaga controlada correspondiente a 100ms
            for _ in range(BATCH_TARGET):
                # El semáforo asegura backpressure si ActiveMQ se satura y no envía RECEIPTS
                if not semaphore.acquire(blocking=True, timeout=0.05):
                    break # Si se agota el timeout, rompemos el lote para procesar ACKs
                
                receipt_id = f"r-{sent_count}"
                current_time = time.time()
                
                with lock:
                    start_times[receipt_id] = current_time

                # Importante: persistent=false para exprimir el rendimiento de red a estas tasas
                conn.send(
                    body=payload, 
                    destination=QUEUE_NAME, 
                    headers={'receipt': receipt_id, 'persistent': 'false'}
                )
                sent_count += 1

            # --- CONTROL DE VELOCIDAD (THROTTLING) ---
            elapsed = time.time() - cycle_start
            target_duration = 0.1 # Duración objetivo para las ráfagas (100ms)
            
            if elapsed < target_duration:
                # Si el envío fue más rápido que el límite de throughput, pausamos el hilo
                time.sleep(target_duration - elapsed)

        print(f"\nFin del tiempo. Drenando {len(start_times)} confirmaciones pendientes...")
        stop_wait = time.time() + 7
        while len(start_times) > 0 and time.time() < stop_wait:
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nTest abortado por el usuario.")
    finally:
        try:
            conn.disconnect()
        except:
            pass

    total_time = time.time() - start_test
    
    # --- CÁLCULO DE RESULTADOS ---
    if latencies:
        avg_tp = len(latencies) / total_time
        print("\n" + "="*45)
        print(f"      INFORME DE RENDIMIENTO ACTIVEMQ (20KB)")
        print("="*45)
        print(f"Mensajes Confirmados: {len(latencies):,}")
        print(f"Tiempo total:         {total_time:.2f} s")
        print("-" * 45)
        print(f"Throughput Medio:     {avg_tp:.2f} msg/s")
        print(f"Throughput MB/s:      {(avg_tp * MESSAGE_SIZE) / (1024*1024):.2f} MB/s")
        print("-" * 45)
        print(f"Latencia Media:       {np.mean(latencies):.2f} ms")
        print(f"Latencia P95:         {np.percentile(latencies, 95):.2f} ms")
        print(f"Latencia P99:         {np.percentile(latencies, 99):.2f} ms")
        print("="*45)
    else:
        print("\nNo se recibieron confirmaciones (RECEIPTs) del broker. Verifica la configuración de STOMP.")

if __name__ == "__main__":
    run_test()
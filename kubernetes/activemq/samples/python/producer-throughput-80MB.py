import time
import numpy as np
import stomp
import threading

# --- CONFIGURACIÓN ---
AMQ_CONFIG = {
    'host': 'localhost',
    'port': 61613,
    'user': 'artemis',
    'password': 'artemis',
}

QUEUE_NAME = '/queue/test_async_ssl'
MESSAGE_SIZE = 80 * 1024 * 1024  # 80 MB exactos en bytes
DURATION = 60       

# RESTRICCIÓN CRÍTICA: Reducido drásticamente para evitar OOM (80MB * 2 = 160MB max en memoria)
MAX_IN_FLIGHT = 2 

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
    # Generación ultra rápida y eficiente en memoria usando ceros binarios
    return b'0' * size

def run_test():
    conn = stomp.Connection(
        [(AMQ_CONFIG['host'], AMQ_CONFIG['port'])],
        heartbeats=(0, 0) 
    )
    
    conn.set_listener('async_listener', AsyncThroughputListener())
    conn.connect(AMQ_CONFIG['user'], AMQ_CONFIG['password'], wait=True)

    print("Generando payload de 80 MB en memoria...")
    payload = generate_payload(MESSAGE_SIZE)
    
    print(f"--- Iniciando Test Throughput (Mensajes de 80MB) ---")
    print(f"Control de flujo estricto: Max {MAX_IN_FLIGHT} mensajes en vuelo.")

    start_test = time.time()
    end_test = start_test + DURATION
    sent_count = 0

    try:
        while time.time() < end_test:
            # Si el broker no procesa el mensaje anterior, el script se pausa aquí de forma segura
            semaphore.acquire() 
            
            receipt_id = f"r-{sent_count}"
            current_time = time.time()
            
            with lock:
                start_times[receipt_id] = current_time

            # 'persistent': 'false' es vital para que Artemis no intente escribir 80MB a disco sincrónicamente
            conn.send(
                body=payload, 
                destination=QUEUE_NAME, 
                headers={'receipt': receipt_id, 'persistent': 'false'}
            )
            sent_count += 1

        print(f"\nFin del tiempo. Drenando {len(start_times)} confirmaciones pendientes...")
        # Aumentado a 15 segundos porque vaciar 80MB remotos requiere más tiempo de red
        stop_wait = time.time() + 15
        while len(start_times) > 0 and time.time() < stop_wait:
            time.sleep(0.2)

    except KeyboardInterrupt:
        print("\nTest abortado.")
    finally:
        conn.disconnect()

    total_time = time.time() - start_test
    
    if latencies:
        avg_tp = len(latencies) / total_time
        print("\n" + "="*45)
        print(f"      INFORME STOMP DE ALTO RENDIMIENTO")
        print("="*45)
        print(f"Mensajes Confirmados: {len(latencies):,}")
        print(f"Tiempo total:         {total_time:.2f} s")
        print("---------------------------------------------")
        print(f"Throughput Medio:     {avg_tp:.4f} msg/s")
        print(f"Throughput MB/s:      {(len(latencies) * MESSAGE_SIZE) / (1024*1024) / total_time:.2f} MB/s")
        print(f"Latencia Media:       {np.mean(latencies):.2f} ms")
        print(f"Latencia P95:         {np.percentile(latencies, 95):.2f} ms")
        print("="*45)
    else:
        print("\n[!] No se recibieron confirmaciones. El broker rechazó los mensajes o expiró el timeout.")

if __name__ == "__main__":
    run_test()
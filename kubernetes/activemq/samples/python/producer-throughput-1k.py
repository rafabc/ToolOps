import time
import random
import string
import numpy as np
import stomp
# import ssl
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
MESSAGE_SIZE = 1024 
DURATION = 60       
MAX_IN_FLIGHT = 10000 # Máximo de mensajes enviados sin confirmar (evita OOM)

# --- MÉTRICAS Y CONTROL ---
latencies = []
start_times = {}
lock = threading.Lock()
# El semáforo controla el flujo: si hay 10k mensajes sin ACK, el productor espera
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
                semaphore.release() # Liberamos hueco para enviar otro mensaje

    def on_error(self, frame):
        print(f"\n[ERROR BROKER] {frame.body}")

def generate_payload(size):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=size)).encode('utf-8')

def run_test():
    # Contexto SSL
    # context = ssl.create_default_context(cafile=AMQ_CONFIG['ca_certs'])
    # context.check_hostname = False # Descomentar si usas IPs en lugar de nombres DNS
    # context.verify_mode = ssl.CERT_NONE # Descomentar solo para pruebas con certs auto-firmados

    conn = stomp.Connection(
        [(AMQ_CONFIG['host'], AMQ_CONFIG['port'])],
        # use_ssl=True,
        # ssl_context=context,
        heartbeats=(0, 0) # Desactivamos heartbeats para no falsear el throughput
    )
    
    conn.set_listener('async_listener', AsyncThroughputListener())
    conn.connect(AMQ_CONFIG['user'], AMQ_CONFIG['password'], wait=True)

    payload = generate_payload(MESSAGE_SIZE)
    print(f"--- Iniciando Test Throughput ---")
    print(f"Envio (In-Flight): {MAX_IN_FLIGHT} mensajes")

    start_test = time.time()
    end_test = start_test + DURATION
    sent_count = 0

    try:
        while time.time() < end_test:
            semaphore.acquire() # Espera aquí si el broker no confirma rápido
            
            receipt_id = f"r-{sent_count}"
            current_time = time.time()
            
            with lock:
                start_times[receipt_id] = current_time

            conn.send(
                body=payload, 
                destination=QUEUE_NAME, 
                headers={'receipt': receipt_id, 'persistent': 'false'}
            )
            sent_count += 1

        print(f"\nFin del tiempo. Drenando {len(start_times)} confirmaciones pendientes...")
        # Espera máxima de 5 segundos para recibir los ACKs finales
        stop_wait = time.time() + 5
        while len(start_times) > 0 and time.time() < stop_wait:
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nTest abortado.")
    finally:
        conn.disconnect()

    total_time = time.time() - start_test
    
    if latencies:
        avg_tp = len(latencies) / total_time
        print("\n" + "="*45)
        print(f"      INFORME ASÍNCRONO SSL")
        print("="*45)
        print(f"Mensajes Confirmados: {len(latencies):,}")
        print(f"Throughput Medio:     {avg_tp:.2f} msg/s")
        print(f"Throughput MB/s:      {(avg_tp * MESSAGE_SIZE) / (1024*1024):.2f} MB/s")
        print(f"Latencia P95:         {np.percentile(latencies, 95):.2f} ms")
        print("="*45)

if __name__ == "__main__":
    run_test()
import os
import time
import requests
from datetime import datetime

# Importamos Topic además de los anteriores
from solace.messaging.messaging_service import MessagingService
from solace.messaging.resources.topic import Topic
from solace.messaging.resources.queue import Queue
from solace.messaging.publisher.persistent_message_publisher import PersistentMessagePublisher, MessagePublishReceiptListener

# ==========================
# CONFIGURACIÓN Y MEMORIA
# ==========================
seguimiento_mensajes = {}

QUEUE_NAME = 'Q.INPUT.PYTHON'
SEMP_HOST = os.getenv('SEMP_URL', 'localhost')
SEMP_PORT = os.getenv('SEMP_PORT', '8088')
SOLACE_URL = os.getenv('SOLACE_URL', 'tcp://localhost:5555')

SEMP_CONFIG = {
    "url": f"http://{SEMP_HOST}:{SEMP_PORT}",
    "vpn": 'default',
    "username": os.getenv('SEMP_USER', 'admin'),
    "password": os.getenv('SEMP_PASSWORD', 'admin')
}

# ==========================
# SEMP: ASEGURAR COLA
# ==========================
def ensure_queue_exists(queue_name, config):
    print('🔧 Verificando cola mediante SEMP...')
    base_path = f"{config['url']}/SEMP/v2/config/msgVpns/{config['vpn']}/queues"
    auth = (config['username'], config['password'])
    try:
        response = requests.get(f"{base_path}/{queue_name}", auth=auth, timeout=5)
        if response.status_code == 200:
            print(f'✅ La cola "{queue_name}" ya existe')
    except Exception:
        pass

# ==========================
# GESTIÓN DE ACKS
# ==========================
class SimpleAckHandler(MessagePublishReceiptListener):
    def on_publish_receipt(self, receipt):
        t_fin = time.perf_counter()
        h_log = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        
        msg_id = getattr(receipt, 'user_context', None)
        if msg_id is None and hasattr(receipt, 'get_user_context'):
            msg_id = receipt.get_user_context()
        
        if msg_id and msg_id in seguimiento_mensajes:
            meta = seguimiento_mensajes.pop(msg_id)
            latencia = (t_fin - meta['t_inicio']) * 1000
            print(f"[{h_log}] ✔ ACK OK. ID: {msg_id} | Latencia: {latencia:.2f} ms")

# ==========================
# LÓGICA DE ENVÍO
# ==========================
def start_producer():
    broker_props = {
        "solace.messaging.transport.host": SOLACE_URL,
        "solace.messaging.service.vpn-name": SEMP_CONFIG['vpn'],
        "solace.messaging.authentication.scheme.basic.username": os.getenv('BROKER_USER', 'admin'),
        "solace.messaging.authentication.scheme.basic.password": os.getenv('BROKER_PASSWORD', 'admin'),
    }

    try:
        service = MessagingService.builder().from_properties(broker_props).build()
        service.connect()
        print('✅ Conectado al broker Solace')

        publisher = service.create_persistent_message_publisher_builder().build()
        publisher.start()
        publisher.set_message_publish_receipt_listener(SimpleAckHandler())
        
        # CAMBIO CLAVE: Usamos un Point-to-Point Topic que apunta a la cola
        # Esto engaña al validador de tipos pero el mensaje termina en la cola
        destination = Topic.of(f"#P2P/QUE/{QUEUE_NAME}")
        
        print(f"🚀 Iniciando envío persistente a la cola vía {destination.get_name()}...")

        count = 1
        while count <= 90000:
            msg_id = str(count)
            t_inicio = time.perf_counter()
            h_inicio = datetime.now().strftime("%H:%M:%S.%f")[:-3]
            seguimiento_mensajes[msg_id] = {'t_inicio': t_inicio, 'h_inicio': h_inicio}

            message = service.message_builder() \
                .with_application_message_id(msg_id) \
                .build(f"Msg {msg_id}")

            # Ahora el destino es un objeto Topic (que el validador acepta)
            # pero con la sintaxis P2P de Solace
            publisher.publish(message, destination, user_context=msg_id)
            
            count += 1
            time.sleep(0.05)

    except Exception as e:
        print(f"❌ Error crítico: {e}")
    finally:
        if 'publisher' in locals(): publisher.terminate(500)
        if 'service' in locals(): service.disconnect()
        print("🔌 Sesión cerrada.")

if __name__ == '__main__':
    ensure_queue_exists(QUEUE_NAME, SEMP_CONFIG)
    start_producer()
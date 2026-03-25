import os
import time
from datetime import datetime
from solace.messaging.messaging_service import MessagingService
from solace.messaging.resources.queue import Queue
from solace.messaging.receiver.message_receiver import MessageHandler, InboundMessage

QUEUE_NAME = 'Q.INPUT.PYTHON'
SOLACE_URL = os.getenv('SOLACE_URL', 'tcp://localhost:5555')

class MessageHandlerImpl(MessageHandler):
    def __init__(self, receiver):
        self.receiver = receiver

    def on_message(self, message: InboundMessage):
        ahora = datetime.now()
        hora_log = ahora.strftime("%H:%M:%S.%f")[:-3]
        msg_id = message.get_application_message_id()
        payload = message.get_payload_as_string()
        
        if payload is None:
            payload_bytes = message.get_payload_as_bytes()
            payload = payload_bytes.decode('utf-8', errors='ignore') if payload_bytes else "[Vacio]"

        print(f"[{hora_log}] 📨 Mensaje recibido ID: {msg_id} - Contenido: {payload}")
        
        # El receptor es quien hace el ack del mensaje en esta versión
        try:
            self.receiver.ack(message)
        except Exception as e:
            print(f"⚠️ Error al confirmar: {e}")

def start_consumer():
    broker_props = {
        "solace.messaging.transport.host": SOLACE_URL,
        "solace.messaging.service.vpn-name": "default",
        "solace.messaging.authentication.scheme.basic.username": "admin",
        "solace.messaging.authentication.scheme.basic.password": "admin",
    }
    try:
        service = MessagingService.builder().from_properties(broker_props).build()
        service.connect()
        print('✅ Conectado al broker')
        
        durable_queue = Queue.durable_exclusive_queue(QUEUE_NAME)
        receiver = service.create_persistent_message_receiver_builder().build(durable_queue)
        receiver.start()
        
        # Pasamos el receiver al handler para poder hacer ACK
        handler = MessageHandlerImpl(receiver) 
        receiver.receive_async(handler)
        
        print(f"✅ Consumidor conectado a la cola: {QUEUE_NAME}")
        print("🚀 Esperando mensajes... (Ctrl+C para salir)")
        
        while True:
            time.sleep(1)
            
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        if 'receiver' in locals(): receiver.terminate(500)
        if 'service' in locals(): service.disconnect()

if __name__ == '__main__':
    start_consumer()
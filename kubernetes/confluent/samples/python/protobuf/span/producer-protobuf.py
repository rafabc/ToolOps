import json
from confluent_kafka import Producer
import span_pb2 as pb2  # Archivo generado por protoc

# Configuración del productor de Kafka
kafka_config = {
    'bootstrap.servers': 'localhost:9092',  # Cambia por la dirección de tu broker
    'client.id': 'python-protobuf-producer'
}

producer = Producer(kafka_config)
topic_name = "opentelemetry-traces"

# Callback para verificar si el mensaje se entregó correctamente
def delivery_report(err, msg):
    if err is not None:
        print(print(f"❌ Error al entregar el mensaje: {err}"))
    else:
        print(f"✅ Mensaje entregado con éxito a {msg.topic()} [Partición: {msg.partition()}]")

def build_protobuf_message():
    """Construye el objeto Protobuf basándose en tu estructura JSON"""
    
    # 1. Crear el mensaje raíz
    request = pb2.ExportTraceServiceRequest()
    
    # 2. Agregar un ResourceSpan
    resource_span = request.resource_spans.add()
    
    # 3. Configurar Atributos del Recurso
    attr1 = resource_span.resource.attributes.add()
    attr1.key = "service.name"
    attr1.value.string_value = "xxx"
    
    attr2 = resource_span.resource.attributes.add()
    attr2.key = "telemetry.sdk.language"
    attr2.value.string_value = "xxx"
    
    # 4. Agregar ScopeSpans
    scope_span = resource_span.scope_spans.add()
    
    # 5. Agregar el Span principal
    span = scope_span.spans.add()
    span.trace_id = "05d1c62f4ec542c9aab7f12502e60848"
    span.span_id = "aab7f12502e60848"
    span.name = "xxx"
    span.kind = 1
    span.start_time_unix_nano = 1683915855057000000
    span.end_time_unix_nano = 1683915855906000000
    
    # 6. Atributos del Span (Mapeo del JSON de ejemplo)
    span_attributes = [
        ("prefixSpanId", "xxx"),
        ("UUAA", "xxx"),
        ("EngineName", "xxx"),
        ("MachineName", "xxx"),
        ("ProcessName", "xxxx"),
        ("ProjectName", "xxx"),
        ("InvocationUser", "xxx"),
        ("ServiceType", "xxx"),
        ("BusinessObject", "xxx"),
        ("ClientExternalId", "xxx"),
        ("StarterServiceId", "xxx"),
        ("TraceLevel", "2")
    ]
    
    for key, val in span_attributes:
        kv = span.attributes.add()
        kv.key = key
        kv.value.string_value = val
        
    # 7. Estado (Status)
    span.status.code = 1
    
    # 8. Enlaces (Links)
    link = span.links.add()
    link.trace_id = "05d1c62f4ec542c9aab7f12502e60848"
    link.span_id = "aab7f12502e60848"
    
    link_attr = link.attributes.add()
    link_attr.key = "prefixSpanId"
    link_attr.value.string_value = "xxx"
    
    return request

def main():
    print("Construyendo el mensaje Protobuf...")
    proto_message = build_protobuf_message()
    
    # Serializar el objeto Protobuf a bytes (formato binario de alta velocidad)
    binary_data = proto_message.SerializeToString()
    
    print(f"Enviando mensaje serializado ({len(binary_data)} bytes) a Kafka...")
    
    try:
        # Enviar a Kafka de forma asíncrona
        # Se puede usar una clave (key) opcional si deseas direccionar a una partición específica
        producer.produce(
            topic=topic_name, 
            value=binary_data, 
            key=proto_message.resource_spans[0].scope_spans[0].spans[0].trace_id,
            callback=delivery_report
        )
        
        # Esperar a que se procesen los callbacks pendientes en la cola de eventos
        producer.flush()
        
    except Exception as e:
        print(f"❌ Error durante el envío: {e}")

if __name__ == '__main__':
    main()
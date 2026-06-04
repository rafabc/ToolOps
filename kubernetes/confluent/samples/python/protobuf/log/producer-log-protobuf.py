import os
from confluent_kafka import Producer

# --- TRUCO DE COMPATIBILIDAD DE VERSIONES ---
# Esta variable de entorno desactiva la validación estricta de versiones de Google.
# Te salvará de tener que editar los archivos generados a mano.
os.environ["PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"] = "python"

import log_pb2 as pb2  # Importamos el archivo generado por protoc

# Configuración de Kafka
kafka_config = {
    'bootstrap.servers': 'localhost:9092',  # Cambia por tu broker
    'client.id': 'python-protobuf-logs-producer'
}

producer = Producer(kafka_config)
topic_name = "opentelemetry-logs"

def delivery_report(err, msg):
    if err is not None:
        print(f"❌ Error al entregar el log: {err}")
    else:
        print(f"✅ Log entregado a {msg.topic()} [Partición: {msg.partition()}]")

def build_protobuf_log():
    # 1. Mensaje Raíz
    request = pb2.ExportLogsServiceRequest()
    
    # 2. Resource Logs
    res_log = request.resource_logs.add()
    
    # Atributos del recurso
    attr1 = res_log.resource.attributes.add()
    attr1.key = "service.name"
    attr1.value.string_value = "xxxxx"
    
    attr2 = res_log.resource.attributes.add()
    attr2.key = "telemetry.sdk.language"
    attr2.value.string_value = "xxx"
    
    # 3. Scope Logs
    scope_log = res_log.scope_logs.add()
    
    # 4. Log Record
    record = scope_log.log_records.add()
    record.trace_id = "466825e206134032ae7f1d7d556cc334"
    record.span_id = "9134475b9153ac23"
    record.time_unix_nano = 1708344921179000000
    
    # Cuerpo del Log (Contiene el sub-JSON escapado en string)
    record.body.string_value = (
        "{\n"
        "  \"Header\":\"H4sIAAAAAAAAAI1UXY+iMBR9319heOejBUSMMsEZzJLNZiaDbrL7YgrUGVZp2bbqzL+f2qLixyY+8NBzzz3cnHva0cNHve5tMeMVJWMDWI7Rw6SgZUXexsZ8NjUHxkP0bUS4M4xZ8V4JXIgNw98xKjHryWbCh7I4Nt6FaIa2vdvtrDzfIqugtZ3E6ZShGu8oWxmRFtmUldDdGkhgkpaR1+8PoI+h0weu57gQ4WAJyqD0/X5RuK43sk9c1faCGCYiJVwgUuC7Fa7alFjnDFwnD10fD5ah75VoGUo1L/DzEPguKqCrZS4FnjBuCOY8Arp+PKtqhtm2UuRs8eP382SRxovpazx/SjT7VO/SZ58NjtKfL/EZSaEH4x4pEYyuoyVac3y06IB2fLrNvapp+HpFj1n3KBhSw85MEDgDaU8IgeNB874NHLqVVKMmyBpEIsLtt7W1+qS5hZrGrErT9QPPs0q8tWvG5beoKakEZTRfOA6wuezidnYxRJJN7hyk8281y15vv6KOIAhCJXhfKFqBdg/nnr3ifxvMz1ydTH7Fcy5Pc7IidEd03xHVzn8IzAhaS1nf8/ut9AnUQhte7cP2nP+VlzOSN25Tthu+KOl4CcTErKrlOKhuIuhAz3SgCcIZgEPgD6F8BDz4p03dOfk8zqooR21Tnfwn1Qeahm84kTBGWRdIuYK6WT1ArQXdDvv24xR9AVoFx6ncBAAA\",\n"
        "  \"Functional\":\"H4sIAAAAAAAAAEVRS3OCMBC+91cw3CHhXRnFAcSLFhyw1Z4yFLbKVBKGYPXnNwLF2+732G83mS/v9UX6hZZXjC5kTcWyBLRgZUVPC/l9v1Ze5aX3Mqccu9/VBVJoWlYA55LwUe4KfCGfu65xEbrdbmpXfRVMLViNeHGGOudoH5DNZxKQ4EASCkFOf8jK3ycZeYvS0F8lGcrOeQtlCpxdWzEaZaPzkK22Y6PeeSmPkVni75Qo/phyxyRV0JzljcraE3oUCOgvXFgDSPb6A64cWi/ClmNgZ44mZDqO5jV4SRwFfrzRjscjCbdk5+8InmFbx7oWpmtsqqEfD+bJ0g+oWVnmHXgaVrCt6JqkGa7puOZsEP/TvbYqPcu07IERTQ+KR6tFrRuGYzj6wI3YtKE4s4P2obIN2zJmz0Um5glNf+X9AbcKiovmAQAA\",\n"
        "  \"Hash\":\"5d46eba1507fd7945d580c0a12b6dfe3e604148cd0546fd360ee5203c4f7155f\"\n"
        "}"
    )
    
    # Atributos específicos del Log Record
    log_attributes = [
        ("prefixSpanId", "xxxx"),
        ("EventId", "08613d07a95a46f78c3cdb8222fd7158"),
        ("EventCode", "xxx-xxx-xxx"),
        ("EventType", "1"),
        ("MessageType", "xxx"),
        ("ServiceType", "xxx"),
        ("StarterServiceId", "xxxx"),
        ("Category", "xxx"),
        ("UUAA", "xxx"),
        ("TraceLevel", "4")
    ]
    
    for key, val in log_attributes:
        kv = record.attributes.add()
        kv.key = key
        kv.value.string_value = val
        
    return request

def main():
    print("Construyendo el mensaje de Log Protobuf...")
    proto_message = build_protobuf_log()
    
    # Serialización binaria
    binary_data = proto_message.SerializeToString()
    
    print(f"Enviando Log ({len(binary_data)} bytes) a Kafka...")
    
    try:
        producer.produce(
            topic=topic_name,
            value=binary_data,
            key=proto_message.resource_logs[0].scope_logs[0].log_records[0].trace_id,
            callback=delivery_report
        )
        producer.flush()
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == '__main__':
    main()
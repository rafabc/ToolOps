package com.job;

import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.formats.json.JsonRowDeserializationSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.types.Row;
//import org.apache.flink.util.ParameterTool;

import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.common.typeinfo.Types;
// import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
// import org.apache.flink.types.Row;
// import org.apache.flink.streaming.api.datastream.DataStream;
// import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
// import org.apache.flink.api.common.serialization.SimpleStringSchema;import org.apache.flink.api.common.typeinfo.TypeInformation;



import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.api.common.typeinfo.Types;
import org.apache.flink.formats.json.JsonRowDeserializationSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.types.Row;
import org.apache.flink.api.java.utils.ParameterTool;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public class KafkaTableAPI {

    public static void main(String[] args) throws Exception {
        // set up the execution environment
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        StreamTableEnvironment tEnv = StreamTableEnvironment.create(env);

        // set up Kafka consumer properties
        ParameterTool parameterTool = ParameterTool.fromArgs(args);
        String kafkaBootstrapServers = parameterTool.get("bootstrap.servers", "broker:9092");
        String kafkaTopic = parameterTool.get("kafka.topic", "assets");

        // define the JSON schema
        String[] fieldNames = {"field1", "field2", "field3"}; // replace with your actual field names
        TypeInformation<?>[] fieldTypes = {
            Types.STRING,
            Types.INT,
            Types.DOUBLE
        }; // replace with your actual types

        TypeInformation<Row> typeInfo = Types.ROW_NAMED(fieldNames, fieldTypes);

        JsonRowDeserializationSchema schema = new JsonRowDeserializationSchema(typeInfo);

        // create a Kafka data source
        DataStream<Row> kafkaStream = env
            .addSource(new FlinkKafkaConsumer<>(kafkaTopic, schema, parameterTool.getProperties()))
            .name("Kafka Source");

        // register the Kafka data source as a table
        tEnv.createTemporaryView("kafka_table", kafkaStream, "key, value");

        // execute a SQL query on the Kafka table
        tEnv.executeSql("SELECT * FROM kafka_table").print();
    }
}

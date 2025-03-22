package com.job;

import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import java.util.Properties;

public class KafkaConsumerJob {

    public static void main(String[] args) throws Exception {
        // Set up the execution environment
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        // Configure Kafka consumer
        Properties consumerProps = new Properties();
        consumerProps.setProperty(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "broker:9092");
        consumerProps.setProperty(ConsumerConfig.GROUP_ID_CONFIG, "flink-group");
        FlinkKafkaConsumer<String> kafkaConsumer = new FlinkKafkaConsumer<>("assets", new SimpleStringSchema(), consumerProps);

        // Configure Kafka producer
        Properties producerProps = new Properties();
        producerProps.setProperty("bootstrap.servers", "broker:9092");
        FlinkKafkaProducer<String> kafkaProducer = new FlinkKafkaProducer<>("output-topic", new SimpleStringSchema(), producerProps);

        // Add Kafka consumer
        DataStream<String> input = env.addSource(kafkaConsumer);

        // Process data (optional)

        // Add Kafka producer
        input.addSink(kafkaProducer);

        // Execute the job
        env.execute("Kafka Consumer Job");
    }
}

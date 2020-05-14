# Set up for TLS

# Create a topic

```
kafka-topics.sh --create --bootstrap-server ... --repication-factor 1 --partitions 1 --command-config properties --topic
```

# Run the producer and consumer

In separate terminals do the following.

Terminal 1

```

```

Terminal 2

```
```

kafka-console-producer.sh --broker-list localhost:9093 --topic test --producer.config client-ssl.properties

kafka-console-consumer.sh --bootstrap-server localhost:9093 --topic test --new-consumer --consumer.config client-ssl.properties
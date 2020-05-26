# Set up for TLS

# Create a topic

```
kafka-topics.sh --create --bootstrap-server ... --repication-factor 1 --partitions 2 --command-config properties --topic
```

We have two brokers so create a partition on each and replicate to the other.

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

# Non-JVM based produder and consumer

Another useful utility is kafkacat (https://github.com/edenhill/kafkacat). Below is the producer I use to
test integration from my syslog server to MSK:

```
echo "test" | kafkacat -b broker19094,broker2:9094, -X security.protocol=SSL -t test-topic \
  -v -X debug=generic,broker,security
```

This uses librdkafka, which is the same used by omkafka if you're dumping a syslog to Kafka.  It makes testing
simple.
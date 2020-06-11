# Set up for TLS

* Create a file called client-ssl.properties 
* Copy 

```
security.protocol=SSL
ssl.truststore.location=/Users/dan/software/kafka-config/kafka.client-truststore.jks
ssl.endpoint.identification.algorithm=
```

# Create a topic

```
./kafka-topics.sh --create \
                  --bootstrap-server kafka-broker1.dev.internal:9094 \
                  --replication-factor 1 \
                  --partitions 2 \
                  --command-config client-ssl.properties \
                  --topic "platform.test.v1"
```

We have two brokers so create a partition on each and replicate to the other.

# Run the producer and consumer

In separate terminals do the following.

Terminal 1

```
./kafka-console-producer.sh --broker-list kafka-broker1.test.internal:9094,kafka-broker2.test.internal:9094 --topic platform.test.v1 --producer.config client-ssl.properties

```

Terminal 2

```
./kafka-console-consumer.sh --bootstrap-server kafka-broker1.test.internal:9094 --topic platform.test.v1 --consumer.config client-ssl.properties
```

# Non-JVM based produder and consumer

Another useful utility is kafkacat (https://github.com/edenhill/kafkacat). Below is the producer I use to
test integration from my syslog server to MSK:

## Install

* sudo yum group install "Development Tools" -y
* sudo yum install -y librdkafka-devel yajl-devel avro-c-devel
* sudo yum install git
* git clone https://github.com/edenhill/kafkacat.git
* cd kafkacat
* make
* sudo make install

## Produce

```
echo "test" | kafkacat -b kafka-broker.dev.internal:9094,kafka-broker2.dev.internal:9094, -X security.protocol=SSL -t platform.module.test.v1 \
  -v -X debug=generic,broker,security
```

This uses librdkafka, which is the same used by omkafka if you're dumping a syslog to Kafka.  It makes testing
simple.
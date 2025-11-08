# Kafka Playground

A simple Kafka development environment using Docker Compose with KRaft mode (no Zookeeper required).

## Features

- Apache Kafka 4.0+ running in KRaft mode
- Redpanda Console for UI-based Kafka management
- Pre-configured for local development

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Start the Kafka cluster:
```bash
docker-compose up -d
```

2. Access Redpanda Console:
   - Open your browser to http://localhost:8080

3. Connect to Kafka:
   - Bootstrap server: `localhost:9092`

## Stopping the Cluster

```bash
docker-compose down
```

## Services

- **Kafka Broker**: Port 9092
- **Redpanda Console**: Port 8080 (UI for managing Kafka)

## Usage Examples

### Create a topic
```bash
docker exec -it broker /opt/kafka/bin/kafka-topics.sh \
  --create \
  --topic test-topic \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1
```

### List topics
```bash
docker exec -it broker /opt/kafka/bin/kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092
```

### Produce messages
```bash
docker exec -it broker /opt/kafka/bin/kafka-console-producer.sh \
  --topic test-topic \
  --bootstrap-server localhost:9092
```

### Consume messages
```bash
docker exec -it broker /opt/kafka/bin/kafka-console-consumer.sh \
  --topic test-topic \
  --from-beginning \
  --bootstrap-server localhost:9092
```


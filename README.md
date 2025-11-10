# Kafka Playground

A simple Kafka development environment using Docker Compose with KRaft mode (no Zookeeper required).

## Features

- Apache Kafka 4.0+ running in KRaft mode
- Redpanda Console for UI-based Kafka management
- Terraform configuration for declarative topic management
- Pre-configured for local development with best practices

## Prerequisites

- Docker
- Docker Compose
- Terraform (optional, for topic management)

## Project Structure

```
kafka-playground/
├── docker-compose.yml      # Kafka cluster configuration
├── docs/
│   └── troubleshooting.md # Common issues and solutions
├── terraform/
│   ├── main.tf            # Terraform configuration for Kafka topics
│   ├── topics.yaml        # Declarative topic definitions
│   └── README.md          # Terraform usage guide & best practices
└── README.md
```

### Terraform Topic Management

The `terraform/` directory contains infrastructure-as-code for managing Kafka topics:

- **`main.tf`**: Defines the Kafka provider and topic resources
- **`topics.yaml`**: YAML file where you define your topics declaratively

This approach allows you to:
- Version control your topic configurations
- Consistently deploy topics across environments
- Manage topic retention, segmentation, and other configs in one place

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

## Managing Topics with Terraform

### Creating Topics

1. Define your topics in `terraform/topics.yaml`:

```yaml
topics:
  - name: my-topic
    partitions: 3
    replication_factor: 1
    config:
      "cleanup.policy": "delete"
      "retention.bytes": "100000000"   # 100 MB
      "retention.ms": "86400000"       # 1 day
      "segment.bytes": "10485760"      # 10 MB
      "segment.ms": "3600000"          # 1 hour
```

2. Apply the configuration:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

3. Update or add more topics by editing `topics.yaml` and running `terraform apply` again.

For detailed information about topic configuration best practices, segment vs retention alignment, and common patterns, see [terraform/README.md](terraform/README.md).

## Troubleshooting

Running into issues? Check out the [Troubleshooting Guide](docs/troubleshooting.md) for common problems and solutions.

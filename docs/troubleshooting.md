# Troubleshooting

This document contains common issues you might encounter when working with this Kafka playground and how to resolve them.

## Terraform Connection Issues

### Error: "kafka: client has run out of available brokers to talk to: EOF"

**Error Message:**
```
Error: kafka: client has run out of available brokers to talk to: EOF

  with kafka_topic.topics["test-topic"],
  on main.tf line 19, in resource "kafka_topic" "topics":
  19: resource "kafka_topic" "topics" {
```

**Cause:**

This error occurs when Terraform cannot establish a connection to the Kafka broker. Common reasons include:

1. Kafka cluster is not running
2. Kafka is still starting up (can take 10-30 seconds)
3. Port 9092 is not accessible
4. Docker networking issues

**Solution:**

Follow these steps to diagnose and fix the issue:

**Step 1: Check if Kafka is running**
```bash
docker ps | grep broker
```

You should see a container named `broker` with status `Up`.

**Step 2: If not running, start the cluster**
```bash
# Navigate to the project root directory
cd kafka-playground
docker-compose up -d
```

**Step 3: Wait for Kafka to be fully ready**
```bash
# Watch the logs until you see "started"
docker logs -f broker

# Look for this message:
# [KafkaServer id=1] started
```

Press `Ctrl+C` to stop watching logs.

**Step 4: Verify Kafka connectivity**
```bash
# Try to list topics
docker exec -it broker /opt/kafka/bin/kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092
```

If this command works, Kafka is ready.

**Step 5: Verify port mapping**
```bash
docker ps | grep broker
```

You should see `0.0.0.0:9092->9092/tcp` in the output.

**Step 6: Retry Terraform**
```bash
cd terraform
terraform apply
```

**Quick Fix:**
```bash
# All-in-one command sequence
docker-compose up -d && \
sleep 15 && \
cd terraform && \
terraform apply
```

## Docker Compose Issues

### Container Exits Immediately After Starting

**Symptoms:**
- `docker ps` shows no running containers
- `docker-compose up` shows errors

**Solution:**

Check the logs:
```bash
docker-compose logs broker
```

Look for specific error messages and refer to the relevant sections below.

### Port Already in Use

**Error Message:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:9092: bind: address already in use
```

**Cause:**

Another process is already using port 9092 or 8080.

**Solution:**

Find and stop the process using the port:
```bash
# On macOS/Linux
lsof -i :9092
lsof -i :8080

# Kill the process (replace PID with actual process ID)
kill -9 PID
```

Or change the port mapping in `docker-compose.yml`:
```yaml
ports:
  - "9093:9092"  # Use 9093 on host instead
```

Remember to update your Terraform provider configuration to use the new port.

## Redpanda Console Issues

### Console Shows "No Brokers Available"

**Cause:**

Redpanda Console cannot connect to the Kafka broker.

**Solution:**

1. Ensure the broker container is running:
```bash
docker ps | grep broker
```

2. Check if Console is using the correct broker address:
```bash
docker exec redpanda-console env | grep KAFKA_BROKERS
```

Should show: `KAFKA_BROKERS=broker:29092`

3. Verify network connectivity:
```bash
docker exec redpanda-console ping broker
```

4. Restart the Console:
```bash
docker-compose restart redpanda-console
```

## Topic Management Issues

### Topics Not Being Created

**Symptoms:**
- Terraform apply succeeds but topics don't appear

**Solution:**

1. Verify Terraform state:
```bash
cd terraform
terraform state list
```

2. Check actual topics in Kafka:
```bash
docker exec -it broker /opt/kafka/bin/kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092
```

3. If mismatch exists, check Terraform output for errors:
```bash
terraform apply -auto-approve
```

### Cannot Delete Topics

**Error Message:**
```
Topic is marked for deletion
```

**Cause:**

Kafka's topic deletion is asynchronous.

**Solution:**

Wait a few seconds and check again:
```bash
# Wait and check
sleep 5
docker exec -it broker /opt/kafka/bin/kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092
```

If topic persists, check the broker configuration for `delete.topic.enable=true`.

## Performance Issues

### High Memory Usage

**Cause:**

Kafka's default JVM heap settings might be too high for local development.

**Solution:**

Add heap size limits to `docker-compose.yml`:
```yaml
environment:
  KAFKA_HEAP_OPTS: "-Xmx512M -Xms512M"
```

### Slow Message Processing

**Symptoms:**
- Producer/Consumer operations are slow
- High latency

**Solution:**

1. Check if Kafka has enough resources:
```bash
docker stats broker
```

2. Reduce partition count for local testing
3. Adjust consumer/producer batch settings
4. Ensure your Docker Desktop has adequate CPU/memory allocated

## Getting More Help

If you encounter an issue not covered here:

1. Check the Kafka logs:
```bash
docker logs broker --tail 100
```

2. Check Redpanda Console logs:
```bash
docker logs redpanda-console --tail 100
```

3. Verify your configuration files:
   - `docker-compose.yml`
   - `terraform/main.tf`
   - `terraform/topics.yaml`

4. Restart everything from scratch:
```bash
docker-compose down -v
docker-compose up -d
```

Note: The `-v` flag removes volumes, giving you a completely fresh start.


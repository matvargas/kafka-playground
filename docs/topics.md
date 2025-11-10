# Kafka Topic Management with Terraform

This directory contains Terraform configuration for declarative Kafka topic management.

## Files

- **`main.tf`**: Terraform configuration defining the Kafka provider and topic resources
- **`topics.yaml`**: YAML file for declaratively defining your topics

## Quick Start

1. Ensure your Kafka cluster is running:
```bash
cd ..
docker-compose up -d
```

2. Define your topics in `topics.yaml`:

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

3. Apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

4. Update or add more topics by editing `topics.yaml` and running `terraform apply` again.

## Kafka Best Practices

### Understanding Segment vs Retention Configuration

When configuring Kafka topics, it's critical to properly align segment and retention settings. Misalignment can lead to unexpected behavior and storage issues.

#### The Problem

Kafka deletes data at the **segment level**, not at the message level. This means:

- **Retention policies** define WHAT to keep (the goal)
- **Segment settings** define HOW to enforce it (the mechanism)

#### Bad Configuration Example

```yaml
retention.bytes: "100000000"   # Goal: Keep 100MB
segment.bytes: "1073741824"    # Default: 1GB segments
```

**What happens:**
- Kafka won't delete data until a segment reaches 1GB or closes due to time
- Your partition could grow to 1GB even though retention is set to 100MB
- You exceed your retention goal by 10x!

#### Good Configuration Example

```yaml
retention.bytes: "100000000"   # Goal: Keep 100MB
retention.ms: "86400000"       # Goal: Keep 1 day
segment.bytes: "10485760"      # Mechanism: 10MB segments (10% of retention)
segment.ms: "3600000"          # Mechanism: Close segments every 1 hour
```

**What happens:**
- Segments close every 10MB or 1 hour (whichever comes first)
- Kafka can delete old segments more frequently and granularly
- Your retention policy is enforced as expected
- You maintain ~10 segments at any time

#### Key Rules

1. **Always set BOTH retention and segment configs explicitly**
   - Don't rely on defaults (1GB segments might be too large)
   
2. **Segment size should be ≤ 10-20% of retention size**
   - For 100MB retention → 10MB segments
   - For 1GB retention → 100MB segments

3. **Consider both time and size-based settings**
   - `retention.bytes` + `segment.bytes` for size control
   - `retention.ms` + `segment.ms` for time control
   - Kafka uses whichever limit is reached first

4. **Default values if not specified:**
   - `segment.bytes`: 1GB (1073741824 bytes)
   - `segment.ms`: 7 days (604800000 ms)
   - `retention.bytes`: -1 (infinite)
   - `retention.ms`: 7 days (168 hours)

#### Why This Matters

- **Storage predictability**: Prevent partitions from growing beyond intended limits
- **Cleanup frequency**: Smaller segments = more frequent cleanup opportunities
- **Performance**: Properly sized segments improve broker performance
- **Cost control**: Better storage management = lower infrastructure costs

## Common Topic Configurations

### High-Throughput Topic
```yaml
- name: high-throughput-topic
  partitions: 10
  replication_factor: 1
  config:
    "cleanup.policy": "delete"
    "retention.bytes": "5368709120"      # 5 GB
    "retention.ms": "259200000"          # 3 days
    "segment.bytes": "536870912"         # 512 MB
    "segment.ms": "3600000"              # 1 hour
    "compression.type": "snappy"
```

### Compacted Topic (for state/changelog)
```yaml
- name: state-topic
  partitions: 5
  replication_factor: 1
  config:
    "cleanup.policy": "compact"
    "min.compaction.lag.ms": "60000"     # 1 minute
    "segment.bytes": "104857600"         # 100 MB
    "segment.ms": "3600000"              # 1 hour
```

### Small Event Topic
```yaml
- name: small-events
  partitions: 1
  replication_factor: 1
  config:
    "cleanup.policy": "delete"
    "retention.bytes": "10485760"        # 10 MB
    "retention.ms": "3600000"            # 1 hour
    "segment.bytes": "1048576"           # 1 MB
    "segment.ms": "300000"               # 5 minutes
```

## Cleanup

To destroy all managed topics:

```bash
terraform destroy
```

**Warning**: This will delete all topics defined in your `topics.yaml` file!


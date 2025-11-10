terraform {
  required_providers {
    kafka = {
      source  = "Mongey/kafka"
      version = "~> 0.7"
    }
  }
}

provider "kafka" {
  bootstrap_servers = ["localhost:9092"]
}

locals {
  topics_config = yamldecode(file("${path.module}/topics.yaml"))
}

# Loop over the topics defined in topics.yaml
resource "kafka_topic" "topics" {
  for_each = {
    for topic in local.topics_config.topics : topic.name => topic
  }

  name               = each.value.name
  partitions         = each.value.partitions
  replication_factor = each.value.replication_factor

  config = lookup(each.value, "config", {})
}
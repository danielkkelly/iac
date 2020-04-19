# TODO: cloudwatch alarm at 85% of KafkaDataLogsDiskUsed

provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet_ids" "msk_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Type = "private"
    MSK = 1
  }
}

data "aws_subnet" "msk_subnet_id" {
  for_each = data.aws_subnet_ids.msk_subnet_ids.ids
  id       = each.value
}

resource "aws_security_group" "msk_sg" {
  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_kms_key" "msk_kms" {
  description = "platform-msk"
}

resource aws_cloudwatch_log_group log_group_msk {
  name              = "platform-msk"
  retention_in_days = 14
}

resource "aws_msk_cluster" "platform_msk" {
  cluster_name           = "platform-msk"
  kafka_version          = "2.2.1"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    ebs_volume_size = 1000
    client_subnets = [for s in data.aws_subnet.msk_subnet_id : s.id]
    security_groups = [aws_security_group.msk_sg.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk_kms.arn
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.log_group_msk.name
      }
    }
  }

  tags = {
    Environment = var.env
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.platform_msk.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.platform_msk.bootstrap_brokers_tls
}
# TODO: cloudwatch alarm at 85% of KafkaDataLogsDiskUsed

provider "aws" {
  region  = var.region
  profile = var.env
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
    MSK  = 1
  }
}

data "aws_subnet" "msk_subnet_id" {
  for_each = data.aws_subnet_ids.msk_subnet_ids.ids
  id       = each.value
}

// open to specific private networks that will use the service
locals {
  ingress_cidr_blocks = [var.cidr_block_subnet_pri_1,
    var.cidr_block_subnet_pri_2,
  var.cidr_block_subnet_vpn_1]
}

resource "aws_security_group" "msk_sg" {
  vpc_id      = data.aws_vpc.vpc.id
  name        = "platform-msk"
  description = "Kafka from private networks and vpn"

  // brokers use TLS
  ingress {
    from_port = 9094
    to_port   = 9094
    protocol  = "tcp"

    cidr_blocks = local.ingress_cidr_blocks
  }

  // zookeeper
  ingress {
    from_port = 2181
    to_port   = 2181
    protocol  = "tcp"

    cidr_blocks = local.ingress_cidr_blocks
  }

  tags = {
    Name        = "platform-msk"
    Environment = var.env
  }
}

data "aws_kms_key" "msk_kms_key" {
  key_id = "alias/${var.env}-msk"
}

resource "aws_cloudwatch_log_group" "log_group_msk" {
  name              = "platform-msk"
  retention_in_days = 14
}

resource "aws_msk_cluster" "platform_msk" {
  cluster_name           = "platform-msk"
  kafka_version          = "2.8.1"
  number_of_broker_nodes = length(var.brokers)

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    ebs_volume_size = 1000
    client_subnets  = [for s in data.aws_subnet.msk_subnet_id : s.id]
    security_groups = [aws_security_group.msk_sg.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = data.aws_kms_key.msk_kms_key.arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
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

data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

locals {
  msk_broker_names = split(",", aws_msk_cluster.platform_msk.bootstrap_brokers_tls)
  dns_broker_names = {
    for broker in var.brokers : index(var.brokers, broker) => broker
  }
}

resource "aws_route53_record" "msk" {
  for_each = local.dns_broker_names
  zone_id  = data.aws_route53_zone.private.zone_id
  name     = "${each.value}.${data.aws_route53_zone.private.name}"
  type     = "CNAME"
  ttl      = "300"
  records  = [trimsuffix(element(local.msk_broker_names, each.key), ":9094")]
}
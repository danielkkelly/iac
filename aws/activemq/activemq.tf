locals {
  name = "platform-mq"
}

provider "aws" {
  region  = var.region
  profile = var.env
}

resource "aws_security_group" "broker_sg" {
  name        = local.name
  description = "Managed by Terraform"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = var.ingress
    description = "MQ port"
    from_port   = 61616
    protocol    = "tcp"
    self        = false
    to_port     = 61616
  }
}

resource "aws_mq_configuration" "broker_configuration" {
  description    = local.name
  name           = local.name

  data = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <plugins>
    <forcePersistencyModeBrokerPlugin persistenceFlag="true"/>
    <statisticsBrokerPlugin/>
    <timeStampingBrokerPlugin ttlCeiling="86400000" zeroExpirationOverride="86400000"/>
  </plugins>
</broker>
DATA
  
  engine_type        = "ActiveMQ"
  engine_version     = "5.15.9"

  tags = {
    Name        = local.name
    Environment = var.env
  }
}

resource "aws_mq_broker" "broker" {
  broker_name = local.name

  configuration {
    id       = aws_mq_configuration.broker_configuration.id
  }

  engine_type        = "ActiveMQ"
  engine_version     = "5.15.9"
  storage_type       = "ebs"
  host_instance_type = "mq.m5.large"
  security_groups    = [aws_security_group.broker_sg.id]


  user {
    username = var.username
    password = var.password
  }

  maintenance_window_start_time {
    day_of_week = var.maintenance_window_start_time["day_of_week"]
    time_of_day = var.maintenance_window_start_time["time_of_day"]
    time_zone   = var.maintenance_window_start_time["time_zone"]
  }

  tags = {
    Name        = local.name
    Environment = var.env
  }
}

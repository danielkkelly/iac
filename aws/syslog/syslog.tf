provider "aws" {
  region  = var.region
  profile = var.env
}

locals {
  private_ip = cidrhost(data.aws_subnet.subnet_syslog.cidr_block, var.host_number)
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet" "subnet_syslog" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Type   = "private"
    Syslog = "1"
  }
}

data "aws_security_group" "bastion_sg" {
  tags = {
    Name = "platform-bastion"
  }
}

resource "aws_security_group" "syslog_sg" {

  vpc_id      = data.aws_vpc.vpc.id
  name        = "platform-syslog"
  description = "SSH from bastion server and private subnets"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    security_groups = [data.aws_security_group.bastion_sg.id]

    cidr_blocks = [
      var.cidr_block_subnet_vpn_1
    ]
  }

  ingress {
    from_port = 514
    to_port   = 514
    protocol  = "tcp"

    // open only to bastion server on the public subnets
    security_groups = [data.aws_security_group.bastion_sg.id]

    // open to any on the private subnets
    cidr_blocks = [
      var.cidr_block_subnet_pri_1,
      var.cidr_block_subnet_pri_2
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "platform-syslog"
    Environment = var.env
  }
}

module "syslog_instance" {
  source                 = "../ec2-instance"
  env                    = var.env
  key_pair_name          = var.key_pair_name
  host_type              = "syslog"
  instance_type          = var.instance_type
  volume_size            = var.volume_size
  private_ip             = local.private_ip
  subnet_id              = data.aws_subnet.subnet_syslog.id
  vpc_security_group_ids = [aws_security_group.syslog_sg.id]
}
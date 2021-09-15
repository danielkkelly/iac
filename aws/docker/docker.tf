provider "aws" {
  region  = var.region
  profile = var.env
}

locals {
  private_ip = cidrhost(data.aws_subnet.subnet_docker.cidr_block, var.host_number)
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet" "subnet_docker" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Type   = "private"
    Docker = "1"
  }
}

data "aws_security_group" "bastion_sg" {
  tags = {
    Name = "platform-bastion"
  }
}

resource "aws_security_group" "docker_sg" {
  vpc_id      = data.aws_vpc.vpc.id
  name        = "platform-docker"
  description = "SSH from bastion server and VPN"

  tags = {
    Name        = "platform-docker"
    Environment = var.env
  }
}

resource "aws_security_group_rule" "bastion_sgr" {
  for_each                 = toset(var.ingress_ports)
  type                     = "ingress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.docker_sg.id
}

resource "aws_security_group_rule" "vpn_mgmt_sgr" {
  for_each          = toset(var.ingress_ports)
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block_subnet_vpn_1]
  security_group_id = aws_security_group.docker_sg.id
}

resource "aws_security_group_rule" "egress_sgr" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.docker_sg.id
}

module "docker_instance" {
  source                 = "../ec2-instance"
  env                    = var.env
  key_pair_name          = var.key_pair_name
  host_type              = "docker"
  instance_type          = var.instance_type
  volume_size            = var.volume_size
  private_ip             = local.private_ip
  subnet_id              = data.aws_subnet.subnet_docker.id
  vpc_security_group_ids = [aws_security_group.docker_sg.id]
}
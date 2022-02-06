# Based on https://aws.amazon.com/articles/leveraging-multiple-ip-addresses-for-virtual-ip-address-fail-over-in-6-simple-steps/
# This could become its own module for active-passive ec2 instances as another abstraction.  
# For now this is specific to an HA syslog implementation.  TODO: make into a generic module, ec2-ha-instances.

#TODO:
# add instance role
# add secondary ip 
# create instances
# test by manually implementing monitoring script
# add monitoring via ansible

provider "aws" {
  region  = var.region
  profile = var.env
}

locals {
  host1_ip = cidrhost(data.aws_subnet.subnet_syslog.cidr_block, var.host1_number)
  host2_ip = cidrhost(data.aws_subnet.subnet_syslog.cidr_block, var.host2_number)
  vip      = cidrhost(data.aws_subnet.subnet_syslog.cidr_block, var.vip_number)
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
  name        = "platform-syslog-ha"
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
    Name        = "platform-syslog-ha"
    Environment = var.env
  }
}

module "syslog_ha_instance1" {
  source                 = "../ec2-instance"
  env                    = var.env
  key_pair_name          = var.key_pair_name
  host_type              = "syslog-ha1"
  instance_type          = var.instance_type
  volume_size            = var.volume_size
  private_ip             = local.host1_ip
  secondary_private_ips  = [local.vip]
  subnet_id              = data.aws_subnet.subnet_syslog.id
  vpc_security_group_ids = [aws_security_group.syslog_sg.id]
  instance_profile_name = "platform-${var.env}-ec2-ha-profile" 
}

module "syslog_ha_instance2" {
  source                 = "../ec2-instance"
  env                    = var.env
  key_pair_name          = var.key_pair_name
  host_type              = "syslog-ha2"
  instance_type          = var.instance_type
  volume_size            = var.volume_size
  private_ip             = local.host2_ip
  subnet_id              = data.aws_subnet.subnet_syslog.id
  vpc_security_group_ids = [aws_security_group.syslog_sg.id]
  instance_profile_name = "platform-${var.env}-ec2-ha-profile" 
}
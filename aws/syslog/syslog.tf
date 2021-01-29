provider "aws" {
  region  = var.region
  profile = var.env
}

module "default_ami" {
  source = "../ami"
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

data "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "platform-${ var.env }-ec2-ssm-profile"
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
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "platform-syslog"
    Environment = var.env
  }
}

resource "aws_instance" "syslog" {
  ami                  = module.default_ami.id
  instance_type        = "t2.micro"
  key_name             = var.key_pair_name
  subnet_id            = data.aws_subnet.subnet_syslog.id
  security_groups      = [aws_security_group.syslog_sg.id]
  private_ip           = local.private_ip
  iam_instance_profile = data.aws_iam_instance_profile.ec2_ssm_profile.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = var.volume_size
    encrypted   = true
  }

  tags = {
    Name          = "platform-syslog"
    HostType      = "syslog"
    Environment   = var.env
    "Patch Group" = var.env
  }
}

data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

resource "aws_route53_record" "syslog" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "syslog.${data.aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [local.private_ip]
}
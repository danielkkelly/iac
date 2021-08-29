provider "aws" {
  region  = var.region
  profile = var.env
}

module "default_ami" {
  source = "../ami"
}

locals {
  private_ip = cidrhost(data.aws_subnet.subnet_bastion.cidr_block, var.host_number)
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

/* 
 * The AWS bastion server really acts as a dev server that resides on a private network
 * vs. the traditional bastion server, which is on a public network and is given access
 * to VMs on private networks.  Comment out the EIP below if you'd like to go the 
 * traditional route.
 */
data "aws_subnet" "subnet_bastion" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Type    = var.is_public ? "public" : "private"
    Bastion = "1"
  }
}

/* Only created if is_public is set to true in variables.tf, otherwise no EIP created */
resource "aws_eip" "bastion_eip" {
  count                     = var.is_public ? 1 : 0
  vpc                       = true
  instance                  = aws_instance.bastion.id
  associate_with_private_ip = local.private_ip

  tags = {
    Name        = "platform-bastion"
    Environment = var.env
  }
}

data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

data "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "platform-${var.env}-ec2-ssm-profile"
}

resource "aws_security_group" "bastion_sg" {

  vpc_id      = data.aws_vpc.vpc.id
  name        = "platform-bastion"
  description = "SSH from world"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = var.cidr_blocks_ingress
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "platform-bastion"
    Environment = var.env
  }
}

resource "aws_instance" "bastion" {
  ami                    = module.default_ami.id
  instance_type          = "t2.nano"
  key_name               = var.key_pair_name
  subnet_id              = data.aws_subnet.subnet_bastion.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  private_ip             = local.private_ip
  iam_instance_profile   = data.aws_iam_instance_profile.ec2_ssm_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name          = "platform-bastion"
    HostType      = "bastion"
    Environment   = var.env
    "Patch Group" = var.env
    Backup        = "1"
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "bastion.${data.aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [local.private_ip]
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}
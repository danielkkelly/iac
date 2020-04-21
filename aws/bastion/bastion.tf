provider "aws" {
  region = var.region
}

module "default_ami" {
  source = "../ami"
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet" "subnet_bastion" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Type    = "public"
    Bastion = "1"
  }
}

data "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "platform-ec2-ssm-profile"
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
  ami                  = module.default_ami.id
  instance_type        = "t2.nano"
  key_name             = var.key_pair_name
  subnet_id            = data.aws_subnet.subnet_bastion.id
  security_groups      = [aws_security_group.bastion_sg.id]
  private_ip           = var.private_ip
  iam_instance_profile = data.aws_iam_instance_profile.ec2_ssm_profile.name

  tags = {
    Name          = "platform-bastion"
    HostType      = "bastion"
    Environment   = var.env
    "Patch Group" = var.env
  }
}

resource "aws_eip" "bastion_eip" {
  vpc                       = true
  instance                  = aws_instance.bastion.id
  associate_with_private_ip = var.private_ip

  tags = {
    Name        = "platform-bastion"
    Environment = var.env
  }
}

data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "bastion.${data.aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [var.private_ip]
}

output "bastion_public_ip" {
  value = aws_eip.bastion_eip.public_ip
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}
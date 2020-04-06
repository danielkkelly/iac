provider "aws" {
  region = var.region
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

    cidr_blocks = ["0.0.0.0/0"]
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
  ami                  = "ami-0e38b48473ea57778"
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

output "bastion_public_ip" {
  value = aws_eip.bastion_eip.public_ip
}

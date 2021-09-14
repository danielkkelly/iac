provider "aws" {
  region  = var.region
  profile = var.env
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
  instance                  = module.bastion_instance.instance_id
  associate_with_private_ip = local.private_ip

  tags = {
    Name        = "platform-bastion"
    Environment = var.env
  }
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

module "bastion_instance" {
  source                 = "../ec2-instance"
  env                    = var.env
  key_pair_name          = var.key_pair_name
  host_type              = "bastion"
  instance_type          = "t2.nano"
  private_ip             = local.private_ip
  subnet_id              = data.aws_subnet.subnet_bastion.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

}

output "bastion_instance_id" {
  value = module.bastion_instance.instance_id
}
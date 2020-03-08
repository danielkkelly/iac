provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  tags = {
    Name	= "platform-vpc"
  }
}

data "aws_subnet" "subnet_pub_1" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Type 	= "public"
    Number	= "1"
  }
}

resource "aws_security_group" "bastion_sg" {
 
  vpc_id        = data.aws_vpc.vpc.id
  name          = "sg-platform-bastion"
  description   = "Allows SSH"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"] 
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_network_interface" "bastion_ni" {
  subnet_id 	= data.aws_subnet.subnet_pub_1.id
  private_ips 	= ["10.0.1.2"]
  tags = {
    Name = "platform-bastion-ni"
  }
}
 
resource "aws_instance" "bastion" {
  ami 			= "ami-0e38b48473ea57778"
  instance_type 	= "t2.nano"
  key_name 		= "aws-kp-admin"
  subnet_id 		= data.aws_subnet.subnet_pub_1.id
  security_groups 	= [aws_security_group.bastion_sg.id]
 
  network_interface {
    network_interface_id = aws_network_interface.bastion_ni.id
    device_index 	= 0
  }
 
  tags = {
    Name 	= "platform-bastion"
    HostType	= "bastion"
    Environment = var.env
  }
}

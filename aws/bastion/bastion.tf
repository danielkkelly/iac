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
  name          = "platform-bastion"
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

  tags = {
    Name 			= "platform-bastion"
    Environment			= var.env
  }
}
 
resource "aws_instance" "bastion" {
  ami 			= "ami-0e38b48473ea57778"
  instance_type 	= "t2.nano"
  key_name 		= "aws-ec2-user"
  subnet_id 		= data.aws_subnet.subnet_pub_1.id
  security_groups 	= [aws_security_group.bastion_sg.id]
  private_ip 		= var.private_ip
 
  tags = {
    Name 		= "platform-bastion"
    HostType		= "bastion"
    Environment 	= var.env
  }
}

resource "aws_eip" "bastion_eip" {
  vpc				= true
  instance			= aws_instance.bastion.id
  associate_with_private_ip	= var.private_ip

  tags = {
    Name 			= "platform-bastion"
    Environment			= var.env
  }
}

output "bastion_public_ip" {
  value 	= aws_eip.bastion_eip.public_ip
}

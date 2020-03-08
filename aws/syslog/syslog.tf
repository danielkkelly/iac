provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  tags = {
    Name        = "platform-vpc"
  }
}

data "aws_subnet" "subnet_pri_1" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Type        = "private"
    Number      = "1"
  }
}

data "aws_security_group" "bastion_sg" {
  tags = {
    Name 	= "platform-bastion"
  }
}
 
resource "aws_security_group" "syslog_sg" {
 
  vpc_id        = data.aws_vpc.vpc.id
  name          = "platform-syslog"
  description   = "SSH from bastion server"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
 
    security_groups = [data.aws_security_group.bastion_sg.id]
  }
 
  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
 
    security_groups = [data.aws_security_group.bastion_sg.id]
  }

  tags = {
    Name 	= "platform-syslog"
    Environment = var.env
  }
}
 
resource "aws_instance" "syslog" {
  ami 		= "ami-0e38b48473ea57778"
  instance_type = "t2.micro"
  key_name 	= "aws-ec2-user"
  subnet_id 	= data.aws_subnet.subnet_pri_1.id
  security_groups = [aws_security_group.syslog_sg.id]
  private_ip	= var.private_ip 
 
  tags = {
    Name 	= "platform-syslog"
    HostType 	= "syslog"
    Environment = var.env
  }
}

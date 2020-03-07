provider "aws" {
  region = var.region
}
 
resource "aws_security_group" "syslog_sg" {
 
  vpc_id        = var.vpc_id
  name          = "Syslog Server"
  description   = "SSH from bastion server"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
 
    security_groups = [var.bastion_sg]
  }
 
  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
 
    security_groups = [var.bastion_sg]
  }
 
  # Enable if Internet access is required (reverted)
  #
  #  egress {
  #    from_port   = 0
  #    to_port     = 0
  #    protocol    = "-1"
  #    cidr_blocks = ["0.0.0.0/0"]
  #}
}
 
resource "aws_network_interface" "syslog_ni" {
  subnet_id = var.subnet_private_1_id
  private_ips = ["10.0.1.50"]
  tags {
    Name = "Syslog Server PNI"
  }
}
 
resource "aws_instance" "syslog" {
  ami = "ami-0e38b48473ea57778"
  instance_type = "t2.micro"
  key_name = "aws-kp-admin"
  subnet_id = var.subnet_private_1_id
  security_groups = [aws_security_group.syslog_sg.id]
 
  network_interface {
    network_interface_id = aws_network_interface.syslog_ni.id
    device_index = 0
  }
 
  tags = {
    Name = "Syslog Server"
    host-type = "syslog"
  }
}

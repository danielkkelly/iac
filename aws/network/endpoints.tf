resource "aws_security_group" "ec2_endpoint_sg" {

  vpc_id      = aws_vpc.vpc.id
  name        = "platform-ec2-endpoint"
  description = "Allow from private subnets"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [var.cidr_block_subnet_pri_1, var.cidr_block_subnet_pri_2]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "platform-ec2-endpoint"
    Environment = var.env
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  subnet_ids          = [aws_subnet.subnet_pri_1.id, aws_subnet.subnet_pri_2.id]
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ec2_endpoint_sg.id]
  private_dns_enabled = true
}
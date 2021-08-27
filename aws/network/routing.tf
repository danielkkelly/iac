/* 
 * Adds an Internet gatway and associated it with the routing table for public subnets.
 * Hosts on public subnets will be addressable from the Internet.  As a result, these
 * subnets should be used carefully and apps should be run on the private subnets 
 * instead.
  */
resource "aws_internet_gateway" "platform_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Environment = var.env
    Name        = "platform-igw"
  }
}

resource "aws_route_table" "rt_pub" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.platform_igw.id
  }

  tags = {
    Environment = var.env
    Name        = "platform-rt-pub"
  }
}

resource "aws_route_table_association" "rta_subnet_pub_1" {
  subnet_id      = aws_subnet.subnet_pub_1.id
  route_table_id = aws_route_table.rt_pub.id
}

resource "aws_route_table_association" "rta_subnet_pub_2" {
  subnet_id      = aws_subnet.subnet_pub_2.id
  route_table_id = aws_route_table.rt_pub.id
}

/*
 * Sets up a NAT gateway and associates it to the routing table for private subnets.
 * These subnets will have the ability to initiate connections to the Internet but
 * cannot be reached from hosts on the Internet.  This allows these EC2 instnaces to
 * update software, etc.
 */
resource "aws_eip" "platform_ngw_eip" {
  vpc = true

  tags = {
    Name        = "platform-ngw"
    Environment = var.env
  }
}

resource "aws_nat_gateway" "platform_ngw" {
  allocation_id = aws_eip.platform_ngw_eip.id
  subnet_id     = aws_subnet.subnet_pub_1.id

  tags = {
    Name        = "platform-ngw"
    Environment = var.env
  }

  depends_on = [aws_internet_gateway.platform_igw]
}

resource "aws_route_table" "rt_pri" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.platform_ngw.id
  }

  tags = {
    Environment = var.env
    Name        = "platform-rt-pri"
  }
}

resource "aws_route_table_association" "rta_subnet_pri_1" {
  subnet_id      = aws_subnet.subnet_pri_1.id
  route_table_id = aws_route_table.rt_pri.id
}

resource "aws_route_table_association" "rta_subnet_pri_2" {
  subnet_id      = aws_subnet.subnet_pri_2.id
  route_table_id = aws_route_table.rt_pri.id
}
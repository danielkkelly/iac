provider "aws" {
  region     = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block 		= var.cidr_block_vpc
  enable_dns_support   	= true
  enable_dns_hostnames 	= true
  tags = {
    Name		= "platform-vpc"
    Environment 	= var.env
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet_pub_1" {
  vpc_id 		= aws_vpc.vpc.id
  cidr_block 		= var.cidr_block_subnet_pub_1
  availability_zone 	= data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = "true"
  tags = {
    Name 		= "subnet-pub-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment 	= var.env
    Type 		= "public"
    Number		= "1"
  }
}

resource "aws_subnet" "subnet_pub_2" {
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.cidr_block_subnet_pub_2
  availability_zone     = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = "true"
  tags = {
    Name 		= "subnet-pub-2-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment         = var.env
    Type                = "public"
    Number		= "2"
  }
}

resource "aws_subnet" "subnet_pri_1" {
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.cidr_block_subnet_pri_1
  availability_zone     = data.aws_availability_zones.available.names[0]
  tags = {
    Name 		= "subnet-pri-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment         = var.env
    Type                = "private"
    Number		= "1"
  }
}

resource "aws_subnet" "subnet_pri_2" {
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.cidr_block_subnet_pri_2
  availability_zone     = data.aws_availability_zones.available.names[1]
  tags = {
    Name 		= "subnet-pri-2-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment         = var.env
    Type                = "private"
    Number		= "2"
  }
}

resource "aws_internet_gateway" "platform_igw" {
  vpc_id 		= aws_vpc.vpc.id
  tags = {
    Environment 	= var.env
    Name		= "platform-igw"
  }
}

resource "aws_route_table" "rt_pub" {
  vpc_id 		= aws_vpc.vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.platform_igw.id
  }
  tags = {
    Environment 	= var.env
    Name 		= "platform-rt-pub"
  }
}

resource "aws_route_table_association" "rta_subnet_pub_1" {
  subnet_id      	= aws_subnet.subnet_pub_1.id
  route_table_id 	= aws_route_table.rt_pub.id
}

resource "aws_route_table_association" "rta_subnet_pub_2" {
  subnet_id             = aws_subnet.subnet_pub_2.id
  route_table_id        = aws_route_table.rt_pub.id
}




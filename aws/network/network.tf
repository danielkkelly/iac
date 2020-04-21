provider "aws" {
  region = var.region
}

/* 
 * Creates a VPC with six subnets.  Two public subnets with access to an Internet gateway,
 * two private subnets for apps, and two for RDS.  App subnets have access to a NAT
 * gateway.
 */
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "platform-vpc"
    Type        = "platform-vpc"
    Environment = var.env
  }
}

// gets a list of availability zones.  We'll spread our networks across zones for 
// reliability
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet_pub_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_block_subnet_pub_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "subnet-pub-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment = var.env
    Type        = "public"
    Number      = "1"
    Bastion     = "1"
  }
}

resource "aws_subnet" "subnet_pub_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_block_subnet_pub_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = "true"
  tags = {
    Name        = "subnet-pub-2-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment = var.env
    Type        = "public"
    Number      = "2"
  }
}

resource "aws_subnet" "subnet_pri_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_pri_1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name        = "subnet-pri-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment = var.env
    Type        = "private"
    Number      = "1"
    Syslog      = "1"
    MSK         = "1"
  }
}

resource "aws_subnet" "subnet_pri_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_pri_2
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name        = "subnet-pri-2-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment = var.env
    Type        = "private"
    Number      = "2"
    Docker      = "1"
    MSK         = "1"
  }
}

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
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.platform_ngw.id
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

/*
 * Subnets for RDS servers.  These servers don't have any outbound access.
 */
resource "aws_subnet" "subnet_rds_1" {
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.cidr_block_subnet_rds_1
  availability_zone     = data.aws_availability_zones.available.names[0]

  tags = {
    Name                = "subnet-rds-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment         = var.env
    Type                = "private"
    Number              = "3"
    RDS			= "1"
  }
}

resource "aws_subnet" "subnet_rds_2" {
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.cidr_block_subnet_rds_2
  availability_zone     = data.aws_availability_zones.available.names[1]

  tags = {
    Name                = "subnet-rds-1-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment         = var.env
    Type                = "private"
    Number              = "4"
    RDS                 = "1"
  }
}

/* 
 * Create a subnet (could be multiple in different zones if needed) to act as a VPN
 * endpoint.  This will host the ENIs for the VPN endpoint for easy visibility and
 * traceability of client VPN traffic.  This subnet can be ignored if you don't 
 * use a VPN
 */

 resource "aws_subnet" "subnet_vpn_1" {
  vpc_id                = aws_vpc.vpc.id
  cidr_block            = var.cidr_block_subnet_vpn_1
  availability_zone     = data.aws_availability_zones.available.names[0]

  tags = {
    Name                = "subnet-vpn-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment         = var.env
    Type                = "private"
    Number              = "5"
    VPN                 = "1"
  }
}


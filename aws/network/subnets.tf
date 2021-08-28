// gets a list of availability zones.  We'll spread our networks across zones for 
// reliability
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet_pub_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_block_subnet_pub_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = "false"
  tags = {
    Name                     = "subnet-pub-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment              = var.env
    Type                     = "public"
    Bastion                  = "1" # works in conjunction with aws/bastion is_public variable
    Kubernetes               = "1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "subnet_pub_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.cidr_block_subnet_pub_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = "false"
  tags = {
    Name                     = "subnet-pub-2-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment              = var.env
    Type                     = "public"
    Kubernetes               = "1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "subnet_pri_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_pri_1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name                              = "subnet-pri-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment                       = var.env
    Type                              = "private"
    Syslog                            = "1"
    MSK                               = "1"
    Kubernetes                        = "1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "subnet_pri_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_pri_2
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name                              = "subnet-pri-2-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment                       = var.env
    Type                              = "private"
    Bastion                           = "1" # works in conjunction with aws/bastion is_public variable
    Docker                            = "1"
    MSK                               = "1"
    Kubernetes                        = "1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

/*
 * Subnets for RDS servers.  These servers don't have any outbound access.
 */
resource "aws_subnet" "subnet_rds_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_rds_1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "subnet-rds-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment = var.env
    Type        = "private"
    RDS         = "1"
  }
}

resource "aws_subnet" "subnet_rds_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_rds_2
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "subnet-rds-2-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment = var.env
    Type        = "private"
    RDS         = "1"
  }
}

/* 
 * Create a subnet (could be multiple in different zones if needed) to act as a VPN
 * endpoint.  This will host the ENIs for the VPN endpoint for easy visibility and
 * traceability of client VPN traffic.  This subnet can be ignored if you don't 
 * use a VPN
 */
resource "aws_subnet" "subnet_vpn_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_vpn_1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "subnet-vpn-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment = var.env
    Type        = "private"
    VPN         = "1"
  }
}
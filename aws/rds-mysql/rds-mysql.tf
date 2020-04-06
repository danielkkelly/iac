provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet_rds_1" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_rds_1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "subnet-rds-1-${data.aws_availability_zones.available.zone_ids[0]}"
    Environment = var.env
    Type        = "private"
    Number      = "3"
    RDS         = "1"
  }
}

resource "aws_subnet" "subnet_rds_2" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = var.cidr_block_subnet_rds_2
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "subnet-rds-1-${data.aws_availability_zones.available.zone_ids[1]}"
    Environment = var.env
    Type        = "private"
    Number      = "4"
    RDS         = "1"
  }
}

resource "aws_db_subnet_group" "subnet_group_rds" {
  name       = "platform-rds"
  subnet_ids = [aws_subnet.subnet_rds_1.id, aws_subnet.subnet_rds_2.id]

  tags = {
    Name = "platform-rds"
  }
}

data "aws_security_group" "bastion_sg" {
  tags = {
    Name = "platform-bastion"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id      = data.aws_vpc.vpc.id
  name        = "platform-rds"
  description = "MySQL from bastion"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    security_groups = [data.aws_security_group.bastion_sg.id]
  }

  tags = {
    Name        = "platform-rds"
    Environment = var.env
  }
}

resource "aws_rds_cluster_parameter_group" "platform_rds_cluster_pg" {
  name   = "platform-rds"
  family = "aurora-mysql5.7"

  parameter {
    name         = "lower_case_table_names"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_rds_cluster" "platform_rds_cluster" {
  cluster_identifier = "platform-rds-cluster"

  engine         = "aurora-mysql"
  engine_version = "5.7.mysql_aurora.2.07.1"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  /*
  availability_zones      = [data.aws_availability_zones.available.zone_ids[0], 
                             data.aws_availability_zones.available.zone_ids[1],
                             data.aws_availability_zones.available.zone_ids[2]]
*/
  db_subnet_group_name = aws_db_subnet_group.subnet_group_rds.name

  master_username = "manager"
  master_password = "password"

  backup_retention_period = 5
  preferred_backup_window = "04:00-06:00"
  skip_final_snapshot     = true
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  cluster_identifier = aws_rds_cluster.platform_rds_cluster.id

  engine         = aws_rds_cluster.platform_rds_cluster.engine
  engine_version = aws_rds_cluster.platform_rds_cluster.engine_version

  identifier     = "platform-rds-cluster-${count.index}"
  count          = var.rds_instance_count
  instance_class = var.rds_instance_class
}

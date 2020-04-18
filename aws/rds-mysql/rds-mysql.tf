provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

/*
 * Find the subnets ids that are tagged for RDS, map these to subnets, and then
 * iterate through those subnet ids to build a group that can later be used on
 * instance creation
*/
data "aws_subnet_ids" "rds_subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Type = "private"
    RDS  = 1
  }
}

data "aws_subnet" "rds_subnet_id" {
  for_each = data.aws_subnet_ids.rds_subnet_ids.ids
  id       = each.value
}

resource "aws_db_subnet_group" "subnet_group_rds" {
  name       = "platform-rds"
  subnet_ids = [for s in data.aws_subnet.rds_subnet_id : s.id]

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

    // open only to the bastion server on the public subnets 
    security_groups = [data.aws_security_group.bastion_sg.id]

    // open to any on the private subnets
    cidr_blocks = [var.cidr_block_subnet_pri_1, var.cidr_block_subnet_pri_2]
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

  db_subnet_group_name            = aws_db_subnet_group.subnet_group_rds.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.platform_rds_cluster_pg.name

  master_username = var.master_username
  master_password = var.master_password

  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
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

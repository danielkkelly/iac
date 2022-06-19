provider "aws" {
  region  = var.region
  profile = var.env
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
  description = "MySQL from bastion host, app subnets, and VPN"

  ingress {
    from_port = var.mysql_port
    to_port   = var.mysql_port
    protocol  = "tcp"

    // open only to the bastion server on the public subnets 
    security_groups = [data.aws_security_group.bastion_sg.id]

    // open to any on the private subnets
    cidr_blocks = [var.cidr_block_subnet_pri_1,
      var.cidr_block_subnet_pri_2,
      var.cidr_block_subnet_vpn_1,
    ]
  }

  tags = {
    Name        = "platform-rds"
    Environment = var.env
  }
}

resource "aws_rds_cluster_parameter_group" "platform_rds_cluster_pg" {
  name        = "platform-rds-cluster"
  description = "Cluster parameter group"
  family      = "aurora-mysql5.7"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value["name"]
      value        = parameter.value["value"]
      apply_method = parameter.value["apply_method"]
    }
  }
}

resource "aws_db_parameter_group" "platform_rds_cluster_instance_pg" {
  name        = "platform-rds-instance"
  description = "Instances parameter group"
  family      = "aurora-mysql5.7"

  dynamic "parameter" {
    for_each = var.instance_parameters
    content {
      name         = parameter.value["name"]
      value        = parameter.value["value"]
      apply_method = parameter.value["apply_method"]
    }
  }
}

resource "aws_rds_cluster" "platform_rds_cluster" {
  cluster_identifier = var.rds_cluster_identifier

  engine         = "aurora-mysql"
  engine_version = "5.7.mysql_aurora.2.07.5"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  db_subnet_group_name            = aws_db_subnet_group.subnet_group_rds.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.platform_rds_cluster_pg.name

  master_username = var.master_username
  master_password = var.master_password

  # Backups and backtracking
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  backtrack_window        = var.backtrack_window_seconds

  # Snapshots
  copy_tags_to_snapshot = true
  skip_final_snapshot   = true

  # Additional security best practices
  storage_encrypted                   = true
  iam_database_authentication_enabled = true
  deletion_protection                 = var.rds_deletion_protection
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]

  # Port should be non-standard
  port = var.mysql_port

 lifecycle { /* we allow auto_minor_version_upgrade = true (defalut) so this could change */
    ignore_changes = [engine_version]
  }

  depends_on = [
    module.cluster_audit_lg,
    module.cluster_error_lg,
    module.cluster_general_lg,
    module.cluster_slowquery_lg
  ]
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  cluster_identifier = aws_rds_cluster.platform_rds_cluster.id

  engine         = aws_rds_cluster.platform_rds_cluster.engine
  engine_version = aws_rds_cluster.platform_rds_cluster.engine_version

  identifier     = "platform-rds-cluster-${count.index}"
  count          = var.rds_instance_count
  instance_class = var.rds_instance_class

  db_parameter_group_name = aws_db_parameter_group.platform_rds_cluster_instance_pg.name

  monitoring_interval = var.enhanced_monitoring_interval
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring_iam_role.arn

  tags = {
    Backup = "1"
  }

   lifecycle { /* we allow auto_minor_version_upgrade = true (defalut) so this could change */
    ignore_changes = [engine_version]
  }
}
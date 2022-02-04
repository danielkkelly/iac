provider "aws" {
  region  = var.region
  profile = var.env
}

provider "aws" {
  alias  = "replica"
  region = var.replication_region
  profile = var.env
}

locals {
  backups = {
    schedule  = "cron(0 5 ? * MON-FRI *)" /* UTC Time */
    retention = 7 // days
  }
}

resource "aws_backup_vault" "backup_vault" {
  name = "platform-backup-vault"
  tags = {
    Project = "platform"
    Role    = "backup-vault"
  }
}

resource "aws_backup_vault" "backup_vault_replica" {
  provider = aws.replica
  name = "platform-backup-vault"
  tags = {
    Project = "platform"
    Role    = "backup-vault"
  }
}

resource "aws_backup_plan" "backup_plan" {
  name = "platform-backup-plan"

  rule {
    rule_name         = "weekdays-every-2-hours-${local.backups.retention}-day-retention"
    target_vault_name = aws_backup_vault.backup_vault.name
    schedule          = local.backups.schedule
    start_window      = 60
    completion_window = 300

    lifecycle {
      delete_after = local.backups.retention
    }

    recovery_point_tags = {
      Project = "platform"
      Role    = "backup"
      Creator = "aws-backups"
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.backup_vault_replica.arn
    }
  }

  tags = {
    Project = "platform"
    Role    = "backup"
  }
}

resource "aws_backup_selection" "server_backup_selection" {
  iam_role_arn = aws_iam_role.backup_service_role.arn
  name         = "backup-resources"
  plan_id      = aws_backup_plan.backup_plan.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "1"
  }
}
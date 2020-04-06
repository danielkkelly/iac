provider "aws" {
  region = var.region
}

resource "aws_ssm_patch_baseline" "dev_ssm_patch_baseline" {
  name             = "platform-dev-patch-baseline"
  description      = "Development patch baseline"
  operating_system = "AMAZON_LINUX"

  approval_rule {
    approve_after_days = 0
    compliance_level   = "CRITICAL"

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical"]
    }
  }

  approval_rule {
    approve_after_days = 2
    compliance_level   = "HIGH"

    patch_filter {
      key    = "SEVERITY"
      values = ["Important", "Medium", "Low"]
    }
  }
}

resource "aws_ssm_patch_group" "dev_patch_group" {
  baseline_id = aws_ssm_patch_baseline.dev_ssm_patch_baseline.id
  patch_group = var.env
}

resource "aws_ssm_maintenance_window" "ssm_dev_mw" {
  name                       = "platform-dev-mw"
  schedule_timezone          = "America/New_York"
  schedule                   = var.mw_cron_dev
  duration                   = 4
  cutoff                     = 1
  allow_unassociated_targets = true
}

resource "aws_ssm_maintenance_window_target" "platform_dev_mw_target" {
  name      = "platform-dev-mw-target"
  window_id = aws_ssm_maintenance_window.ssm_dev_mw.id

  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = ["dev"]
  }
}

data "aws_iam_role" "ssm_maintenance_window_role" {
  name = "platform-ssm-maintenance-window-role"
}

resource "aws_ssm_maintenance_window_task" "platform_dev_mw_task" {
  name             = "Patching"
  max_concurrency  = 500
  max_errors       = "20%"
  priority         = 1
  service_role_arn = data.aws_iam_role.ssm_maintenance_window_role.arn
  task_arn         = "AWS-RunPatchBaseline"
  task_type        = "RUN_COMMAND"
  window_id        = aws_ssm_maintenance_window.ssm_dev_mw.id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.platform_dev_mw_target.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      timeout_seconds = 600

      parameter {
        name   = "Operation"
        values = ["Install"]
      }
    }
  }
}

output "dev_maintenance_window_id" {
  value = aws_ssm_maintenance_window.ssm_dev_mw.id
}

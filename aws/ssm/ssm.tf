provider "aws" {
  region  = var.region
  profile = var.env
}

/* 
 * Sets up System Manager to provide automatic patching to EC2 instances.  These instances are
 * configured to participate, having the correct IAM profile and Patch Group assigned.  Here 
 * we create a patch baseline for different severities, assign the baseline the appropriate 
 * patch group, which must match the Patch Group tag on the instances.  We create a maintenance
 * window, and give it target instances (by tag).  Then we assign the run command for applying
 * patch baselines.
 */

resource "aws_ssm_patch_baseline" "ssm_patch_baseline" {
  name             = "platform-${ var.env }-patch-baseline"
  description      = "Platform ${ var.env } patch baseline"
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

resource "aws_ssm_patch_group" "patch_group" {
  baseline_id = aws_ssm_patch_baseline.ssm_patch_baseline.id
  patch_group = var.env
}

resource "aws_ssm_maintenance_window" "ssm_mw" {
  name                       = "platform-${ var.env }-mw"
  schedule_timezone          = "America/New_York"
  schedule                   = var.mw_cron
  duration                   = 4
  cutoff                     = 1
  allow_unassociated_targets = true
}

resource "aws_ssm_maintenance_window_target" "platform_mw_target" {
  name      = "platform-${ var.env }-mw-target"
  window_id = aws_ssm_maintenance_window.ssm_mw.id

  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = [var.env]
  }
}

// required permission set up in ../iam
data "aws_iam_role" "ssm_maintenance_window_role" {
  name = "platform-${ var.env }-ssm-maintenance-window-role"
}

resource "aws_ssm_maintenance_window_task" "platform_mw_task" {
  name             = "Patching"
  max_concurrency  = 500
  max_errors       = "20%"
  priority         = 1
  service_role_arn = data.aws_iam_role.ssm_maintenance_window_role.arn
  task_arn         = "AWS-RunPatchBaseline"
  task_type        = "RUN_COMMAND"
  window_id        = aws_ssm_maintenance_window.ssm_mw.id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.platform_mw_target.id]
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

// useful for pull down information about the success or failure of the window
output "maintenance_window_id" {
  value = aws_ssm_maintenance_window.ssm_mw.id
}

# Borrowed approach from https://github.com/trussworks/terraform-aws-wafv2, which
# takes a more comprehensive approach.

resource "aws_wafv2_rule_group" "waf_geo_rule_group" {
  name     = "geo-rule-group"
  scope    = "REGIONAL"
  capacity = 1

  rule {
    name     = "out-of-country-rule"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["US"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "geo-rule-metric"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "geo-rule-group-metric"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl" "platform_lb_waf_web_acl" {
  name  = "platform-lb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "platform-lb-waf"
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = var.managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"

          dynamic "excluded_rule" {
            for_each = rule.value.excluded_rules
            content {
              name = excluded_rule.value
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "out-of-country-rule"
    priority = 1

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "out-of-country-rule"
      sampled_requests_enabled   = true
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.waf_geo_rule_group.arn
      }
    }
  }

  tags = {
    Environment = var.env
  }
}

resource "aws_wafv2_web_acl_association" "platform_lb_waf_acl_assoc" {
  resource_arn = aws_lb.platform_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.platform_lb_waf_web_acl.arn
}
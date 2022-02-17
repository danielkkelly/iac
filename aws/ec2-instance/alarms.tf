data "aws_sns_topic" "alarm_topic" {
  name = "platform-${var.env}-cloudwatch-alarm-topic"
}

data "aws_region" "current" {}

/* Monitor system status checks.  If there is an issue with the underlying AWS infrastructure
 * that is hosting our instance then raise a CloudWatch metric alarm and automatically attemp
 * to recover the system and alarm to an SNS topic
 */
resource "aws_cloudwatch_metric_alarm" "auto_recovery_alarm" {
  alarm_name          = "EC2 System Status Check Recovery (${var.env}-${local.host_name})"
  alarm_description   = "Recover EC2 instance on Status Check failure"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  period              = "300"
  evaluation_periods  = "1"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"

  dimensions = {
    InstanceId = aws_instance.instance.id
  }

  insufficient_data_actions = [data.aws_sns_topic.alarm_topic.arn]

  alarm_actions = [
    "arn:aws:automate:${data.aws_region.current.name}:ec2:recover",
    data.aws_sns_topic.alarm_topic.arn
  ]
}

/* Monitor VM status checks.  If there is a status check on the VM then alarm to an SNS 
 * topic
 */
resource "aws_cloudwatch_metric_alarm" "instance_statuscheck" {
  alarm_name                = "EC2 Status Check Failed (${var.env}-${local.host_name})"
  alarm_description         = "Notify when EC2 instance Status Check fails"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "StatusCheckFailed_Instance"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Maximum"
  threshold                 = "1.0"
  alarm_actions             = [data.aws_sns_topic.alarm_topic.arn]
  insufficient_data_actions = [data.aws_sns_topic.alarm_topic.arn]
  dimensions = {
    InstanceId = aws_instance.instance.id
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name                = "CPU Utilization Exceeds 80 Percent (${var.env}-${local.host_name}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120" #seconds
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_actions             = [data.aws_sns_topic.alarm_topic.arn]
  insufficient_data_actions = [data.aws_sns_topic.alarm_topic.arn]

  dimensions = {
    InstanceId = aws_instance.instance.id
  }
}


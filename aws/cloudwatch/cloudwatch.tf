provider aws {
  region = var.region
}

resource aws_sns_topic platform_sns_topic {
  name         = "platform-notification"
  display_name = "platform-notifications"
}

data aws_instance bastion {
   filter {
    name   = "tag:Name"
    values = ["platform-bastion"]
   }
}

resource "aws_cloudwatch_metric_alarm" "cma_health" {
  alarm_name                = "health-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors ec2 health status"
  alarm_actions             = [aws_sns_topic.platform_sns_topic.arn]
}

resource aws_cloudwatch_metric_alarm cma_cpu {
  alarm_name                = "cpu"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_actions             = [aws_sns_topic.platform_sns_topic.arn]
}

resource aws_cloudwatch_dashboard dashboard_bastion {
 dashboard_name = "platform-bastion"
 dashboard_body = <<EOF
{
    "widgets": [
        {
           "type":"metric",
           "x":0,
           "y":0,
           "width":12,
           "height":6,
           "properties":{
              "metrics":[
                 [
                    "AWS/EC2",
                    "CPUUtilization",
                    "InstanceId",
                    "${data.aws_instance.bastion.id}"
                 ]
              ],
              "period":300,
              "stat":"Average",
              "region":"${var.region}",
              "title":"EC2 Instance CPU"
           }
        }
    ]
  }
  EOF
}
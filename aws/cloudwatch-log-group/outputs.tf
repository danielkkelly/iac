output "name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudwatch_lg.name
}

output "arn" {
  description = "Amazon resource name for the log group"
  value       = aws_cloudwatch_log_group.cloudwatch_lg.arn
}
output "user_access_key" {
  value = [for user in module.user : user.user_access_key]
}

output "ha_monitor_role_arn" {
  value = aws_iam_role.ec2_ha_monitor_role.arn
}
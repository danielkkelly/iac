output "user_access_key" {
  value = [for user in module.user: user.user_access_key]
}
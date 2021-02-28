output "user_key_id" {
  value = [for access_key in aws_iam_access_key.user_access_key : {
    "user"                        = access_key.user,
    "access_key_id"               = access_key.id,
    "access_key_encrypted_secret" = access_key.encrypted_secret
  }]
}
output "user_access_key" {
    value = {
        "user"                        = aws_iam_access_key.user_access_key.user,
        "access_key_id"               = aws_iam_access_key.user_access_key.id,
        "access_key_encrypted_secret" = aws_iam_access_key.user_access_key.encrypted_secret
    }
}
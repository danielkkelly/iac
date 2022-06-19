output "smtp_user_access_key" {
  value = aws_iam_access_key.smtp_user_access_key.id
}

output "smtp_user_access_key_secret" {
  value = aws_iam_access_key.smtp_user_access_key.ses_smtp_password_v4
  sensitive = true
}

output "domain_identity_verification_token" {
  value = aws_ses_domain_identity.domain_identity.verification_token
}

output "domain_dkim_tokens" {
  value = aws_ses_domain_dkim.domain_dkim.dkim_tokens
}
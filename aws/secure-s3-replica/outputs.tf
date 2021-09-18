output "bucket" {
  value = aws_s3_bucket.replication_bucket.bucket
}

output "id" {
  value = aws_s3_bucket.replication_bucket.id
}

output "arn" {
  value = aws_s3_bucket.replication_bucket.arn
}

output "replication_role_arn" {
  value = aws_iam_role.replication.arn
}
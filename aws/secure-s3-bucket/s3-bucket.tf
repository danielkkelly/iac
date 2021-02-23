resource "random_id" "random_s3_index" {
  byte_length = 4
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "platform-${var.name}-${var.env}-${random_id.random_s3_index.hex}"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = var.versioning_enabled
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
/* 
 * Sets up for a secure S3 bucket.  It would be even better if we coudl add a stanza to 
 * a policy to deny all without SSL and to handle the aws_s3_bucket_public_access_block
 * here as well.
 */
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
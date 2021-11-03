// https://docs.aws.amazon.com/AmazonS3/latest/userguide/setting-repl-config-perm-overview.html

resource "aws_iam_role" "replication" {
  provider = aws.default
  name = "${var.bucket_name}-replication-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  provider = aws.default
  name = "${var.bucket_name}-replication-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Resource": "arn:aws:s3:::${local.bucket_name_replica}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectRetention",
        "s3:GetObjectLegalHold"
      ],
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}/*"
      ]    
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  provider = aws.default
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}
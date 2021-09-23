locals {
    username = "${var.username}.${var.env}"
}

resource "aws_iam_user" "user" {
  name          = local.username
  force_destroy = true
}

resource "aws_iam_access_key" "user_access_key" {
  user       = local.username
  pgp_key    = file("${var.iac_home}/keys/${var.username}-gpg.pub")
  depends_on = [aws_iam_user.user]
}
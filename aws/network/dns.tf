resource "aws_route53_zone" "private" {
  name = "${var.env}.internal"

  vpc {
    vpc_id = aws_vpc.vpc.id
  }

  tags = {
    Environment = var.env
  }
}
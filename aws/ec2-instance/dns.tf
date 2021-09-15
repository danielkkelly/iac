
data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

resource "aws_route53_record" "host_record" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "${var.host_type}.${data.aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [var.private_ip]
}
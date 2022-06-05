data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

resource "aws_route53_record" "syslog_ha_host_record" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "syslog-ha.${data.aws_route53_zone.private.name}"
  type    = "A"
  ttl     = "300"
  records = [local.vip]
}

resource "aws_route53_record" "syslog_ha_cname_record" { 
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "syslog.${data.aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_route53_record.syslog_ha_host_record.name]
}
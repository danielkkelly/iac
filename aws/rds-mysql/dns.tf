data "aws_route53_zone" "private" {
  name         = "${var.env}.internal."
  private_zone = true
}

resource "aws_route53_record" "rds_mysql" { # for general use
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "mysql.${data.aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_rds_cluster.platform_rds_cluster.endpoint]
}

resource "aws_route53_record" "rds_writer" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "db-writer.${data.aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_rds_cluster.platform_rds_cluster.endpoint]
}

resource "aws_route53_record" "rds_reader" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "db-reader.${data.aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_rds_cluster.platform_rds_cluster.reader_endpoint]
}
provider "google" {
  region = var.region
}

resource "google_dns_managed_zone" "platform_dns" {
  project     = var.project_id
  name        = "platform-dns"
  description = "platform-dns"

  dns_name   = "${var.env}.internal."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.network_id
    }
  }
}

resource "google_dns_record_set" "a_record_bastion" {
  project      = var.project_id
  name         = "bastion.${var.env}.internal."
  managed_zone = google_dns_managed_zone.platform_dns.name
  type         = "A"
  ttl          = 300
  rrdatas      = [var.private_ip_bastion]
}

resource "google_dns_record_set" "a_record_mysql" {
  project      = var.project_id
  name         = "mysql.${var.env}.internal."
  managed_zone = google_dns_managed_zone.platform_dns.name
  type         = "A"
  ttl          = 300
  rrdatas      = [var.private_ip_mysql]
}

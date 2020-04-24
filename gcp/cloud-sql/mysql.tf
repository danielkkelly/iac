provider "google" {
  credentials = file("~/iac/gcp/service-account.json")
  project     = "terraform-273919"
  region      = var.region
}

data "google_compute_network" "platform_vpc" {
  name = "platform-vpc"
}

resource "google_compute_global_address" "private_ip_block" {
  name         = "private-ip-block"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  ip_version   = "IPV4"
  prefix_length = 20
  network       = data.google_compute_network.platform_vpc.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.platform_vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

resource "google_compute_firewall" "allow_ssh" {
  name        = "allow-ssh"
  network     = data.google_compute_network.platform_vpc.name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["ssh-enabled"]
}

// ha enabled, autogrow storage, private ip?, "database flags": lower_case_table_names = 1, backups, maintwindow interval, maint window
resource "google_sql_database_instance" "platform_db" {
  name             = "platform-${var.env}"
 
  database_version = "MYSQL_5_7"
  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    disk_size         = 10  # 10 GB is the smallest disk size

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.platform_vpc.self_link
    }

    database_flags {
      name = "lower_case_table_names"
      value = "1"
    }
  }
}

resource "google_sql_user" "db_user" {
  name     = var.user
  instance = google_sql_database_instance.platform_db.name
  password = var.password
}
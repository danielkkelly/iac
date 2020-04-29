# TODO: maint and notificaiton preferences

provider "google" {
  region = var.region
}

resource "google_compute_global_address" "sql_private_ip_block" {
  project       = var.project_id
  name          = "platform-sql-ip-block"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 24
  network       = var.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_private_ip_block.name]
}

// ha enabled, backups, maintwindow interval
resource "google_sql_database_instance" "platform_db" {
  name             = "platform-db-${var.env}"
  project          = var.project_id
  database_version = "MYSQL_5_7"
  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"

    disk_size       = 10 // 10 GB is the smallest disk size
    disk_autoresize = true

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "03:15"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }

    database_flags {
      name  = "lower_case_table_names"
      value = "1"
    }

    maintenance_window {
      day  = 6
      hour = 6
    }
  }
}

resource "google_sql_user" "db_user" {
  project  = var.project_id
  instance = google_sql_database_instance.platform_db.name
  name     = var.user
  password = var.password
}
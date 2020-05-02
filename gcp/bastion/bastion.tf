provider "google" {
  region = var.region
}

resource "google_compute_address" "internal_with_subnet_and_address" {
  name         = "platform-bastion"
  project      = var.project_id
  subnetwork   = var.subnet_app_1_id
  address_type = "INTERNAL"
  address      = var.private_ip
  region       = var.region
}

resource "google_compute_address" "static" {
  name    = "platform-bastion-ipv4-address"
  project = var.project_id
}

data "google_compute_image" "debian_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_instance" "bastion" {
  name         = "platform-bastion"
  project      = var.project_id
  machine_type = "n1-standard-1"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }

  network_interface {
    network_ip = google_compute_address.internal_with_subnet_and_address.address
    subnetwork = var.subnet_app_1_id
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  #service_account {
  #  scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  #}

  tags = ["bastion", var.env]
}

resource "google_compute_firewall" "firewall_bastion" {
  name    = "platform-bastion"
  project = var.project_id
  network = var.network_id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
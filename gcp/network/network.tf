provider "google" {
  credentials = file("~/iac/gcp/service-account.json")
  project     = "terraform-273919"
  region      = "us-east1"
}

resource "google_compute_network" "platform-vpc" {
  name                    = "platform-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_app_1" {
  name          = "platform-app-subnet-1"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-east1"
  network       = google_compute_network.platform-vpc.self_link
}

resource "google_compute_subnetwork" "subnet_app_2" {
  name          = "platform-app-subnet-2"
  ip_cidr_range = "10.0.4.0/24"
  region        = "us-east1"
  network       = google_compute_network.platform-vpc.self_link
}

resource "google_compute_firewall" "platform-firewall" {
  name    = "platform-firewall"
  network = google_compute_network.platform-vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

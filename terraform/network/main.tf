provider "google" {}

data "google_project" "project" {}

resource "google_service_account" "demo" {
  account_id   = "demo-user"
  display_name = "Demo"
}

resource "google_service_account_key" "key" {
  service_account_id = "${google_service_account.demo.name}"
}

resource "google_project_iam_member" "service-account" {
  role   = "roles/editor"
  member = "serviceAccount:${google_service_account.demo.email}"
}

resource "google_compute_network" "chef" {
  name                    = "network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "chef" {
  name          = "chef-subnet"
  network       = "${google_compute_network.chef.self_link}"
  ip_cidr_range = "10.0.96.0/22"
}

resource "google_compute_firewall" "internal" {
  name = "internal"
  network = "${google_compute_network.chef.self_link}"

  allow {
    protocol = "all"
  }

  source_ranges = ["${google_compute_subnetwork.chef.ip_cidr_range}"]
}

resource "google_compute_firewall" "ssh" {
  name = "ssh"
  network = "${google_compute_network.chef.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ipsec" {
  name = "ipsec"
  network = "${google_compute_network.chef.self_link}"

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  target_tags = ["ipsec"]
  source_ranges = ["0.0.0.0/0"]
}

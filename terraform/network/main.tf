terraform {
  backend "gcs" {
    bucket  = "daughertyk8s-1-tf-state"
    prefix  = "network"
  }
}

provider "google" {}

data "google_project" "project" {}

data "terraform_remote_state" "iam" {
  backend = "gcs"
  config {
    bucket = "daughertyk8s-1-tf-state"
    prefix = "iam"
  }
}

data "terraform_remote_state" "dns" {
  backend = "gcs"
  config {
    bucket = "daughertyk8s-1-tf-state"
    prefix = "dns"
  }
}

locals {
  vpn_ip = "${data.terraform_remote_state.dns.vpn_ip}"
}

resource "google_compute_network" "labs" {
  name                    = "network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "labs" {
  name          = "chef-subnet"
  network       = "${google_compute_network.labs.self_link}"
  ip_cidr_range = "10.0.96.0/22"
}

resource "google_compute_router" "router" {
  name    = "router"
  network = "${google_compute_network.labs.self_link}"

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "simple-nat" {
  name                               = "nat-1"
  router                             = "${google_compute_router.router.name}"
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "internal" {
  name = "internal"
  network = "${google_compute_network.labs.self_link}"

  allow {
    protocol = "all"
  }

  source_ranges = ["${google_compute_subnetwork.labs.ip_cidr_range}"]
}

resource "google_compute_firewall" "ssh" {
  name = "ssh"
  network = "${google_compute_network.labs.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ipsec" {
  name = "ipsec"
  network = "${google_compute_network.labs.self_link}"

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  target_tags = ["ipsec"]
  source_ranges = ["0.0.0.0/0"]
}

data "template_file" "setup_vpn" {
  template = "${file("${path.module}/setup_vpn.sh")}"
  vars {
    address = "${local.vpn_ip}"
    subnet = "${google_compute_subnetwork.labs.ip_cidr_range}"
  }
}

data "google_compute_image" "vpn" {
  family  = "vpn"
  project = "${data.google_project.project.name}"
}

resource "google_compute_instance" "vpn" {
  name         = "vpn"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.vpn.self_link}"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.labs.self_link}"

    access_config {
      nat_ip = "${local.vpn_ip}"
    }
  }

  metadata_startup_script = "${data.template_file.setup_vpn.rendered}"

  metadata = {
    foo = "bar"
  }

  tags = ["ssh", "ipsec"]

  service_account {
    email  = "${data.terraform_remote_state.iam.service_account_email}"
    scopes = ["compute-rw", "storage-rw"]
  }
}

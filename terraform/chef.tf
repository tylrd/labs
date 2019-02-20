resource "google_compute_instance" "chef" {
  name         = "chef"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.chef.self_link}"
  }

  metadata = {
    foo = "bar"
  }

  service_account {
    email  = "${google_service_account.demo.email}"
    scopes = ["compute-rw", "storage-rw"]
  }
}

resource "google_compute_instance" "vpn" {
  name         = "vpn"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.chef.self_link}"

    access_config {}
  }

  metadata = {
    foo = "bar"
  }

  tags = ["ssh", "ipsec"]

  service_account {
    email  = "${google_service_account.demo.email}"
    scopes = ["compute-rw", "storage-rw"]
  }
}

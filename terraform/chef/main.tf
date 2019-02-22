terraform {
  backend "gcs" {
    bucket  = "daughertyk8s-1-tf-state"
    prefix  = "chef"
  }
}

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

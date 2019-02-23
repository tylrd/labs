terraform {
  backend "gcs" {
    bucket  = "daughertyk8s-1-tf-state"
    prefix  = "chef"
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"
  config {
    bucket = "daughertyk8s-1-tf-state"
    prefix = "network"
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
    subnetwork = "${data.terraform_remote_state.network.subnet}"
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script =<<EOF
apt-get update
apt-get install -y apache2
cat <<EOF > /var/www/html/index.html
<html><body><h1>Hello World</h1>
<p>This page was created from a simple start up script!</p>
</body></html>
EOF

  service_account {
    scopes = ["compute-rw", "storage-rw"]
  }
}

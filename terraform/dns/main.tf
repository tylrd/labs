terraform {
  backend "gcs" {
    bucket  = "daughertyk8s-1-tf-state"
    prefix  = "dns"
  }
}

provider "google" {}

resource "google_compute_address" "vpn" {
  name = "vpn"
}

output "vpn_ip" {
  value = "${google_compute_address.vpn.address}"
}

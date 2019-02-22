terraform {
  backend "gcs" {
    bucket  = "daughertyk8s-1-tf-state"
    prefix  = "tls"
  }
}

provider "google" {}

data "google_project" "project" {}

data "terraform_remote_state" "dns" {
  backend = "gcs"
  config {
    bucket = "daughertyk8s-1-tf-state"
    prefix = "dns"
  }
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "RSA"
  private_key_pem = "${file("${path.module}/../../certs/ca/key.pem")}"

  subject {
    common_name  = "Daugherty Labs CA"
    organization = "Daugherty Labs"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]

  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > ../../certs/ca/ca.pem && chmod 0600 ../../certs/ca/ca.pem"
  }
}

# Create the request to sign the cert with our CA
resource "tls_cert_request" "vpn_req" {
  key_algorithm   = "RSA"
  private_key_pem = "${file("${path.module}/../../certs/vpn/key.pem")}"

  ip_addresses = [
    "${data.terraform_remote_state.dns.vpn_ip}"
  ]

  subject {
    common_name  = "${data.terraform_remote_state.dns.vpn_ip}"
    organization = "Daugherty Labs"
  }
}

# Now sign the cert
resource "tls_locally_signed_cert" "vpn_cert" {
  cert_request_pem = "${tls_cert_request.vpn_req.cert_request_pem}"

  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${file("${path.module}/../../certs/ca/key.pem")}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 8760

  allowed_uses = [
    "server_auth",
  ]

  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > ../../certs/vpn/cert.pem && echo '${tls_self_signed_cert.ca.cert_pem}' >> ../../certs/vpn/cert.pem && chmod 0600 ../../certs/vpn/cert.pem"
  }
}

output "ca" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}

output "vpn_cert" {
  value = "${tls_locally_signed_cert.vpn_cert.cert_pem}"
}

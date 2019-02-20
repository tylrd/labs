resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "${tls_private_key.ca.algorithm}"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

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
    command = "echo '${self.cert_pem}' > ../tls/ca.pem && chmod 0600 ../tls/ca.pem"
  }
}

resource "tls_private_key" "chef_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"

  provisioner "local-exec" {
    command = "echo '${self.private_key_pem}' > ../tls/chef.key && chmod 0600 ../tls/chef.key"
  }
}

# Create the request to sign the cert with our CA
resource "tls_cert_request" "chef_req" {
  key_algorithm   = "${tls_private_key.chef_key.algorithm}"
  private_key_pem = "${tls_private_key.chef_key.private_key_pem}"

  dns_names = [
    "chef",
    "chef.c.${data.google_project.project.name}.internal",
    "chef.service.consul",
  ]

  subject {
    common_name  = "chef.c.${data.google_project.project.name}.internal"
    organization = "Daugherty Labs"
  }
}

# Now sign the cert
resource "tls_locally_signed_cert" "chef_cert" {
  cert_request_pem = "${tls_cert_request.chef_req.cert_request_pem}"

  ca_key_algorithm   = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]

  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > ../tls/chef.pem && echo '${tls_self_signed_cert.ca.cert_pem}' >> ../tls/chef.pem && chmod 0600 ../tls/chef.pem"
  }
}

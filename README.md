# Labs

Playground for:

* GCP
* Terraform
* Kubernetes
* Istio
* StrongSwan
* Spinnaker
* Packer
* Chef
* Vault
* Consul

# Steps

1. TLS

Create private keys for the CA and the VPN:

```
openssl genrsa -out certs/ca/key.pem 2048
openssl genrsa -out certs/vpn/key.pem 2048
```

2. DNS

Provision an external IP for the VPN, Load Balancer, and NAT gateway.
Generate client certificates for the VPN

```
./bin/vpn_client_cert.sh <email>
```

This will generate client certificates in ./certs/vpn/client/
On Mac, it will add the root CA and the client cert to the keychain as trusted
certs.

4. Network

Generate network & subnetwork, firewall rules,

Create a client certificate for the 

3. Chef Server

#!/usr/bin/env bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[ -z "$1" ] && { echo 'Must provide email'; exit 1; }

EMAIL=$1
VPNIP=$(cd "$DIR/../terraform/dns" && terraform output vpn_ip)

echo "VPNIP: $VPNIP"

cd "$DIR/../certs/vpn/client"

echo "Generating client cert for $EMAIL"

openssl genrsa -out vpn-client.key 2048
openssl req -new -key vpn-client.key -subj "/C=US/ST=GA/O=$ORGNAME/CN=$EMAIL" -out vpn-client.csr

openssl x509 -req \
  -extfile <(printf "subjectAltName=IP:$VPNIP") \
  -days 365 \
  -in vpn-client.csr \
  -CA ../../ca/ca.pem \
  -CAkey ../../ca/key.pem \
  -CAcreateserial \
  -out vpn-client.pem
# openssl req -new -sha256 \
#   -key vpn-client.key \
#   -subj "/C=US/ST=GA/O=$ORGNAME/CN=$EMAIL" \
#   -reqexts SAN \
#   -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=IP:$VPNIP")) \
#   -out vpn-client.csr
openssl pkcs12 -export -out cert.pfx -inkey vpn-client.key -in vpn-client.pem -certfile ../../ca/ca.pem

# if [ "$(uname)" == "Darwin" ]; then
#   security add-trusted-cert -d -r trustRoot -k $HOME/Library/Keychains/login.keychain ../../ca/ca.pem
#   security add-trusted-cert -r trustAsRoot -k $HOME/Library/Keychains/login.keychain vpn-client.pem
# fi

echo "Succesfully generated client cert at $(pwd)/cert.pfx"

finish() {
  rm -f "$DIR/../certs/vpn/client/client.cnf"
}
trap finish EXIT

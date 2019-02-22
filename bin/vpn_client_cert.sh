#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[ -z "$1" ] && { echo 'Must provide username'; exit 1; }

USER=$1
ORGNAME="Daugherty Labs"
CACERT="$DIR/../certs/ca/ca.pem"
CAKEY="$DIR/../certs/ca/key.pem"

cd "$DIR/../certs/vpn/client"

echo "Generating client cert for $USER"

# genereate CSR
openssl genrsa -out "$USER-key.pem" 2048
openssl req -new -key "$USER-key.pem" -subj "/O=$ORGNAME/CN=$USER" -out "$USER.csr"

# sign CSR with CA
openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:$USER") \
  -days 365 \
  -in "$USER.csr" \
  -CA "$CACERT" \
  -CAkey "$CAKEY" \
  -CAcreateserial \
  -out "$USER.pem"

# generate p12
openssl pkcs12 -export \
  -out "$USER.p12" \
  -inkey "$USER-key.pem" \
  -in "$USER.pem" \
  -certfile "$CACERT"

echo "Succesfully generated client cert at $(pwd)/$USER.p12"

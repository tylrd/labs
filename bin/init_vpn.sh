#!/usr/bin/env bash

set -eo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT="${GOOGLE_PROJECT:-"daughertyk8s-1"}"
BUCKET="${PKI_BUCKET:-"gs://$PROJECT-pki"}"

VPNKEY_REMOTE="$BUCKET/private/vpn/key.pem.enc"
VPNKEY_LOCAL="$DIR/../certs/vpn/key.pem"

KEYRING_NAME="pki"
KEY_NAME="ca"

if ! gsutil -q stat "$VPNKEY_REMOTE"; then
  openssl genrsa -out "$VPNKEY_LOCAL" 2048

  echo "Encrypting and uploading key at $VPNKEY_LOCAL to $VPNKEY_REMOTE"
  gcloud kms encrypt \
    --location global \
    --keyring "$KEYRING_NAME" \
    --key "$KEY_NAME" \
    --plaintext-file "$VPNKEY_LOCAL" \
    --ciphertext-file - \
    --project "$PROJECT" \
    | gsutil cp - "$VPNKEY_REMOTE"

else
  if [ ! -f "$VPNKEY_LOCAL" ]; then
    echo "Private key already exists in bucket, downloading to $VPNKEY_LOCAL..."

    gcloud kms decrypt \
      --location global \
      --keyring "$KEYRING_NAME" \
      --key "$KEY_NAME" \
      --ciphertext-file <(gsutil cat "$VPNKEY_REMOTE") \
      --plaintext-file "$VPNKEY_LOCAL" \
      --project "$PROJECT"

  echo "Done"
  else
    echo "Key already exists at $VPNKEY_LOCAL"
  fi
fi

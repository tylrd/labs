#!/usr/bin/env bash

set -eo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT="${GOOGLE_PROJECT:-"daughertyk8s-1"}"
BUCKET="${PKI_BUCKET:-"gs://$PROJECT-pki"}"

CAKEY_REMOTE="$BUCKET/private/ca/key.pem.enc"
CAKEY_LOCAL="$DIR/../certs/ca/key.pem"

KEYRING_NAME="pki"
KEY_NAME="ca"

if ! gsutil -q stat "$CAKEY_REMOTE"; then
  openssl genrsa -out "$CAKEY_LOCAL" 2048

  echo "Encrypting and uploading key at $CAKEY_LOCAL to $CAKEY_REMOTE"
  gcloud kms encrypt \
    --location global \
    --keyring "$KEYRING_NAME" \
    --key "$KEY_NAME" \
    --plaintext-file "$CAKEY_LOCAL" \
    --ciphertext-file - \
    --project "$PROJECT" \
    | gsutil cp - "$CAKEY_REMOTE"

else
  if [ ! -f "$CAKEY_LOCAL" ]; then
    echo "Private key already exists in bucket, downloading to $CAKEY_LOCAL..."

    gcloud kms decrypt \
      --location global \
      --keyring "$KEYRING_NAME" \
      --key "$KEY_NAME" \
      --ciphertext-file <(gsutil cat "$CAKEY_REMOTE") \
      --plaintext-file "$CAKEY_LOCAL" \
      --project "$PROJECT"

  echo "Done"
  else
    echo "Key already exists at $CAKEY_LOCAL"
  fi
fi

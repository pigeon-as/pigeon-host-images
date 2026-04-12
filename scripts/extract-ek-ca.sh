#!/bin/bash
# Extract TPM EK CA chain via AIA walking → /etc/pigeon/ek-ca/ (PEM).
# pigeon-enroll uses these to validate worker EK certs during attestation.
set -euo pipefail

EK_CA_DIR="/etc/pigeon/ek-ca"
mkdir -p "$EK_CA_DIR"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

aia_uri() {
    openssl x509 -inform "$1" -in "$2" -noout -ext authorityInfoAccess 2>/dev/null \
        | grep -oP 'CA Issuers - URI:\K\S+' || true
}

tpm2_getekcertificate -o "$tmp/ek.der"

cert="$tmp/ek.der"
count=0
while [ "$count" -lt 5 ]; do
    uri=$(aia_uri DER "$cert")
    [ -z "$uri" ] && break

    next="$tmp/$count.der"
    curl -fsSL -o "$next" "$uri"
    openssl x509 -inform DER -in "$next" -out "$EK_CA_DIR/$count.pem"

    cert="$next"
    count=$((count + 1))
done

[ "$count" -eq 0 ] && { echo "ERROR: no CA certs found in AIA chain" >&2; exit 1; }
echo "Extracted $count CA cert(s) to $EK_CA_DIR"

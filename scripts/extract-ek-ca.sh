#!/bin/bash
# Extract TPM EK CA chain via AIA walking → /etc/pigeon/ek-ca/ (PEM).
# pigeon-enroll uses these to validate worker EK certs during attestation.
set -euo pipefail

EK_CA_DIR="/etc/pigeon/ek-ca"
mkdir -p "$EK_CA_DIR"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

tpm2_getekcertificate -o "$tmp/ek.der"

# Walk AIA caIssuers chain from EK cert up to root
cert="$tmp/ek.der"
inform="DER"
count=0

while [ "$count" -lt 5 ]; do
    aia=$(openssl x509 -inform "$inform" -in "$cert" -noout -text 2>/dev/null \
        | grep -A1 'CA Issuers' | grep -oP 'URI:\K\S+' || true)
    [ -z "$aia" ] && break

    issuer="$tmp/issuer-$count.der"
    curl -fsSL -o "$issuer" "$aia"

    cn=$(openssl x509 -inform DER -in "$issuer" -noout -subject -nameopt oneline,utf8 \
        | sed 's/.*CN = //;s/[^a-zA-Z0-9._-]/-/g')
    openssl x509 -inform DER -in "$issuer" -out "$EK_CA_DIR/${cn}.pem"

    cert="$issuer"
    inform="DER"
    count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
    echo "ERROR: no CA certificates found in AIA chain" >&2
    exit 1
fi

echo "Extracted $count CA cert(s) to $EK_CA_DIR"

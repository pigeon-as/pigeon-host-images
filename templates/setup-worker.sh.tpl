#!/bin/bash
set -eu
# Worker first-boot: LUKS setup + secret enrollment + config rendering via ConfigDrive user_data.

ENROLL_URL="${file.secrets.vars.enroll_url}"
ENROLL_TOKEN="${exec.enroll_token}"
ENROLL_CERT="${exec.enroll_cert}"

bash /usr/local/bin/configure-luks.sh

# Write client cert bundle to temp file for mTLS claim.
CERT_FILE=$(mktemp)
trap 'rm -f "$CERT_FILE"' EXIT
printf '%s' "$ENROLL_CERT" | base64 -d > "$CERT_FILE"

pigeon-enroll claim \
  -url "$ENROLL_URL" \
  -token "$ENROLL_TOKEN" \
  -tls "$CERT_FILE" \
  -scope worker \
  -output /encrypted/pigeon/secrets.json

# Render config files from templates using claimed secrets.
pigeon-enroll render \
  -config /etc/pigeon/render.hcl \
  -vars /encrypted/pigeon/secrets.json

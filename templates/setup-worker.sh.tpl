#!/bin/bash
set -eu
# Worker first-boot: LUKS setup + secret enrollment + config rendering via ConfigDrive user_data.

ENROLL_URL="${file.secrets.vars.enroll_url}"
ENROLL_TOKEN="${exec.enroll_token}"
ENROLL_CERT="${exec.enroll_cert}"

: "${ENROLL_URL:?missing ENROLL_URL}"
: "${ENROLL_TOKEN:?missing ENROLL_TOKEN}"
: "${ENROLL_CERT:?missing ENROLL_CERT}"

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

# Render configs, extract CAs, generate leaf certs — all in one pass.
pigeon-template --once --config=/etc/pigeon/template.hcl

# Start services that were waiting for rendered configs.
# vault-agent issues Nomad TLS cert → nomad-cert.path detects it → starts nomad.
systemctl start pigeon-mesh consul vault-agent

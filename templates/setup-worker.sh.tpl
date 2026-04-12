#!/bin/bash
set -eu
# Worker first-boot: secret enrollment + config rendering via ConfigDrive user_data.

ENROLL_URL="${file.enroll.vars.enroll_url}"
ENROLL_TOKEN="${exec.enroll_token}"
ENROLL_CERT="${exec.enroll_cert}"

: "${ENROLL_URL:?missing ENROLL_URL}"
: "${ENROLL_TOKEN:?missing ENROLL_TOKEN}"
: "${ENROLL_CERT:?missing ENROLL_CERT}"

# Generate unique hostname BEFORE claim so -subject = hostname.
PETNAME=$(pigeon-petname)
HOSTNAME="$${PETNAME}.worker.${file.enroll.vars.datacenter}.${file.enroll.vars.region}.${file.enroll.vars.domain}"
hostnamectl set-hostname "$$HOSTNAME"

# Write client cert bundle to temp file for mTLS claim.
CERT_FILE=$(mktemp)
trap 'rm -f "$CERT_FILE"' EXIT
printf '%s' "$ENROLL_CERT" | base64 -d > "$CERT_FILE"

pigeon-enroll claim \
  -url "$ENROLL_URL" \
  -token "$ENROLL_TOKEN" \
  -tls "$CERT_FILE" \
  -scope worker \
  -subject "$$HOSTNAME" \
  -output /var/lib/pigeon/enroll.json

# Render configs, extract CAs, generate leaf certs — all in one pass.
pigeon-template --once --config=/etc/pigeon/bootstrap.tmpl.hcl

# Start services that were waiting for rendered configs.
# vault-agent issues Nomad TLS cert → nomad-cert.path detects it → starts nomad.
systemctl start pigeon-mesh consul vault-agent

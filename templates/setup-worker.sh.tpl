#!/bin/bash
# Worker first-boot user_data, rendered on the control-plane by
# pigeon-template-reconcile.service (every 10 min, with a fresh HMAC token
# and up-to-date identity CA) and shipped via OVH ConfigDrive.
#
# Only the imperative first-contact work lives here: hostname, identity CA,
# ENROLL_ADDR, register. The rest of the bootstrap is declarative and fires
# automatically when /etc/pigeon/identity/cert.pem appears.
set -euo pipefail

cat > /etc/pigeon/certs/identity-ca.crt <<'CA'
${exec.identity_ca}
CA

echo "ENROLL_ADDR=${exec.enroll_url}" > /etc/pigeon/enroll.env

hostnamectl set-hostname "$(pigeon-petname)"

pigeon-enroll register \
  -addr     "${exec.enroll_url}" \
  -ca       /etc/pigeon/certs/identity-ca.crt \
  -identity worker \
  -subject  "$(hostname -f)" \
  -token    "${exec.enroll_token}"

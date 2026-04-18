source "exec" "peers" {
  command  = "pigeon-mesh list-peers"
  interval = "30s"
}

# Mint a fresh HMAC bootstrap token every 10 minutes, delivered to newly
# ordered workers via OVH ConfigDrive. Uses the control-plane identity
# cert (policy "server" → path "token/worker" write capability).
source "exec" "enroll_token" {
  command  = "pigeon-enroll write token/worker"
  interval = "10m"
}

# Identity CA, refreshed every 6h. Changes extremely rarely (HKDF-derived
# from the static enrollment key) but this keeps any rotation picked up
# without a daemon restart.
source "exec" "identity_ca" {
  command  = "pigeon-enroll read ca/identity"
  interval = "6h"
}

source "exec" "enroll_url" {
  command  = "pigeon-enroll read var/enroll_url"
  interval = "6h"
}

source "exec" "domain" {
  command  = "pigeon-enroll read var/domain"
  interval = "6h"
}

# --- Infrastructure DNS zone (from mesh peers) ---

template {
  source      = "/etc/pigeon/infra.zone.tpl"
  destination = "/etc/unbound/zones/infra.zone"
  perms       = "0644"
  command     = "unbound-control auth_zone_reload ${exec.domain}"
}

# --- Worker first-boot user_data (for OVH ConfigDrive) ---

template {
  source      = "/etc/pigeon/setup-worker.sh.tpl"
  destination = "/var/lib/pigeon/setup-worker.sh"
  perms       = "0600"
}

wait {
  min = "5s"
  max = "30s"
}

log_level = "info"

source "file" "enroll" {
  path = "/encrypted/pigeon/enroll.json"
}

source "exec" "peers" {
  command  = "pigeon-mesh list-peers"
  interval = "30s"
}

source "exec" "enroll_token" {
  command  = "pigeon-enroll generate-token -config=/encrypted/pigeon/enroll-server.hcl"
  interval = "10m"
}

source "exec" "enroll_cert" {
  command  = "pigeon-enroll generate-cert -base64 -bundle - -config=/encrypted/pigeon/enroll-server.hcl -ttl 1h"
  interval = "30m"
}

# --- Infrastructure DNS zone (from mesh peers) ---

template {
  source      = "/etc/pigeon/infra.zone.tpl"
  destination = "/etc/unbound/zones/infra.zone"
  perms       = "0644"
  command     = "unbound-control auth_zone_reload $${file.enroll.vars.domain}"
}

# --- Setup worker script (uses exec sources for token rotation) ---

template {
  source      = "/etc/pigeon/setup-worker.sh.tpl"
  destination = "/encrypted/pigeon/setup-worker.sh"
  perms       = "0600"
}

wait {
  min = "5s"
  max = "30s"
}

log_level = "info"

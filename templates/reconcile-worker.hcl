source "exec" "peers" {
  command  = "pigeon-mesh list-peers"
  interval = "30s"
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

log_level = "info"

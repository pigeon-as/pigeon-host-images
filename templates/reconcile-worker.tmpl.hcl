source "file" "enroll" {
  path = "/var/lib/pigeon/enroll.json"
}

source "exec" "peers" {
  command  = "pigeon-mesh list-peers"
  interval = "30s"
}

# --- Infrastructure DNS zone (from mesh peers) ---

template {
  source      = "/etc/pigeon/infra.zone.tpl"
  destination = "/etc/unbound/zones/infra.zone"
  perms       = "0644"
  command     = "unbound-control auth_zone_reload $${file.enroll.vars.domain}"
}

log_level = "info"

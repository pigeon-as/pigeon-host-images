source "file" "enroll" {
  path = "/var/lib/pigeon/enroll.json"
}

source "exec" "peers" {
  command  = "pigeon-mesh list-peers"
  interval = "30s"
}

source "exec" "refresh_enroll_json" {
  command  = "pigeon-enroll read template/enroll-worker -o /var/lib/pigeon/enroll.json"
  interval = "1h"
}

# Seal the gossip key to the host's TPM for pigeon-mesh's LoadCredentialEncrypted.
# Same pattern as control-plane reconcile-server.hcl: plaintext never lands on
# disk; systemctl start is a no-op post-first-boot.
source "exec" "seal_gossip_key" {
  command  = <<-EOT
    set -euo pipefail
    mkdir -p /etc/credstore.encrypted
    pigeon-enroll read secret/gossip_key \
      | systemd-creds encrypt --with-key=tpm2 --name=gossip-key - /etc/credstore.encrypted/pigeon-mesh.gossip-key
    systemctl start pigeon-mesh
  EOT
  interval = "6h"
}

# Stage-0 leaf issuance. Idempotent via -renew-before=1h: no-op when cert is
# valid for >1h. Heals deletion within 30s. Post-handover vault-agent owns
# these paths.
source "exec" "issue_mesh_worker" {
  command  = "pigeon-enroll issue pki/mesh_worker -out-cert=/etc/pigeon/certs/mesh-cert.pem -out-key=/etc/pigeon/certs/mesh-key.pem -renew-before=1h"
  interval = "30s"
}
source "exec" "issue_auth_worker" {
  command  = "pigeon-enroll issue pki/auth_worker -out-cert=/etc/pigeon/certs/auth/cert.pem -out-key=/etc/pigeon/certs/auth/key.pem -renew-before=1h"
  interval = "30s"
}

source "exec" "domain"       { command = "pigeon-enroll read var/domain", interval = "6h" }
source "exec" "ca_mesh"      { command = "pigeon-enroll read ca/mesh", interval = "6h" }
source "exec" "ca_bootstrap" { command = "pigeon-enroll read ca/bootstrap", interval = "6h" }
source "exec" "ca_vault"     { command = "pigeon-enroll read ca/vault", interval = "6h" }
source "exec" "jwt_consul_auto_config" {
  command  = "pigeon-enroll write jwt/consul_auto_config"
  interval = "12h"
}

# --- CA certs ---

template {
  content     = "$${exec.ca_mesh}"
  destination = "/etc/pigeon/certs/mesh-ca.crt"
  perms       = "0644"
}

template {
  content     = "$${exec.ca_mesh}"
  destination = "/etc/pigeon/certs/mesh-enroll-ca.crt"
  perms       = "0644"
}

template {
  content     = "$${exec.ca_bootstrap}"
  destination = "/etc/pigeon/certs/bootstrap-ca.crt"
  perms       = "0644"
}

template {
  content     = "$${exec.ca_bootstrap}"
  destination = "/etc/consul.d/certs/ca.crt"
  perms       = "0644"
  user        = "consul"
  group       = "consul"
}

template {
  content     = "$${exec.ca_bootstrap}"
  destination = "/etc/nomad.d/certs/ca.crt"
  perms       = "0644"
}

template {
  content     = "$${exec.ca_bootstrap}"
  destination = "/etc/pigeon/certs/auth/ca.crt"
  perms       = "0644"
}

template {
  content     = "$${exec.ca_vault}"
  destination = "/etc/vault.d/certs/ca.crt"
  perms       = "0644"
}

# --- Consul auto_config intro token (signed JWT minted on demand) ---

template {
  content     = "$${exec.jwt_consul_auto_config}"
  destination = "/etc/consul.d/intro-token.jwt"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

# --- Service configs ---

template {
  source      = "/etc/pigeon/mesh.json.tpl"
  destination = "/etc/pigeon/mesh.json"
  perms       = "0600"
  command     = "systemctl start pigeon-mesh"
}

template {
  source      = "/etc/pigeon/unbound.conf.tpl"
  destination = "/etc/unbound/unbound.conf"
  perms       = "0644"
  command     = "systemctl start unbound"
}

template {
  source      = "/etc/pigeon/resolv.conf.tpl"
  destination = "/etc/resolv.conf"
  perms       = "0644"
}

template {
  source      = "/etc/pigeon/consul.hcl.tpl"
  destination = "/etc/consul.d/consul.hcl"
  perms       = "0640"
  user        = "consul"
  group       = "consul"
  command     = "systemctl start consul"
}

# nomad.service is gated by nomad-cert.path — it self-starts once vault-agent
# issues the Vault-PKI nomad-client cert.
template {
  source      = "/etc/pigeon/nomad.hcl.tpl"
  destination = "/etc/nomad.d/nomad.hcl"
  perms       = "0640"
}

# --- Infrastructure DNS zone (from mesh peers) ---

template {
  source      = "/etc/pigeon/infra.zone.tpl"
  destination = "/etc/unbound/zones/infra.zone"
  perms       = "0644"
  command     = "unbound-control auth_zone_reload ${exec.domain}"
}

wait {
  min = "5s"
  max = "30s"
}

log_level = "info"

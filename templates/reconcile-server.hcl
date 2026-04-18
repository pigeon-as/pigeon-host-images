source "file" "enroll" {
  path = "/var/lib/pigeon/enroll.json"
}

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

# Keep enroll.json fresh: if it's deleted or the server rotates vars/secrets,
# the next tick writes a new bundle and downstream templates re-render.
source "exec" "refresh_enroll_json" {
  command  = "pigeon-enroll read template/enroll-server -o /var/lib/pigeon/enroll.json"
  interval = "1h"
}

# Stage-0 leaf issuance. Idempotent: -renew-before=1h makes each call a no-op
# if the cert already exists and is valid for more than an hour. On first
# boot all five pairs issue fresh; subsequent ticks skip. If a leaf is deleted
# (pre-handover narrow window), the next tick re-issues it. Post-handover
# vault-agent owns these paths; its cert has plenty of lifetime so these
# stay no-ops until it tears down.
source "exec" "issue_mesh_server" {
  command  = "pigeon-enroll issue pki/mesh_server -out-cert=/etc/pigeon/certs/mesh-cert.pem -out-key=/etc/pigeon/certs/mesh-key.pem -renew-before=1h"
  interval = "30s"
}
source "exec" "issue_auth_server" {
  command  = "pigeon-enroll issue pki/auth_server -out-cert=/etc/pigeon/certs/auth/cert.pem -out-key=/etc/pigeon/certs/auth/key.pem -renew-before=1h"
  interval = "30s"
}
source "exec" "issue_vault_server" {
  command  = "pigeon-enroll issue pki/vault_server -out-cert=/etc/vault.d/certs/cert.pem -out-key=/etc/vault.d/certs/key.pem -renew-before=1h"
  interval = "30s"
}
source "exec" "issue_consul_server" {
  command  = "pigeon-enroll issue pki/consul_server -out-cert=/etc/consul.d/certs/cert.pem -out-key=/etc/consul.d/certs/key.pem -renew-before=1h"
  interval = "30s"
}
source "exec" "issue_nomad_server" {
  command  = "pigeon-enroll issue pki/nomad_server -out-cert=/etc/nomad.d/certs/cert.pem -out-key=/etc/nomad.d/certs/key.pem -renew-before=1h"
  interval = "30s"
}

source "exec" "identity_ca"                { command = "pigeon-enroll read ca/identity", interval = "6h" }
source "exec" "enroll_url"                 { command = "pigeon-enroll read var/enroll_url", interval = "6h" }
source "exec" "domain"                     { command = "pigeon-enroll read var/domain", interval = "6h" }
source "exec" "ca_mesh"                    { command = "pigeon-enroll read ca/mesh", interval = "6h" }
source "exec" "ca_bootstrap"               { command = "pigeon-enroll read ca/bootstrap", interval = "6h" }
source "exec" "ca_vault"                   { command = "pigeon-enroll read ca/vault", interval = "6h" }
source "exec" "jwt_consul_auto_config_pub" { command = "pigeon-enroll read jwt_key/consul_auto_config", interval = "6h" }

# --- CA certs ---

template {
  content     = "$${exec.ca_mesh}"
  destination = "/etc/pigeon/certs/mesh-ca.crt"
  perms       = "0644"
}

# Preserved HKDF mesh CA for vault-agent's CA bundle template.
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
  user        = "vault"
  group       = "vault"
}

template {
  content     = "$${exec.jwt_consul_auto_config_pub}"
  destination = "/etc/consul.d/auto-config-pubkey.pem"
  perms       = "0644"
  user        = "consul"
  group       = "consul"
}

# --- Service configs. Each config template fires `systemctl start X` only
# when its content changes (pigeon-template skip-if-unchanged). systemctl
# start on a running unit is a no-op, so steady-state reconcile is silent;
# if a config was deleted, re-rendering restarts the service. ---

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
  source      = "/etc/pigeon/vault.hcl.tpl"
  destination = "/etc/vault.d/vault.hcl"
  perms       = "0640"
  user        = "vault"
  group       = "vault"
  command     = "systemctl start vault"
}

template {
  content     = <<-EOT
  PIGEON_DATACENTER=$${file.enroll.vars.datacenter}
  PIGEON_REGION=$${file.enroll.vars.region}
  EOT
  destination = "/etc/pigeon/vault-agent.env"
  perms       = "0600"
  command     = "systemctl start vault-agent"
}

template {
  source      = "/etc/pigeon/consul-server.hcl.tpl"
  destination = "/etc/consul.d/consul.hcl"
  perms       = "0640"
  user        = "consul"
  group       = "consul"
  command     = "systemctl start consul"
}

template {
  source      = "/etc/pigeon/nomad-server.hcl.tpl"
  destination = "/etc/nomad.d/nomad.hcl"
  perms       = "0640"
  command     = "systemctl start nomad"
}

# --- Infrastructure DNS zone (from mesh peers) + worker first-boot user_data ---

template {
  source      = "/etc/pigeon/infra.zone.tpl"
  destination = "/etc/unbound/zones/infra.zone"
  perms       = "0644"
  command     = "unbound-control auth_zone_reload ${exec.domain}"
}

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

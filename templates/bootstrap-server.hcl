source "file" "enroll" {
  path = "/var/lib/pigeon/enroll.json"
}

# --- CA certs (read from the local enroll server) ---

source "exec" "ca_mesh"      { command = "pigeon-enroll read ca/mesh" }
source "exec" "ca_bootstrap" { command = "pigeon-enroll read ca/bootstrap" }
source "exec" "ca_vault"     { command = "pigeon-enroll read ca/vault" }

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

# --- Leaf certs (issued locally; private keys never leave the host) ---

source "exec" "issue_mesh_server" {
  command = "pigeon-enroll issue pki/mesh_server -out-cert=/etc/pigeon/certs/mesh-cert.pem -out-key=/etc/pigeon/certs/mesh-key.pem"
}

source "exec" "issue_auth_server" {
  command = "pigeon-enroll issue pki/auth_server -out-cert=/etc/pigeon/certs/auth/cert.pem -out-key=/etc/pigeon/certs/auth/key.pem"
}

source "exec" "issue_vault_server" {
  command = "pigeon-enroll issue pki/vault_server -out-cert=/etc/vault.d/certs/cert.pem -out-key=/etc/vault.d/certs/key.pem"
}

source "exec" "issue_consul_server" {
  command = "pigeon-enroll issue pki/consul_server -out-cert=/etc/consul.d/certs/cert.pem -out-key=/etc/consul.d/certs/key.pem"
}

source "exec" "issue_nomad_server" {
  command = "pigeon-enroll issue pki/nomad_server -out-cert=/etc/nomad.d/certs/cert.pem -out-key=/etc/nomad.d/certs/key.pem"
}

# --- Consul auto_config JWT public key ---

source "exec" "jwt_consul_auto_config_pub" {
  command = "pigeon-enroll read jwt_key/consul_auto_config"
}

template {
  content     = "$${exec.jwt_consul_auto_config_pub}"
  destination = "/etc/consul.d/auto-config-pubkey.pem"
  perms       = "0644"
  user        = "consul"
  group       = "consul"
}

# --- Service configs: each config template starts its service once rendered.
# pigeon-template's command hook fires only when content changed (atomic rename),
# so a no-op reconcile doesn't restart anything; systemctl start on a running
# unit is itself a no-op.

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

log_level = "info"

source "file" "enroll" {
  path = "/var/lib/pigeon/enroll.json"
}

# --- CA certs ---

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
}

# --- Leaf certs (stage-0 only; vault-agent takes over from Vault PKI once up) ---

source "exec" "issue_mesh_worker" {
  command = "pigeon-enroll issue pki/mesh_worker -out-cert=/etc/pigeon/certs/mesh-cert.pem -out-key=/etc/pigeon/certs/mesh-key.pem"
}

source "exec" "issue_auth_worker" {
  command = "pigeon-enroll issue pki/auth_worker -out-cert=/etc/pigeon/certs/auth/cert.pem -out-key=/etc/pigeon/certs/auth/key.pem"
}

# --- Consul auto_config intro token (signed JWT minted on demand) ---

source "exec" "jwt_consul_auto_config" {
  command = "pigeon-enroll write jwt/consul_auto_config"
}

template {
  content     = "$${exec.jwt_consul_auto_config}"
  destination = "/etc/consul.d/intro-token.jwt"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

# --- Service configs: each starts its service post-render. ---

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

log_level = "info"

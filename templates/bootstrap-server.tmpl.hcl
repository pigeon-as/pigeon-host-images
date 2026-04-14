source "file" "enroll" {
  path = "/var/lib/pigeon/enroll.json"
}

# --- Mesh TLS (CA cert for verification + pre-issued leaf cert) ---

template {
  content     = "$${file.enroll.ca.mesh.cert_pem}"
  destination = "/etc/pigeon/certs/mesh-ca.crt"
  perms       = "0600"
}

# Preserved HKDF mesh CA for vault-agent CA bundle template
template {
  content     = "$${file.enroll.ca.mesh.cert_pem}"
  destination = "/etc/pigeon/certs/mesh-enroll-ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_server.cert_pem}"
  destination = "/etc/pigeon/certs/mesh-cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_server.key_pem}"
  destination = "/etc/pigeon/certs/mesh-key.pem"
  perms       = "0600"
}

# --- Bootstrap CA cert (shared trust root for vault/consul/nomad/auth during stage 0) ---

template {
  content     = "$${file.enroll.ca.bootstrap.cert_pem}"
  destination = "/etc/pigeon/certs/bootstrap-ca.crt"
  perms       = "0644"
}

# --- Vault TLS (Vault CA + pre-issued leaf cert from enroll) ---

template {
  content     = "$${file.enroll.ca.vault.cert_pem}"
  destination = "/etc/vault.d/certs/ca.crt"
  perms       = "0600"
  user        = "vault"
  group       = "vault"
}

template {
  content     = "$${file.enroll.certs.vault_server.cert_pem}"
  destination = "/etc/vault.d/certs/cert.pem"
  perms       = "0600"
  user        = "vault"
  group       = "vault"
}

template {
  content     = "$${file.enroll.certs.vault_server.key_pem}"
  destination = "/etc/vault.d/certs/key.pem"
  perms       = "0600"
  user        = "vault"
  group       = "vault"
}

# --- Consul TLS (bootstrap CA + pre-issued leaf cert from enroll) ---

template {
  content     = "$${file.enroll.ca.bootstrap.cert_pem}"
  destination = "/etc/consul.d/certs/ca.crt"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

template {
  content     = "$${file.enroll.certs.consul_server.cert_pem}"
  destination = "/etc/consul.d/certs/cert.pem"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

template {
  content     = "$${file.enroll.certs.consul_server.key_pem}"
  destination = "/etc/consul.d/certs/key.pem"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

# --- Nomad TLS (bootstrap CA + pre-issued leaf cert from enroll) ---

template {
  content     = "$${file.enroll.ca.bootstrap.cert_pem}"
  destination = "/etc/nomad.d/certs/ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.nomad_server.cert_pem}"
  destination = "/etc/nomad.d/certs/cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.nomad_server.key_pem}"
  destination = "/etc/nomad.d/certs/key.pem"
  perms       = "0600"
}

# --- Auth TLS (bootstrap CA + pre-issued leaf cert for vault-agent cert auth) ---

template {
  content     = "$${file.enroll.ca.bootstrap.cert_pem}"
  destination = "/etc/pigeon/certs/auth/ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.auth_server.cert_pem}"
  destination = "/etc/pigeon/certs/auth/cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.auth_server.key_pem}"
  destination = "/etc/pigeon/certs/auth/key.pem"
  perms       = "0600"
}

# --- Vault Agent environment (datacenter/region for PKI cert SANs) ---

template {
  content     = <<-EOT
PIGEON_DATACENTER=$${file.enroll.vars.datacenter}
PIGEON_REGION=$${file.enroll.vars.region}
EOT
  destination = "/etc/pigeon/vault-agent.env"
  perms       = "0600"
  command     = "systemctl start vault-agent"
}

# --- Service configs ---

template {
  source      = "/etc/pigeon/mesh.json.tpl"
  destination = "/etc/pigeon/mesh.json"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/consul-server.hcl.tpl"
  destination = "/etc/consul.d/consul.hcl"
  perms       = "0640"
  user        = "consul"
  group       = "consul"
}

template {
  source      = "/etc/pigeon/nomad-server.hcl.tpl"
  destination = "/etc/nomad.d/nomad.hcl"
  perms       = "0640"
}

template {
  source      = "/etc/pigeon/vault.hcl.tpl"
  destination = "/etc/vault.d/vault.hcl"
  perms       = "0640"
  user        = "vault"
  group       = "vault"
}

template {
  source      = "/etc/pigeon/resolv.conf.tpl"
  destination = "/etc/resolv.conf"
  perms       = "0644"
}

# --- Unbound config (domain from enrollment vars) ---

template {
  source      = "/etc/pigeon/unbound.conf.tpl"
  destination = "/etc/unbound/unbound.conf"
  perms       = "0644"
  command     = "systemctl restart unbound"
}

log_level = "info"

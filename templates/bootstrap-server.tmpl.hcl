source "file" "enroll" {
  path = "/encrypted/pigeon/enroll.json"
}

# --- Mesh TLS (CA cert for verification + pre-issued leaf cert) ---

template {
  content     = "$${file.enroll.ca.mesh.cert_pem}"
  destination = "/encrypted/pigeon/mesh-ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_server.cert_pem}"
  destination = "/encrypted/pigeon/mesh-cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_server.key_pem}"
  destination = "/encrypted/pigeon/mesh-key.pem"
  perms       = "0600"
}

# --- Vault TLS (CA cert + pre-issued leaf cert from enroll) ---

template {
  content     = "$${file.enroll.ca.vault.cert_pem}"
  destination = "/encrypted/tls/vault/ca.crt"
  perms       = "0600"
  user        = "vault"
  group       = "vault"
}

template {
  content     = "$${file.enroll.certs.vault_server.cert_pem}"
  destination = "/encrypted/tls/vault/cert.pem"
  perms       = "0600"
  user        = "vault"
  group       = "vault"
}

template {
  content     = "$${file.enroll.certs.vault_server.key_pem}"
  destination = "/encrypted/tls/vault/key.pem"
  perms       = "0600"
  user        = "vault"
  group       = "vault"
}

# --- Consul TLS (CA cert + pre-issued leaf cert from enroll) ---

template {
  content     = "$${file.enroll.ca.consul.cert_pem}"
  destination = "/encrypted/tls/consul/ca.crt"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

template {
  content     = "$${file.enroll.certs.consul_server.cert_pem}"
  destination = "/encrypted/tls/consul/cert.pem"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

template {
  content     = "$${file.enroll.certs.consul_server.key_pem}"
  destination = "/encrypted/tls/consul/key.pem"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

# --- Nomad TLS (CA cert + pre-issued leaf cert from enroll) ---

template {
  content     = "$${file.enroll.ca.nomad.cert_pem}"
  destination = "/encrypted/tls/nomad/ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.nomad_server.cert_pem}"
  destination = "/encrypted/tls/nomad/cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.nomad_server.key_pem}"
  destination = "/encrypted/tls/nomad/key.pem"
  perms       = "0600"
}

# --- Auth TLS (CA cert + pre-issued leaf cert for vault-agent cert auth) ---

template {
  content     = "$${file.enroll.ca.auth.cert_pem}"
  destination = "/encrypted/tls/auth/ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.auth_server.cert_pem}"
  destination = "/encrypted/tls/auth/cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.auth_server.key_pem}"
  destination = "/encrypted/tls/auth/key.pem"
  perms       = "0600"
}

# --- Vault Agent environment (datacenter/region for PKI cert SANs) ---

template {
  content     = <<-EOT
PIGEON_DATACENTER=$${file.enroll.vars.datacenter}
PIGEON_REGION=$${file.enroll.vars.region}
EOT
  destination = "/encrypted/pigeon/vault-agent.env"
  perms       = "0600"
}

# --- Service configs ---

template {
  source      = "/etc/pigeon/mesh.json.tpl"
  destination = "/encrypted/pigeon/mesh.json"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/fence-ovh.hcl.tpl"
  destination = "/encrypted/pigeon/fence.d/ovh.hcl"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/consul-server.hcl.tpl"
  destination = "/encrypted/consul/consul.hcl"
  perms       = "0640"
  user        = "consul"
  group       = "consul"
}

template {
  source      = "/etc/pigeon/nomad-server.hcl.tpl"
  destination = "/encrypted/nomad/nomad.hcl"
  perms       = "0640"
}

template {
  source      = "/etc/pigeon/vault.hcl.tpl"
  destination = "/encrypted/vault/vault.hcl"
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

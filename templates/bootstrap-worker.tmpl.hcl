source "file" "enroll" {
  path = "/encrypted/pigeon/enroll.json"
}

# --- Mesh CA cert (for peer verification) + pre-issued leaf cert ---

template {
  content     = "$${file.enroll.ca.mesh.cert_pem}"
  destination = "/encrypted/pigeon/mesh-ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_worker.cert_pem}"
  destination = "/encrypted/pigeon/mesh-cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_worker.key_pem}"
  destination = "/encrypted/pigeon/mesh-key.pem"
  perms       = "0600"
}

# --- Vault CA cert (workers verify server TLS, no leaf cert needed) ---

template {
  content     = "$${file.enroll.ca.vault.cert_pem}"
  destination = "/encrypted/tls/vault/ca.crt"
  perms       = "0644"
}

# --- Consul CA cert (auto_config handles leaf certs) ---

template {
  content     = "$${file.enroll.ca.consul.cert_pem}"
  destination = "/encrypted/tls/consul/ca.crt"
  perms       = "0644"
}

# --- Consul auto_config intro token (JWT for joining the cluster) ---

template {
  content     = "$${file.enroll.jwts.consul_auto_config}"
  destination = "/encrypted/consul/intro-token.jwt"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

# --- Nomad CA cert (trust only — vault-agent issues leaf certs from Vault PKI) ---

template {
  content     = "$${file.enroll.ca.nomad.cert_pem}"
  destination = "/encrypted/tls/nomad/ca.crt"
  perms       = "0644"
}

# --- Auth CA cert + leaf cert (server-issued during claim, for vault-agent cert auth) ---

template {
  content     = "$${file.enroll.ca.auth.cert_pem}"
  destination = "/encrypted/tls/auth/ca.crt"
  perms       = "0644"
}

template {
  content     = "$${file.enroll.certs.auth_worker.cert_pem}"
  destination = "/encrypted/tls/auth/cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.auth_worker.key_pem}"
  destination = "/encrypted/tls/auth/key.pem"
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
  source      = "/etc/pigeon/consul.hcl.tpl"
  destination = "/encrypted/consul/consul.hcl"
  perms       = "0640"
  user        = "consul"
  group       = "consul"
}

template {
  source      = "/etc/pigeon/nomad.hcl.tpl"
  destination = "/encrypted/nomad/nomad.hcl"
  perms       = "0640"
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

source "file" "enroll" {
  path = "/var/lib/pigeon/enroll.json"
}

# --- Mesh CA cert (for peer verification) + pre-issued leaf cert ---

template {
  content     = "$${file.enroll.ca.mesh.cert_pem}"
  destination = "/etc/pigeon/certs/mesh-ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_worker.cert_pem}"
  destination = "/etc/pigeon/certs/mesh-cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.mesh_worker.key_pem}"
  destination = "/etc/pigeon/certs/mesh-key.pem"
  perms       = "0600"
}

# --- Vault CA cert (workers verify server TLS, no leaf cert needed) ---

template {
  content     = "$${file.enroll.ca.vault.cert_pem}"
  destination = "/etc/vault.d/certs/ca.crt"
  perms       = "0644"
}

# --- Consul CA cert (auto_config handles leaf certs) ---

template {
  content     = "$${file.enroll.ca.consul.cert_pem}"
  destination = "/etc/consul.d/certs/ca.crt"
  perms       = "0644"
}

# --- Consul auto_config intro token (JWT for joining the cluster) ---

template {
  content     = "$${file.enroll.jwts.consul_auto_config}"
  destination = "/etc/consul.d/intro-token.jwt"
  perms       = "0600"
  user        = "consul"
  group       = "consul"
}

# --- Nomad CA cert (trust only — vault-agent issues leaf certs from Vault PKI) ---

template {
  content     = "$${file.enroll.ca.nomad.cert_pem}"
  destination = "/etc/nomad.d/certs/ca.crt"
  perms       = "0644"
}

# --- Auth CA cert + leaf cert (server-issued during claim, for vault-agent cert auth) ---

template {
  content     = "$${file.enroll.ca.auth.cert_pem}"
  destination = "/etc/pigeon/certs/auth/ca.crt"
  perms       = "0644"
}

template {
  content     = "$${file.enroll.certs.auth_worker.cert_pem}"
  destination = "/etc/pigeon/certs/auth/cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.enroll.certs.auth_worker.key_pem}"
  destination = "/etc/pigeon/certs/auth/key.pem"
  perms       = "0600"
}

# --- Service configs ---

template {
  source      = "/etc/pigeon/mesh.json.tpl"
  destination = "/etc/pigeon/mesh.json"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/consul.hcl.tpl"
  destination = "/etc/consul.d/consul.hcl"
  perms       = "0640"
  user        = "consul"
  group       = "consul"
}

template {
  source      = "/etc/pigeon/nomad.hcl.tpl"
  destination = "/etc/nomad.d/nomad.hcl"
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

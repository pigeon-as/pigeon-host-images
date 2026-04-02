source "file" "secrets" {
  path = "/encrypted/pigeon/secrets.json"
}

source "exec" "peers" {
  command  = "pigeon-mesh list-peers"
  interval = "30s"
}

# --- Mesh CA (pigeon-mesh reads these directly) ---

template {
  content     = "$${file.secrets.ca.mesh.cert_pem}"
  destination = "/encrypted/pigeon/mesh-ca.crt"
  perms       = "0600"
}

template {
  content     = "$${file.secrets.ca.mesh.private_key_pem}"
  destination = "/encrypted/pigeon/mesh-ca.key"
  perms       = "0600"
}

# --- Vault CA cert (workers verify server TLS, no leaf cert needed) ---

template {
  content     = "$${file.secrets.ca.vault.cert_pem}"
  destination = "/encrypted/tls/vault/ca.crt"
  perms       = "0644"
}

# --- Consul CA cert (auto_encrypt handles leaf certs) ---

template {
  content     = "$${file.secrets.ca.consul.cert_pem}"
  destination = "/encrypted/tls/consul/ca.crt"
  perms       = "0644"
}

# --- Nomad CA cert (trust only — vault-agent issues leaf certs from Vault PKI) ---

template {
  content     = "$${file.secrets.ca.nomad.cert_pem}"
  destination = "/encrypted/tls/nomad/ca.crt"
  perms       = "0644"
}

# --- Auth CA cert + leaf cert (server-issued during claim, for vault-agent cert auth) ---

template {
  content     = "$${file.secrets.ca.auth.cert_pem}"
  destination = "/encrypted/tls/auth/ca.crt"
  perms       = "0644"
}

template {
  content     = "$${file.secrets.certs.auth_worker.cert_pem}"
  destination = "/encrypted/tls/auth/cert.pem"
  perms       = "0600"
}

template {
  content     = "$${file.secrets.certs.auth_worker.key_pem}"
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

# --- Unbound config (domain from enrollment vars) ---

template {
  source      = "/etc/pigeon/unbound.conf.tpl"
  destination = "/etc/unbound/unbound.conf"
  perms       = "0644"
  command     = "systemctl restart unbound"
}

# --- Infrastructure DNS zone (from mesh peers) ---

template {
  source      = "/etc/pigeon/infra.zone.tpl"
  destination = "/etc/unbound/zones/infra.zone"
  perms       = "0644"
  command     = "unbound-control auth_zone_reload ${file.secrets.vars.domain}"
}

template {
  source      = "/etc/pigeon/resolv.conf.tpl"
  destination = "/etc/resolv.conf"
  perms       = "0644"
}

log_level = "info"

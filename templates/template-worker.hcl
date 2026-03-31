source "file" "secrets" {
  path = "/encrypted/pigeon/secrets.json"
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

# --- Auth CA + leaf cert (for vault-agent cert auth to Vault) ---

template {
  content     = <<-EOT
$${file.secrets.ca.auth.cert_pem}
$${file.secrets.ca.auth.private_key_pem}
EOT
  destination = "/encrypted/tls/auth/ca.pem"
  perms       = "0600"
  command     = <<-EOC
    pigeon-enroll generate-cert -from-ca /encrypted/tls/auth/ca.pem \
      -cn $(hostname) \
      -ttl 720h \
      -cert /encrypted/tls/auth/cert.pem \
      -key /encrypted/tls/auth/key.pem \
      -ca /encrypted/tls/auth/ca.crt
  EOC
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

log_level = "info"

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

# --- Vault CA + leaf cert ---

template {
  content     = <<-EOT
$${file.secrets.ca.vault.cert_pem}
$${file.secrets.ca.vault.private_key_pem}
EOT
  destination = "/encrypted/tls/vault/ca.pem"
  perms       = "0600"
  command     = <<-EOC
    (
      set -e
      pigeon-enroll generate-cert -from-ca /encrypted/tls/vault/ca.pem \
        -cn $(hostname) \
        -dns localhost \
        -ip 127.0.0.1 -ttl 720h \
        -cert /encrypted/tls/vault/cert.pem \
        -key /encrypted/tls/vault/key.pem \
        -ca /encrypted/tls/vault/ca.crt
      chown vault:vault /encrypted/tls/vault/{ca.crt,cert.pem,key.pem}
    )
  EOC
}

# --- Consul CA + leaf cert ---

template {
  content     = <<-EOT
$${file.secrets.ca.consul.cert_pem}
$${file.secrets.ca.consul.private_key_pem}
EOT
  destination = "/encrypted/tls/consul/ca.pem"
  perms       = "0600"
  command     = <<-EOC
    (
      set -e
      pigeon-enroll generate-cert -from-ca /encrypted/tls/consul/ca.pem \
        -cn $(hostname) \
        -dns localhost \
        -ip 127.0.0.1 -ttl 720h \
        -cert /encrypted/tls/consul/cert.pem \
        -key /encrypted/tls/consul/key.pem \
        -ca /encrypted/tls/consul/ca.crt
      chown consul:consul /encrypted/tls/consul/{ca.crt,cert.pem,key.pem}
    )
  EOC
}

# --- Nomad CA + leaf cert ---

template {
  content     = <<-EOT
$${file.secrets.ca.nomad.cert_pem}
$${file.secrets.ca.nomad.private_key_pem}
EOT
  destination = "/encrypted/tls/nomad/ca.pem"
  perms       = "0600"
  command     = <<-EOC
    pigeon-enroll generate-cert -from-ca /encrypted/tls/nomad/ca.pem \
      -cn $(hostname) \
      -dns localhost \
      -ip 127.0.0.1 -ttl 720h \
      -cert /encrypted/tls/nomad/cert.pem \
      -key /encrypted/tls/nomad/key.pem \
      -ca /encrypted/tls/nomad/ca.crt
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

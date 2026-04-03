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

# --- Vault CA + leaf cert ---

template {
  content     = <<-EOT
$${file.enroll.ca.vault.cert_pem}
$${file.enroll.ca.vault.private_key_pem}
EOT
  destination = "/encrypted/tls/vault/ca.pem"
  perms       = "0600"
  command     = <<-EOC
    (
      set -e
      pigeon-enroll generate-cert -from-ca /encrypted/tls/vault/ca.pem \
        -cn $(hostname) \
        -dns localhost -dns vault.service.internal -dns active.vault.service.internal \
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
$${file.enroll.ca.consul.cert_pem}
$${file.enroll.ca.consul.private_key_pem}
EOT
  destination = "/encrypted/tls/consul/ca.pem"
  perms       = "0600"
  command     = <<-EOC
    (
      set -e
      pigeon-enroll generate-cert -from-ca /encrypted/tls/consul/ca.pem \
        -cn $(hostname) \
        -dns localhost -dns server.$${file.enroll.vars.datacenter}.internal \
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
$${file.enroll.ca.nomad.cert_pem}
$${file.enroll.ca.nomad.private_key_pem}
EOT
  destination = "/encrypted/tls/nomad/ca.pem"
  perms       = "0600"
  command     = <<-EOC
    pigeon-enroll generate-cert -from-ca /encrypted/tls/nomad/ca.pem \
      -cn $(hostname) \
      -dns localhost -dns server.$${file.enroll.vars.region}.nomad \
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

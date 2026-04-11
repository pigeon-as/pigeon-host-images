vault {
  address = "https://127.0.0.1:8200"
  ca_cert = "/encrypted/tls/vault/ca.crt"
}

auto_auth {
  method "cert" {
    config = {
      name        = "server"
      client_cert = "/encrypted/tls/auth/cert.pem"
      client_key  = "/encrypted/tls/auth/key.pem"
    }
  }
}

template_config {
  exit_on_retry_failure = true
}

# Consul server cert
template {
  source      = "/etc/pigeon/consul-server-key.ctmpl"
  destination = "/encrypted/tls/consul/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/consul-server-cert.ctmpl"
  destination = "/encrypted/tls/consul/cert.pem"
  perms       = 0640
  command     = "chown consul:consul /encrypted/tls/consul/cert.pem /encrypted/tls/consul/key.pem && systemctl reload consul 2>/dev/null || true"
}

# Nomad server cert
template {
  source      = "/etc/pigeon/nomad-server-key.ctmpl"
  destination = "/encrypted/tls/nomad/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/nomad-server-cert.ctmpl"
  destination = "/encrypted/tls/nomad/cert.pem"
  perms       = 0640
  command     = "systemctl reload nomad 2>/dev/null || true"
}

# Vault server cert
template {
  source      = "/etc/pigeon/vault-server-key.ctmpl"
  destination = "/encrypted/tls/vault/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/vault-server-cert.ctmpl"
  destination = "/encrypted/tls/vault/cert.pem"
  perms       = 0640
  command     = "chown vault:vault /encrypted/tls/vault/cert.pem /encrypted/tls/vault/key.pem && systemctl reload vault 2>/dev/null || true"
}

vault {
  address = "https://127.0.0.1:8200"
  ca_cert = "/etc/vault.d/certs/ca.crt"
}

auto_auth {
  method "cert" {
    config = {
      name        = "server"
      client_cert = "/etc/pigeon/certs/auth/cert.pem"
      client_key  = "/etc/pigeon/certs/auth/key.pem"
    }
  }
}

template_config {
  exit_on_retry_failure = true
}

# Consul server cert
template {
  source      = "/etc/pigeon/consul-server-key.ctmpl"
  destination = "/etc/consul.d/certs/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/consul-server-cert.ctmpl"
  destination = "/etc/consul.d/certs/cert.pem"
  perms       = 0640
  command     = "chown consul:consul /etc/consul.d/certs/cert.pem /etc/consul.d/certs/key.pem && systemctl reload consul 2>/dev/null || true"
}

# Nomad server cert
template {
  source      = "/etc/pigeon/nomad-server-key.ctmpl"
  destination = "/etc/nomad.d/certs/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/nomad-server-cert.ctmpl"
  destination = "/etc/nomad.d/certs/cert.pem"
  perms       = 0640
  command     = "systemctl reload nomad 2>/dev/null || true"
}

# Vault server cert
template {
  source      = "/etc/pigeon/vault-server-key.ctmpl"
  destination = "/etc/vault.d/certs/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/vault-server-cert.ctmpl"
  destination = "/etc/vault.d/certs/cert.pem"
  perms       = 0640
  command     = "chown vault:vault /etc/vault.d/certs/cert.pem /etc/vault.d/certs/key.pem && systemctl reload vault 2>/dev/null || true"
}

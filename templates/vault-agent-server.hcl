vault {
  address = "https://127.0.0.1:8200"
  ca_cert = "/etc/vault.d/certs/ca.crt"
}

auto_auth {
  enable_reauth_on_new_credentials = true

  method "cert" {
    config = {
      name        = "server"
      client_cert = "/etc/pigeon/certs/auth/cert.pem"
      client_key  = "/etc/pigeon/certs/auth/key.pem"
      reload      = true
    }
  }
}

template_config {
  exit_on_retry_failure = true
}

# Auth cert self-renewal (Vault PKI replaces bootstrap-CA-signed cert)
template {
  source      = "/etc/pigeon/auth-server-key.ctmpl"
  destination = "/etc/pigeon/certs/auth/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/auth-server-cert.ctmpl"
  destination = "/etc/pigeon/certs/auth/cert.pem"
  perms       = 0600
}

# Mesh CA bundle (Vault root + HKDF mesh CA)
template {
  source      = "/etc/pigeon/mesh-ca.ctmpl"
  destination = "/etc/pigeon/certs/mesh-ca.crt"
  perms       = 0600
}

# Mesh server cert (Vault PKI replaces HKDF cert — certReloader picks up)
template {
  source      = "/etc/pigeon/mesh-server-key.ctmpl"
  destination = "/etc/pigeon/certs/mesh-key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/mesh-server-cert.ctmpl"
  destination = "/etc/pigeon/certs/mesh-cert.pem"
  perms       = 0600
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

# Consul CA bundle (Vault root + bootstrap CA)
template {
  source      = "/etc/pigeon/consul-ca.ctmpl"
  destination = "/etc/consul.d/certs/ca.crt"
  perms       = 0640
  command     = "chown consul:consul /etc/consul.d/certs/ca.crt && systemctl reload consul 2>/dev/null || true"
}

# Nomad CA bundle (Vault root + bootstrap CA)
template {
  source      = "/etc/pigeon/nomad-ca.ctmpl"
  destination = "/etc/nomad.d/certs/ca.crt"
  perms       = 0640
  command     = "systemctl reload nomad 2>/dev/null || true"
}

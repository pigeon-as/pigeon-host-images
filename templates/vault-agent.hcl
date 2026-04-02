vault {
  address = "https://active.vault.service.internal:8200"
  ca_cert = "/encrypted/tls/vault/ca.crt"
}

auto_auth {
  method "cert" {
    config = {
      name        = "worker"
      client_cert = "/encrypted/tls/auth/cert.pem"
      client_key  = "/encrypted/tls/auth/key.pem"
    }
  }
}

template_config {
  exit_on_retry_failure = true
}

template {
  source      = "/etc/pigeon/nomad-key.ctmpl"
  destination = "/encrypted/tls/nomad/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/nomad-cert.ctmpl"
  destination = "/encrypted/tls/nomad/cert.pem"
  perms       = 0640
  command     = "systemctl reload nomad 2>/dev/null || true"
}

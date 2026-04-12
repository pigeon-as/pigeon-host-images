vault {
  address = "https://active.vault.service.internal:8200"
  ca_cert = "/etc/vault.d/certs/ca.crt"
}

auto_auth {
  method "cert" {
    config = {
      name        = "worker"
      client_cert = "/etc/pigeon/certs/auth/cert.pem"
      client_key  = "/etc/pigeon/certs/auth/key.pem"
    }
  }
}

template_config {
  exit_on_retry_failure = true
}

template {
  source      = "/etc/pigeon/nomad-key.ctmpl"
  destination = "/etc/nomad.d/certs/key.pem"
  perms       = 0600
}

template {
  source      = "/etc/pigeon/nomad-cert.ctmpl"
  destination = "/etc/nomad.d/certs/cert.pem"
  perms       = 0640
  command     = "systemctl reload nomad 2>/dev/null || true"
}

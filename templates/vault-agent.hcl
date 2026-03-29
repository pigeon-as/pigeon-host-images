vault {
  address = "https://127.0.0.1:8200"

  tls_skip_verify = true
}

auto_auth {
  method "cert" {
    mount_path = "auth/cert"

    config {
      client_cert = "/encrypted/tls/vault-agent.crt"
      client_key  = "/encrypted/tls/vault-agent.key"
    }
  }

  sink "file" {
    config {
      path = "/encrypted/vault/agent-token"
      mode = 0600
    }
  }
}

template {
  contents    = <<-EOT
    {{- with pkiCert "pki_int/issue/node" (printf "common_name=%s.node.pigeon.internal" (env "HOSTNAME")) "alt_names=localhost" "ip_sans=127.0.0.1" "ttl=72h" }}{{ .Cert }}
    {{ .CA }}{{ end }}
  EOT
  destination = "/encrypted/tls/node.crt"
  perms       = "0600"

  exec {
    command = ["bash", "-c", "systemctl reload vault consul nomad 2>/dev/null || true"]
  }
}

template {
  contents    = <<-EOT
    {{- with pkiCert "pki_int/issue/node" (printf "common_name=%s.node.pigeon.internal" (env "HOSTNAME")) "alt_names=localhost" "ip_sans=127.0.0.1" "ttl=72h" }}{{ .Key }}{{ end }}
  EOT
  destination = "/encrypted/tls/node.key"
  perms       = "0600"
}

template {
  contents    = <<-EOT
    {{- with secret "pki_int/cert/ca_chain" }}{{ .Data.ca_chain }}{{ end }}
  EOT
  destination = "/encrypted/tls/ca-chain.crt"
  perms       = "0644"
}

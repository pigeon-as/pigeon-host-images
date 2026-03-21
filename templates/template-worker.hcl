# pigeon-template config for worker nodes.
#
# Source: /encrypted/pigeon/secrets.json (written by pigeon-enroll --claim at boot)
# Renders: mesh.json, consul.hcl, nomad.hcl
#
# Secret values that must be JSON arrays (not comma-separated):
#   mesh_seeds, consul_retry_join, nomad_servers

source "secrets" "file" {
  path = "/encrypted/pigeon/secrets.json"
}

# --- pigeon-mesh ---

template {
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $s := index $d "secrets" -}}
    {{ $v := index $d "vars" -}}
    {
      "seeds": {{ index $v "mesh_seeds" }},
      "gossip_key": "{{ index $s "gossip_key" }}",
      "wg_psk": "{{ index $s "wg_psk" }}",
      "egress_cidr": "{{ index $v "egress_cidr" }}"
    }
    EOT
  destination = "/encrypted/pigeon/mesh.json"
  perms       = "0600"
}

# --- Consul (client mode) ---

template {
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $s := index $d "secrets" -}}
    {{ $v := index $d "vars" -}}
    datacenter = "{{ index $v "datacenter" }}"
    domain     = "internal"

    server = false

    bind_addr   = "{{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
    client_addr = "127.0.0.1 {{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"

    retry_join = {{ index $v "consul_retry_join" }}

    encrypt = "{{ index $s "consul_encrypt" }}"

    acl {
      enabled        = true
      default_policy = "deny"

      tokens {
        agent = "{{ index $s "consul_agent_token" }}"
      }
    }

    ports {
      dns   = 8600
      http  = 8500
      https = -1
    }
    EOT
  destination = "/encrypted/consul/consul.hcl"
  perms       = "0640"
}

# --- Nomad (client only) ---

template {
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $s := index $d "secrets" -}}
    {{ $v := index $d "vars" -}}
    datacenter = "{{ index $v "datacenter" }}"
    region     = "{{ index $v "region" }}"

    client {
      enabled = true
    }

    addresses {
      http = "127.0.0.1 {{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
      rpc  = "{{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
      serf = "{{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
    }

    servers = {{ index $v "nomad_servers" }}

    consul {
      address = "127.0.0.1:8500"
      token   = "{{ index $s \"consul_agent_token\" }}"
      service_identity {
        aud = ["consul.io"]
        ttl = "1h"
      }

      task_identity {
        aud = ["consul.io"]
        ttl = "1h"
      }
    }

    vault {
      enabled          = true
      address          = "https://active.vault.service.internal:8200"
      tls_skip_verify  = true

      default_identity {
        aud  = ["vault.io"]
        env  = false
        file = false
        ttl  = "1h"
      }
    }

    acl {
      enabled = true
    }
    EOT
  destination = "/encrypted/nomad/nomad.hcl"
  perms       = "0640"
}

wait {
  min = "100ms"
  max = "1s"
}

log_level = "info"

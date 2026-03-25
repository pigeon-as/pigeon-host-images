source "file" "secrets" {
  path = "/encrypted/pigeon/secrets.json"
}

source "exec" "enroll_token" {
  command  = "pigeon-enroll generate-token -config=/encrypted/pigeon/enroll.json"
  interval = "10m"
}

template {
  destination = "/encrypted/pigeon/mesh.json"
  perms       = "0600"
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $s := index $d "secrets" -}}
    {{ $v := index $d "vars" -}}
    {
      "seeds": {{ index $v "mesh_seeds" }},
      "gossip_key": "{{ index $s "gossip_key" }}",
      "wg_psk": "{{ index $s "wg_psk" }}",
      "endpoint_interface": "eth0",
      "egress_cidr": "{{ index $v "egress_cidr" }}"
    }
    EOT
}

template {
  destination = "/encrypted/consul/consul.hcl"
  perms       = "0640"
  user        = "consul"
  group       = "consul"
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $s := index $d "secrets" -}}
    {{ $v := index $d "vars" -}}
    datacenter = "{{ index $v "datacenter" }}"
    domain     = "internal"

    server           = true
    bootstrap_expect = 3

    bind_addr   = "{{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
    client_addr = "127.0.0.1 {{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"

    retry_join = {{ index $v "consul_retry_join" }}

    encrypt = "{{ index $s "consul_encrypt" }}"

    acl {
      enabled                  = true
      default_policy           = "deny"
      enable_token_persistence = true

      tokens {
        initial_management = "{{ index $s "consul_bootstrap_token" }}"
        agent              = "{{ index $s "consul_bootstrap_token" }}"
      }
    }

    ports {
      dns   = 8600
      http  = 8500
      https = -1
    }
    EOT
}

template {
  destination = "/encrypted/vault/vault.hcl"
  perms       = "0640"
  user        = "vault"
  group       = "vault"
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $s := index $d "secrets" -}}
    {{ $v := index $d "vars" -}}
    ui = true

    listener "tcp" {
      address         = "0.0.0.0:8200"
      tls_cert_file   = "/encrypted/tls/server.crt"
      tls_key_file    = "/encrypted/tls/server.key"
      tls_min_version = "tls12"
    }

    storage "consul" {
      address = "127.0.0.1:8500"
      path    = "vault/"
      token   = "{{ index $s "consul_bootstrap_token" }}"
    }

    seal "azurekeyvault" {
      tenant_id     = "{{ index $v "seal_tenant_id" }}"
      client_id     = "{{ index $v "seal_client_id" }}"
      client_secret = "{{ index $v "seal_client_secret" }}"
      vault_name    = "{{ index $v "seal_key_vault_name" }}"
      key_name      = "{{ index $v "seal_key_name" }}"
    }

    disable_mlock = false
    EOT
}

template {
  destination = "/encrypted/nomad/nomad.hcl"
  perms       = "0640"
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $s := index $d "secrets" -}}
    {{ $v := index $d "vars" -}}
    datacenter = "{{ index $v "datacenter" }}"
    region     = "{{ index $v "region" }}"

    server {
      enabled          = true
      bootstrap_expect = 3
    }

    client {
      enabled = true
    }

    addresses {
      http = "127.0.0.1 {{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
      rpc  = "{{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
      serf = "{{ "{{" }} GetInterfaceIP \"wg0\" {{ "}}" }}"
    }

    consul {
      address = "127.0.0.1:8500"
      token   = "{{ index $s "consul_bootstrap_token" }}"

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
      address          = "https://127.0.0.1:8200"
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
}

template {
  destination = "/encrypted/pigeon/fence.d/ovh.hcl"
  perms       = "0600"
  contents = <<-EOT
    {{ $d := .secrets | parseJSON -}}
    {{ $v := index $d "vars" -}}
    provider "ovh" {
      endpoint           = "ovh-eu"
      application_key    = "{{ index $v "ovh_application_key" }}"
      application_secret = "{{ index $v "ovh_application_secret" }}"
      consumer_key       = "{{ index $v "ovh_consumer_key" }}"
    }

    data "ovh_ips" "servers" {}

    rule "allow_wireguard_inbound" {
      provider  = provider.nftables
      direction = "inbound"
      protocol  = "udp"
      dst_port  = ["51820"]
      source    = [data.ovh_ips.servers]
      action    = "accept"
      comment   = "WireGuard tunnel (fleet only)"
    }

    rule "allow_memberlist_tcp_inbound" {
      provider  = provider.nftables
      direction = "inbound"
      protocol  = "tcp"
      dst_port  = ["7946"]
      source    = [data.ovh_ips.servers]
      action    = "accept"
      comment   = "Memberlist gossip (fleet only)"
    }

    rule "allow_memberlist_udp_inbound" {
      provider  = provider.nftables
      direction = "inbound"
      protocol  = "udp"
      dst_port  = ["7946"]
      source    = [data.ovh_ips.servers]
      action    = "accept"
      comment   = "Memberlist gossip (fleet only)"
    }
    EOT
}

template {
  destination = "/etc/pigeon/worker-userdata.sh"
  perms       = "0600"
  contents = <<-EOT
    #!/bin/bash
    {{ $d := .secrets | parseJSON -}}
    {{ $v := index $d "vars" -}}
    export ENROLL_URL="{{ index $v "enroll_url" }}"
    export ENROLL_TOKEN="{{ .enroll_token }}"
    exec /usr/local/bin/setup-worker.sh
    EOT
}

wait {
  min = "100ms"
  max = "1s"
}

log_level = "info"

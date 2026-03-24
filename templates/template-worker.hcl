source "file" "secrets" {
  path = "/encrypted/pigeon/secrets.json"
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

wait {
  min = "100ms"
  max = "1s"
}

log_level = "info"

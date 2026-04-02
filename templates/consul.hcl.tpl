datacenter = "${vars.datacenter}"
domain     = "internal"

server = false

bind_addr   = "{{ GetInterfaceIP \"wg0\" }}"
client_addr = "127.0.0.1"

addresses {
  https = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
  dns   = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
}

retry_join = ["servers.${vars.datacenter}.${vars.region}.${vars.domain}"]

auto_encrypt {
  tls = true
}

encrypt = "${secrets.consul_encrypt}"

acl {
  enabled        = true
  default_policy = "deny"

  tokens {
    agent = "${secrets.consul_agent_token}"
  }
}

tls {
  defaults {
    ca_file = "/encrypted/tls/consul/ca.crt"
  }
  internal_rpc {
    verify_incoming        = false
    verify_outgoing        = true
    verify_server_hostname = true
  }
}

ports {
  dns   = 8600
  http  = 8500
  https = 8501
}
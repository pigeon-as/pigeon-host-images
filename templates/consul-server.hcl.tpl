datacenter = "${vars.datacenter}"
domain     = "internal"

server           = true
bootstrap_expect = 3

bind_addr   = "{{ GetInterfaceIP \"wg0\" }}"
client_addr = "127.0.0.1"

addresses {
  https = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
  dns   = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
}

retry_join = ${vars.consul_retry_join}

encrypt = "${secrets.consul_encrypt}"

acl {
  enabled                  = true
  default_policy           = "deny"
  enable_token_persistence = true

  tokens {
    initial_management = "${secrets.consul_bootstrap_token}"
    agent              = "${secrets.consul_bootstrap_token}"
  }
}

tls {
  defaults {
    ca_file   = "/encrypted/tls/consul/ca.crt"
    cert_file = "/encrypted/tls/consul/cert.pem"
    key_file  = "/encrypted/tls/consul/key.pem"
  }
  internal_rpc {
    verify_incoming        = true
    verify_outgoing        = true
    verify_server_hostname = true
  }
}

ports {
  dns   = 8600
  http  = 8500
  https = 8501
}

datacenter = "${vars.datacenter}"
domain     = "internal"

server           = true
bootstrap_expect = 3

bind_addr   = "{{ GetInterfaceIP \"wg0\" }}"
client_addr = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"

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

ports {
  dns   = 8600
  http  = 8500
  https = -1
}

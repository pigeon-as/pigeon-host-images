datacenter = "${vars.datacenter}"
domain     = "internal"

server = false

bind_addr   = "{{ GetInterfaceIP \"wg0\" }}"
client_addr = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"

retry_join = ${vars.consul_retry_join}

encrypt = "${secrets.consul_encrypt}"

acl {
  enabled        = true
  default_policy = "deny"

  tokens {
    agent = "${secrets.consul_agent_token}"
  }
}

ports {
  dns   = 8600
  http  = 8500
  https = -1
}
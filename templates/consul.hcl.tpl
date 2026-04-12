datacenter = "${file.enroll.vars.datacenter}"
domain     = "internal"

server = false

bind_addr   = "{{ GetInterfaceIP \"wg0\" }}"
client_addr = "127.0.0.1"

addresses {
  https = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
  dns   = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
}

retry_join = ["servers.${file.enroll.vars.datacenter}.${file.enroll.vars.domain}"]

auto_config {
  enabled          = true
  intro_token_file = "/etc/consul.d/intro-token.jwt"
}

encrypt = "${file.enroll.secrets.consul_encrypt}"

acl {
  enabled        = true
  default_policy = "deny"
}

tls {
  defaults {
    ca_file = "/etc/consul.d/certs/ca.crt"
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
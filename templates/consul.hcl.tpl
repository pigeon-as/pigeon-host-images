datacenter = "${file.enroll.vars.datacenter}"
domain     = "internal"

server = false

bind_addr   = "{{ GetInterfaceIP \"wg0\" }}"
client_addr = "127.0.0.1"

leave_on_terminate = true

addresses {
  http  = "unix:///run/consul/consul.sock"
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

# HVD: disable plaintext HTTP listener. Local access via unix socket.
ports {
  dns   = 8600
  http  = -1
  https = 8501
}
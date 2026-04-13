datacenter = "${file.enroll.vars.datacenter}"
domain     = "internal"

server           = true
bootstrap_expect = 3

bind_addr   = "{{ GetInterfaceIP \"wg0\" }}"
client_addr = "127.0.0.1"

addresses {
  https = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
  dns   = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
}

retry_join = ["servers.${file.enroll.vars.datacenter}.${file.enroll.vars.domain}"]

retry_join_wan = ["servers.${file.enroll.vars.domain}"]

auto_config {
  authorization {
    enabled = true
    static {
      jwt_validation_pub_keys = ["${file.enroll.jwt_keys.consul_auto_config}"]
      bound_issuer            = "pigeon-enroll"
      bound_audiences         = ["consul-auto-config"]
      claim_assertions        = ["value.sub == \"$${node}\""]
    }
  }
}

encrypt = "${file.enroll.secrets.consul_encrypt}"

acl {
  enabled                  = true
  default_policy           = "deny"
  enable_token_persistence = true

  # HVD: management token for both initial_management and agent on servers.
  tokens {
    initial_management = "${file.enroll.secrets.consul_bootstrap_token}"
    agent              = "${file.enroll.secrets.consul_bootstrap_token}"
  }
}

tls {
  defaults {
    ca_file   = "/etc/consul.d/certs/ca.crt"
    cert_file = "/etc/consul.d/certs/cert.pem"
    key_file  = "/etc/consul.d/certs/key.pem"
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

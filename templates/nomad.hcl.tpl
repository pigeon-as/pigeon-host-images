datacenter = "${vars.datacenter}"
region     = "${vars.region}"

client {
  enabled = true
}

tls {
  http      = true
  rpc       = true
  ca_file   = "/encrypted/tls/nomad/ca.crt"
  cert_file = "/encrypted/tls/nomad/cert.pem"
  key_file  = "/encrypted/tls/nomad/key.pem"
  verify_server_hostname = true
}

addresses {
  http = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
  rpc  = "{{ GetInterfaceIP \"wg0\" }}"
  serf = "{{ GetInterfaceIP \"wg0\" }}"
}

servers = ${vars.nomad_servers}

consul {
  address = "127.0.0.1:8500"
  token   = "${secrets.consul_agent_token}"
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
  tls_ca_file      = "/encrypted/tls/vault/ca.crt"

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
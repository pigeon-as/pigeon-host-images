datacenter = "${vars.datacenter}"
region     = "${vars.region}"

server {
  enabled          = true
  bootstrap_expect = 3

  server_join {
    retry_join = ["servers.${vars.domain}"]
  }
}

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

consul {
  address = "127.0.0.1:8500"
  token   = "${secrets.consul_bootstrap_token}"

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

datacenter = "${vars.datacenter}"
region     = "${vars.region}"

server {
  enabled          = true
  bootstrap_expect = 3
}

client {
  enabled = true
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

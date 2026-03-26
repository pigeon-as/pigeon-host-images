datacenter = "${vars.datacenter}"
region     = "${vars.region}"

client {
  enabled = true
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
datacenter = "${file.enroll.vars.datacenter}"
region     = "${file.enroll.vars.region}"
data_dir   = "/opt/nomad/data"

server {
  enabled          = true
  bootstrap_expect = 3
  encrypt          = "${file.enroll.secrets.nomad_gossip_key}"

  server_join {
    retry_join = ["servers.${file.enroll.vars.domain}"]
  }
}

client {
  enabled = true
}

tls {
  http      = true
  rpc       = true
  ca_file   = "/etc/nomad.d/certs/ca.crt"
  cert_file = "/etc/nomad.d/certs/cert.pem"
  key_file  = "/etc/nomad.d/certs/key.pem"
  verify_server_hostname = true
}

addresses {
  http = "127.0.0.1 {{ GetInterfaceIP \"wg0\" }}"
  rpc  = "{{ GetInterfaceIP \"wg0\" }}"
  serf = "{{ GetInterfaceIP \"wg0\" }}"
}

# HVD: management token for server Consul registration. Workloads use WI.
consul {
  address = "unix:///run/consul/consul.sock"
  token   = "${file.enroll.secrets.consul_bootstrap_token}"

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
  tls_ca_file      = "/etc/vault.d/certs/ca.crt"

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

telemetry {
  collection_interval        = "1s"
  disable_hostname           = true
  prometheus_metrics          = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
}

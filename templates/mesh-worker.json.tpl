{
  "seeds": ${vars.mesh_seeds},
  "gossip_key": "${secrets.gossip_key}",
  "wg_psk": "${secrets.wg_psk}",
  "endpoint_interface": "eth0",
  "egress_cidr": "${vars.egress_cidr}",
  "datacenter": "${vars.datacenter}",
  "tls_ca_cert": "/encrypted/pigeon/mesh-ca.crt",
  "tls_cert_file": "/encrypted/pigeon/mesh-cert.pem",
  "tls_key_file": "/encrypted/pigeon/mesh-key.pem",
  "tls_server_name": "mesh.pigeon.internal"
}

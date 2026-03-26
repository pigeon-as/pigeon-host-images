{
  "seeds": ${vars.mesh_seeds},
  "gossip_key": "${secrets.gossip_key}",
  "wg_psk": "${secrets.wg_psk}",
  "endpoint_interface": "eth0",
  "egress_cidr": "${vars.egress_cidr}",
  "tls_ca_cert": "/encrypted/pigeon/mesh-ca.crt",
  "tls_ca_key": "/encrypted/pigeon/mesh-ca.key"
}
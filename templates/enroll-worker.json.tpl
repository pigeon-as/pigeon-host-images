{
  "vars": {
    "datacenter":  "${var.datacenter}",
    "region":      "${var.region}",
    "domain":      "${var.domain}",
    "enroll_url":  "${var.enroll_url}",
    "mesh_seeds":  ${var.mesh_seeds},
    "egress_cidr": "${var.egress_cidr}"
  },
  "secrets": {
    "gossip_key":         "${secret.gossip_key}",
    "consul_encrypt":     "${secret.consul_encrypt}",
    "consul_agent_token": "${secret.consul_agent_token}"
  }
}

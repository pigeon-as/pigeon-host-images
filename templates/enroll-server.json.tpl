{
  "vars": {
    "datacenter":          "${var.datacenter}",
    "region":              "${var.region}",
    "domain":              "${var.domain}",
    "enroll_url":          "${var.enroll_url}",
    "anycast_ipv4":        "${var.anycast_ipv4}",
    "anycast_ipv6":        "${var.anycast_ipv6}",
    "local_asn":           "${var.local_asn}",
    "egress_cidr":         "${var.egress_cidr}",
    "mesh_seeds":          ${var.mesh_seeds},
    "seal_key_vault_name": "${var.seal_key_vault_name}",
    "seal_key_name":       "${var.seal_key_name}",
    "seal_tenant_id":      "${var.seal_tenant_id}",
    "seal_client_id":      "${var.seal_client_id}",
    "seal_client_secret":  "${var.seal_client_secret}"
  },
  "secrets": {
    "gossip_key":             "${secret.gossip_key}",
    "consul_encrypt":         "${secret.consul_encrypt}",
    "consul_agent_token":     "${secret.consul_agent_token}",
    "consul_bootstrap_token": "${secret.consul_bootstrap_token}",
    "nomad_bootstrap_token":  "${secret.nomad_bootstrap_token}",
    "nomad_gossip_key":       "${secret.nomad_gossip_key}",
    "vault_management_token": "${secret.vault_management_token}",
    "luks_recovery":          "${secret.luks_recovery}"
  }
}

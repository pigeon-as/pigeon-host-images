ui = true

listener "tcp" {
  address         = "{{ GetInterfaceIP \"wg0\" }}:8200"
  tls_cert_file   = "/etc/vault.d/certs/cert.pem"
  tls_key_file    = "/etc/vault.d/certs/key.pem"
  tls_min_version = "tls12"
}

listener "tcp" {
  address         = "127.0.0.1:8200"
  tls_cert_file   = "/etc/vault.d/certs/cert.pem"
  tls_key_file    = "/etc/vault.d/certs/key.pem"
  tls_min_version = "tls12"
}

api_addr     = "https://vault.service.internal:8200"
cluster_addr = "https://{{ GetInterfaceIP \"wg0\" }}:8201"

storage "raft" {
  path = "/opt/vault/data"

  retry_join {
    leader_api_addr       = "https://servers.${file.enroll.vars.datacenter}.${file.enroll.vars.domain}:8200"
    leader_tls_servername = "vault.service.internal"
    leader_ca_cert_file   = "/etc/vault.d/certs/ca.crt"
  }
}

service_registration "consul" {
  address = "unix:///run/consul/consul.sock"
  token   = "${file.enroll.secrets.consul_bootstrap_token}"
}

seal "azurekeyvault" {
  tenant_id     = "${file.enroll.vars.seal_tenant_id}"
  client_id     = "${file.enroll.vars.seal_client_id}"
  client_secret = "${file.enroll.vars.seal_client_secret}"
  vault_name    = "${file.enroll.vars.seal_key_vault_name}"
  key_name      = "${file.enroll.vars.seal_key_name}"
}

disable_mlock = true

default_lease_ttl = "768h"
max_lease_ttl     = "768h"

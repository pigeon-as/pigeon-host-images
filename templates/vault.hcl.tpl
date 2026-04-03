ui = true

listener "tcp" {
  address         = "0.0.0.0:8200"
  tls_cert_file   = "/encrypted/tls/vault/cert.pem"
  tls_key_file    = "/encrypted/tls/vault/key.pem"
  tls_min_version = "tls12"
}

storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
  token   = "${file.enroll.secrets.consul_bootstrap_token}"
}

seal "azurekeyvault" {
  tenant_id     = "${file.enroll.vars.seal_tenant_id}"
  client_id     = "${file.enroll.vars.seal_client_id}"
  client_secret = "${file.enroll.vars.seal_client_secret}"
  vault_name    = "${file.enroll.vars.seal_key_vault_name}"
  key_name      = "${file.enroll.vars.seal_key_name}"
}

disable_mlock = false

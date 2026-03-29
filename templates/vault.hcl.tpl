ui = true

listener "tcp" {
  address         = "0.0.0.0:8200"
  tls_cert_file   = "/encrypted/tls/node.crt"
  tls_key_file    = "/encrypted/tls/node.key"
  tls_min_version = "tls12"
}

storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
  token   = "${secrets.consul_bootstrap_token}"
}

seal "azurekeyvault" {
  tenant_id     = "${vars.seal_tenant_id}"
  client_id     = "${vars.seal_client_id}"
  client_secret = "${vars.seal_client_secret}"
  vault_name    = "${vars.seal_key_vault_name}"
  key_name      = "${vars.seal_key_name}"
}

disable_mlock = false

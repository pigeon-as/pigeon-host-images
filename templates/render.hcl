template {
  source      = "/etc/pigeon/templates/mesh-ca.crt.tpl"
  destination = "/encrypted/pigeon/mesh-ca.crt"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/templates/mesh-ca.key.tpl"
  destination = "/encrypted/pigeon/mesh-ca.key"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/templates/mesh.json.tpl"
  destination = "/encrypted/pigeon/mesh.json"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/templates/fence-ovh.hcl.tpl"
  destination = "/encrypted/pigeon/fence.d/ovh.hcl"
  perms       = "0600"
}

template {
  source      = "/etc/pigeon/templates/consul.hcl.tpl"
  destination = "/encrypted/consul/consul.hcl"
  perms       = "0640"
}

template {
  source      = "/etc/pigeon/templates/nomad.hcl.tpl"
  destination = "/encrypted/nomad/nomad.hcl"
  perms       = "0640"
}

source "file" "secrets" {
  path = "/encrypted/pigeon/secrets.json"
}

source "exec" "enroll_token" {
  command  = "pigeon-enroll generate-token -config=/encrypted/pigeon/enroll.hcl"
  interval = "10m"
}

source "exec" "enroll_cert" {
  command  = "pigeon-enroll generate-cert -base64 -config=/encrypted/pigeon/enroll.hcl"
  interval = "30m"
}

template {
  source      = "/etc/pigeon/templates/worker-userdata.sh.tpl"
  destination = "/etc/pigeon/worker-userdata.sh"
  perms       = "0600"
}

wait {
  min = "5s"
  max = "30s"
}

log_level = "info"

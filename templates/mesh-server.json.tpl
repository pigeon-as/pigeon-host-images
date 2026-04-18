{
  "role": "control-plane",
  "seeds": ${file.enroll.vars.mesh_seeds},
  "endpoint_interface": "eth0",
  "egress_cidr": "${file.enroll.vars.egress_cidr}",
  "datacenter": "${file.enroll.vars.datacenter}",
  "tls_ca_cert": "/etc/pigeon/certs/mesh-ca.crt",
  "tls_cert_file": "/etc/pigeon/certs/mesh-cert.pem",
  "tls_key_file": "/etc/pigeon/certs/mesh-key.pem",
  "tls_server_name": "mesh.pigeon.internal"
}

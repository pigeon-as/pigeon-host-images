#!/bin/bash -ex
# Install Consul via HashiCorp apt repo.

apt-get install -y "consul=${CONSUL_VERSION}"
systemctl enable consul

echo 'export CONSUL_HTTP_ADDR="http://127.0.0.1:8500"' >> /etc/profile.d/pigeon.sh

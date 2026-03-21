#!/bin/bash -ex
# Install Nomad via HashiCorp apt repo.

apt-get install -y "nomad=${NOMAD_VERSION}"
mkdir -p /opt/nomad/plugins
systemctl enable nomad

echo 'export NOMAD_ADDR="http://127.0.0.1:4646"' >> /etc/profile.d/pigeon.sh

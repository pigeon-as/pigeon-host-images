#!/bin/bash
set -ex

ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

mkdir -p /opt/nomad/plugins

curl -fsSL -o /opt/nomad/plugins/nomad-driver-firecracker \
  "https://github.com/pigeon-as/nomad-driver-firecracker/releases/download/v${DRIVER_VERSION}/nomad-driver-firecracker_linux_${ARCH}"
chmod 0755 /opt/nomad/plugins/nomad-driver-firecracker

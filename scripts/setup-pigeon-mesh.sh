#!/bin/bash -ex

ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

mkdir -p /opt/pigeon/bin /etc/pigeon

curl -fsSL -o /opt/pigeon/bin/pigeon-mesh \
  "https://github.com/pigeon-as/pigeon-mesh/releases/download/v${PIGEON_MESH_VERSION}/pigeon-mesh_linux_${ARCH}"
chmod 0755 /opt/pigeon/bin/pigeon-mesh

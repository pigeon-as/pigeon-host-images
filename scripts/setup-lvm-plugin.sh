#!/bin/bash
set -ex

VERSION="${LVM_PLUGIN_VERSION:?must set a version}"
ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

mkdir -p /opt/nomad/plugins

curl -fsSL -o /opt/nomad/plugins/nomad-plugin-lvm \
  "https://github.com/pigeon-as/nomad-plugin-lvm/releases/download/v${VERSION}/nomad-plugin-lvm_linux_${ARCH}"
chmod 0755 /opt/nomad/plugins/nomad-plugin-lvm

#!/bin/bash
set -ex

VERSION="${PIGEON_PROVISIONER_VERSION:?must set a version}"
ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

curl -fsSL -o /opt/pigeon/bin/pigeon-provisioner \
  "https://github.com/pigeon-as/pigeon-provisioner/releases/download/v${VERSION}/pigeon-provisioner_linux_${ARCH}"
chmod 0755 /opt/pigeon/bin/pigeon-provisioner
ln -sf /opt/pigeon/bin/pigeon-provisioner /usr/local/bin/pigeon-provisioner

#!/bin/bash
set -ex

VERSION="${PIGEON_TEMPLATE_VERSION:?must set a version}"
ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

mkdir -p /opt/pigeon/bin /etc/pigeon

curl -fsSL -o /opt/pigeon/bin/pigeon-template \
  "https://github.com/pigeon-as/pigeon-template/releases/download/v${VERSION}/pigeon-template_linux_${ARCH}"
chmod 0755 /opt/pigeon/bin/pigeon-template

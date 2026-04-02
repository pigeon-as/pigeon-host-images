#!/bin/bash
set -ex

VERSION="${PIGEON_PETNAME_VERSION:?must set a version}"
ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

curl -fsSL -o /opt/pigeon/bin/pigeon-petname \
  "https://github.com/pigeon-as/pigeon-petname/releases/download/v${VERSION}/pigeon-petname_linux_${ARCH}"
chmod 0755 /opt/pigeon/bin/pigeon-petname
ln -sf /opt/pigeon/bin/pigeon-petname /usr/local/bin/pigeon-petname

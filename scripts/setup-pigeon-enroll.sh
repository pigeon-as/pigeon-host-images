#!/bin/bash
set -ex

VERSION="${PIGEON_ENROLL_VERSION:?must set a version}"
ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

curl -fsSL -o /opt/pigeon/bin/pigeon-enroll \
  "https://github.com/pigeon-as/pigeon-enroll/releases/download/v${VERSION}/pigeon-enroll_linux_${ARCH}"
chmod 0755 /opt/pigeon/bin/pigeon-enroll
ln -sf /opt/pigeon/bin/pigeon-enroll /usr/local/bin/pigeon-enroll

#!/bin/bash -ex
# Install pigeon-enroll binary.

ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

mkdir -p /opt/pigeon/bin /etc/pigeon

curl -fsSL -o /opt/pigeon/bin/pigeon-enroll \
  "https://github.com/pigeon-as/pigeon-enroll/releases/download/v${PIGEON_ENROLL_VERSION}/pigeon-enroll_linux_${ARCH}"
chmod 0755 /opt/pigeon/bin/pigeon-enroll

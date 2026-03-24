#!/bin/bash
set -ex

VERSION="${PIGEON_FENCE_VERSION:?must set a version}"
ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

mkdir -p /opt/pigeon/bin /etc/pigeon

echo "Installing pigeon-fence ${VERSION} (${ARCH})..."
curl -fsSL -o /opt/pigeon/bin/pigeon-fence \
  "https://github.com/pigeon-as/pigeon-fence/releases/download/v${VERSION}/pigeon-fence-linux-${ARCH}"
chmod 0755 /opt/pigeon/bin/pigeon-fence

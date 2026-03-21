#!/bin/bash -ex
set -o pipefail
# Install CNI plugins.

ARCH=$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)

mkdir -p /opt/cni/bin /opt/cni/net.d

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

curl -fsSL -o "$tmp/cni.tgz" \
  "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${ARCH}-v${CNI_VERSION}.tgz"
curl -fsSL -o "$tmp/cni.tgz.sha256" \
  "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${ARCH}-v${CNI_VERSION}.tgz.sha256"
echo "$(cat "$tmp/cni.tgz.sha256")  $tmp/cni.tgz" | sha256sum -c -
tar -xzf "$tmp/cni.tgz" -C /opt/cni/bin

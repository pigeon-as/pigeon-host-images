#!/bin/bash -ex
set -o pipefail
# Install Firecracker and jailer binaries.

ARCH=$(uname -m)

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

release="firecracker-v${FIRECRACKER_VERSION}-${ARCH}"
curl -fsSL -o "$tmp/fc.tgz" \
  "https://github.com/firecracker-microvm/firecracker/releases/download/v${FIRECRACKER_VERSION}/${release}.tgz"
curl -fsSL -o "$tmp/SHA256SUMS" \
  "https://github.com/firecracker-microvm/firecracker/releases/download/v${FIRECRACKER_VERSION}/SHA256SUMS"
(cd "$tmp" && grep "${release}.tgz" SHA256SUMS | sha256sum -c -)
tar -xzf "$tmp/fc.tgz" -C "$tmp"

install -m 0755 "$tmp/${release}/firecracker-v${FIRECRACKER_VERSION}-${ARCH}" /usr/local/bin/firecracker
install -m 0755 "$tmp/${release}/jailer-v${FIRECRACKER_VERSION}-${ARCH}" /usr/local/bin/jailer

#!/bin/bash
set -exo pipefail

VERSION="${FIRECRACKER_VERSION:?must set a version}"
ARCH=$(uname -m)

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

release="firecracker-v${VERSION}-${ARCH}"
curl -fsSL -o "$tmp/fc.tgz" \
  "https://github.com/firecracker-microvm/firecracker/releases/download/v${VERSION}/${release}.tgz"
curl -fsSL -o "$tmp/SHA256SUMS" \
  "https://github.com/firecracker-microvm/firecracker/releases/download/v${VERSION}/SHA256SUMS"
(cd "$tmp" && grep "${release}.tgz" SHA256SUMS | sha256sum -c -)
tar -xzf "$tmp/fc.tgz" -C "$tmp"

install -m 0755 "$tmp/${release}/firecracker-v${VERSION}-${ARCH}" /usr/local/bin/firecracker
install -m 0755 "$tmp/${release}/jailer-v${VERSION}-${ARCH}" /usr/local/bin/jailer

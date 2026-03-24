#!/bin/bash
set -ex

VERSION="${CONSUL_VERSION:?must set a version}"

apt-get install -y "consul=${VERSION}"
systemctl enable consul

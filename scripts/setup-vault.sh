#!/bin/bash
set -ex

VERSION="${VAULT_VERSION:?must set a version}"

apt-get install -y "vault=${VERSION}"

# Shell env for interactive sessions
echo 'export VAULT_ADDR="https://127.0.0.1:8200"' >> /etc/profile.d/pigeon.sh
echo 'export VAULT_CACERT="/encrypted/tls/vault/ca.crt"' >> /etc/profile.d/pigeon.sh

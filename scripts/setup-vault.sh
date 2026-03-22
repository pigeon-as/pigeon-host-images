#!/bin/bash -ex

apt-get install -y "vault=${VAULT_VERSION}"
systemctl enable vault

echo 'export VAULT_ADDR="https://127.0.0.1:8200"' >> /etc/profile.d/pigeon.sh
echo 'export VAULT_SKIP_VERIFY=1' >> /etc/profile.d/pigeon.sh

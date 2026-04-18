#!/bin/bash
set -ex

VERSION="${VAULT_VERSION:?must set a version}"

apt-get install -y "vault=${VERSION}"

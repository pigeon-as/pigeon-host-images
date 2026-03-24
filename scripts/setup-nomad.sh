#!/bin/bash
set -ex

VERSION="${NOMAD_VERSION:?must set a version}"

apt-get install -y "nomad=${VERSION}"
mkdir -p /opt/nomad/plugins
systemctl enable nomad

#!/bin/bash -ex
# Install nftables.

apt-get install -y nftables
systemctl enable nftables

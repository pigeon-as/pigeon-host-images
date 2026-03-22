#!/bin/bash
set -ex

apt-get install -y nftables
systemctl enable nftables

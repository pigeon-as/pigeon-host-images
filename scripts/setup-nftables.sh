#!/bin/bash -ex

apt-get install -y nftables
systemctl enable nftables

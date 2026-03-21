#!/bin/bash -ex
# Install BIRD2 for BGP anycast.

apt-get install -y bird2
systemctl enable bird

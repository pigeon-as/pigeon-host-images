#!/bin/bash -ex
# Install HAProxy.

apt-get install -y haproxy
systemctl enable haproxy

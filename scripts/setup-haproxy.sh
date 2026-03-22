#!/bin/bash
set -ex

apt-get install -y haproxy
systemctl enable haproxy

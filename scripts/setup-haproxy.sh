#!/bin/bash -ex

apt-get install -y haproxy
systemctl enable haproxy

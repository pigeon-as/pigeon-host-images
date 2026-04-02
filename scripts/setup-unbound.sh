#!/bin/bash
set -ex

apt-get install -y unbound

# Generate control socket keys for unbound-control (zone reload)
unbound-control-setup

# Disable default service — the systemctl enable block is the single source of truth
systemctl disable unbound

#!/bin/bash
set -ex

apt-get install -y unbound

# Generate control socket keys for unbound-control (zone reload)
unbound-control-setup

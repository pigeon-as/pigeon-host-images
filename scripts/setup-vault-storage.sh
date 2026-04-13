#!/bin/bash
set -ex

# Raft Integrated Storage data directory
mkdir -p /opt/vault/data
chown vault:vault /opt/vault/data

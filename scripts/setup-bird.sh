#!/bin/bash
set -ex

apt-get install -y bird2
systemctl enable bird

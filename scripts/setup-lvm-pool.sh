#!/bin/bash
set -euo pipefail
# First-boot oneshot: convert md2 (dead OVH staging partition) into an LVM thin pool.
# md2 is the remainder of the NVMe RAID1 array after md0 (ESP) and md1 (LUKS root).
# After make-image-bootable.sh runs and the server reboots, md2 is unused.

SENTINEL="/var/lib/pigeon/lvm-pool-ready"
VG="vg0"
POOL="thinpool"
DEV="/dev/md2"

if [ -f "$SENTINEL" ]; then
  echo "LVM pool already initialized, skipping"
  exit 0
fi

if [ ! -b "$DEV" ]; then
  echo "FATAL: $DEV not found" >&2
  exit 1
fi

# Wipe any existing filesystem signatures from OVH staging
wipefs -a "$DEV"

# Create PV → VG → thin pool (80% of VG for data, remainder for metadata + overcommit headroom)
pvcreate "$DEV"
vgcreate "$VG" "$DEV"
lvcreate --type thin-pool --name "$POOL" -l 80%FREE "$VG"

mkdir -p "$(dirname "$SENTINEL")"
touch "$SENTINEL"
echo "LVM thin pool $VG/$POOL ready"

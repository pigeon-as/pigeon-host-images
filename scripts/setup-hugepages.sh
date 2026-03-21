#!/bin/bash -ex
# Prepare hugetlbfs mount for Firecracker VMs.
# The mount is created at build time; actual hugepage allocation
# (vm.nr_hugepages) is done at runtime based on available memory.

mkdir -p /mnt/hugepages

# Add fstab entry so hugetlbfs mounts on every boot.
echo "hugetlbfs /mnt/hugepages hugetlbfs defaults 0 0" >> /etc/fstab

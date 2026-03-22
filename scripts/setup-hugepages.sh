#!/bin/bash -ex

mkdir -p /mnt/hugepages
echo "hugetlbfs /mnt/hugepages hugetlbfs defaults 0 0" >> /etc/fstab

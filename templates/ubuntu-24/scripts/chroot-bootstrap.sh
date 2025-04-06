#!/usr/bin/env bash

# Copyright 2025 Genesis Corporation
#
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -eu
set -x
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

mkdir -p /run/systemd/resolve/
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
apt update
apt install zfs-initramfs -y

# Populate mount list
mkdir /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/rpool
zed -F &
sleep 2
kill $(cat /run/zed.pid)
sed -Ei "s|/mnt/?|/|" /etc/zfs/zfs-list.cache/*
sed -i '/LABEL=cloudimg-rootfs/d' /etc/fstab

sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&root=ZFS=rpool\/ROOT\/ubuntu init_on_alloc=0 init_on_free=0 /' /etc/default/grub
update-initramfs -c -k all
update-grub
grub-install /dev/vdb

# Cleanup
# Shell history
history -c

# Cloud-init clean
sudo cloud-init clean --log --seed

# Cleanup apt cache
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean

# Sync FS
sync

zpool sync
zpool trim -w rpool
echo '0' > /sys/module/zfs/parameters/zfs_initialize_value
zpool initialize -w rpool

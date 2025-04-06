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

[[ "$EUID" == 0 ]] || exec sudo -s "$0" "$@"

export DEBIAN_FRONTEND=noninteractive

apt update
apt install qemu-utils zfsutils-linux -y

cd /tmp || exit
wget --progress=bar:force:noscroll https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img

modprobe nbd max_part=8
qemu-nbd --connect=/dev/nbd0 /tmp/ubuntu*.img

sfdisk -d /dev/nbd0 | sfdisk /dev/vdb
printf "fix\n" | parted ---pretend-input-tty /dev/vdb print
# parted /dev/vdb -s resizepart 1 100%
dd if=/dev/nbd0p14 of=/dev/vdb14
dd if=/dev/nbd0p15 of=/dev/vdb15
dd if=/dev/nbd0p16 of=/dev/vdb16

mkdir /orig
mount -r /dev/nbd0p1 /orig

zpool create \
    -o autotrim=on \
    -O acltype=posixacl -O xattr=sa -O dnodesize=auto \
    -O compression=lz4 \
    -O atime=off \
    -O canmount=off -O mountpoint=/ -R /mnt \
    rpool /dev/vdb1

# Root dataset
zfs create -o canmount=off -o mountpoint=none rpool/ROOT
zfs create -o canmount=noauto -o mountpoint=/ rpool/ROOT/ubuntu
zfs mount rpool/ROOT/ubuntu

# Additional datasets
zfs create                     rpool/home
zfs create -o mountpoint=/root rpool/home/root
chmod 700 /mnt/root
zfs create                     rpool/var
zfs create                     rpool/var/lib
zfs create                     rpool/var/log
zfs create                     rpool/var/spool
zfs create -o com.sun:auto-snapshot=false rpool/var/cache
zfs create -o com.sun:auto-snapshot=false rpool/var/lib/nfs
zfs create -o com.sun:auto-snapshot=false rpool/var/tmp
chmod 1777 /mnt/var/tmp

# Ubuntu server doesn't use tmpfs for /tmp
zfs create -o com.sun:auto-snapshot=false -o sync=disabled rpool/tmp
chmod 1777 /mnt/tmp

zfs create rpool/srv
zfs create -o com.sun:auto-snapshot=false rpool/var/lib/docker
zfs create rpool/var/mail
zfs create rpool/var/snap

rsync -a /orig/ /mnt/

# growpart for root
mkdir -p /mnt/etc/cloud/cloud.cfg.d
cp /tmp/zfs-growpart-root.cfg \
    /mnt/etc/cloud/cloud.cfg.d/zfs-growpart-root.cfg

# cp /etc/zfs/zpool.cache /mnt/etc/zfs/

mount /dev/vdb16 /mnt/boot
mount /dev/vdb15 /mnt/boot/efi

mount -t tmpfs tmpfs /mnt/run
mkdir /mnt/run/lock
mount --make-private --rbind /dev  /mnt/dev
mount --make-private --rbind /proc /mnt/proc
mount --make-private --rbind /sys  /mnt/sys

cp /tmp/chroot-bootstrap.sh /mnt/tmp/chroot-bootstrap.sh
chroot /mnt /tmp/chroot-bootstrap.sh
rm -f /mnt/tmp/chroot-bootstrap.sh

umount /mnt/boot/efi
fstrim /mnt/boot/
umount /mnt/boot/

mount | grep -v zfs | tac | awk '/\/mnt/ {print $3}' | \
    xargs -I{} umount -f {}

systemctl stop zed

# We have to export pool, otherwise on first boot user will need to import pool manually
remaining_attemps=10
while (( remaining_attemps-- > 0 )); do
    zpool export -a < /dev/null && break
    # Sometimes systemd locks root dataset, we don't care - just kill it
    grep [r]pool /proc/*/mounts | cut -d/ -f3 | uniq | xargs kill
    sleep 1
done

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

RELEASE="${1:-ubuntu-24}"
echo "Will build: $RELEASE"

TARGET_IMAGE="./output/${RELEASE}-zfs.qcow2-1"
TARGET_IMAGE_COMPRESSED="./output/${RELEASE}_zfs.qcow2"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root, packer and qemu will be used."
  exit
fi

cd "./templates/$RELEASE/" || exit

packer init ./

packer build ./

qemu-img convert -c -O qcow2 -o compression_type=zstd "$TARGET_IMAGE" "$TARGET_IMAGE_COMPRESSED"

echo "Target image built:"
realpath "$TARGET_IMAGE_COMPRESSED"

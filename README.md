# Ubuntu Cloud Images with Root on ZFS

It's still a little bit complicated to have Linux with ZFS as root file system,
so let's build one!

## Motivation

Use upstream images as long as we can, but move data nearly as-is on ZFS pool.
So, you'll have nearly vanilla Ubuntu server image, but with ZFS :)

## Use

See Github releases for already built qcow2 images (zstd-compressed).

## Build

You can easily build it by yourself, prerequisites:
- Packer
- Qemu (`qemu-system-amd64 qemu-utils guestfs-tools cloud-image-utils`)
- `./build.sh [TEMPLATE_NAME]`

# Ubuntu Cloud Images with Root on ZFS

It's still a little bit complicated to have Linux with ZFS as root file system,
so let's build one!

> **_NOTE:_**  This image doesn't use any of `zsys` mechanisms.

## Motivation

Use upstream images as long as we can, but move data nearly as-is on ZFS pool.
So, you'll have nearly vanilla Ubuntu server image, but with ZFS :)

## Use

See Github releases for already built qcow2 images (zstd-compressed).

## Customize

If you don't want to build image locally - just fork and push changes, Github Actions will build image and add it as a build artifact.

## Build

You can easily build it by yourself, prerequisites:
- Packer
- Qemu (`qemu-system-amd64 qemu-utils guestfs-tools cloud-image-utils`)
- `./build.sh [TEMPLATE_NAME]`

## Dataset layout example

(Mix of [Ubuntu](https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2022.04%20Root%20on%20ZFS.html) and [Debian](https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Bookworm%20Root%20on%20ZFS.html) official guides)

```
# zfs list
NAME                   USED  AVAIL  REFER  MOUNTPOINT
rpool                 1.06G  7.41G    24K  /
rpool/ROOT             931M  7.41G    24K  none
rpool/ROOT/ubuntu      931M  7.41G   931M  /
rpool/home            63.5K  7.41G    33K  /home
rpool/home/root       30.5K  7.41G  30.5K  /root
rpool/srv               24K  7.41G    24K  /srv
rpool/tmp               96K  7.41G    96K  /tmp
rpool/var              157M  7.41G   660K  /var
rpool/var/cache       72.4M  7.41G  72.4M  /var/cache
rpool/var/lib         82.7M  7.41G  82.7M  /var/lib
rpool/var/lib/docker    24K  7.41G    24K  /var/lib/docker
rpool/var/lib/nfs       24K  7.41G    24K  /var/lib/nfs
rpool/var/log          994K  7.41G   994K  /var/log
rpool/var/mail          24K  7.41G    24K  /var/mail
rpool/var/snap          24K  7.41G    24K  /var/snap
rpool/var/spool         25K  7.41G    25K  /var/spool
rpool/var/tmp           36K  7.41G    36K  /var/tmp
```

## Dataset properties:
- `recordsize` is default on every dataset, may be optimized in future (for ex. for some databases)
- whole pool has:
  - `compression=on`
  - `xattr=sa`
  - `atime=off`
- Some non-mission-critical datasets have `com.sun:auto-snapshot=false`
- `rpool/tmp` have `sync=disabled` ([programs must not assume that any files or directories in /tmp are preserved between invocations of the program](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s18.html))

(See `prepare-zfs-root.sh` for exact create commands)

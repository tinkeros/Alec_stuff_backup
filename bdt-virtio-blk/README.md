# bdt-virtio-blk
Virtio-blk Loadable Device Driver for TempleOS

![Virtio-blk Loadable Device Driver for TempleOS](https://git.checksum.fail/alec/bdt-virtio-blk/raw/branch/master/preview.png?)

# details

Mount a Virtio block device in TempleOS on QEMU, without having to recompile the Kernel. Re-assigns drive letter `A` to `BDT_VIRTIO_BLK` device.

# usage

- Clone the repo, create a RedSea ISO.C disk image using [RedSeaExplorer](https://checksum.fail/files/RedSeaExplorer-0.6.zip) for Windows or [redseafs](https://github.com/obecebo/redseafs) for Linux.
- Load the driver `#include "MakeVirtioBlk";`
- Mount the block device `MountVirtioBlk;`
- Format (if new device) `Fmt('A',,FALSE,FSt_REDSEA);`

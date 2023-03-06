# bmik

Bare-Metal Installation Kit - Easily install TempleOS on bare-metal

# Details

The goal for this project is to provide an easy way to create a hard disk image that can be booted on bare-metal hardware and QEMU seamlessly, to allow for transfer of files between PCs while developing software projects.

The intended usage is to create a disk image that can be copied to a hard disk mounted in a removable enclosure, and the hard disk transferred between the virtual environment and a bare-metal machine.

# Usage

- Create a raw disk image, at least large enough to hold 2*1G TempleOS RedSea partitions + partition table `qemu-img create -f raw disk_img.raw 4G`

- `qemu-system-x86_64 -drive format=raw,file=disk_img.raw -m 1024 -cdrom TempleOS.ISO -boot d`

- Run the VM install wizard, then re-run install wizard w/o VM option from each partition and choose RedSea format for each install

OR

- Use the provided disk image `disk_img.raw.xz` which skips these steps for you.

THEN

- Clone the repo, add files to `bmik.ISO.C` 

- `qemu-system-x86_64 -drive format=raw,file=disk_img.raw -m 1024 -cdrom bmik.ISO.C`

FINALLY, for each partition:

- Mount the CDROM, if it is not mounted already `Mount;` - drive letter 'T', 'p' for probe, number '2' for Secondary IDE

- `Cd("T:"); #include "Install";`

- Enter your Primary/Secondary base0, base1 I/O ports from `lspci -v` 

- Reboot

# Done

`dd` the resulting `disk_img.raw` to your target HDD, and you now have a TempleOS RedSea installation with 2 partitions, bootable on bare-metal and QEMU.

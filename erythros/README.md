# erythros

A comfy desktop environment for TempleOS

![Erythros](https://git.checksum.fail/alec/erythros/raw/branch/master/screenshot.png "Erythros")

# About

Erythros is a modern desktop environment which runs on top of stock, unmodified TempleOS Kernel.

It is a work in progress, and there is much more work to be done. If you would like to contribute, send an email to `alec@checksum.fail` and request access.

# Discuss

Matrix: Type `/join !cqUdTDNXzGlqwfOuuS:envs.net`

# Prerequisites

- A supported hypervisor (QEMU recommended)

- [redseafs](https://git.checksum.fail/alec/redseafs) and [Shrine](https://github.com/minexew/Shrine) `Adam/Net` (if using the included build-and-boot scripts)

- A 9P server such as [u9fs](https://bitbucket.org/plan9-from-bell-labs/u9fs) to provide a root filesystem (and [socat](http://www.dest-unreach.org/socat/) if you use the sample config located in `System`)


# Usage

It is recommended to use the build-and-boot scripts located in `System` if you intend to hack on the system with an IDE such as VSCode, CLion etc. that supports build tasks.

*Alternatively*, you can write the contents of `Boot` directory to an ISO.C file, using a tool such as [RedSea Explorer](https://checksum.fail/files/RedSeaExplorer-0.6.zip) for Windows or [redseafs](https://git.checksum.fail/alec/redseafs) for Linux. You will need to manually add the files from [Shrine](https://github.com/minexew/Shrine) in `Adam/Net` to `3rdParty/SnailNet` in the ISO.C to provide networking support. 

Mount the ISO.C file in the virtual CDROM drive.

Add the following to your `Once.HC` script:
```
blkdev.boot_drv_let = 'T';
Adam("Cd(\"T:\");\n");
AdamFile("T:/Run.HC");
```

By default, Erythros will attempt to mount a 9P root filesystem using the VM Network's gateway address, as it assumes a NAT configuration. You can modify `Plan9FS.Init` to set the values of `Plan9FS.Host` and `Plan9FS.Port` to match your setup if necessary.

Use the `generate-root-paths.sh` script located in `System` to create the required paths for the root filesystem.

# templeos-uefi
UEFI boot loader and patchset for TempleOS

This is a work in progress. PRs welcome and encouraged!!

# Instructions (kinda)

Copy `Patch` folder to `::/Kernel/Patch`

`Cmp("::/path/to/git/src/Kernel");` will generate a `Kernel.BIN.Z` with a combined Kernel and Compiler.

Uncompress to `Kernel.BIN.C` and run `Tools/patchtool`

Build `TOSBoot` as `BOOTX64.EFI` and copy to EFI system partition `/EFI/BOOT` along with `Kernel.BIN.C`

Create a boot entry or launch from UEFI Shell

![templeos-uefi](https://git.checksum.fail/alec/templeos-uefi/raw/branch/master/example.gif "templeos-uefi") 

Enjoy the comfy greeting

# Prerequisites

[EDK II](https://github.com/tianocore/edk2)

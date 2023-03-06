# hgbd
Host-Guest Block Device for TempleOS

PLEASE NOTE: The use of 3rd party libraries in TempleOS is banned per the Charter. Please do not build programs that depend on the use of HGBD.

(This can cause some issues with FileMgr if it tries to read a RedSea FS from the block device.)

Makes use of shared memory buffer between TempleOS Guest and Host.

![HGBD](https://git.checksum.fail/alec/hgbd/raw/branch/master/example.gif "Host-Guest Block Device") 

# Features
- Copy files between Host-Guest
- Copy-paste clipboard between Host-Guest
- Download files to Guest via HTTP/HTTPS
- Take screenshot from Guest to Host as 4-bit PNG

You can create custom modules for HGBD and include them in `modules` section of the config
file `/etc/hgbdd.conf`

Start HGBD daemon on Host:

```
    /usr/sbin/hgbdd
```

In `/etc/hgbdd.conf`, replace `blk_dev` with the RAM disk block device (not tmpfs) and
`user` with your username (for shared file write ownership)

To create the block device (64 MiB or larger):

Debian/Ubuntu: `/dev/ram0` builtin  
macOS: `hdiutil attach -nomount ram://131072`  
Windows: Use [ImDisk](http://www.ltr-data.se/opencode.html/#ImDisk) or a similar utility 
 
On your TempleOS VM, connect `COM2` to `TCP4:127.0.0.1:7202` (default) and create a raw
device mapping to the block device. 

Examples: 

QEMU: Add `-hdX /dev/ram0` to startup parameters  
VirtualBox: `VBoxManage internalcommands createrawvmdk -filename "ram0.vmdk" -rawdisk /dev/ram0`  
VMware: `Edit VM > Settings > Use a physical disk`

Define `unit`, `base0`, `base1` and drive letter for `HGBD_DEV` in `HGBD.HC` (default is `I:`)

`#include "HGBD"` in your `::/Home/HomeKeyPlugIns.HC` to make use of shortcut keys for
copy-paste and screenshots.


# Commands

`CdH(path);` to change Host directory  
`CopyFindH(files);` to copy FilesFind(files) in Guest to Host  
`CopyG(file);` to copy Host `file` to Guest in current directory  
`CopyH(file);` to copy Guest `file` to Host  
`DelH(file);` Delete file in Host directory  
`DirCurH;` points to current Host directory  
`DirH;` List files in Host directory (click a directory to navigate, or a file to CopyG)  
`GetURL(url)` download `url` to Guest in current directory  
`GetURLStr(url)` return the response text of `url` as a string  
`HCopy;` copies Guest clipboard to Host  
`HPaste;` paste Host clipboard at cursor location  
`ScrShot;` take screenshot to Host directory


# Prerequisites

- pip install: clipboard, urlparse
- wget
- GraphicsMagick (for screenshots)
- TOSZ (to transfer .Z files)

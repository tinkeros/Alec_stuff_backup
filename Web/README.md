# Web

World Wide Web browser for TempleOS

![Web](https://git.checksum.fail/alec/Web/raw/branch/master/example.png?)

# About

This is a from-scratch reimplementation of the [Uriel](https://git.checksum.fail/alec/uriel) proof-of-concept web browser I wrote several years ago. Unlike Uriel, which was dependent on a host PC running the HGBD driver and a Python application to convert HTML and images to DolDoc, this browser runs entirely in TempleOS.

Most of the code is written in HolyC. There is a HolyC <-> GCC FFI implementation for the image loading code, which uses `stb_image.h`.

# Usage

`#include "Run";`

# TODO

- a lot

# Dependencies

- SnailNet Libraries from [Shrine](https://github.com/minexew/Shrine)
- aes256, curve25519, sha256, hmac-sha256, sha1, hmac-sha1, tls12, string, http Libraries from [Erythros](https://git.checksum.fail/alec/erythros)

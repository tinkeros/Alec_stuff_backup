/*
 * Megadrive memory map as well as main execution loop.
 */

U8 *ROM = CAlloc(0x400000);
U8 *RAM = CAlloc(0x10000);
U8 *ZRAM = CAlloc(0x2000);

I64 MCLOCK_NTSC = 53693175;
I64 MCYCLES_PER_LINE = 3420;

I64 lines_per_frame = 262; /* NTSC: 262, PAL: 313 */

I64 cycle_counter = 0;

U0 set_rom(U8 *buffer, I64 size) {
  MemSet(ROM, 0, 0x400000);
  MemSet(RAM, 0, 0x10000);
  MemSet(ZRAM, 0, 0x2000);
  MemCpy(ROM, buffer, size);
}

U32 read_memory(U32 address) {
  U32 range = (address & 0xff0000) >> 16;

  if (range <= 0x3f) {
    /* ROM */
    return ROM[address];
  } else if (range == 0xa0) {
    /* Z80 space */
    if (address >= 0xa00000 && address < 0xa04000) {
      return ZRAM[address & 0x1fff];
    }
    return 0;
  } else if (range == 0xa1) {
    /* I/O and registers */
    if (address >= 0xa10000 && address < 0xa10020) {
      return io_read_memory(address & 0x1f);
    } else if (address >= 0xa11100 && address < 0xa11300) {
      return z80_ctrl_read(address & 0xffff);
    }
    return 0;
  } else if (range >= 0xc0 && range <= 0xdf) {
    /* VDP */
    return vdp_read(address);
  } else if (range >= 0xe0 && range <= 0xff) {
    /* RAM */
    return RAM[address & 0xffff];
    // RAM
  }
  // printf("read(%x)\n", address);
  return 0;
}

U0 write_memory(U32 address, U32 value) {
  U32 range = (address & 0xff0000) >> 16;

  if (range <= 0x3f) {
    /* ROM */
    ROM[address] = value;
    return;
  } else if (range == 0xa0) {
    /* Z80 space */
    if (address >= 0xa00000 && address < 0xa04000) {
      ZRAM[address & 0x1fff] = value;
    }
    return;
  } else if (range == 0xa1) {
    /* I/O and registers */
    if (address >= 0xa10000 && address < 0xa10020) {
      io_write_memory(address & 0x1f, value);
      return;
    } else if (address >= 0xa11100 && address < 0xa11300) {
      z80_ctrl_write(address & 0xffff, value);
      return;
    }
    return;
  } else if (range >= 0xc0 && range <= 0xdf) {
    /* VDP */
    return;
  } else if (range >= 0xe0 && range <= 0xff) {
    /* RAM */
    RAM[address & 0xffff] = value;
    return;
  }
  // printf("write(%x, %x)\n", address, value);
  return;
}

U32 m68k_read_memory_8(U32 address) { return read_memory(address); }
U32 m68k_read_memory_16(U32 address) {

  U32 range = (address & 0xff0000) >> 16;

  if (range >= 0xc0 && range <= 0xdf) {
    return vdp_read(address);
  } else {
    U32 word = read_memory(address) << 8 | read_memory(address + 1);
    return word;
  }
}
U32 m68k_read_memory_32(U32 address) {
  U32 longword = read_memory(address) << 24 | read_memory(address + 1) << 16 |
                 read_memory(address + 2) << 8 | read_memory(address + 3);
  return longword;
}
U0 m68k_write_memory_8(U32 address, U32 value) {
  write_memory(address, value);

  return;
}
U0 m68k_write_memory_16(U32 address, U32 value) {
  U32 range = (address & 0xff0000) >> 16;

  if (range >= 0xc0 && range <= 0xdf) {
    vdp_write(address, value);
  } else {
    write_memory(address, (value >> 8) & 0xff);
    write_memory(address + 1, (value)&0xff);
  }
}
U0 m68k_write_memory_32(U32 address, U32 value) {
  m68k_write_memory_16(address, (value >> 16) & 0xffff);
  m68k_write_memory_16(address + 2, (value)&0xffff);

  return;
}

/*
 * The Megadrive frame, called every 1/60th second
 * (or 1/50th in PAL mode)
 */
U0 frame() {
  I64 hint_counter = vdp_reg[10];

  cycle_counter = 0;

  screen_width = T((vdp_reg[12] & 0x01), 320, 256);
  screen_height = T((vdp_reg[1] & 0x08), 240, 224);

  vdp_clear_vblank();
  MemSetU32(screen, 0, 320 * 240); /* clear the screen before rendering */

  for (line = 0; line < screen_height; line++) {
    m68k_execute(2560 + 120);

    if (--hint_counter < 0) {
      hint_counter = vdp_reg[10];
      if (vdp_reg[0] & 0x10) {
        m68k_set_irq(4); /* HI64 */
                         // m68k_execute(7000);
      }
    }

    vdp_set_hblank();
    m68k_execute(64 + 313 + 259); /* HBlank */
    vdp_clear_hblank();

    m68k_execute(104);

    vdp_render_line(line); /* render line */
  }
  MemCpyU32(pixel_ctx0->fb, pixel_ctx->fb, 320 * 240);

  vdp_set_vblank();

  m68k_execute(588);

  vdp_status |= 0x80;

  m68k_execute(200);

  if (vdp_reg[1] & 0x20) {
    m68k_set_irq(6); /* HI64 */
  }

  m68k_execute(3420 - 788);
  line++;

  for (; line < lines_per_frame; line++) {
    m68k_execute(3420); /**/
  }
}

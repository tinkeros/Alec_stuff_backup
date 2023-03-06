/*
 * Sega Megadrive joypad support
 */

#define PAD_UP 0
#define PAD_DOWN 1
#define PAD_LEFT 2
#define PAD_RIGHT 3
#define PAD_B 4
#define PAD_C 5
#define PAD_A 6
#define PAD_S 7

U16 button_state[3];
U16 pad_state[3];
U8 io_reg[16] = {0xa0, 0x7f, 0x7f, 0x7f, 0, 0,    0, 0xff,
                 0,    0,    0xff, 0,    0, 0xff, 0, 0}; /* initial state */

U0 pad_press_button(I64 pad, I64 button) { button_state[pad] |= (1 << button); }

U0 pad_release_button(I64 pad, I64 button) {
  button_state[pad] &= ~(1 << button);
}

U0 pad_write(I64 pad, I64 value) {
  U8 mask = io_reg[pad + 4];

  pad_state[pad] &= ~mask;
  pad_state[pad] |= value & mask;
}

U8 pad_read(I64 pad) {
  U8 value;

  value = pad_state[pad] & 0x40;
  value |= 0x3f;

  if (value & 0x40) {
    value &= ~(button_state[pad] & 0x3f);
  } else {
    value &=
        ~(0xc | (button_state[pad] & 3) | ((button_state[pad] >> 2) & 0x30));
  }
  return value;
}

U0 io_write_memory(U32 address, U32 value) {
  address >>= 1;

  if (address >= 0x1 && address < 0x4) {
    /* port data */
    io_reg[address] = value;
    pad_write(address - 1, value);
    return;
  } else if (address >= 0x4 && address < 0x7) {
    /* port ctrl */
    if (io_reg[address] != value) {
      io_reg[address] = value;
      pad_write(address - 4, io_reg[address - 3]);
    }
    return;
  }

  // printf("io_write_memory(%x, %x)\n", address, value);
}

U32 io_read_memory(U32 address) {
  address >>= 1;

  if (address >= 0x1 && address < 0x4) {
    U8 mask = 0x80 | io_reg[address + 3];
    U8 value;
    value = io_reg[address] & mask;
    value |= pad_read(address - 1) & ~mask;
    return value;
  } else {
    return io_reg[address];
  }
}
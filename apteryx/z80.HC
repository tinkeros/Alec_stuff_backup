I64 bus_ack = 0;
I64 reset = 0;

U0 z80_ctrl_write(U32 address, U32 value) {
  if (address == 0x1100) // BUSREQ
  {
    if (value) {
      bus_ack = 1;
    } else {
      bus_ack = 0;
    }
  } else if (address == 0x1200) // RESET
  {
    if (value) {
      reset = 1;
    } else {
      reset = 0;
    }
  }
}

U32 z80_ctrl_read(U32 address) {
  if (address == 0x1100) {
    return !(reset && bus_ack);
  }
  return 0;
}

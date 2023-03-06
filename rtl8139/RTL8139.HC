#define RTL8139_RX_BUF_SIZE 8192
#define RTL8139_RX_BUF_SIZE_EXT RTL8139_RX_BUF_SIZE + 16 + 1500

#ifdef RTL8139_DEBUG
#define rtl8139_debug Print
#else
#define rtl8139_debug rtl8139_mute_debug
#endif

class @rtl8139 {
  @pci_info pci;
  U16 iobase;
  U8 mac[6];
  U32 rx_buffer;
  I64 rx_pos;
  I64 tx_ctr;
};

@rtl8139 RTL8139;

U0 rtl8139_mute_debug(U8 *buf, ...) {
  no_warn buf;
  no_warn argc;
  no_warn argv;
}

U0 rtl8139_rx_packet(U8 *data, I64 *len) {
  if (!data || !len)
    return;
  U16 *t = RTL8139.rx_buffer + RTL8139.rx_pos;
  if (!(*t & 1)) {
    *len = -1;
    return;
  }
  U16 packet_length = *(t + 1);
  *len = packet_length - 4;
  t += 2;
  MemCpy(data, t, *len);
  RTL8139.rx_pos = (RTL8139.rx_pos + packet_length + 4 + 3) & ~3;
  if (RTL8139.rx_pos >= RTL8139_RX_BUF_SIZE)
    RTL8139.rx_pos -= RTL8139_RX_BUF_SIZE;
  OutU16(RTL8139.iobase + 0x38, RTL8139.rx_pos - 0x10);
}

U0 rtl8139_tx_packet(U8 *data, I64 len) {
  if (!data || !len)
    return;
  OutU32(RTL8139.iobase + 0x20 + (RTL8139.tx_ctr * 4), data);
  OutU32(RTL8139.iobase + 0x10 + (RTL8139.tx_ctr * 4), len);
  RTL8139.tx_ctr++;
  if (RTL8139.tx_ctr > 3)
    RTL8139.tx_ctr = 0;
}

I64 rtl8139_init() {
  I64 i;
  I64 j;

  // Scan for device
  j = PCIClassFind(0x020000, 0);
  if (j < 0) {
  device_not_found:
    rtl8139_debug("[rtl8139] Device not found\n");
    return -1;
  }

  @get_pci_info(j, &RTL8139.pci);

  switch (RTL8139.pci.device_id) {
  case 0x1340:
  case 0x8139:
    break;
  default:
    goto device_not_found;
    break;
  }
  switch (RTL8139.pci.vendor_id) {
  case 0x10EC:
    rtl8139_debug("[rtl8139] Realtek 8139, QEMU\n");
    break;
  case 0x1186:
    rtl8139_debug("[rtl8139] D-Link DFE-690TXD\n");
    break;
  default:
    rtl8139_debug("[rtl8139] Unsupported device\n");
    return -1;
    break;
  }

  // Get the I/O base port
  RTL8139.iobase = RTL8139.pci.bar[0] & ~0xFF;

  rtl8139_debug("[rtl8139] I/O base: 0x%04x\n", RTL8139.iobase);

  // Read the MAC address
  for (i = 0; i < 6; i++)
    RTL8139.mac[i] = InU8(RTL8139.iobase + i);

  rtl8139_debug("[rtl8139] MAC address: %02x:%02x:%02x:%02x:%02x:%02x\n",
                RTL8139.mac[0], RTL8139.mac[1], RTL8139.mac[2], RTL8139.mac[3],
                RTL8139.mac[4], RTL8139.mac[5]);

  // Enable bus master
  U16 cmd_v = PCIReadU16(j.u8[2], j.u8[1], j.u8[0], 0x4);
  cmd_v = cmd_v | 1 << 2;
  PCIWriteU16(j.u8[2], j.u8[1], j.u8[0], 0x4, cmd_v);

  // "Power on" the device
  OutU8(RTL8139.iobase + 0x52, 0x0);

  // Software reset
  OutU8(RTL8139.iobase + 0x37, 0x10);
  while ((InU8(RTL8139.iobase + 0x37) & 0x10) != 0)
    Sleep(1);

  // Allocate receive buffer
  RTL8139.rx_buffer =
      CAllocAligned(RTL8139_RX_BUF_SIZE_EXT, 4096, Fs->code_heap);

  rtl8139_debug("[rtl8139] rx_buffer: 0x%08x\n", RTL8139.rx_buffer);

  // Init receive buffer
  OutU32(RTL8139.iobase + 0x30, RTL8139.rx_buffer);

  // Set IMR + ISR
  OutU16(RTL8139.iobase + 0x3C, 0x0005);

  // Configuring receive buffer (RCR)
  OutU32(RTL8139.iobase + 0x44, 0xf | (1 << 7));

  // Enable Receive and Transmitter
  OutU8(RTL8139.iobase + 0x37, 0x0C);

  // Clear RX/TX incremental counters
  RTL8139.rx_pos = 0;
  RTL8139.tx_ctr = 0;

  return 0;
}

rtl8139_init;
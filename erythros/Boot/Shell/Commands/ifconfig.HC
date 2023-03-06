I64 @shell_cmd_ifconfig(@shell *sh, I64 argc, U8 **argv) {
  U8 *en0_mac = EthernetGetAddress;
  U32 en0_addr = my_ip;
  U32 en0_mask = ipv4_subnet_mask;
  U32 en0_bcast = my_ip | ~ipv4_subnet_mask;

  U8 buf[512];

  StrPrint(buf, "en0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu %d\n",
           ETHERNET_FRAME_SIZE - 18);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf,
           "        inet %d.%d.%d.%d  netmask %d.%d.%d.%d  broadcast "
           "%d.%d.%d.%d\n",
           en0_addr.u8[3], en0_addr.u8[2], en0_addr.u8[1], en0_addr.u8[0],
           en0_mask.u8[3], en0_mask.u8[2], en0_mask.u8[1], en0_mask.u8[0],
           en0_bcast.u8[3], en0_bcast.u8[2], en0_bcast.u8[1], en0_bcast.u8[0]);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf,
           "        ether %02x:%02x:%02x:%02x:%02x:%02x  txqueuelen 0  "
           "(Ethernet)\n",
           en0_mac[0], en0_mac[1], en0_mac[2], en0_mac[3], en0_mac[4],
           en0_mac[5]);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "        RX packets %d  bytes %d\n", VirtioNet.rx_packets,
           VirtioNet.rx_bytes);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "        RX errors %d  dropped %d  overruns %d  frame %d\n", 0,
           0, 0, 0); // TODO
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "        TX packets %d  bytes %d\n", VirtioNet.tx_packets,
           VirtioNet.tx_bytes);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf,
           "        TX errors %d  dropped %d overruns %d  carrier %d  "
           "collisions %d\n",
           0, 0, 0, 0, 0); // TODO
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "\n");
  Stdio.WriteLine(sh, buf);
  return 0;
}
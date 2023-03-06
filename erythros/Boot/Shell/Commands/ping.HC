I64 @shell_cmd_ping(@shell *sh, I64 argc, U8 **argv) {
  if (argc < 2) {
    Stdio.WriteLine(sh, "ping: usage error: Destination address required\n");
    return 1;
  }
  CIPv4Packet *packet;
  CIcmpHeader *icmp_header;
  Bool replies_mismatch = FALSE;
  I64 cnt = 0;
  I64 echo_size = 48;
  I64 timeout = 0;
  I64 timeout_cnt = 0;
  I64 timeout_max = 1000;
  I64 time_begin;
  I64 time_req;
  I64 time_resp;
  I64 wait_ctr = 0;
  I64 wait_len = 0;
  U8 buf[512];
  U8 *data = CAlloc(echo_size);
  U16 iden = (RandU16 * SysTimerRead) & 0xFFFF;
  U16 seq = 0;
  U32 dest_ip;

  I64 err = Net.ResolveIPv4Address(argv[1], &dest_ip);
  if (!err) {
    StrPrint(&buf, "PING %s (%d.%d.%d.%d): %d data bytes\n", argv[1],
             dest_ip.u8[0], dest_ip.u8[1], dest_ip.u8[2], dest_ip.u8[3],
             echo_size + 8);
    Stdio.WriteLine(sh, &buf);
    time_begin = cnts.jiffies;
    while (!sh->break) {
      icmp_reply[iden] = NULL;
      IcmpSendRequest(htonl(dest_ip), iden, seq, 0, data, echo_size);
      time_req = cnts.jiffies;
      timeout = 0;
      while (!sh->break && !icmp_reply[iden] && timeout < timeout_max) {
        Sleep(1);
        timeout++;
      }
      if (sh->break) {
        Stdio.WriteLine(sh, "^C\n");
        goto @shell_cmd_ping_exit;
      }
      if (timeout < timeout_max) {
        packet = icmp_reply[iden];
        icmp_header = packet->data;
        time_resp = cnts.jiffies;
        StrPrint(&buf,
                 "%d bytes from %d.%d.%d.%d: icmp_seq=%d ttl=%d time=%d ms\n",
                 packet->length + 8, dest_ip.u8[0], dest_ip.u8[1],
                 dest_ip.u8[2], dest_ip.u8[3], icmp_header->seq_number,
                 packet->ttl, time_resp - time_req);
        Stdio.WriteLine(sh, &buf);
      } else {
        StrPrint(buf, "Request timeout for icmp_seq %d\n", seq);
        Stdio.WriteLine(sh, &buf);
        replies_mismatch = TRUE;
        timeout_cnt++;
      }
      cnt++;
      seq++;
      wait_ctr = 0;
      wait_len = 1000 - timeout;
      while (!sh->break && wait_ctr < wait_len) {
        wait_ctr++;
        Sleep(1);
      }
    }
  } else {
    StrPrint(&buf, "ping: %s: Name or service not known\n", argv[1]);
    Stdio.WriteLine(sh, &buf);
    return 2;
  }
  @shell_cmd_ping_exit
      : StrPrint(&buf, "--- %s ping statistics ---\n", argv[1]);
  Stdio.WriteLine(sh, &buf);
  StrPrint(&buf,
           "%d packets transmitted, %d received, %d%% packet loss, time %dms\n",
           cnt, cnt - timeout_cnt, (timeout_cnt / cnt) * 100,
           cnts.jiffies - time_begin);
  Stdio.WriteLine(sh, &buf);
  return T(replies_mismatch, 1, 0);
}
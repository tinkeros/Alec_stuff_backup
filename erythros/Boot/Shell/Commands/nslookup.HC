I64 @shell_cmd_nslookup(@shell *sh, I64 argc, U8 **argv) {
  if (argc < 2) {
    // TODO: Interactive mode
    return 0;
  }
  if (argc > 2) {
    // TODO: Server argument
  }
  U8 buf[512];
  U32 res_ip = NULL;
  U32 resolver_ip = Net.GetIPv4DNSResolver();
  addrinfo *res = NULL;
  StrPrint(&buf, "Server:         %d.%d.%d.%d\n", resolver_ip.u8[3],
           resolver_ip.u8[2], resolver_ip.u8[1], resolver_ip.u8[0]);
  Stdio.WriteLine(sh, &buf);
  StrPrint(&buf, "Address:        %d.%d.%d.%d#53\n\n", resolver_ip.u8[3],
           resolver_ip.u8[2], resolver_ip.u8[1], resolver_ip.u8[0]);
  Stdio.WriteLine(sh, &buf);
  I64 err = getaddrinfo(argv[1], NULL, NULL, &res);
  if (!err) {
    StrPrint(&buf, "Non-authoritative answer:\n");
    Stdio.WriteLine(sh, &buf);
    res_ip = (res->ai_addr(sockaddr_in *))->sin_addr.s_addr;
    StrPrint(&buf, "Name:   %s\n", argv[1]);
    Stdio.WriteLine(sh, &buf);
    StrPrint(&buf, "Address: %d.%d.%d.%d\n\n", res_ip.u8[0], res_ip.u8[1],
             res_ip.u8[2], res_ip.u8[3]);
    Stdio.WriteLine(sh, &buf);
    if (res)
      freeaddrinfo(res);
    return 0;
  }
  StrPrint(&buf, "** server can't find %s: NXDOMAIN\n\n", argv[1]);
  Stdio.WriteLine(sh, &buf);
  if (res)
    freeaddrinfo(res);
  return 1;
}
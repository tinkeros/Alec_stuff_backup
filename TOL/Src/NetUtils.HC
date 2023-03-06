I64 @net_resolve_ipv4_address(U8 *_str, U32 *addr) {
  U8 *str = StrNew(_str);
  *addr = NULL;
  I64 err = NULL;
  addrinfo *res = NULL;
  if (!inet_pton(AF_INET, str, addr)) {
    err = getaddrinfo(str, NULL, NULL, &res);
    if (!err) {
      *addr = (res->ai_addr(sockaddr_in *))->sin_addr.s_addr;
    }
    if (res) {
      freeaddrinfo(res);
    }
    Free(str);
    return err;
  }
  Free(str);
  return 0;
}

U32 @net_get_ipv4_dns_resolver() { return dns_ip; }

U32 inet_addr(U8 *str) {
  U32 res = NULL;
  @net_resolve_ipv4_address(str, &res);
  return res;
}

class @net {
  I64 (*ResolveIPv4Address)(U8 * _str, U32 * addr);
  U32 (*GetIPv4DNSResolver)();
};

@net Net;

Net.GetIPv4DNSResolver = &@net_get_ipv4_dns_resolver;
Net.ResolveIPv4Address = &@net_resolve_ipv4_address;

"[OK] netutils \n";
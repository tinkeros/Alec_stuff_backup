// Load SnailNet 3rd party libraries

extern U16 htons(U16 h);

#include "::/3rdParty/SnailNet/NativeSocket";
#include "::/3rdParty/SnailNet/NetFifo";
#include "::/3rdParty/SnailNet/Socket";

// Layer 2
#include "::/3rdParty/SnailNet/Ethernet";

// Layer 3
#include "::/3rdParty/SnailNet/Arp";
#include "::/3rdParty/SnailNet/IPv4";

// Layer 4
#include "::/3rdParty/SnailNet/Icmp";
#include "::/3rdParty/SnailNet/Tcp";
#include "::/3rdParty/SnailNet/Udp";

// Layer 7
#include "::/3rdParty/SnailNet/Dhcp";
#include "::/3rdParty/SnailNet/Dns";

#include "::/3rdParty/SnailNet/Netcfg";

U0 @virtio_net_handle_net_fifo_entry(CNetFifoEntry *e) {
  CEthFrame l2_frame;

  if (EthernetFrameParse(&l2_frame, e->frame, e->length) < 0)
    return;

  CL3Protocol *l3 = l3_protocols;

  while (l3) {
    if (l3->ethertype == l2_frame.ethertype) {
      l3->handler(&l2_frame);
      break;
    }
    l3 = l3->next;
  }
}

U0 @virtio_net_handler_task() {
  I64 idx_used, idx_rec;
  I64 i, j;
  @virtio_used_item *item;
  U8 *buffer;
  I64 length;
  while (1) {
    idx_rec = VirtioNet.rq_index;
    idx_used = VirtioNet.rq->used.index;

    if (idx_used < idx_rec) {
      idx_used += 0x10000;
    }

    if (idx_rec != idx_used && idx_used) {

      j = 0;
      for (i = idx_rec; i < idx_used; i++) {
        item = VirtioNet.rq->used.ring;
        buffer = VirtioNet.rq->buffers[item[i % 256].index + 1];
        length = item[i % 256].length;
        NetFifoPushCopy(buffer, length - 10);
        j++;
        VirtioNet.rx_packets++;
        VirtioNet.rx_bytes += length - 10;
      }
      VirtioNet.rq_index = idx_used % 0x10000;
      VirtioNet.rq->available.index += j;
      OutU16(VirtioNet.port + VIRTIO_PCI_QUEUE_NOTIFY, 0);
    }
    CNetFifoEntry *e = NetFifoPull;
    if (e) {
      @virtio_net_handle_net_fifo_entry(e);
    }
    Yield;
  }
}

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

class @net {
  I64 (*ResolveIPv4Address)(U8 * _str, U32 * addr);
  U32 (*GetIPv4DNSResolver)();
};

@net Net;

Net.GetIPv4DNSResolver = &@net_get_ipv4_dns_resolver;
Net.ResolveIPv4Address = &@net_resolve_ipv4_address;

"net ";
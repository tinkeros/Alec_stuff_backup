CDoc *tmpdoc = DocNew;
CDoc *fsdoc = Fs->put_doc;

U0 DISABLE_STDOUT() { Fs->put_doc = tmpdoc; }
U0 ENABLE_STDOUT() { Fs->put_doc = fsdoc; }

I64 aol_socket = NULL;

/* clang-format off */

#include "Src/Debug";

#include "Net/Virtio";
#include "Net/Virtio-net";

#include "Net/NativeSocket";
#include "Net/NetFifo";
#include "Net/Socket";

// Layer 2
#include "Net/Ethernet";

// Layer 3
#include "Net/Arp";
#include "Net/IPv4";

// Layer 4
#include "Net/Icmp";
#include "Net/Tcp";
#include "Net/Udp";

// Layer 7
#include "Net/Dhcp";
#include "Net/Dns";

#include "Net/Netcfg";
#include "Net/NetHandler";

#include "Src/NetUtils";
#include "TOL";

/* clang-format on */

Netcfg;
dns_ip = 0x08080808;

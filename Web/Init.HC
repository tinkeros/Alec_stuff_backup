CDoc *tmpdoc = DocNew;
CDoc *fsdoc = Fs->put_doc;

U0 DISABLE_STDOUT() { Fs->put_doc = tmpdoc; }
U0 ENABLE_STDOUT() { Fs->put_doc = fsdoc; }

/* clang-format off */

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

/* clang-format on */

/* clang-format off */

#include "Tls/Aes256";
#include "Tls/Curve25519";
#include "Tls/Sha256";
#include "Tls/Hmac-Sha256";
#include "Tls/Sha1";
#include "Tls/Hmac-Sha1";
#include "Tls/Tls12";

#include "Tls/String";
#include "Tls/NetUtils";
#include "Tls/Http";

/* clang-format on */

#include "Web";

Netcfg;
dns_ip = 0x08080808;
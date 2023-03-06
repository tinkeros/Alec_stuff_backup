#define include_noreindex #include

include_noreindex "Lib/Util";

"Loading drivers: ";
include_noreindex "Drivers/Virtio";
include_noreindex "Drivers/Virtio-net";
"\n";

include_noreindex "Net";

include_noreindex "Lib/Aes256";
include_noreindex "Lib/Curve25519";
include_noreindex "Lib/Sha256";
include_noreindex "Lib/Hmac-Sha256";
include_noreindex "Lib/Sha1";
include_noreindex "Lib/Hmac-Sha1";
include_noreindex "Lib/Tls12";

U0 Main() {

  U32 our_ip = 0;
  U8 *server_host = "www.google.com";
  U32 server_ip = 0;
  U16 port = 443;

  // "TOO LITTLE DATA, SO I MAKE BIG."
  WinMax;

  // Initialize Network
  @virtio_net_init;
  Spawn(&@virtio_net_handler_task, , "Virtio-net", mp_cnt - 1);
  Spawn(&Netcfg, , "Netcfg");

  "\n Waiting for DHCP...";
  while (!my_ip)
    Sleep(1);

  our_ip = EndianU32(my_ip);
  "\n Our IP address is : %d.%d.%d.%d\n", our_ip.u8[0], our_ip.u8[1],
      our_ip.u8[2], our_ip.u8[3];

  "\n DNS record lookup : %s ... ", server_host;
  Net.ResolveIPv4Address(server_host, &server_ip);
  "\n Address : %d.%d.%d.%d\n", server_ip.u8[0], server_ip.u8[1],
      server_ip.u8[2], server_ip.u8[3];

  "\n Making TLS connection to %d.%d.%d.%d:%d ... ", server_ip.u8[0],
      server_ip.u8[1], server_ip.u8[2], server_ip.u8[3], port;

  @tls_context *ctx = @tls12_new_context;
  @tls12_connect(ctx, server_host, server_ip, port);

  "\n Sending HTTPS GET request ...";

  I64 request_len = 0;
  U8 *request_body = FileRead("request.txt", &request_len);

  @tls12_send(ctx, request_body, request_len, 0);
  @tls12_recv(ctx, 1, 2048, 0);

  "\n";
}

Main;
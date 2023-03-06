#define TLS12_ERR_UNSUPPORTED_HANDSHAKE_MSG -1
#define TLS12_ERR_UNSUPPORTED_CONTENT_TYPE -2
#define TLS12_ERR_INCOMPLETE_HANDSHAKE -3

#define TLS1_VERSION 0x0301
#define TLS1_1_VERSION 0x0302
#define TLS1_2_VERSION 0x0303
#define TLS1_3_VERSION 0x0304

#define CHANGE_CIPHER_SPEC 0x14
#define ALERT 0x15
#define HANDSHAKE 0x16
#define APPLICATION_DATA 0x17

#define HT_HELLO_REQUEST 0x00
#define HT_CLIENT_HELLO 0x01
#define HT_SERVER_HELLO 0x02
#define HT_CERTIFICATE 0x0B
#define HT_SERVER_KEY_EXCHANGE 0x0C
#define HT_CERTIFICATE_REQUEST 0x0D
#define HT_SERVER_HELLO_DONE 0x0E
#define HT_CERTIFICATE_VERIFY 0x0F
#define HT_CLIENT_KEY_EXCHANGE 0x10
#define HT_FINISHED 0x14
#define HT_CERTIFICATE_STATUS 0x16

Bool tls_debug = FALSE;
Bool doc_debug = FALSE;

U8 *ke_str_magic_ms = "master secret";
U8 *ke_str_magic_ke = "key expansion";
U8 *ke_str_magic_cf = "client finished";

U8 tls12_cipher_suites[6] = {0x00, 0x04, 0xc0, 0x14, 0xc0, 0x0a};

U8 tls12_client_hello_2_data[42] = {
    0x00, 0x05, 0x00, 0x05, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0a,
    0x00, 0x04, 0x00, 0x02, 0x00, 0x1d, 0x00, 0x0b, 0x00, 0x02, 0x01,
    0x00, 0x00, 0x0d, 0x00, 0x06, 0x00, 0x04, 0x04, 0x01, 0x04, 0x03,
    0xff, 0x01, 0x00, 0x01, 0x00, 0x00, 0x12, 0x00, 0x00};

U8 tls12_client_key_exchange_header[10] = {0x16, 0x03, 0x03, 0x00, 0x25,
                                           0x10, 0x00, 0x00, 0x21, 0x20};

U8 tls12_client_change_cipher_spec[6] = {0x14, 0x03, 0x03, 0x00, 0x01, 0x01};

class @tls_key_expansion {
  U8 client_write_mac_key[20];
  U8 server_write_mac_key[20];
  U8 client_write_key[32];
  U8 server_write_key[32];
  U8 client_write_iv[16];
  U8 server_write_iv[16];
};

class @tls_context {
  I64 sock;
  U64 client_seq_num;
  U64 server_seq_num;
  U8 server_name[512];
  U8 session_id[32];
  U8 client_random[32];
  U8 server_random[32];
  U8 client_public_key[32];
  U8 client_private_key[32];
  U8 server_public_key[32];
  U8 pre_master_secret[32];
  U8 master_secret[48];
  @tls_key_expansion ke;
};

class @tls_record {
  U8 content_type;
  U16 version;
  U16 length;
  U8 data;
};

class @tls_handshake_header {
  U8 message_type;
  U8 length_pad;
  U16 length; // this is actually 24 bit, but we don't care :^)
  U8 data;
}

class @tls_client_hello_1 {
  U16 client_version;
  U8 client_random[32];
  U8 session_id;
  U8 cipher_suites[6];
  U16 compression;
  U16 extensions_length;
  U8 data;
};

class @tls_server_hello_1 {
  U16 server_version;
  U8 server_random[32];
  U8 session_id;
  U8 data;
};

class @tls_server_key_exchange_header {
  U8 curve_type;
  U16 named_curve;
  U8 pubkey_length;
  U8 pubkey[32];
  U8 data;
};

class @tls_client_hello_extension_server_name {
  U16 extension_type;
  U16 extension_length;
  U16 list_entry_length;
  U8 list_entry_type;
  U16 hostname_length;
  U8 data;
};

@tls_record *@tls12_build_client_hello(@tls_context *ctx, U8 *server_name) {

  @tls_record *record = CAlloc(512);

  record->content_type = HANDSHAKE;
  record->version = EndianU16(TLS1_2_VERSION);

  @tls_handshake_header *handshake_header = &record->data;
  handshake_header->message_type = HT_CLIENT_HELLO;

  @tls_client_hello_1 *client_hello_1 = &handshake_header->data;
  client_hello_1->client_version = TLS1_2_VERSION;
  MemCpy(&client_hello_1->client_random, &ctx->client_random, 32);
  client_hello_1->session_id = 0;
  MemCpy(&client_hello_1->cipher_suites, &tls12_cipher_suites, 6);
  client_hello_1->compression = 1;

  // Set Client Hello server name
  @tls_client_hello_extension_server_name *extension_server_name =
      &client_hello_1->data;
  extension_server_name->extension_type = 0;
  extension_server_name->extension_length = EndianU16(StrLen(server_name) + 5);
  extension_server_name->list_entry_length = EndianU16(StrLen(server_name) + 3);
  extension_server_name->list_entry_type = 0;
  extension_server_name->hostname_length = EndianU16(StrLen(server_name));
  MemCpy(&extension_server_name->data, server_name, StrLen(server_name));

  // MemCpy remaining extensions
  MemCpy(&extension_server_name->data + StrLen(server_name),
         &tls12_client_hello_2_data, 42);

  // Calculate Extensions length
  client_hello_1->extensions_length =
      sizeof(@tls_client_hello_extension_server_name) - 1;
  client_hello_1->extensions_length += StrLen(server_name);
  client_hello_1->extensions_length += 42;
  client_hello_1->extensions_length =
      EndianU16(client_hello_1->extensions_length);

  // Calculate Handshake length
  handshake_header->length = EndianU16(client_hello_1->extensions_length) +
                             sizeof(@tls_client_hello_1) - 1;
  handshake_header->length = EndianU16(handshake_header->length);

  // Calculate TLS record length
  record->length =
      EndianU16(handshake_header->length) + sizeof(@tls_record) - 2;
  record->length = EndianU16(record->length);

  return record;
}

@tls_context *@tls12_new_context() {
  I64 i;
  @tls_context *ctx = CAlloc(sizeof(@tls_context));
  for (i = 0; i < 32; i++) {
    ctx->client_random[i] = RandU16 & 0xFF;
    ctx->client_private_key[i] = RandU16 & 0xFF;
    // ctx->session_id[i] = RandU16 & 0xFF;
  }
  cf_curve25519_mul_base(ctx->client_public_key, ctx->client_private_key);
  return ctx;
}

U0 @tls_calculate_master_secret(@tls_context *ctx) {
  U8 a0[77];
  U8 a1[109];
  U8 a2[109];
  U8 p1[32];
  U8 p2[32];
  I64 i;

  MemCpy(a0, ke_str_magic_ms, StrLen(ke_str_magic_ms));
  MemCpy(a0 + StrLen(ke_str_magic_ms), &ctx->client_random, 32);
  MemCpy(a0 + StrLen(ke_str_magic_ms) + 32, &ctx->server_random, 32);

  hmac_sha256(&ctx->pre_master_secret, 32, a0, 77, a1, 32);
  hmac_sha256(&ctx->pre_master_secret, 32, a1, 32, a2, 32);
  MemCpy(a1 + 32, a0, 77);
  MemCpy(a2 + 32, a0, 77);

  hmac_sha256(&ctx->pre_master_secret, 32, a1, 109, p1, 32);
  hmac_sha256(&ctx->pre_master_secret, 32, a2, 109, p2, 32);

  MemCpy(&ctx->master_secret, p1, 32);
  for (i = 0; i < 16; i++)
    ctx->master_secret[32 + i] = p2[i];
}

U0 @tls_do_key_expansion(@tls_context *ctx) {
  U8 a0[77];
  U8 a1[109];
  U8 a2[109];
  U8 a3[109];
  U8 a4[109];
  U8 a5[109];
  U8 p1[32];
  U8 p2[32];
  U8 p3[32];
  U8 p4[32];
  U8 p5[32];
  U8 p[160];
  I64 i;

  MemCpy(a0, ke_str_magic_ke, StrLen(ke_str_magic_ke));
  MemCpy(a0 + StrLen(ke_str_magic_ke), &ctx->server_random, 32);
  MemCpy(a0 + StrLen(ke_str_magic_ke) + 32, &ctx->client_random, 32);

  hmac_sha256(&ctx->master_secret, 48, a0, 77, a1, 32);
  hmac_sha256(&ctx->master_secret, 48, a1, 32, a2, 32);
  hmac_sha256(&ctx->master_secret, 48, a2, 32, a3, 32);
  hmac_sha256(&ctx->master_secret, 48, a3, 32, a4, 32);
  hmac_sha256(&ctx->master_secret, 48, a4, 32, a5, 32);
  MemCpy(a1 + 32, a0, 77);
  MemCpy(a2 + 32, a0, 77);
  MemCpy(a3 + 32, a0, 77);
  MemCpy(a4 + 32, a0, 77);
  MemCpy(a5 + 32, a0, 77);

  hmac_sha256(&ctx->master_secret, 48, a1, 109, p1, 32);
  hmac_sha256(&ctx->master_secret, 48, a2, 109, p2, 32);
  hmac_sha256(&ctx->master_secret, 48, a3, 109, p3, 32);
  hmac_sha256(&ctx->master_secret, 48, a4, 109, p4, 32);
  hmac_sha256(&ctx->master_secret, 48, a5, 109, p5, 32);

  for (i = 0; i < 32; i++) {
    p[i] = p1[i];
    p[32 + i] = p2[i];
    p[64 + i] = p3[i];
    p[96 + i] = p4[i];
    p[128 + i] = p5[i];
  }

  MemCpy(&ctx->ke.client_write_mac_key, p, 20);
  MemCpy(&ctx->ke.server_write_mac_key, p + 20, 20);
  MemCpy(&ctx->ke.client_write_key, p + 40, 32);
  MemCpy(&ctx->ke.server_write_key, p + 72, 32);
  MemCpy(&ctx->ke.client_write_iv, p + 104, 16);
  MemCpy(&ctx->ke.server_write_iv, p + 120, 16);
}

U0 @tls12_generate_verify_data(@tls_context *ctx, U8 *verify_data,
                               U8 *verify_data_sha256) {
  U8 a0[47];
  U8 a1[79];
  U8 p1[32];

  MemCpy(a0, ke_str_magic_cf, StrLen(ke_str_magic_cf));
  MemCpy(a0 + StrLen(ke_str_magic_cf), verify_data_sha256, 32);
  hmac_sha256(&ctx->master_secret, 48, a0, 47, a1, 32);
  MemCpy(a1 + 32, a0, 47);

  hmac_sha256(&ctx->master_secret, 48, a1, 79, p1, 32);

  MemCpy(verify_data, p1, 12);
}

@tls_record **@tls12_parse_buffer(U8 *buf, I64 len, I64 *cnt) {
  @tls_record *rec;
  @tls_record **recs;
  U8 *buf2;
  I64 len2;
  cnt[0] = 0;
  Bool pass2 = FALSE;
  @tls12_parse_buffer_loop : buf2 = buf;
  len2 = len;
  // Pass 1: Get number of TLS records in buffer
  // Pass 2: Populate array with TLS records
  while (len2 > 0) {
    rec = buf2;
    switch (rec->content_type) {
    case NULL:
      len2 = 0;
      break;
    case CHANGE_CIPHER_SPEC:
    case ALERT:
    case HANDSHAKE:
    case APPLICATION_DATA:
      if (pass2)
        recs[cnt[0]] = rec;
      buf2 += EndianU16(rec->length) + 5;
      len2 -= EndianU16(rec->length) + 5;
      cnt[0]++;
      break;
    default:
      PrintErr("Unsupported TLS content type : %d", rec->content_type);
      PressAKey;
      SysHlt;
      break;
    }
  }
  if (cnt[0] && !pass2) {
    recs = CAlloc(sizeof(@tls_record *) * cnt[0]);
    cnt[0] = 0;
    pass2 = TRUE;
    goto @tls12_parse_buffer_loop;
  }
  return recs;
}

U0 @tls12_new_client_iv(@tls_context *ctx) {
  I64 i;
  // Set new initialization vector
  for (i = 0; i < 16; i++)
    ctx->ke.client_write_iv[i] = RandU16 & 0xFF;
}

I64 *@tls12_connect(@tls_context *ctx, U8 *server_name, U32 ip, U16 port) {
  I64 ret = 0;
  CFifoU8 *client_send_fifo = FifoU8New(131072);
  CFifoU8 *verify_data_fifo = FifoU8New(131072);
  U8 *byteptr;
  U64 *qwordptr;
  U8 buf[32768];
  U8 buf2[32768];
  U8 buf3[32768];
  U8 buf4[32768];
  U8 ch;
  U8 client_kexch[42];
  U8 verify_data[12];
  U8 verify_data_sha256[32];
  I64 cnt = 0;
  I64 len = 0;
  I64 payload_acc_len = 0;
  I64 total_len = 0;
  I64 sock = socket(AF_INET, SOCK_STREAM);
  I64 err = 0;
  I64 i;
  I64 j;
  sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = ip;

  ctx->sock = sock;
  err = connect(sock, &addr, sizeof(addr));
  if (err)
    return NULL;

  @tls_record *client_hello = @tls12_build_client_hello(ctx, server_name);

  if (doc_debug)
    "\n";

  send(sock, client_hello, EndianU16(client_hello->length) + 5, 0);
  if (doc_debug)
    "\n \dFG,2\d-> \dFG,0\dClient Hello \dFD\d";

  @tls_record *server_hello = NULL;
  @tls_record *certificate = NULL;
  @tls_record *certificate_status = NULL;
  @tls_record *certificate_request = NULL;
  @tls_record *server_key_exchange = NULL;
  @tls_record *server_hello_done = NULL;
  @tls_record **recs;

  while (!server_hello_done) {
    total_len = 0;
    payload_acc_len = 0;
    len = recv(sock, buf3, sizeof(@tls_record) - 1, 0);
    if (tls_debug)
      System.Log(Fs, "Received len: %d bytes", len);
    total_len += len;

    if (!total_len)
      break;

    cnt = 0;
    recs = @tls12_parse_buffer(buf3, total_len, &cnt);

    if (!cnt) {
      System.Log(Fs, "ERROR: Unable to parse TLS records in received data.");
      return NULL;
    }
    if (cnt > 1) {
      System.Log(Fs, "ERROR: Expected 1 TLS record in received data, got >1.");
      return NULL;
    }

    payload_acc_len = EndianU16(recs[0]->length);
    while (payload_acc_len) {
      len = recv(sock, buf3 + total_len, payload_acc_len, 0);
      if (tls_debug)
        System.Log(Fs, "Requested len: %d bytes", payload_acc_len);
      payload_acc_len -= len;
      total_len += len;
      if (tls_debug)
        System.Log(Fs, "Received len: %d bytes", len);
    }

    for (i = 0; i < cnt; i++) {
      switch (recs[i]->content_type) {
      case CHANGE_CIPHER_SPEC:
        break;
      case ALERT:
        break;
      case HANDSHAKE:
        byteptr = &recs[i]->data;
        for (j = 0; j < EndianU16(recs[i]->length); j++)
          FifoU8Ins(verify_data_fifo, byteptr[j]);
        switch (recs[i]->data) {
        case HT_SERVER_HELLO:
          server_hello = MAlloc(EndianU16(recs[i]->length) + 5);
          MemCpy(server_hello, recs[i], EndianU16(recs[i]->length) + 5);
          if (doc_debug)
            "\n \dFG,3\d<- \dFG,0\dServer Hello \dFD\d";
          break;
        case HT_CERTIFICATE:
          certificate = MAlloc(EndianU16(recs[i]->length) + 5);
          MemCpy(certificate, recs[i], EndianU16(recs[i]->length) + 5);
          if (doc_debug)
            "\n \dFG,3\d<- \dFG,0\dCertificate \dFD\d";
          break;
        case HT_CERTIFICATE_REQUEST:
          certificate_request = MAlloc(EndianU16(recs[i]->length) + 5);
          MemCpy(certificate_request, recs[i], EndianU16(recs[i]->length) + 5);
          if (doc_debug)
            "\n \dFG,3\d<- \dFG,0\dCertificate Request\dFD\d";
          break;
        case HT_CERTIFICATE_STATUS:
          certificate_status = MAlloc(EndianU16(recs[i]->length) + 5);
          MemCpy(certificate_status, recs[i], EndianU16(recs[i]->length) + 5);
          if (doc_debug)
            "\n \dFG,3\d<- \dFG,0\dCertificate Status\dFD\d";
          break;
        case HT_SERVER_KEY_EXCHANGE:
          server_key_exchange = MAlloc(EndianU16(recs[i]->length) + 5);
          MemCpy(server_key_exchange, recs[i], EndianU16(recs[i]->length) + 5);
          if (doc_debug)
            "\n \dFG,3\d<- \dFG,0\dServer Key Exchange \dFD\d";
          break;
        case HT_SERVER_HELLO_DONE:
          server_hello_done = MAlloc(EndianU16(recs[i]->length) + 5);
          MemCpy(server_hello_done, recs[i], EndianU16(recs[i]->length) + 5);
          if (doc_debug)
            "\n \dFG,3\d<- \dFG,0\dServer Hello Done \dFD\d";
          break;
        default:
          // PrintErr("Unsupported TLS handshake message type from server.");
          // PressAKey;
          // SysHlt;
          ret = TLS12_ERR_UNSUPPORTED_HANDSHAKE_MSG;
          goto tls12_connect_return_err;
          break;
        }
        break;
      case APPLICATION_DATA:
        break;
      default:
        // PrintErr("Unsupported TLS content type from server.");
        // SysHlt;
        ret = TLS12_ERR_UNSUPPORTED_CONTENT_TYPE;
        goto tls12_connect_return_err;
        break;
      }
    }
  }

  if (!server_hello || !certificate || !server_key_exchange ||
      !server_hello_done) {
    // PrintErr("Did not receive all required handshake content from server.");
    // PressAKey;
    // SysHlt;
    ret = TLS12_ERR_INCOMPLETE_HANDSHAKE;
    goto tls12_connect_return_err;
  }

  MemCpy(client_kexch, tls12_client_key_exchange_header, 10);
  MemCpy(client_kexch + 10, ctx->client_public_key, 32);
  // send(sock, client_kexch, 42, 0);
  for (j = 0; j < 42; j++)
    FifoU8Ins(client_send_fifo, client_kexch[j]);
  if (doc_debug)
    "\n \dFG,2\d-> \dFG,0\dClient Key Exchange \dFD\d";

  for (j = 0; j < 6; j++)
    FifoU8Ins(client_send_fifo, tls12_client_change_cipher_spec[j]);
  // send(sock, tls12_client_change_cipher_spec, 6, 0);
  if (doc_debug)
    "\n \dFG,2\d-> \dFG,0\dChange Cipher Spec \dFD\d";

  // Make a copy of Server Random
  @tls_server_hello_1 *server_hello_1 = &server_hello->data + 4;
  MemCpy(&ctx->server_random, &server_hello_1->server_random, 32);

  // Make a copy of Server Public Key
  @tls_server_key_exchange_header *server_kexch_1 =
      &server_key_exchange->data + 4;
  MemCpy(&ctx->server_public_key, &server_kexch_1->pubkey, 32);

  // Calculate PreMasterSecret
  cf_curve25519_mul(&ctx->pre_master_secret, &ctx->client_private_key,
                    &ctx->server_public_key);

  // Calculate MasterSecret
  @tls_calculate_master_secret(ctx);

  // Do Key Expansion
  @tls_do_key_expansion(ctx);

  U8 str_SSLKEYLOGFILE[512];
  U8 debug_buf[3];

  // Debug output: SSLKEYLOGFILE
  if (tls_debug) {
    StrCpy(str_SSLKEYLOGFILE, "CLIENT_RANDOM ");

    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->client_random[i]);
      StrCpy(str_SSLKEYLOGFILE + StrLen(str_SSLKEYLOGFILE), debug_buf);
    }
    StrCpy(str_SSLKEYLOGFILE + StrLen(str_SSLKEYLOGFILE), " ");
    for (i = 0; i < 48; i++) {
      StrPrint(debug_buf, "%02x", ctx->master_secret[i]);
      StrCpy(str_SSLKEYLOGFILE + StrLen(str_SSLKEYLOGFILE), debug_buf);
    }
    System.Log(Fs, str_SSLKEYLOGFILE);
  }

  // Build Verify Data buffer

  // Zero the buffer
  MemSet(buf4, 0, 32768);

  // Copy Client Hello to buf
  len = 0;
  MemCpy(buf4, &client_hello->data, EndianU16(client_hello->length));
  len += EndianU16(client_hello->length);

  // Copy all Server Handshake messages to buf
  while (FifoU8Cnt(verify_data_fifo)) {
    FifoU8Rem(verify_data_fifo, &ch);
    buf4[len] = ch;
    len++;
  }
  FifoU8Flush(verify_data_fifo);
  FifoU8Del(verify_data_fifo);

  // Copy Client Key Exchange to buf
  for (j = 0; j < 37; j++)
    buf4[len + j] = client_kexch[5 + j];
  len += 37;

  // Get SHA256 digest of buf
  calc_sha_256(verify_data_sha256, buf4, len);

  // Generate Verify Data value
  @tls12_generate_verify_data(ctx, verify_data, verify_data_sha256);

  // Set new client initialization vector
  @tls12_new_client_iv(ctx);

  // Build payload
  buf2[0] = 0x14;
  buf2[1] = 0x00;
  buf2[2] = 0x00;
  buf2[3] = 0x0c;
  for (j = 0; j < 12; j++)
    buf2[4 + j] = verify_data[j];

  // Build payload to calculate HMAC
  ctx->client_seq_num = 0;
  qwordptr = buf;
  qwordptr[0] = EndianU64(ctx->client_seq_num);
  buf[8] = 0x16;
  buf[9] = 0x03;
  buf[10] = 0x03;
  buf[11] = 0x00;
  buf[12] = 0x10;

  for (j = 0; j < 16; j++)
    buf[13 + j] = buf2[j];
  hmac_sha1(&ctx->ke.client_write_mac_key, 20, buf, 29, buf2 + 16, 20);

  i = 36;
  while (i % 16) {
    buf2[i] = 0x0b; // Padding
    i++;
  }

  // Encrypt payload
  AES_ctx aes_ctx;
  AES_init_ctx_iv(&aes_ctx, &ctx->ke.client_write_key,
                  &ctx->ke.client_write_iv);
  AES_CBC_encrypt_buffer(&aes_ctx, &buf2, i);

  // Debug values
  U8 debug_str[64];
  if (tls_debug) {
    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "client_private_key: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->client_private_key[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "client_public_key: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->client_public_key[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "server_public_key: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->server_public_key[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "client_random: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->client_random[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "server_random: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->server_random[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "pre_master_secret: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->pre_master_secret[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "client_write_mac_key: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 20; i++) {
      StrPrint(debug_buf, "%02x", ctx->ke.client_write_mac_key[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "client_write_key: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 32; i++) {
      StrPrint(debug_buf, "%02x", ctx->ke.client_write_key[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "client_write_iv: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 16; i++) {
      StrPrint(debug_buf, "%02x", ctx->ke.client_write_iv[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }

    OutU8(0x3F8, '\n');
    StrCpy(debug_str, "encrypted payload: ");
    for (i = 0; i < StrLen(debug_str); i++)
      OutU8(0x3F8, debug_str[i]);
    for (i = 0; i < 48; i++) {
      StrPrint(debug_buf, "%02x", buf2[i]);
      OutU8(0x3F8, debug_buf[0]);
      OutU8(0x3F8, debug_buf[1]);
    }
    OutU8(0x3F8, '\n');
  }

  // Build Client Handshake Finished
  MemSet(buf, 0, 69);
  buf[0] = 0x16;
  buf[1] = 0x03;
  buf[2] = 0x03;
  buf[3] = 0x00;
  buf[4] = 0x40;

  for (j = 0; j < 16; j++)
    buf[5 + j] = ctx->ke.client_write_iv[j];

  for (j = 0; j < i; j++)
    buf[21 + j] = buf2[j];

  for (j = 0; j < 69; j++)
    FifoU8Ins(client_send_fifo, buf[j]);
  if (doc_debug)
    "\n \dFG,2\d-> \dFG,0\dFinished \dFD\d";

  U8 fbyte;
  i = FifoU8Cnt(client_send_fifo);
  for (j = 0; j < i; j++) {
    FifoU8Rem(client_send_fifo, &fbyte);
    buf[j] = fbyte;
  }
  send(sock, buf, i, 0);

  len = recv(sock, buf3, 1024, 0);
  recs = @tls12_parse_buffer(buf3, len, &cnt);

  for (i = 0; i < cnt; i++) {
    switch (recs[i]->content_type) {
    case CHANGE_CIPHER_SPEC:
      if (doc_debug)
        "\n \dFG,3\d<- \dFG,0\dChange Cipher Spec \dFD\d";
      break;
    case ALERT:
      break;
    case HANDSHAKE:
      MemCpy(buf2, &recs[i]->data, EndianU16(recs[i]->length));
      MemCpy(&ctx->ke.server_write_iv, buf2, 16);
      byteptr = buf2;
      byteptr += 16;
      AES_init_ctx_iv(&aes_ctx, &ctx->ke.server_write_key,
                      &ctx->ke.server_write_iv);
      AES_CBC_decrypt_buffer(&aes_ctx, byteptr,
                             EndianU16(recs[i]->length) - 16);
      switch (byteptr[0]) {
      case HT_FINISHED:
        if (doc_debug)
          "\n \dFG,3\d<- \dFG,0\dFinished \dFD\d";
        break;
      default:
        // PrintErr("Unsupported TLS handshake message type from server.");
        // PressAKey;
        // SysHlt;
        ret = TLS12_ERR_UNSUPPORTED_HANDSHAKE_MSG;
        goto tls12_connect_return_err;
        break;
      }
      break;
    case APPLICATION_DATA:
      break;
    default:
      // PrintErr("Unsupported TLS content type from server.");
      // SysHlt;
      ret = TLS12_ERR_UNSUPPORTED_CONTENT_TYPE;
      goto tls12_connect_return_err;
      break;
    }
  }
tls12_connect_return_err:
  FifoU8Del(client_send_fifo);
  return ret;
}

I64 @tls12_get_decrypt_pad_len(U8 *buf, I64 size) {
  if (buf[size - 1] < 0x10)
    return buf[size - 1];
  return NULL;
}

I64 @tls12_recv2(@tls_context *ctx, U8 *buf) {
  // Receive TLS Application Data
  if (!ctx || !buf)
    return NULL;

  I64 i;
  U8 *buf2 = CAlloc(65536);
  // U8 *buf3 = MAlloc(65536);
  @tls_record **recs;

  I64 out_len = 0;
  I64 decrypt_pad_len = 0;
  I64 len = 0;
  I64 total_len = len;
  I64 payload_acc_len = 0;

  len = recv(ctx->sock, buf2, sizeof(@tls_record) - 1, 0);
  if (tls_debug)
    System.Log(Fs, "Received len: %d bytes", len);
  total_len += len;

  if (!total_len)
    return 0;

  I64 cnt = 0;
  recs = @tls12_parse_buffer(buf2, total_len, &cnt);

  if (!cnt) {
    System.Log(Fs, "ERROR: Unable to parse TLS records in received data.");
    Free(buf2);
    return NULL;
  }
  if (cnt > 1) {
    System.Log(Fs, "ERROR: Expected 1 TLS record in received data, got >1.");
    Free(buf2);
    return NULL;
  }

  payload_acc_len = EndianU16(recs[0]->length);

  while (payload_acc_len) {
    len = recv(ctx->sock, buf2 + total_len, payload_acc_len, 0);
    if (tls_debug)
      System.Log(Fs, "Requested len: %d bytes", payload_acc_len);
    payload_acc_len -= len;
    total_len += len;
    if (tls_debug)
      System.Log(Fs, "Received len: %d bytes", len);
  }

  AES_ctx aes_ctx;

  for (i = 0; i < cnt; i++) {
    switch (recs[i]->content_type) {
    case APPLICATION_DATA:
      MemCpy(buf, &recs[i]->data + 16, EndianU16(recs[i]->length) - 16);
      MemCpy(&ctx->ke.server_write_iv, &recs[i]->data, 16);

      AES_init_ctx_iv(&aes_ctx, &ctx->ke.server_write_key,
                      &ctx->ke.server_write_iv);
      AES_CBC_decrypt_buffer(&aes_ctx, buf, EndianU16(recs[i]->length) - 16);
      decrypt_pad_len =
          @tls12_get_decrypt_pad_len(buf, EndianU16(recs[i]->length) - 16);
      out_len += EndianU16(recs[i]->length) - 16 - 20 - decrypt_pad_len;
      break;
    default:
      break;
    }
  }

  Free(recs);
  Free(buf2);
  return out_len;
}

I64 @tls12_recv(@tls_context *ctx, U8 *buf, I64 size, I64 flags = NULL) {
  if (!ctx || !buf || !size)
    return NULL;

  I64 i;
  U8 *buf2 = MAlloc(1048576);
  U8 *buf3 = MAlloc(1048576);
  @tls_record **recs;

  I64 out_len = 0;
  I64 decrypt_pad_len = 0;
  I64 len = 0;
  I64 total_len = len;

tls12_recv_loop:
  len = recv(ctx->sock, buf3 + total_len, size, flags);
  total_len += len;

  while (len)
    goto tls12_recv_loop;

  if (!total_len)
    return NULL;

  I64 cnt = 0;
  recs = @tls12_parse_buffer(buf3, total_len, &cnt);

  AES_ctx aes_ctx;

  for (i = 0; i < cnt; i++) {
    switch (recs[i]->content_type) {
    case APPLICATION_DATA:
      MemCpy(buf2, &recs[i]->data + 16, EndianU16(recs[i]->length) - 16);
      MemCpy(&ctx->ke.server_write_iv, &recs[i]->data, 16);

      AES_init_ctx_iv(&aes_ctx, &ctx->ke.server_write_key,
                      &ctx->ke.server_write_iv);
      AES_CBC_decrypt_buffer(&aes_ctx, buf2, EndianU16(recs[i]->length) - 16);
      decrypt_pad_len =
          @tls12_get_decrypt_pad_len(buf2, EndianU16(recs[i]->length) - 16);
      MemCpy(buf + out_len, buf2,
             EndianU16(recs[i]->length) - 16 - 20 - decrypt_pad_len);
      out_len += EndianU16(recs[i]->length) - 16 - 20 - decrypt_pad_len;
      break;
    default:
      break;
    }
  }
  Free(buf2);
  Free(buf3);
  return out_len - 1;
}

I64 @tls12_send(@tls_context *ctx, U8 *buf, I64 size, I64 flags = NULL) {
  if (!ctx || !buf || !size)
    return NULL;

  @tls12_new_client_iv(ctx);

  U64 *qwordptr;
  I64 i;
  U8 buf2[4096];
  U8 buf3[4096];
  U16 u16_size = size;

  // Initial pad of the buffer
  I64 padding_len = 0;
  I64 padded_buf_size = size + 20;
  while (padded_buf_size % 16) {
    padded_buf_size++;
    padding_len++;
  }
  if (!padding_len) {
    padded_buf_size += 16;
    padding_len = 16;
  }
  MemSet(buf2, padding_len - 1, padded_buf_size);
  MemCpy(buf2, buf, size);

  // Build payload to calculate HMAC
  ctx->client_seq_num++;
  qwordptr = buf3;
  qwordptr[0] = EndianU64(ctx->client_seq_num);

  buf3[8] = APPLICATION_DATA;
  buf3[9] = 0x03;
  buf3[10] = 0x03;
  buf3[11] = u16_size.u8[1];
  buf3[12] = u16_size.u8[0];

  for (i = 0; i < size; i++)
    buf3[13 + i] = buf2[i];

  hmac_sha1(&ctx->ke.client_write_mac_key, 20, buf3, 13 + i, buf2 + size, 20);

  // Encrypt payload
  AES_ctx aes_ctx;
  AES_init_ctx_iv(&aes_ctx, &ctx->ke.client_write_key,
                  &ctx->ke.client_write_iv);
  AES_CBC_encrypt_buffer(&aes_ctx, buf2, padded_buf_size);

  u16_size = padded_buf_size + 16;

  buf3[0] = APPLICATION_DATA;
  buf3[1] = 0x03;
  buf3[2] = 0x03;
  buf3[3] = u16_size.u8[1];
  buf3[4] = u16_size.u8[0];

  for (i = 0; i < 16; i++)
    buf3[5 + i] = ctx->ke.client_write_iv[i];

  for (i = 0; i < padded_buf_size; i++)
    buf3[21 + i] = buf2[i];

  send(ctx->sock, buf3, padded_buf_size + 21, flags);
}

"tls12 ";
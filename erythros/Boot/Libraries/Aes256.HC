@disable_doldoc_output;

class AES_ctx {
  U8 RoundKey[240];
  U8 Iv[16];
};

class AES_state {
  U8 t[4][4];
};

U8 sbox[256] = {

    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b,
    0xfe, 0xd7, 0xab, 0x76, 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
    0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, 0xb7, 0xfd, 0x93, 0x26,
    0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2,
    0xeb, 0x27, 0xb2, 0x75, 0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
    0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84, 0x53, 0xd1, 0x00, 0xed,
    0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f,
    0x50, 0x3c, 0x9f, 0xa8, 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
    0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, 0xcd, 0x0c, 0x13, 0xec,
    0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14,
    0xde, 0x5e, 0x0b, 0xdb, 0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
    0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, 0xe7, 0xc8, 0x37, 0x6d,
    0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f,
    0x4b, 0xbd, 0x8b, 0x8a, 0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
    0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e, 0xe1, 0xf8, 0x98, 0x11,
    0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f,
    0xb0, 0x54, 0xbb, 0x16};

U8 rsbox[256] = {
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e,
    0x81, 0xf3, 0xd7, 0xfb, 0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87,
    0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb, 0x54, 0x7b, 0x94, 0x32,
    0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49,
    0x6d, 0x8b, 0xd1, 0x25, 0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16,
    0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92, 0x6c, 0x70, 0x48, 0x50,
    0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05,
    0xb8, 0xb3, 0x45, 0x06, 0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02,
    0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b, 0x3a, 0x91, 0x11, 0x41,
    0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8,
    0x1c, 0x75, 0xdf, 0x6e, 0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89,
    0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b, 0xfc, 0x56, 0x3e, 0x4b,
    0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59,
    0x27, 0x80, 0xec, 0x5f, 0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d,
    0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef, 0xa0, 0xe0, 0x3b, 0x4d,
    0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63,
    0x55, 0x21, 0x0c, 0x7d};

U8 Rcon[11] = {0x8d, 0x01, 0x02, 0x04, 0x08, 0x10,
               0x20, 0x40, 0x80, 0x1b, 0x36};

U0 KeyExpansion(U8 *RoundKey, U8 *Key) {
  U32 i, j, k;
  U8 tempa[4];

  for (i = 0; i < 8; ++i) {
    RoundKey[(i * 4) + 0] = Key[(i * 4) + 0];
    RoundKey[(i * 4) + 1] = Key[(i * 4) + 1];
    RoundKey[(i * 4) + 2] = Key[(i * 4) + 2];
    RoundKey[(i * 4) + 3] = Key[(i * 4) + 3];
  }

  for (i = 8; i < 4 * (14 + 1); ++i) {
    {
      k = (i - 1) * 4;
      tempa[0] = RoundKey[k + 0];
      tempa[1] = RoundKey[k + 1];
      tempa[2] = RoundKey[k + 2];
      tempa[3] = RoundKey[k + 3];
    }

    if (i % 8 == 0) {

      {
        U8 u8tmp = tempa[0];
        tempa[0] = tempa[1];
        tempa[1] = tempa[2];
        tempa[2] = tempa[3];
        tempa[3] = u8tmp;
      }

      {
        tempa[0] = (sbox[(tempa[0])]);
        tempa[1] = (sbox[(tempa[1])]);
        tempa[2] = (sbox[(tempa[2])]);
        tempa[3] = (sbox[(tempa[3])]);
      }

      tempa[0] = tempa[0] ^ Rcon[i / 8];
    }

    if (i % 8 == 4) {

      {
        tempa[0] = (sbox[(tempa[0])]);
        tempa[1] = (sbox[(tempa[1])]);
        tempa[2] = (sbox[(tempa[2])]);
        tempa[3] = (sbox[(tempa[3])]);
      }
    }

    j = i * 4;
    k = (i - 8) * 4;
    RoundKey[j + 0] = RoundKey[k + 0] ^ tempa[0];
    RoundKey[j + 1] = RoundKey[k + 1] ^ tempa[1];
    RoundKey[j + 2] = RoundKey[k + 2] ^ tempa[2];
    RoundKey[j + 3] = RoundKey[k + 3] ^ tempa[3];
  }
}

U0 AES_init_ctx(AES_ctx *ctx, U8 *key) { KeyExpansion(ctx->RoundKey, key); }

U0 AES_init_ctx_iv(AES_ctx *ctx, U8 *key, U8 *iv) {
  KeyExpansion(ctx->RoundKey, key);
  MemCpy(ctx->Iv, iv, 16);
}

U0 AES_ctx_set_iv(AES_ctx *ctx, U8 *iv) { MemCpy(ctx->Iv, iv, 16); }

U0 AddRoundKey(U8 round, AES_state *AES_state, U8 *RoundKey) {
  U8 i, j;
  for (i = 0; i < 4; ++i) {
    for (j = 0; j < 4; ++j) {
      AES_state->t[i][j] ^= RoundKey[(round * 4 * 4) + (i * 4) + j];
    }
  }
}

U0 SubBytes(AES_state *AES_state) {
  U8 i, j;
  for (i = 0; i < 4; ++i) {
    for (j = 0; j < 4; ++j) {
      AES_state->t[j][i] = (sbox[(AES_state->t[j][i])]);
    }
  }
}

U0 ShiftRows(AES_state *AES_state) {
  U8 temp;

  temp = AES_state->t[0][1];
  AES_state->t[0][1] = AES_state->t[1][1];
  AES_state->t[1][1] = AES_state->t[2][1];
  AES_state->t[2][1] = AES_state->t[3][1];
  AES_state->t[3][1] = temp;

  temp = AES_state->t[0][2];
  AES_state->t[0][2] = AES_state->t[2][2];
  AES_state->t[2][2] = temp;

  temp = AES_state->t[1][2];
  AES_state->t[1][2] = AES_state->t[3][2];
  AES_state->t[3][2] = temp;

  temp = AES_state->t[0][3];
  AES_state->t[0][3] = AES_state->t[3][3];
  AES_state->t[3][3] = AES_state->t[2][3];
  AES_state->t[2][3] = AES_state->t[1][3];
  AES_state->t[1][3] = temp;
}

U8 xtime(U8 x) { return ((x << 1) ^ (((x >> 7) & 1) * 0x1b)); }

U0 MixColumns(AES_state *AES_state) {
  U8 i;
  U8 Tmp, Tm, t;
  for (i = 0; i < 4; ++i) {
    t = AES_state->t[i][0];
    Tmp = AES_state->t[i][0] ^ AES_state->t[i][1] ^ AES_state->t[i][2] ^
          AES_state->t[i][3];
    Tm = AES_state->t[i][0] ^ AES_state->t[i][1];
    Tm = xtime(Tm);
    AES_state->t[i][0] ^= Tm ^ Tmp;
    Tm = AES_state->t[i][1] ^ AES_state->t[i][2];
    Tm = xtime(Tm);
    AES_state->t[i][1] ^= Tm ^ Tmp;
    Tm = AES_state->t[i][2] ^ AES_state->t[i][3];
    Tm = xtime(Tm);
    AES_state->t[i][2] ^= Tm ^ Tmp;
    Tm = AES_state->t[i][3] ^ t;
    Tm = xtime(Tm);
    AES_state->t[i][3] ^= Tm ^ Tmp;
  }
}

U0 InvMixColumns(AES_state *AES_state) {
  I32 i;
  U8 a, b, c, d;
  for (i = 0; i < 4; ++i) {
    a = AES_state->t[i][0];
    b = AES_state->t[i][1];
    c = AES_state->t[i][2];
    d = AES_state->t[i][3];

    AES_state->t[i][0] = (((0x0e & 1) * a) ^ ((0x0e >> 1 & 1) * xtime(a)) ^
                          ((0x0e >> 2 & 1) * xtime(xtime(a))) ^
                          ((0x0e >> 3 & 1) * xtime(xtime(xtime(a)))) ^
                          ((0x0e >> 4 & 1) * xtime(xtime(xtime(xtime(a)))))) ^
                         (((0x0b & 1) * b) ^ ((0x0b >> 1 & 1) * xtime(b)) ^
                          ((0x0b >> 2 & 1) * xtime(xtime(b))) ^
                          ((0x0b >> 3 & 1) * xtime(xtime(xtime(b)))) ^
                          ((0x0b >> 4 & 1) * xtime(xtime(xtime(xtime(b)))))) ^
                         (((0x0d & 1) * c) ^ ((0x0d >> 1 & 1) * xtime(c)) ^
                          ((0x0d >> 2 & 1) * xtime(xtime(c))) ^
                          ((0x0d >> 3 & 1) * xtime(xtime(xtime(c)))) ^
                          ((0x0d >> 4 & 1) * xtime(xtime(xtime(xtime(c)))))) ^
                         (((0x09 & 1) * d) ^ ((0x09 >> 1 & 1) * xtime(d)) ^
                          ((0x09 >> 2 & 1) * xtime(xtime(d))) ^
                          ((0x09 >> 3 & 1) * xtime(xtime(xtime(d)))) ^
                          ((0x09 >> 4 & 1) * xtime(xtime(xtime(xtime(d))))));
    AES_state->t[i][1] = (((0x09 & 1) * a) ^ ((0x09 >> 1 & 1) * xtime(a)) ^
                          ((0x09 >> 2 & 1) * xtime(xtime(a))) ^
                          ((0x09 >> 3 & 1) * xtime(xtime(xtime(a)))) ^
                          ((0x09 >> 4 & 1) * xtime(xtime(xtime(xtime(a)))))) ^
                         (((0x0e & 1) * b) ^ ((0x0e >> 1 & 1) * xtime(b)) ^
                          ((0x0e >> 2 & 1) * xtime(xtime(b))) ^
                          ((0x0e >> 3 & 1) * xtime(xtime(xtime(b)))) ^
                          ((0x0e >> 4 & 1) * xtime(xtime(xtime(xtime(b)))))) ^
                         (((0x0b & 1) * c) ^ ((0x0b >> 1 & 1) * xtime(c)) ^
                          ((0x0b >> 2 & 1) * xtime(xtime(c))) ^
                          ((0x0b >> 3 & 1) * xtime(xtime(xtime(c)))) ^
                          ((0x0b >> 4 & 1) * xtime(xtime(xtime(xtime(c)))))) ^
                         (((0x0d & 1) * d) ^ ((0x0d >> 1 & 1) * xtime(d)) ^
                          ((0x0d >> 2 & 1) * xtime(xtime(d))) ^
                          ((0x0d >> 3 & 1) * xtime(xtime(xtime(d)))) ^
                          ((0x0d >> 4 & 1) * xtime(xtime(xtime(xtime(d))))));
    AES_state->t[i][2] = (((0x0d & 1) * a) ^ ((0x0d >> 1 & 1) * xtime(a)) ^
                          ((0x0d >> 2 & 1) * xtime(xtime(a))) ^
                          ((0x0d >> 3 & 1) * xtime(xtime(xtime(a)))) ^
                          ((0x0d >> 4 & 1) * xtime(xtime(xtime(xtime(a)))))) ^
                         (((0x09 & 1) * b) ^ ((0x09 >> 1 & 1) * xtime(b)) ^
                          ((0x09 >> 2 & 1) * xtime(xtime(b))) ^
                          ((0x09 >> 3 & 1) * xtime(xtime(xtime(b)))) ^
                          ((0x09 >> 4 & 1) * xtime(xtime(xtime(xtime(b)))))) ^
                         (((0x0e & 1) * c) ^ ((0x0e >> 1 & 1) * xtime(c)) ^
                          ((0x0e >> 2 & 1) * xtime(xtime(c))) ^
                          ((0x0e >> 3 & 1) * xtime(xtime(xtime(c)))) ^
                          ((0x0e >> 4 & 1) * xtime(xtime(xtime(xtime(c)))))) ^
                         (((0x0b & 1) * d) ^ ((0x0b >> 1 & 1) * xtime(d)) ^
                          ((0x0b >> 2 & 1) * xtime(xtime(d))) ^
                          ((0x0b >> 3 & 1) * xtime(xtime(xtime(d)))) ^
                          ((0x0b >> 4 & 1) * xtime(xtime(xtime(xtime(d))))));
    AES_state->t[i][3] = (((0x0b & 1) * a) ^ ((0x0b >> 1 & 1) * xtime(a)) ^
                          ((0x0b >> 2 & 1) * xtime(xtime(a))) ^
                          ((0x0b >> 3 & 1) * xtime(xtime(xtime(a)))) ^
                          ((0x0b >> 4 & 1) * xtime(xtime(xtime(xtime(a)))))) ^
                         (((0x0d & 1) * b) ^ ((0x0d >> 1 & 1) * xtime(b)) ^
                          ((0x0d >> 2 & 1) * xtime(xtime(b))) ^
                          ((0x0d >> 3 & 1) * xtime(xtime(xtime(b)))) ^
                          ((0x0d >> 4 & 1) * xtime(xtime(xtime(xtime(b)))))) ^
                         (((0x09 & 1) * c) ^ ((0x09 >> 1 & 1) * xtime(c)) ^
                          ((0x09 >> 2 & 1) * xtime(xtime(c))) ^
                          ((0x09 >> 3 & 1) * xtime(xtime(xtime(c)))) ^
                          ((0x09 >> 4 & 1) * xtime(xtime(xtime(xtime(c)))))) ^
                         (((0x0e & 1) * d) ^ ((0x0e >> 1 & 1) * xtime(d)) ^
                          ((0x0e >> 2 & 1) * xtime(xtime(d))) ^
                          ((0x0e >> 3 & 1) * xtime(xtime(xtime(d)))) ^
                          ((0x0e >> 4 & 1) * xtime(xtime(xtime(xtime(d))))));
  }
}

U0 InvSubBytes(AES_state *AES_state) {
  U8 i, j;
  for (i = 0; i < 4; ++i) {
    for (j = 0; j < 4; ++j) {
      AES_state->t[j][i] = (rsbox[(AES_state->t[j][i])]);
    }
  }
}

U0 InvShiftRows(AES_state *AES_state) {
  U8 temp;

  temp = AES_state->t[3][1];
  AES_state->t[3][1] = AES_state->t[2][1];
  AES_state->t[2][1] = AES_state->t[1][1];
  AES_state->t[1][1] = AES_state->t[0][1];
  AES_state->t[0][1] = temp;

  temp = AES_state->t[0][2];
  AES_state->t[0][2] = AES_state->t[2][2];
  AES_state->t[2][2] = temp;

  temp = AES_state->t[1][2];
  AES_state->t[1][2] = AES_state->t[3][2];
  AES_state->t[3][2] = temp;

  temp = AES_state->t[0][3];
  AES_state->t[0][3] = AES_state->t[1][3];
  AES_state->t[1][3] = AES_state->t[2][3];
  AES_state->t[2][3] = AES_state->t[3][3];
  AES_state->t[3][3] = temp;
}

U0 Cipher(AES_state *AES_state, U8 *RoundKey) {
  U8 round = 0;

  AddRoundKey(0, AES_state, RoundKey);

  for (round = 1; round == round; ++round) {
    SubBytes(AES_state);
    ShiftRows(AES_state);
    if (round == 14) {
      break;
    }
    MixColumns(AES_state);
    AddRoundKey(round, AES_state, RoundKey);
  }

  AddRoundKey(14, AES_state, RoundKey);
}

U0 InvCipher(AES_state *AES_state, U8 *RoundKey) {
  U8 round = 0;

  AddRoundKey(14, AES_state, RoundKey);

  for (round = (14 - 1); round == round; --round) {
    InvShiftRows(AES_state);
    InvSubBytes(AES_state);
    AddRoundKey(round, AES_state, RoundKey);
    if (round == 0) {
      break;
    }
    InvMixColumns(AES_state);
  }
}

U0 XorWithIv(U8 *buf, U8 *Iv) {
  U8 i;
  for (i = 0; i < 16; ++i) {
    buf[i] ^= Iv[i];
  }
}

U0 AES_CBC_encrypt_buffer(AES_ctx *ctx, U8 *buf, I64 length) {
  I64 i;
  U8 *Iv = ctx->Iv;
  for (i = 0; i < length; i += 16) {
    XorWithIv(buf, Iv);
    Cipher(buf, ctx->RoundKey);
    Iv = buf;
    buf += 16;
  }

  MemCpy(ctx->Iv, Iv, 16);
}

U0 AES_CBC_decrypt_buffer(AES_ctx *ctx, U8 *buf, I64 length) {
  I64 i;
  U8 storeNextIv[16];
  for (i = 0; i < length; i += 16) {
    MemCpy(storeNextIv, buf, 16);
    InvCipher(buf, ctx->RoundKey);
    XorWithIv(buf, ctx->Iv);
    MemCpy(ctx->Iv, storeNextIv, 16);
    buf += 16;
  }
}

@enable_doldoc_output;

"aes256 ";
#define SHA1_HASH_SIZE 20

U0 __H1(U8 *x, I64 xlen, U8 *y, I64 ylen, U8 *out, I64 outlen) {
  no_warn outlen;
  I64 buflen = xlen + ylen;
  U8 *buf = CAlloc(buflen);
  MemCpy(buf, x, xlen);
  MemCpy(buf + xlen, y, ylen);
  calc_sha_1(out, buf, buflen * sizeof(U8));
  Free(buf);
}

I64 hmac_sha1(U8 *key, I64 keylen, U8 *data, I64 datalen, U8 *out, I64 outlen) {
  U8 k[64];
  U8 k_ipad[64];
  U8 k_opad[64];
  U8 ihash[SHA1_HASH_SIZE];
  U8 ohash[SHA1_HASH_SIZE];
  I64 sz;
  I64 i;

  MemSet(k, 0, 64);
  MemSet(k_ipad, 0x36, 64);
  MemSet(k_opad, 0x5c, 64);

  if (keylen > 64) {

    calc_sha_1(k, key, keylen);
  } else {
    MemCpy(k, key, keylen);
  }

  for (i = 0; i < 64; i++) {
    k_ipad[i] ^= k[i];
    k_opad[i] ^= k[i];
  }

  __H1(k_ipad, 64, data, datalen, ihash, SHA1_HASH_SIZE);
  __H1(k_opad, 64, ihash, SHA1_HASH_SIZE, ohash, SHA1_HASH_SIZE);

  if (outlen > SHA1_HASH_SIZE)
    sz = SHA1_HASH_SIZE;
  else
    sz = outlen;
  MemCpy(out, ohash, sz);
  return sz;
}
/*******************************************************************************
 * Teeny SHA-1
 *
 * The below @sha1_digest() calculates a SHA-1 hash value for a
 * specified data buffer and generates a hex representation of the
 * result.  This implementation is a re-forming of the SHA-1 code at
 * https://github.com/jinqiangshou/EncryptionLibrary.
 *
 * Copyright (c) 2017 CTrabant
 *
 * License: MIT, see included LICENSE file for details.
 *
 * To use the @sha1_digest() function either copy it into an existing
 * project source code file or include this file in a project and put
 * the declaration (example below) in the sources files where needed.
 ******************************************************************************/

/* Declaration:
extern int @sha1_digest(U8* digest, char *hexdigest, const U8* data, size_t
databytes);
*/

/*******************************************************************************
 * @sha1_digest: https://github.com/CTrabant/teeny-sha1
 *
 * Calculate the SHA-1 value for supplied data buffer and generate a
 * text representation in hexadecimal.
 *
 * Based on https://github.com/jinqiangshou/EncryptionLibrary, credit
 * goes to @jinqiangshou, all new bugs are mine.
 *
 * @input:
 *    data      -- data to be hashed
 *    databytes -- bytes in data buffer to be hashed
 *
 * @output:
 *    digest    -- the result, MUST be at least 20 bytes
 *    hexdigest -- the result in hex, MUST be at least 41 bytes
 *
 * At least one of the output buffers must be supplied.  The other, if not
 * desired, may be set to NULL.
 *
 * @return: 0 on success and non-zero on error.
 ******************************************************************************/
U32 SHA1ROTATELEFT(U32 value, U32 bits) {
  return (((value) << (bits)) | ((value) >> (32 - (bits))));
};

I64 @sha1_digest(U8 *digest, U8 *hexdigest, U8 *data, I64 databytes) {
  U32 W[80];
  U32 H[5];
  H[0] = 0x67452301;
  H[1] = 0xEFCDAB89;
  H[2] = 0x98BADCFE;
  H[3] = 0x10325476;
  H[4] = 0xC3D2E1F0;
  U32 a;
  U32 b;
  U32 c;
  U32 d;
  U32 e;
  U32 f = 0;
  U32 k = 0;

  U32 idx;
  U32 lidx;
  U32 widx;
  U32 didx = 0;

  I32 wcount;
  U32 temp;
  U64 databits = databytes * 8;
  U32 loopcount = (databytes + 8) / 64 + 1;
  U32 tailbytes = 64 * loopcount - databytes;
  U8 datatail[128];
  MemSet(&datatail, 0, 128);

  if (!digest && !hexdigest)
    return -1;

  if (!data)
    return -1;

  /* Pre-processing of data tail (includes padding to fill out 512-bit chunk):
     Add bit '1' to end of message (big-endian)
     Add 64-bit message length in bits at very end (big-endian) */
  datatail[0] = 0x80;
  datatail[tailbytes - 8] = (databits >> 56 & 0xFF);
  datatail[tailbytes - 7] = (databits >> 48 & 0xFF);
  datatail[tailbytes - 6] = (databits >> 40 & 0xFF);
  datatail[tailbytes - 5] = (databits >> 32 & 0xFF);
  datatail[tailbytes - 4] = (databits >> 24 & 0xFF);
  datatail[tailbytes - 3] = (databits >> 16 & 0xFF);
  datatail[tailbytes - 2] = (databits >> 8 & 0xFF);
  datatail[tailbytes - 1] = (databits >> 0 & 0xFF);

  /* Process each 512-bit chunk */
  for (lidx = 0; lidx < loopcount; lidx++) {
    /* Compute all elements in W */
    MemSetU32(&W, 0, 80);

    /* Break 512-bit chunk into sixteen 32-bit, big endian words */
    for (widx = 0; widx <= 15; widx++) {
      wcount = 24;

      /* Copy byte-per byte from specified buffer */
      while (didx < databytes && wcount >= 0) {
        W[widx] += ((data[didx]) << wcount);
        didx++;
        wcount -= 8;
      }
      /* Fill out W with padding as needed */
      while (wcount >= 0) {
        W[widx] += ((datatail[didx - databytes]) << wcount);
        didx++;
        wcount -= 8;
      }
    }

    /* Extend the sixteen 32-bit words into eighty 32-bit words, with potential
       optimization from: "Improving the Performance of the Secure Hash
       Algorithm (SHA-1)" by Max Locktyukhin */
    for (widx = 16; widx <= 31; widx++) {
      W[widx] = SHA1ROTATELEFT(
          (W[widx - 3] ^ W[widx - 8] ^ W[widx - 14] ^ W[widx - 16]), 1);
    }
    for (widx = 32; widx <= 79; widx++) {
      W[widx] = SHA1ROTATELEFT(
          (W[widx - 6] ^ W[widx - 16] ^ W[widx - 28] ^ W[widx - 32]), 2);
    }

    /* Main loop */
    a = H[0];
    b = H[1];
    c = H[2];
    d = H[3];
    e = H[4];

    for (idx = 0; idx <= 79; idx++) {
      if (idx <= 19) {
        f = (b & c) | ((~b) & d);
        k = 0x5A827999;
      } else if (idx >= 20 && idx <= 39) {
        f = b ^ c ^ d;
        k = 0x6ED9EBA1;
      } else if (idx >= 40 && idx <= 59) {
        f = (b & c) | (b & d) | (c & d);
        k = 0x8F1BBCDC;
      } else if (idx >= 60 && idx <= 79) {
        f = b ^ c ^ d;
        k = 0xCA62C1D6;
      }
      temp = SHA1ROTATELEFT(a, 5) + f + e + k + W[idx];
      e = d;
      d = c;
      c = SHA1ROTATELEFT(b, 30);
      b = a;
      a = temp;
    }

    H[0] += a;
    H[1] += b;
    H[2] += c;
    H[3] += d;
    H[4] += e;
  }

  /* Store binary digest in supplied buffer */
  if (digest) {
    for (idx = 0; idx < 5; idx++) {
      digest[idx * 4 + 0] = (H[idx] >> 24);
      digest[idx * 4 + 1] = (H[idx] >> 16);
      digest[idx * 4 + 2] = (H[idx] >> 8);
      digest[idx * 4 + 3] = (H[idx]);
    }
  }

  /* Store hex version of digest in supplied buffer */
  if (hexdigest) {
    StrPrint(hexdigest, "%08x%08x%08x%08x%08x", H[0], H[1], H[2], H[3], H[4]);
  }

  return 0;
} /* End of @sha1_digest() */

U8 *@sha1_hash_from_string(U8 *str) {
  U8 hexdigest[41];
  @sha1_digest(NULL, &hexdigest, str, StrLen(str));
  return StrNew(&hexdigest);
}

U8 *@sha1_hash_from_buffer(U8 *buf, I64 size) {
  U8 hexdigest[41];
  @sha1_digest(NULL, &hexdigest, buf, size);
  return StrNew(&hexdigest);
}

U0 calc_sha_1(U8 *out, U8 *buf, I64 size) {
  U8 digest[20];
  @sha1_digest(&digest, NULL, buf, size);
  MemCpy(out, &digest, 20);
}

class @sha1 {
  U8 *(*HashFromString)(U8 * str);
  U8 *(*HashFromBuffer)(U8 * buf, I64 size);
};

@sha1 SHA1;
SHA1.HashFromString = &@sha1_hash_from_string;
SHA1.HashFromBuffer = &@sha1_hash_from_buffer;

"sha1 ";
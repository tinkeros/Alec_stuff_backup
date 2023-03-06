#help_index "Graphics/PNG Files"

#define PNG_COLORS_NUM	16
#define ZLIB_CHUNK_SIZE 65535

class CFilePNG
{
  U32 signature[2];
  U32 ihdr_len;
  U32 ihdr_typ;
  U32 width;
  U32 height;
  U8 depth;
  U8 color_type;
  U8 compress;
  U8 filter;
  U8 interlace;
  U32 ihdr_crc;
  U32 plte_len;
  U32 plte_typ;
  U8 plte_tbl[PNG_COLORS_NUM*3];
  U32 plte_crc;
  U32 idat_len;
  U32 idat_typ;
  U0 data;
};

U0 AdlerByte32(U8 _byte, U32 _a, U32 _b, U32 *_ra, U32 *_rb)
{
  I64 MOD_ADLER=65521;
  U32 _ta,_tb;
  _ta = (_a + _byte) % MOD_ADLER;
  _tb = (_b + _a) % MOD_ADLER; 
  MemCpy(_ra, &_ta, 4);
  MemCpy(_rb, &_tb, 4);
}

U32 Crc32(I64 buf, I64 ofs, I64 len)
{
  U32 c;
  U32 crc = 0xFFFFFFFF;
  U32 crc_table[256];
  U8 *stream=buf+(ofs-buf);
  I64 i,k,n;
  n=0;
  while (n<256)
  {
    c=n;
    k=0;
    while (k<8)
    {
      if (c&1)
      {
        c = (c >> 1) ^ 0xEDB88320;
      }
      else
      {
        c = (c >> 1) ^ 0;
      };
      k++;
    };
    crc_table[n] = c;
    n++;
  };
  i=0;
  while (i<len)
  {
    crc = crc_table[(crc ^ stream[i]) & 0xFF] ^ (crc >> 8);
    i++;
  }
  return (crc^0xFFFFFFFF);
}

public I64 PNGWrite(U8 *filename,CDC *dc,I64 bits=4)
{//.
  I64 size=sizeof(CFilePNG)+((dc->width+1)*dc->height);
  bits=4;
  CFilePNG *png=CAlloc((dc->width*dc->height)*4);
  png->signature[0]=htonl(0x89504E47);
  png->signature[1]=htonl(0x0D0A1A0A);
  png->ihdr_len=htonl(13);
  png->ihdr_typ='IHDR';
  png->width=htonl(dc->width);
  png->height=htonl(dc->height);
  png->depth=8;
  png->color_type=3;
  png->compress=0;
  png->filter=0;
  png->interlace=0;
  png->ihdr_crc=htonl(Crc32(png,&png->ihdr_typ,ntohl(png->ihdr_len)+4));
  png->plte_len=htonl(48);
  png->plte_typ='PLTE';

  I64 dci=0;
  I64 pngi=0;
  while (dci<PNG_COLORS_NUM)
  {
    png->plte_tbl[pngi]=dc->palette[dci].r>>8;
    pngi++;
    png->plte_tbl[pngi]=dc->palette[dci].g>>8;
    pngi++;
    png->plte_tbl[pngi]=dc->palette[dci].b>>8;
    pngi++;
    dci++;
  };

  png->plte_crc=htonl(Crc32(png,&png->plte_typ,ntohl(png->plte_len)+4));

  I64 id_clen=0;

  png->idat_typ='IDAT';
  U8 *data=&png->data;
  I64 d_ctr=2;

  // zlib header
  data[0]=0x78;
  data[1]=0x01;

  I64 z_maxchk=(((dc->width+1)*dc->height))/ZLIB_CHUNK_SIZE;
  I64 z_curchk=0;
  I64 chk_pos;
  I64 chk_size;
  I64 px_pos=0;
  I64 scan;
  U32 *chk_a32;
  U32 _a, _b;

  scan=-1;

  while (z_curchk<z_maxchk+1)
  {
    chk_size=ZLIB_CHUNK_SIZE;
    data[d_ctr+0]=0x0;
    if(z_curchk==(z_maxchk))
    {
      // last chunk.
      data[d_ctr+0]=0x1;
      chk_size=(((dc->width+1)*dc->height))%ZLIB_CHUNK_SIZE;
    };

    // chunk size
    data[d_ctr+1]=chk_size & 0xFF;
    data[d_ctr+2]=chk_size >> 8;
    data[d_ctr+3]=(ZLIB_CHUNK_SIZE-chk_size) & 0xFF;
    data[d_ctr+4]=(ZLIB_CHUNK_SIZE-chk_size) >> 8;

    chk_pos=0;
    while(chk_pos<(chk_size))
    {
      if (scan==-1)
      {
        data[d_ctr+5+chk_pos]=0;
      }
      else
      {
        data[d_ctr+5+chk_pos]=dc->body[px_pos];
        px_pos++;
      };
      AdlerByte32(data[d_ctr+5+chk_pos], _a, _b, &_a, &_b);
      chk_pos++;
      scan++;
      if(scan==dc->width)
      {
        scan=-1;
      };
    };    

    z_curchk++;
    d_ctr += 5+chk_pos;
  };

  chk_a32=(data+d_ctr);
  chk_a32[0]=htonl((_b << 16) | _a);

  id_clen = d_ctr+4;
  png->idat_len=htonl(id_clen);
  chk_a32[1]=htonl(Crc32(png,&png->idat_typ,ntohl(png->idat_len)+4));
  chk_a32[2]=0;
  chk_a32[3]='IEND';
  chk_a32[4]=htonl(0xAE426082);
  FileWrite(filename,png,size);
  Free(png);
  return size;
}

#help_index "Graphics/PNG Files;Graphics/Scrn"
public I64 PNGScrnCapture(U8 *filename,I64 bits=4,Bool include_zoom=TRUE)
{//Capture scrn as PNG file.
  I64 size=0;
  CDC *dc=DCScrnCapture(include_zoom);
  size=PNGWrite(filename,dc,bits);
  DCDel(dc);
  return size;
}

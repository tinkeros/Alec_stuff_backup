U8 *gop_fb;

U0 UEFIGopBlt(U8 *addr) {
  I64 *p = 0x3030;
  CallUEFI(*p, addr);
  p = NULL;
}

text.raw_col=0;

U0 UEFIGopRawPutChar(U8 ch, U8 *gop_fb)
{
  U8 *r= sys_font_std;
  I64 col=0;
  I64 cx=0;
  I64 cy=0;
  if (ch==13 || ch==10 || ch==0xC0) 
  {
    while (text.raw_col % 80 != 0)
    {
      text.raw_col++;
    };
    if (text.raw_col>4800)
    {
      text.raw_col=0;
    };
  }
  else
  {
    while (cy<8)
    {
      cx=0;
      while (cx<8)
      {
        col=0;
        if (r[(ch*8)+cy]>>cx&1==1)
        {
          col=255;         
        }
        MemSet(gop_fb+(((text.raw_col/80)*20480)+((text.raw_col%80)*32)+(cy*2560)+(cx*4)), col, 4);
        cx++;        
      };
      cy++;
    };
    text.raw_col++;
    if (text.raw_col>4800)
    {
      text.raw_col=0;
    };
  };
}

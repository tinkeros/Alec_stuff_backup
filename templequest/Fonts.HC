// Fonts

class GameFont
{
  CDC *bitmap;
  CDC *bitmapc;
  U8 chars[0x7F];
  I64 col_max;
  I64 row_max;
  I64 col_ofs;
  I64 row_ofs;
  I64 spacing;
};

GameFont *LoadFont(U8 *gr_file,I64 row_max,I64 col_max,I64 col_ofs,I64 row_ofs,I64 spacing,U8 *chars)
{
  GameFont *NewFont=CAlloc(sizeof(GameFont));
  NewFont->bitmap=GRRead(gr_file);
  NewFont->bitmapc=DCNew(col_ofs,row_ofs);
  StrCpy(NewFont->chars,chars);
  NewFont->col_max=col_max;
  NewFont->row_max=row_max;
  NewFont->col_ofs=col_ofs;
  NewFont->row_ofs=row_ofs;
  NewFont->spacing=spacing;
  return NewFont;
}

U0 FreeFont(GameFont *font)
{
  DCDel(font->bitmapc);
  DCDel(font->bitmap);
  Free(font);
}

U0 FontText(CDC *dc,GameFont *font,U8 *txt,I64 x,I64 y,I64 color=BLACK,I64 bgcolor=WHITE)
{
  I64 ctr=0;
  I64 pos=0;
  I64 pos_c=0;
  I64 pos_r=0;
  I64 pb=0;
  I64 px=0;
  I64 py=0;
  I64 t_len=StrLen(txt);
  
  while (ctr<t_len)
  {
    pb=0;
    while (pb<0x7F)
    {
      if(font->chars[pb]==txt[ctr])
      {
        pos=pb;
        break;
      }
      pb++;
    };
    DCFill(font->bitmapc,TRANSPARENT);
    pos_r=pos/font->row_max;
    pos_c=pos-(pos_r*font->row_max);

    px=-1-pos_c-(pos_c*font->col_ofs);
    py=-1-pos_r-(pos_r*font->row_ofs);

    //"x:%d,y%d",px,py;
    GrBlot(font->bitmapc,px,py,font->bitmap);
    DCColorChg(font->bitmapc,WHITE,0x40);
    DCColorChg(font->bitmapc,0,color);
    DCColorChg(font->bitmapc,0x40,bgcolor);
    GrBlot(dc,x,y,font->bitmapc);
    x+=(font->spacing);
    ctr++;
  }
}


CDC *s_Objects=GRRead("Chars/Objects.CHAR.GR");
CDC *s_Targets=GRRead("Chars/Targets.CHAR.GR");
CDC *s_Terry=GRRead("Chars/Terry.CHAR.GR");
CDC *th_Dianna=GRRead("Chars/DiannaT.CHAR.GR");

U0 FreeChars()
{
  DCDel(th_Dianna);
  DCDel(s_Terry);
  DCDel(s_Targets);
  DCDel(s_Objects);
}

U0 SceneObjBlot(CDC *dc, I64 dc_x, I64 dc_y, I64 gr48_x, I64 gr48_y)
{
  CDC *GR48=DCNew(48,48);
  DCFill(GR48, TRANSPARENT);
  GrBlot(GR48, -(gr48_x*48), -(gr48_y*48), s_Objects);
  GrBlot(dc, dc_x, dc_y, GR48);
  DCDel(GR48);
}

U0 GR96Blot(CDC *dc, I64 dc_x, I64 dc_y, 
               CDC *GR, I64 gr96_x, I64 gr96_y, Bool r)
{
  CDC *GR96=DCNew(96,96);
  DCFill(GR96, TRANSPARENT);
  GrBlot(GR96, -(gr96_x*96), -(gr96_y*96), GR);
  switch(r)
  {
    case TRUE:
      CSprite *s=DC2Sprite(GR96);
      Sprite3YB(dc, 72+dc_x, dc_y, 0, s, 179);
      Free(s);
      break;
    case FALSE:
      GrBlot(dc, dc_x, dc_y, GR96);
      break;
  };
  DCDel(GR96);
}  
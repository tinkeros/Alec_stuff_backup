U0 PCSP()
{
  I64 PCM_LEN=0;
  I64 PCM_POS=0; 

  Cd(__DIR__);;
  CDirEntry *de = FilesFind("./Demo.SND.Z");
  U8 *PCM_TABLE = FileRead(de->full_name);
  PCM_LEN=0x785ED;
  I64 hpet_s;
  I64 period;
  I64 sample_rate=16000;
  while (TRUE) {
    while (PCM_POS < PCM_LEN)
    {
      period=ClampI64(PCM_TABLE[PCM_POS]/2+16,1,U16_MAX);
      OutU8(0x43,0xB6);
      OutU8(0x42,period);
      OutU8(0x42,period.u8[1]); 
      OutU8(0x61,3|InU8(0x61));
      PCM_POS++;
      hpet_s=HPET;
      while (HPET<hpet_s+(sample_rate/32)) {Yield; };  
    };
  PCM_POS=0;
  }; 
};

U0 Demo()
{  
  Cd(__DIR__);;
  SettingsPush;
  AutoComplete;
  WinMax;
  ms.pos.x=-999;
  CTask *snd_task = Spawn(&PCSP,,,2);
  CDC *_bgr=DCNew(640,480);
  CDC *_screen=DCAlias();
  CDC *_text=GRRead("Text.GR.Z");
  CDirEntry *de = FilesFind("./DemoBgr/*.GR.Z");
  I64 d_ptr=de;
  I64 f_ctr;

  I64 p_x=0;
  I64 p_y=0;
  I64 p_c=0;

  I64 t_cx[2048];
  I64 t_cy[2048];
  I64 t_x[2048];
  I64 t_y[2048];
  F64 t_z[2048];


  U8 mtx[60];
  U8 msg[2048];
  U8 msg_spc[32];
  StrCpy(msg_spc, "                          ");
  StrCpy(mtx, "  '    .()  , - 0123456789:;   ? ABCDEFGHIJKLMNOPQRSTUVWXYZ ");
  StrCpy(msg, "");
  StrCpy(msg+StrLen(msg), "INTRODUCING:     TEMPLEOS V5.03");
  StrCpy(msg+StrLen(msg), msg_spc);
  StrCpy(msg+StrLen(msg), "DEMO BY: T.SHEIKHS   03-18-2017");
  StrCpy(msg+StrLen(msg), msg_spc);
  StrCpy(msg+StrLen(msg), "GREETZ:  -TOSG-, TEMPLEOS IRC, MINEXEW, JOEY CROWBRO, COMPSCI GUY, BURT SAMPSON, JAMES BROPHY, FYS, TYREREXUS, AND THE REST OF THE TAD LIVE CHAT CREW");
  StrCpy(msg+StrLen(msg), msg_spc);
  StrCpy(msg+StrLen(msg), "SPECIAL THANKS TO:   TERRY A. DAVIS");
  StrCpy(msg+StrLen(msg), msg_spc);
  StrCpy(msg+StrLen(msg), "PSALM 20:7  -  SOME TRUST IN CHARIOTS AND SOME IN HORSES, BUT WE TRUST IN THE NAME OF THE LORD OUR GOD.");
  StrCpy(msg+StrLen(msg), msg_spc);
  StrCpy(msg+StrLen(msg), "THANKS FOR WATCHING   :-)   ");
  StrCpy(msg+StrLen(msg), msg_spc);

  I64 ctr=0;
  while (ctr<StrLen(msg)) {
    t_cx[ctr]=0;
    t_cy[ctr]=0;
    t_x[ctr]=0;
    t_y[ctr]=0;
    t_z[ctr]=0;
    ctr++;
  };

  ctr=0; 
  while (ctr<StrLen(msg))
  {
    p_x=0;
    p_y=0;
    p_c=0;
    while (p_c<StrLen(mtx)) {
      if (mtx[p_c]==msg[ctr])
      {
        t_cx[ctr] = p_x;
        t_cy[ctr] = p_y;
      };
      p_x++;
      if (p_x>9) { p_x=0; p_y++; };
      p_c++;
    };
    ctr++;
  };  

  f_ctr=0;

  while (!ScanKey)
  {
    _bgr = GRRead(de->full_name);
    GrBlot(_screen,0,0,_bgr);
    DCDel(_bgr);
    f_ctr++;
    if (f_ctr>4) {
      if (de->next!=0) { de=de->next; } else { de=d_ptr; };
      f_ctr=0;
    };
    
    ctr=0;
    while (ctr<StrLen(msg)) {
      if (t_x[ctr]>-32)
      {
        CDC *_tchr = DCExt(_text,0+(32*t_cx[ctr]),0+(32*t_cy[ctr]),31+(32*t_cx[ctr]),31+(32*t_cy[ctr]));
        CSprite *_schr = DC2Sprite(_tchr);
        if (t_y[ctr]==0) { t_y[ctr]=280; t_x[ctr]=672+(32*ctr); };
        if (t_x[ctr]>-32 && t_x[ctr]<640)
        {
          Sprite3ZB(_screen,t_x[ctr],t_y[ctr],0,_schr,t_z[ctr]);
        };
        t_x[ctr] -= 1;
        t_y[ctr] = 240 + (Sin(t_x[ctr]*.7 / 45) * 32);
        Free(_schr);
        DCDel(_tchr);
      };
      ctr++;
    };
    Sleep(0);
    if (t_x[StrLen(msg)-1]<-31)
    {
      ctr=0;
      while (ctr<StrLen(msg)) {
        t_x[ctr]=0;
        t_y[ctr]=0;
        t_z[ctr]=0;
        ctr++;
      };
    };
  };

  Kill(snd_task);
  SndRst;
  DCFill;
  DirEntryDel(de);
  DCDel(_text);
  DCDel(_screen);
  SettingsPop;
}

Demo;

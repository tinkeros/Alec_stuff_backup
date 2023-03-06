#include "::/Apps/TempleTerm/Bookmarks"
#include "::/Apps/TempleTerm/ZModem"

#define PROMPT_Q 0xFFFF
#define REMOTE_Q 0xFFFE

I64 in_rz=0;
I64 abort_rz=0;

#define TT_CFG_FILE "Bookmarks.DATA.Z"
#define TT_CFG_PATH "::/Home/TempleTerm"

CDC *tt_buf;
I64 tt_cur_x=0;
I64 tt_cur_y=0;
I64 tt_cur_bg=BLACK;
I64 tt_cur_fg=WHITE;
I64 tt_cur_int=0;
I64 tt_sr_y1=0;
I64 tt_sr_y2=23;

I64 res=0;

I64 rzh_seq[4] = { ZPAD,ZPAD,ZDLE,ZHEX };
I64 rzb_seq[3] = { ZPAD,ZDLE,ZBIN };

U8 *rz_ibuf;
U8 *rz_fbuf;
U8 *rz_filename;
U8 *rz_shortfn;

I64 rz_xctr=0;

I64 rz_bufpos=0;
I64 rzp_type=0;

I64 rzh_state=0;
I64 rzb_state=0;

U8 zmr_abort[5] = { ZDLE,ZDLE,ZDLE,ZDLE,ZDLE };

I64 isArrow()
{
  I64 i=kbd.scan_code & 0xFF;
  if (i==72) { return 1; };
  if (i==75) { return 1; };
  if (i==80) { return 1; };
  if (i==77) { return 1; };
  if (i==SC_F12) { return 1; };
  return 0;
}

I64 GetChar2(I64 *_scan_code=NULL,Bool echo=TRUE,Bool raw_cursor=FALSE)
{//Waits for non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key or arrow key.
//Sets $LK,"scan_code",A="FI:::/Doc/CharOverview.DD"$.
  I64 ch1;
  do ch1=GetKey(_scan_code,FALSE,raw_cursor);
  while (!ch1 && !isArrow);
  if (echo)
    "$$PT$$%c$$FG$$",ch1;
  if (isArrow) { return 0; };
  return ch1;
}

U0 TDrawIt(CTask *,CDC *dc)
{
  if (!Blink)
  {
    tt_buf->color=YELLOW;
  }
    else
  {
    tt_buf->color=tt_cur_bg;
  };

  GrRect(tt_buf,tt_cur_x*8,tt_cur_y*8,8,8);        
  GrBlot(dc,0,0,tt_buf); 
}

U0 TempleTermSession(I64 sock)
{
  CDC *tt_buf2=DCNew(640,480);
  rz_ibuf=CAlloc(2048);
  rz_filename=CAlloc(1024);
  rz_shortfn=CAlloc(1024);

  RegExe("WalnutLabs/TempleTerm");

  I64 DETECT_ZDLE=0;
  I64 IN_ZDLE=0;

  I64 rz_ibpos=0;
  I64 rz_dfmax=0;

  I64 rz_filesize=0;
  I64 rz_remainfiles=0;
  I64 rz_fileleft=0;
  I64 rz_totalleft=0;
  I64 rz_filetime=0;
  I64 rz_filemode=0;
  I64 rz_pktctr=0;
  I64 rz_serial=0;

  U32 crc=0;
  U32 crc_len=0;
  I64 seq_type=0;

  DCFill(tt_buf,tt_cur_bg);
  tt_buf->color=tt_cur_fg;

  I64 rv;

  I64 ansi_pos=0;  
  I64 rx_size=1024;
  I64 i=0;
  I64 in_esc=0;
  I64 sp_x=0;
  I64 sp_y=0;
  I64 sp_bg=0;
  I64 sp_fg=0;


  I64 j,k,l;
  I64 bold;

  U32 rz_dpos;
  U32 rz_opos;

  U8 *rx_buf=CAlloc(1024);
  U8 *ad_seq=CAlloc(6);
  U8 *sr_buf=CAlloc(32);
  CDC *sr_dc;
  U8 cpos_buf[64];
  U8 ansi_buf[64];
  U8 rx_u8[2]; 

  i=0;
  while(i<64) { cpos_buf[i]=0; ansi_buf[i]=0; i++; };

  rx_u8[1]=0;

  StrPrint(ad_seq+1,"[?6c");
  ad_seq[0]=27;

  bold=0;

  U8 ich[2];
  ich[1]=0;

  I64 got, pos;
  while (TRUE)
  {
    GrRect(tt_buf,tt_cur_x*8,tt_cur_y*8,8,8);        
    tt_buf->color=tt_cur_fg;

    got = recv(sock, rx_buf, rx_size, 0);

    if (!got) { break; };

    if (got>0)
    {
      pos=0;

      while (pos<got)
      {

      // Quick and dirty way to eat XON? yummm
        if (IN_ZDLE==3)
        {
          IN_ZDLE--;
        };
        if (in_rz>0){
          if (rx_buf[pos]==XON)
          {
            IN_ZDLE=3;
          };
        };

      if (IN_ZDLE==1)
      {
        rx_buf[pos] ^= 0x40;
        IN_ZDLE++;
      };

      if (DETECT_ZDLE==1 && IN_ZDLE<1)
      {
        if (rx_buf[pos]==ZDLE) { IN_ZDLE++; };
      };
    
      if (IN_ZDLE==2)
      {
        IN_ZDLE=0;
      };

      if (IN_ZDLE<1)
      {

        if(pos==0)
        {
          // Erase the graphical cursor 
          tt_buf->color=tt_cur_bg;
          GrRect(tt_buf,tt_cur_x*8,tt_cur_y*8,8,8);        
          tt_buf->color=tt_cur_fg;
        };

        if (abort_rz==1)
        {
          send(sock, zmr_abort, 5, 0);
          ProgressBarsRst;
          Snd(42);Sleep(100);Snd(32);Sleep(100);SndRst;
          in_rz=0;
          DETECT_ZDLE=0;
          IN_ZDLE=0;                
          abort_rz=0;
        };

        if (in_rz==20)
        {
          // EOF
          progress1=rz_dpos;
          StrPrint(progress1_desc, "Saving File: %s", rz_shortfn);
          FileWrite(rz_filename, rz_fbuf, rz_filesize);
          rz_remainfiles--;
          Free(rz_fbuf);
          Snd(62);Sleep(50);Snd(74);Sleep(50);SndRst;
          ProgressBarsRst;
          sendHexHeader(sock, ZRINIT, 0, 0, 0, (CANFDX|CANOVIO) );
          in_rz=2;
          rzb_state=0;
        };


        if (in_rz==7)
        {

            progress2_max=0;
            progress3_max=0;
            progress4_max=0;

            // ZDATA, cont...:

            if (rz_ibpos==0)
            {
              // Get ZDLE sequence
              seq_type = rx_buf[pos]^0x40;

              // Calculate CRC16
              crc = getCRC16(rz_ibuf, crc_len);
              crc = crc16Update(crc, seq_type);

            };

            if (rz_ibpos==1)
            {
              if (rx_buf[pos]!=((crc >> 8) & 0xFF))
              {
                  rz_dpos = rz_opos;
                  sendHexHeader(sock, ZRPOS, rz_dpos.u8[0], rz_dpos.u8[1], rz_dpos.u8[2], rz_dpos.u8[3]);
                  in_rz=2;
                  rzb_state=0;
                  rz_bufpos=0;
                  rz_ibpos=0;
                  break;
                  //AdamLog("Pkt %d: \dRED\dBad CRC\dBLUE\d   MSB %02X Got: %02X\n", rz_pktctr,((crc >> 8) & 0xFF),rx_buf[pos]);
              }           
              else
              {
              };           
            };

            if (rz_ibpos==2)
            {
              if (rx_buf[pos]!=(crc & 0xFF))
              {
                  rz_dpos = rz_opos;
                  sendHexHeader(sock, ZRPOS, rz_dpos.u8[0], rz_dpos.u8[1], rz_dpos.u8[2], rz_dpos.u8[3]);
                  in_rz=2;
                  rzb_state=0;
                  rz_bufpos=0;
                  rz_ibpos=0;
                  break;
                  //AdamLog("Pkt %d: \dRED\dBad CRC\dBLUE\d   MSB %02X Got: %02X\n", rz_pktctr,((crc >> 8) & 0xFF),rx_buf[pos]);
              }           
              else
              {
              };           

              // If ZCRCQ or ZCRCW, need to ack. 
              if (seq_type==ZCRCQ || seq_type==ZCRCW)
              {
                sendHexHeader(sock, ZACK, rz_dpos.u8[0], rz_dpos.u8[1], rz_dpos.u8[2], rz_dpos.u8[3]);
                in_rz=2;
                rzb_state=0;
                break;
              };

            };

            if (rz_ibpos==3)
            {
              progress1=rz_dpos;
              StrPrint(progress1_desc, "ZMODEM RX: %s [%d/%d] (%d files remaining)", rz_shortfn, rz_dpos, rz_filesize, rz_remainfiles-1);
            };

            // get length of subpacket       
            if (rz_fileleft<1024)
            {
              rz_dfmax=rz_fileleft; 
            }
            else
            {
              rz_dfmax=1024;
            };

            // copy bytestream to tha buffah
            if (rz_ibpos>2) {
              rz_ibuf[rz_bufpos] = rx_buf[pos];
              if (rz_bufpos<(rz_dfmax))
              {
                rz_bufpos++;
              };
            };

            rz_ibpos++;
  
            if (rz_ibpos==rz_dfmax+3)
            {
              rz_fileleft -= rz_dfmax;

              MemCpy(rz_fbuf+rz_dpos, rz_ibuf, rz_dfmax);

              rz_opos = rz_dpos;
              rz_dpos += rz_dfmax;

              if (rz_fileleft<=0)
              {
                in_rz=2;
              }
              else
              {
                crc_len=rz_dfmax;
                rz_ibpos=0;
                rz_bufpos=0;
                rz_pktctr++;
              };

            };
 
        };

        if (in_rz==6)
        {

            progress2_max=0;
            progress3_max=0;
            progress4_max=0;

            // ZDATA, begin:

            // get length of subpacket              
            if (rz_fileleft<1024)
            {
              rz_dfmax=rz_fileleft; 
            }
            else
            {
              rz_dfmax=1024;
            };

            // copy bytestream to tha buffah
            if (rz_ibpos>5) {
              rz_ibuf[rz_bufpos] = rx_buf[pos];
              if (rz_bufpos<(rz_dfmax))
              {
                rz_bufpos++;
              };

            };

            rz_ibpos++;
  
            if (rz_ibpos==rz_dfmax+6)
            {
              rz_fileleft -= rz_dfmax;

              MemCpy(rz_fbuf+rz_dpos, rz_ibuf,rz_dfmax);

              rz_opos = rz_dpos;
              rz_dpos += rz_dfmax;

              if (rz_fileleft<=0)
              {
                in_rz=2;
              }
              else
              {
                crc_len=rz_dfmax;
                rz_ibpos=0;
                rz_bufpos=0;
                rz_pktctr++;
                in_rz++;
              };

            };
 
        };

        if (in_rz==5)
        {
          // FILEINFO: get fileinfo 
          if (rx_buf[pos] == 32)
          {
            rz_ibuf[rz_ibpos]=0;
          }
          else
          {
            rz_ibuf[rz_ibpos]=rx_buf[pos];
          };

          if (rx_buf[pos] == 0)
          {
            rz_filesize     = Str2I64(rz_ibuf);
            rz_ibpos        = StrLen(rz_ibuf)+1;
            rz_filetime     = Str2I64(rz_ibuf+rz_ibpos);
            rz_ibpos       += StrLen(rz_ibuf+rz_ibpos) + 1;
            rz_filemode     = Str2I64(rz_ibuf+rz_ibpos);
            rz_ibpos       += StrLen(rz_ibuf+rz_ibpos) + 1;
            rz_serial       = Str2I64(rz_ibuf+rz_ibpos);
            rz_ibpos       += StrLen(rz_ibuf+rz_ibpos) + 1;
            // SEXYZ isn't decrementing this..?
            if (rz_remainfiles<1)
            {
              rz_remainfiles  = Str2I64(rz_ibuf+rz_ibpos);
            };
            rz_ibpos       += StrLen(rz_ibuf+rz_ibpos) + 1;
            rz_totalleft     = Str2I64(rz_ibuf+rz_ibpos);
            rz_ibpos       += StrLen(rz_ibuf+rz_ibpos) + 1;
          
            rz_fileleft = rz_filesize;

            // allocate buffer, set pos to 0, and start receiving...
            rz_fbuf=CAlloc(rz_filesize);
            ProgressBarsRst;
            progress1=0;
            progress1_max=rz_filesize;
            progress2_max=0;
            progress3_max=0;
            progress4_max=0;
            progress1_t0=0;
            progress1_tf=0;
            rz_pktctr=0;
            rz_dpos=0;
            rz_opos=0;
            StrPrint(progress1_desc, "ZMODEM RX: %s [%d/%d] (%d files remaining)", rz_shortfn, rz_dpos, rz_filesize, rz_remainfiles-1);
            sendHexHeader(sock, ZRPOS, rz_dpos.u8[0], rz_dpos.u8[1], rz_dpos.u8[2], rz_dpos.u8[3]);
            in_rz=2;
            rzb_state=0;
            rz_ibpos=-1;
          };
          rz_ibpos++;
        };
       
        if (in_rz==4)
        {
          // FILEINFO: get filename
          if (rx_buf[pos] == 0 && rz_ibpos>5)
          {
            rz_ibuf[rz_ibpos-6]=0;
            StrPrint(rz_shortfn, rz_ibuf);
            StrPrint(rz_filename, "::/Home/TempleTerm/Downloads/%s",rz_ibuf);
            in_rz++;
            rz_ibpos=-1;           
          }; 

          if (rz_ibpos>5)
          {
            if (rx_buf[pos]=='/')
            {
              rz_ibuf[rz_ibpos-6]='.';
            }
            else
            {
              rz_ibuf[rz_ibpos-6]=rx_buf[pos];
            };
          };

          rz_ibpos++;
        };

        if (in_rz==3)
        {
          // Process packet

          if (rzp_type==ZHEX)
          {
            switch(rx_buf[pos])
            {
              case 0x30:
                // wait next pass...
                break;

              case 0x30 + ZFIN:
                sendHexHeader(sock, ZFIN);
                if (rz_remainfiles!=0)
                {
                  rz_remainfiles=0;
                };
                in_rz=0;
                DETECT_ZDLE=0;
                IN_ZDLE=0;                     
                break;
               
              // SEXYZ?! you slag 
              case 'b': // ZEOF?
                rz_ibpos=0; 
                rzb_state=0;

                if (rz_fileleft<=0)
                {
                  in_rz=20;
                }
                else
                {
                  in_rz=2;
                };
                break;

              default:
                AdamLog("\n%02X",rx_buf[pos]);
                PopUpOk("ERROR: Unknown HEX type, aborting...");
                progress1=0;progress1_max=0;
                send(sock, zmr_abort, 5, 0);
                in_rz=0;                
                DETECT_ZDLE=0;
                IN_ZDLE=0;               
                break;
            };

          }

          if (rzp_type==ZBIN)
          {
            DETECT_ZDLE=1;
            switch(rx_buf[pos])
            {

              case ZFILE:
                StrPrint(rz_ibuf,"");
                rz_ibpos=0;
                in_rz++;
                break;

              case ZDATA:
                rz_ibpos=0;
                rz_bufpos=0;
                in_rz=6;
                break;

              case ZEOF:
                rz_ibpos=0; 
                rzb_state=0;

                if (rz_fileleft<=0)
                {
                  in_rz=20;
                }
                else
                {
                  in_rz=2;
                };
                break;

              default:
                AdamLog("\n%02X",rx_buf[pos]);
                PopUpOk("ERROR: Unknown BIN type, aborting...");
                progress1=0;progress1_max=0;
                send(sock, zmr_abort, 5, 0);
                in_rz=0;                
                DETECT_ZDLE=0;
                IN_ZDLE=0;               
                break;

            };
            
          };
        };

        if (in_rz==2)
        {
          DETECT_ZDLE=0;
          IN_ZDLE=0;
          // Hang around and wait for a packet...
        };

        if (in_rz==1)
        {
          // ZModem Receive detect: Got ZRQINIT, send ZRINIT
          sendHexHeader(sock, ZRINIT, 0, 0, 0, (CANFDX|CANOVIO) );
          in_rz=2;
          rzb_state=0;
        };

        if (in_esc==2)
        {
          ansi_buf[ansi_pos]=0;          
          // process ANSI sequence
          switch(ansi_buf[ansi_pos-1])
          {

            // detect ansi
            case 'n':
              if (StrFind("[6n",ansi_buf))
              {
                cpos_buf[0]=27;
                StrPrint(cpos_buf+1, "[%d;%dR",tt_cur_y,tt_cur_x);
                //send(sock,cpos_buf,StrLen(cpos_buf),0);
                sendString(sock, cpos_buf, 0);
              };
              break;
            
            case 'c':
            case 'Z':
              send(sock,ad_seq,5,0);
              break;

            case 'r':
              StrPrint(sr_buf, ansi_buf);
              StrFirstOcc(sr_buf,"r")[0]=0;
              tt_sr_y2=Str2I64(StrFirstOcc(sr_buf,";")+1);
              StrFirstOcc(sr_buf,";")[0]=0;
              tt_sr_y1=Str2I64(sr_buf+1);               
              break;

            case 'S':
              StrPrint(sr_buf, ansi_buf);
              StrFirstOcc(sr_buf,"S")[0]=0;
              sr_dc=DCNew(640,(tt_sr_y2*8)-(tt_sr_y1*8));
              GrBlot(sr_dc,0,-((tt_sr_y1+Str2I64(sr_buf+1))*8),tt_buf);
              GrBlot(tt_buf,0,(tt_sr_y1*8),sr_dc);
              DCDel(sr_dc);
              break;

            case 'T':
              StrPrint(sr_buf, ansi_buf);
              StrFirstOcc(sr_buf,"S")[0]=0;
              sr_dc=DCNew(640,(tt_sr_y2*8)-(tt_sr_y1*8));
              GrBlot(sr_dc,0,-((tt_sr_y1-Str2I64(sr_buf+1))*8),tt_buf);
              GrBlot(tt_buf,0,(tt_sr_y1*8),sr_dc);
              DCDel(sr_dc);
              break;

            case 'm':           

              if (StrFind(";7m",ansi_buf)) 
                { tt_cur_fg=rv; tt_cur_fg=tt_cur_bg; tt_cur_bg=rv; 
                  if (tt_cur_bg>7) { tt_cur_bg-=8; };
                };
              if (StrFind("[7m",ansi_buf)) 
                { tt_cur_fg=rv; tt_cur_fg=tt_cur_bg; tt_cur_bg=rv;
                  if (tt_cur_bg>7) { tt_cur_bg-=8; };
                };
              if (StrFind("[7;",ansi_buf)) 
                { tt_cur_fg=rv; tt_cur_fg=tt_cur_bg; tt_cur_bg=rv;
                  if (tt_cur_bg>7) { tt_cur_bg-=8; };
                };
              if (StrFind(";7;",ansi_buf)) 
                { tt_cur_fg=rv; tt_cur_fg=tt_cur_bg; tt_cur_bg=rv;
                  if (tt_cur_bg>7) { tt_cur_bg-=8; };
                };

              if (StrFind(";1m",ansi_buf)) { bold=8; };
              if (StrFind("[1m",ansi_buf)) { bold=8; };
              if (StrFind("[1;",ansi_buf)) { bold=8; };
              if (StrFind(";1;",ansi_buf)) { bold=8; };

              if (StrFind(";01m",ansi_buf)) { bold=8; };
              if (StrFind("[01;",ansi_buf)) { bold=8; };
              if (StrFind(";01;",ansi_buf)) { bold=8; };

              if (StrFind("[0m",ansi_buf)) { bold=0; };
              if (StrFind(";0m",ansi_buf)) { bold=0; };
              if (StrFind("[0;",ansi_buf)) { bold=0; };
              if (StrFind(";0;",ansi_buf)) { bold=0; };

              if (StrFind(";00m",ansi_buf)) { bold=0; };
              if (StrFind("[00;",ansi_buf)) { bold=0; };
              if (StrFind(";00;",ansi_buf)) { bold=0; };

              if (StrFind("30",ansi_buf)) { tt_cur_fg=bold+0; };
              if (StrFind("31",ansi_buf)) { tt_cur_fg=bold+4; };
              if (StrFind("32",ansi_buf)) { tt_cur_fg=bold+2; };
              if (StrFind("33",ansi_buf)) { tt_cur_fg=bold+6; };
              if (StrFind("34",ansi_buf)) { tt_cur_fg=bold+1; };
              if (StrFind("35",ansi_buf)) { tt_cur_fg=bold+5; };
              if (StrFind("36",ansi_buf)) { tt_cur_fg=bold+3; };
              if (StrFind("37",ansi_buf)) { tt_cur_fg=bold+7; };
              if (StrFind("39",ansi_buf)) { tt_cur_fg=WHITE; };


              if (StrFind("40",ansi_buf)) { tt_cur_bg=0; };
              if (StrFind("41",ansi_buf)) { tt_cur_bg=4; };
              if (StrFind("42",ansi_buf)) { tt_cur_bg=2; };
              if (StrFind("43",ansi_buf)) { tt_cur_bg=6; };
              if (StrFind("44",ansi_buf)) { tt_cur_bg=1; };
              if (StrFind("45",ansi_buf)) { tt_cur_bg=5; };
              if (StrFind("46",ansi_buf)) { tt_cur_bg=3; };
              if (StrFind("47",ansi_buf)) { tt_cur_bg=7; };
              if (StrFind("49",ansi_buf)) { tt_cur_bg=BLACK; };

              if (StrFind("90",ansi_buf)) { tt_cur_fg=bold+0; };
              if (StrFind("91",ansi_buf)) { tt_cur_fg=bold+4; };
              if (StrFind("92",ansi_buf)) { tt_cur_fg=bold+2; };
              if (StrFind("93",ansi_buf)) { tt_cur_fg=bold+6; };
              if (StrFind("94",ansi_buf)) { tt_cur_fg=bold+1; };
              if (StrFind("95",ansi_buf)) { tt_cur_fg=bold+5; };
              if (StrFind("96",ansi_buf)) { tt_cur_fg=bold+3; };
              if (StrFind("97",ansi_buf)) { tt_cur_fg=bold+7; };

              if (StrFind("100",ansi_buf)) { tt_cur_bg=bold+0; };
              if (StrFind("101",ansi_buf)) { tt_cur_bg=bold+4; };
              if (StrFind("102",ansi_buf)) { tt_cur_bg=bold+2; };
              if (StrFind("103",ansi_buf)) { tt_cur_bg=bold+6; };
              if (StrFind("104",ansi_buf)) { tt_cur_bg=bold+1; };
              if (StrFind("105",ansi_buf)) { tt_cur_bg=bold+5; };
              if (StrFind("106",ansi_buf)) { tt_cur_bg=bold+3; };
              if (StrFind("107",ansi_buf)) { tt_cur_bg=bold+7; };

              if (StrFind("[0m",ansi_buf)) { tt_cur_bg=BLACK; tt_cur_fg=WHITE; };

              if (StrFind("[7m",ansi_buf)) 
                { tt_cur_fg=rv; tt_cur_fg=tt_cur_bg; tt_cur_bg=rv; 
                  if (tt_cur_bg>7) { tt_cur_bg-=8; };
                };

              break;

            case 'A':
              ansi_buf[ansi_pos-1]=0;
              l=Str2I64(ansi_buf+1);
              tt_cur_y-=l;
              if (tt_cur_y<0) { tt_cur_y=0; };
              break;

            case 'B':
              ansi_buf[ansi_pos-1]=0;
              l=Str2I64(ansi_buf+1);
              tt_cur_y+=l;
              if (tt_cur_y>=(Fs->parent_task->win_height-1)) { 
                tt_cur_y=Fs->parent_task->win_height-1;
              };
              break;

            case 'C':
              ansi_buf[ansi_pos-1]=0;
              l=Str2I64(ansi_buf+1);
              tt_cur_x+=l;
              if (tt_cur_x>=(Fs->parent_task->win_width-1)) { 
                tt_cur_x=Fs->parent_task->win_width-1;
              };
              break;

            case 'D':
              ansi_buf[ansi_pos-1]=0;
              l=Str2I64(ansi_buf+1);
              tt_cur_x-=l;
              if (tt_cur_x<0) { tt_cur_x=0; };
              break;
          
            case 'H':
            case 'f':
              j=1;k=0;
              while (j<64)
              {
                if (ansi_buf[j]==';') { ansi_buf[j]=0; k=j+1; j=64; }; 
                j++;
              };
              if (k>0)
              {
                ansi_buf[ansi_pos-1]=0;
                tt_cur_x=Str2I64(ansi_buf+k);
                tt_cur_y=Str2I64(ansi_buf+1);
                tt_cur_fg=WHITE;
                tt_cur_bg=BLACK;
              };        
              break;
            
            case 'J':
              if (ansi_buf[1]=='0' || ansi_buf[1]=='J')
              {
                GrRect(tt_buf,0,tt_cur_y*8,640,480);
              };
              if (ansi_buf[1]=='1')
              {
                GrRect(tt_buf,0,-480+(tt_cur_y*8),640,480);
              };
              if (ansi_buf[1]=='2')
              {
                DCFill(tt_buf,tt_cur_bg);
                tt_cur_x=0;
                tt_cur_y=0;
              };
              break;

            case 's':
              sp_x=tt_cur_x;
              sp_y=tt_cur_y;
              sp_bg=tt_cur_bg;
              sp_fg=tt_cur_fg;
              break;

            case 'u':
              tt_cur_x=sp_x;
              tt_cur_y=sp_y;
              tt_cur_bg=sp_bg;
              tt_cur_fg=sp_fg;
              break;

            case 'K':
              if(ansi_buf[1]=='0' || ansi_buf[1]=='K')
              {
                tt_buf->color=tt_cur_bg;
                GrRect(tt_buf,tt_cur_x*8,tt_cur_y*8,640,8);
                tt_buf->color=tt_cur_fg;
              };
              if(ansi_buf[1]=='1')
              {
                tt_buf->color=tt_cur_bg;
                GrRect(tt_buf,-640+(tt_cur_x*8),tt_cur_y*8,640,8);
                tt_buf->color=tt_cur_fg;
              };
              if(ansi_buf[1]=='2')
              {
                tt_buf->color=tt_cur_bg;
                GrRect(tt_buf,0,tt_cur_y*8,640,8);
                tt_buf->color=tt_cur_fg;
              };
              break;

            // line wrapping doesn't seem to matter...
            case 'h':
              break;
            case 'l':
              break;

            default:
              //StrPrint(sr_buf, "Code: %02X", ansi_buf[ansi_pos-1]); 
              //PopUpOk(sr_buf);
              break;
          };

          in_esc=0;
        };

        if (in_esc==1)
        {
          // write to ANSI sequence buffer
          ansi_buf[ansi_pos]=rx_buf[pos];
          switch (rx_buf[pos])
          {
            case 'a'...'z':
            case 'A'...'Z':
              in_esc++;
              break;
            default:
              break;
          };
          ansi_pos++;
        }

        if (in_esc==0 && in_rz==0)
        {      
          switch (rx_buf[pos])
          {
            case 7:
              Snd(62);
              Sleep(120);
              SndRst;
              break;
            case 8:
              tt_cur_x--;
              if(tt_cur_x<0) { tt_cur_x=0; };
              break;
            case 10:
              // change back to default attrs when we line feed?
              tt_cur_bg=BLACK;
              tt_cur_fg=WHITE;

              tt_cur_y++;
              break;
            case 13:
              tt_cur_x=0;
              break;
            case 27:
              // Begin escape sequence
              ansi_pos=0;
              in_esc++;
              break;
            case 31...255:
              rx_u8[0]=rx_buf[pos];
              tt_buf->color=tt_cur_bg;
              GrRect(tt_buf,tt_cur_x*8,tt_cur_y*8,8,8);
              tt_buf->color=tt_cur_fg;
              GrPrint(tt_buf,tt_cur_x*8,tt_cur_y*8,rx_u8);
              tt_cur_x++;
              if(tt_cur_x==Fs->parent_task->win_width)
              {
                tt_cur_x-=Fs->parent_task->win_width;
                // change back to default attrs when we line wrap?
                tt_cur_bg=BLACK;
                tt_cur_fg=WHITE;

                tt_cur_y++;
              };            
              break;
            default:
              break;
          };

        };

        if (rzh_state>0)
        {
          if (rx_buf[pos] == rzh_seq[rzh_state])
          {
            rzh_state++;
          }
          else
          {
            rzh_state=0;
          }
        };

        if (rx_buf[pos] == rzh_seq[rzh_state])
        {
          rzh_state++;
        };

        if (rzh_state>3)
        {
          if (in_rz<3)
          {
            rzp_type=ZHEX;
            in_esc=0;
            rz_xctr=0;
            in_rz++;
          };           
          rzh_state=0;
        };

        if (rzb_state>0)
        {
          if (rx_buf[pos] == rzb_seq[rzb_state])
          {
            rzb_state++;
          }
          else
          {
            rzb_state=0;
          }
        };

        if (rx_buf[pos] == rzb_seq[rzb_state])
        {
          rzb_state++;
        };

        if (rzb_state>2)
        {
          if (in_rz>1 && in_rz<3)
          {
            rzp_type=ZBIN;
            DETECT_ZDLE=1;
            in_esc=0;
            in_rz++;
          };           
          rzb_state=0;
        };

        // Y-scroll the frame buffer
        if (tt_cur_y==Fs->parent_task->win_height)
        {
          DCFill(tt_buf2,TRANSPARENT);
          GrBlot(tt_buf2,0,-8,tt_buf);
          DCFill(tt_buf,tt_cur_bg);
          GrBlot(tt_buf,0,0,tt_buf2);
          tt_cur_y--;          
        };
        
      };
      pos++;

      };       

    };

    Sleep(1);
  };
  Free(rz_ibuf);
  Free(rz_filename);
  Free(rz_shortfn);
  Free(rx_buf);
  Free(ad_seq);
  Free(sr_buf);
  PostMsg(Fs->parent_task,MSG_KEY_DOWN_UP,REMOTE_Q,0);
}

I64 TempleTermConnect(U8 *host, I64 port=23)
{
  rzh_state=0;
  rzb_state=0;
  tt_cur_x=0;
  tt_cur_y=0;
  tt_cur_bg=BLACK;
  tt_cur_fg=WHITE;
  tt_cur_int=0;
  DCFill(tt_buf,tt_cur_bg);

  U8 se_u8[4];
  U8 sx_u8[2];

  I64 key;

  se_u8[0]=27;
  se_u8[1]='[';
  se_u8[3]=0;
  sx_u8[1]=0;

  if(StrCmp(host,"")==0)
  {
    "Must specify hostname or IP address.\n";
    return -1;
  };

  I64 sock = create_connection(host, port);
  if (sock>=0)
  {
    MenuPush("File{"
             "  Disconnect(,PROMPT_Q);"
             "}");

    Fs->draw_it=&TDrawIt;
    CTask *session = Spawn(&TempleTermSession,sock,"TempleTermSession",,Fs);
    while (TRUE)
    {
      sx_u8[0]=0;
      key=GetChar2(,FALSE);

    if (in_rz>0)
    {
      if (key==27)
      {
        abort_rz=1;                
      };
    };

    if (in_rz==0 || abort_rz==1)
    {  
      // Send username
      if ((kbd.scan_code & 0xFFFF) == 2070)
      {
        sendString(sock, conn_entries[res].user, 0);
        key=0;
      };

      // Send password
      if ((kbd.scan_code & 0xFFFF) == 2073)
      {
        sendString(sock, conn_entries[res].pass, 0);
        key=0;
      };

      // Support for default shortcut keys
      // toggle border (alt-b)
      if ((kbd.scan_code & 0xFFFF) == 2096)
      {
        WinBorder(!WinBorder);
        key=0;
      };

      // maximize, no border (alt-m)
      if ((kbd.scan_code & 0xFFFF) == 2098)
      {
        WinBorder;
        WinMax;
        key=0;
      };

      // win tile horz (alt-h)
      if ((kbd.scan_code & 0xFFFF) == 2083)
      {
        WinTileHorz;
        key=0;
      };

      // win tile vert (alt-v)
      if ((kbd.scan_code & 0xFFFF) == 2095)
      {
        WinTileVert;
        key=0;
      };
     
      // change task
      if ((kbd.scan_code & 0xFFFF) == 2063)
      {
        LBts(sys_ctrl_alt_flags,CTRL_ALT_TAB);
        key=0;
      };

      if (key==PROMPT_Q)
      {
          ProgressBarsRst;
          if (PopUpCancelOk("OK to disconnect?")==1)
          {
            break;
          };
      };

      if (key==REMOTE_Q) { break; };
      if (key==10) { key=13; };

      if (key==0)
      {
        key=kbd.scan_code & 0xFF;

        if (key==SC_F12) { 
          ProgressBarsRst;
          if (PopUpCancelOk("OK to disconnect?")==1)
          {
            break;
          };
        };

        if (key==72)
        {
          se_u8[2]='A';
          send(sock, se_u8, 3, 0);
        };

        if (key==80)
        {
          se_u8[2]='B';
          send(sock, se_u8, 3, 0);
        };

        if (key==77)
        {
          se_u8[2]='C';
          send(sock, se_u8, 3, 0);
        };

        if (key==75)
        {
          se_u8[2]='D';
          send(sock, se_u8, 3, 0);
        };
        key=0;
      };

      if (key>0) { sx_u8[0]=key; };

      if (sx_u8[0]>0)
      {    
        send(sock, sx_u8, 1, 0);
      };       
    };

    };

    RegWrite("WalnutLabs/TempleTerm", "Fs->parent_task->display_flags=%d;\n",
      Fs->display_flags);
    RegAppend("WalnutLabs/TempleTerm", "Fs->parent_task->win_left=%d;\n",
      Fs->win_left);
    RegAppend("WalnutLabs/TempleTerm", "Fs->parent_task->win_right=%d;\n",
      Fs->win_right);
    RegAppend("WalnutLabs/TempleTerm", "Fs->parent_task->win_top=%d;\n",
      Fs->win_top);
    RegAppend("WalnutLabs/TempleTerm", "Fs->parent_task->win_bottom=%d;\n",
      Fs->win_bottom);
    RegAppend("WalnutLabs/TempleTerm", "Fs->parent_task->win_width=%d;\n",
      Fs->win_width);
    RegAppend("WalnutLabs/TempleTerm", "Fs->parent_task->win_height=%d;\n",
      Fs->win_height);
    Kill(session);
    close(sock);
    PopUpOk("Connection closed.");
    Fs->draw_it=NULL;
    DCFill;
    SndRst;
    MenuPop;
    return 0;
  }
  else
  {
    SndRst;
    PopUpOk("Connection timed out.");
    return sock;
  };    
}

U0 Run()
{
  res=0;
  tt_buf=DCNew(640,480);

  if (FileFind(TT_CFG_PATH "/" TT_CFG_FILE))
  {
    conn_entries=FileRead(TT_CFG_PATH "/" TT_CFG_FILE);
  }
  else
  {
    conn_entries=CAlloc(sizeof(TTConnEntry)*TT_MAX_ENTRIES);
  };

  conn_rc_entries=CAlloc(sizeof(TTConnEntry)*TT_MAX_ENTRIES);

  add_form=CAlloc(sizeof(TTConnEntryForm));
  edit_form=CAlloc(sizeof(TTConnEntryForm));

  conn_list=CAlloc(sizeof(TTConnEntry)*TT_MAX_ENTRIES);  
  conn_edlist=CAlloc(sizeof(TTConnEntry)*TT_MAX_ENTRIES);  

  I64 idx=0;
  I64 dres=0;
  I64 eres=0;

  ConnEntriesRecalc;
  while (res!=-1)
  {      
    res = PopUpBookmarkLst(conn_list);
    if (res!=-1 && res<(conn_idx))
    {
      TempleTermConnect(conn_entries[res].host, conn_entries[res].port);
    };

    if (res==(conn_idx))
    {
      idx = res;
      StrPrint(add_form->name,"");
      StrPrint(add_form->host,"");
      add_form->port=23;
      StrPrint(add_form->user,"");
      StrPrint(add_form->pass,"");
      if(DocForm(add_form))
      {
        // add new entry

        if(StrLen(add_form->name)>0)
        {
          StrPrint(conn_entries[idx].name, add_form->name);          
          StrPrint(conn_entries[idx].host, add_form->host);          
          conn_entries[idx].port=add_form->port;          
          StrPrint(conn_entries[idx].user, add_form->user);          
          StrPrint(conn_entries[idx].pass, add_form->pass);          
          ConnEntriesRecalc;
        };     
      };
    };

    if (res==(conn_idx+1))
    {
      // delete entry
      idx = res;
      dres = PopUpDelLst(conn_edlist);
      if (dres!=-1)
      {
        if(PopUpCancelOk("Ok to DELETE this entry?"))
        {
          StrPrint(conn_entries[dres].name, "");          
          StrPrint(conn_entries[dres].host, "");          
          conn_entries[dres].port=0;                   
          StrPrint(conn_entries[dres].user, "");          
          StrPrint(conn_entries[dres].pass, "");          
        };
      };
      ConnEntriesRecalc;
    };

    if (res==(conn_idx+2))
    {
      // edit entry
      idx = res;
      eres = PopUpEditLst(conn_edlist);
      if (eres!=-1)
      {
        StrPrint(edit_form->name,conn_entries[eres].name);
        StrPrint(edit_form->host,conn_entries[eres].host);
        edit_form->port=conn_entries[eres].port;
        StrPrint(edit_form->user,conn_entries[eres].user);
        StrPrint(edit_form->pass,conn_entries[eres].pass);

        if(DocForm(edit_form))
        {
          if(StrLen(edit_form->name)>0)
          {
            StrPrint(conn_entries[eres].name, edit_form->name);          
            StrPrint(conn_entries[eres].host, edit_form->host);          
            conn_entries[eres].port=edit_form->port;          
            StrPrint(conn_entries[eres].user, edit_form->user);          
            StrPrint(conn_entries[eres].pass, edit_form->pass);          
          };     
        };
      };
      ConnEntriesRecalc;
    };

  };
  if (FileFind(TT_CFG_PATH)==0) { DirMk(TT_CFG_PATH); };
  FileWrite(TT_CFG_PATH "/" TT_CFG_FILE,conn_entries,(sizeof(TTConnEntry)*TT_MAX_ENTRIES));
  DCDel(tt_buf);
  Free(conn_entries);
  Free(conn_rc_entries);
  Free(add_form);
  Free(edit_form);
  Free(conn_list);
  Free(conn_edlist);  
}

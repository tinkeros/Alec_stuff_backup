#define URIEL_GETPAGE 0x10
#define URIEL_NAVBACK 0x11
#define URIEL_NAVFWD 0x12
#define URIEL_THUMB 0x13
#define URIEL_WEBM 0x14

#define URIEL_DL_PATH "::/Home/Downloads/"
#define URIEL_THUMB_BMP "/Tmp/UrielThumb.bmp"
#define URIEL_VERSION "Uriel/0.2"

Bool URIEL_INSTANCE=FALSE;
CDC *URIEL_WEBM_DC;
CFileBMP *URIEL_WEBM_BITMAP;
U8 URIEL_USER_AGENT[64];
U8 URIEL_WEBM_FRAME[5000];
U8 *URIEL_WEBM_PTR;
StrCpy(URIEL_USER_AGENT, URIEL_VERSION);
StrCpy(URIEL_USER_AGENT+StrLen(URIEL_USER_AGENT), " (");
StrCpy(URIEL_USER_AGENT+StrLen(URIEL_USER_AGENT), Define("DD_OS_NAME_VERSION"));
StrCpy(URIEL_USER_AGENT+StrLen(URIEL_USER_AGENT), ")");

U0 U_ZeroWebMFrameBuf()
{
  I64 z=0;
  while (z<5000) {
    URIEL_WEBM_FRAME[z] = 0x0;
    z++;
  };
}

public CDC *U_WebMFrame(Bool dither_probability=FALSE,
        Bool use_ms_paint_palette=FALSE)
{
  I64 i,j,cnt;
  U8 *palette_map;
  Bool rle; 
  CDC *res=NULL;
  URIEL_WEBM_PTR=URIEL_WEBM_FRAME;
  URIEL_WEBM_BITMAP=URIEL_WEBM_PTR;
  if (0<URIEL_WEBM_BITMAP->width<I32_MAX && 0<URIEL_WEBM_BITMAP->height<I32_MAX) {
    res=DCNew(URIEL_WEBM_BITMAP->width,URIEL_WEBM_BITMAP->height);
    URIEL_WEBM_PTR+=URIEL_WEBM_BITMAP->data_offset;
    if (URIEL_WEBM_BITMAP->compression==2)
      rle=TRUE;
    else
      rle=FALSE;
    if (use_ms_paint_palette)
      palette_map=ms_paint_palette;
    else
      palette_map=BMPPaletteNew(URIEL_WEBM_BITMAP);
    if (URIEL_WEBM_BITMAP->bit_cnt==4) {
      for (i=URIEL_WEBM_BITMAP->height-1;i>=0;i--)
        if (rle) {//We don't support full RLE4, just our own subset
          j=0;
          while (cnt=*URIEL_WEBM_PTR++) {
            if (cnt==1) {
              res->color=palette_map[*URIEL_WEBM_PTR++&15];
              GrPlot(res,j++,i);
            } else {
              if (cnt==2 && *URIEL_WEBM_PTR>>4!=*URIEL_WEBM_PTR&15) {
                res->color=palette_map[*URIEL_WEBM_PTR&15];
                GrPlot(res,j+1,i);
                res->color=palette_map[*URIEL_WEBM_PTR>>4];
                GrPlot(res,j,i);
                URIEL_WEBM_PTR++;
                j+=2;
              } else {
                res->color=palette_map[*URIEL_WEBM_PTR++&15];
                while (cnt--)
                  GrPlot(res,j++,i);
              }
            }
          }
          URIEL_WEBM_PTR++;
        } else
          for (j=0;j<(URIEL_WEBM_BITMAP->width+7)&~7;) {
            res->color=palette_map[*URIEL_WEBM_PTR&15];
            GrPlot(res,j+1,i);
            res->color=palette_map[*URIEL_WEBM_PTR>>4];
            GrPlot(res,j,i);
            URIEL_WEBM_PTR++;
            j+=2;
          }
      if (!use_ms_paint_palette)
        Free(palette_map);
    } else if (URIEL_WEBM_BITMAP->bit_cnt==24) {
      for (i=URIEL_WEBM_BITMAP->height-1;i>=0;i--) {
        for (j=0;j<URIEL_WEBM_BITMAP->width;j++,URIEL_WEBM_PTR+=3) {
          res->color=BMP24Color(URIEL_WEBM_PTR,dither_probability);
          GrPlot(res,j,i);
        }
        URIEL_WEBM_PTR+=URIEL_WEBM_BITMAP->width&3;
      }
      if (!use_ms_paint_palette)
        Free(palette_map);
    } else if (URIEL_WEBM_BITMAP->bit_cnt>=32) {
      for (i=URIEL_WEBM_BITMAP->height-1;i>=0;i--)
        for (j=0;j<URIEL_WEBM_BITMAP->width;j++,URIEL_WEBM_PTR+=4) {
          res->color=BMP24Color(URIEL_WEBM_PTR,dither_probability);
          GrPlot(res,j,i);
        }
      if (!use_ms_paint_palette)
        Free(palette_map);
    } else {
      "Format Not Supported.\n";
      DCDel(res);
      res=NULL;
    }
  } else {
    DCDel(res);
    res=NULL;
  };
  return res;
}

U0 U_CloseBrowser()
{
  Bool close=FALSE;
  close = PopUpCancelOk("Close Uriel Browser?");
  if (close) { In("x\n"); };
}

U0 U_InsertThumb(U8 *anchor, U8 *indent, U8 *outdent, U8 *url)
{
  DocAnchorFind(DocPut,anchor);
  I64 size;
  ZeroParamBuf;
  StrCpy(HGBD_PARAM_BUF,URIEL_USER_AGENT);
  WriteParamBuf;
  BlkWrite(HGBD,url,1,(StrLen(url)/BLK_SIZE)+1);
  HGExec(URIEL_THUMB);
  ReadParamBuf;
  size = Str2I64(HGBD_PARAM_BUF);
  if (size<1) {
    PopUpOk("Error loading image.");
    FreeHGBD;
    return;
  };
  BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
  FileWrite(URIEL_THUMB_BMP, HGFS_BUF, size);
  DocAnchorFind(DocPut,anchor);
  DocBMP(,URIEL_THUMB_BMP);
  if (StrCmp(indent,"")!=0) {
    DocAnchorFind(DocPut,indent);
    DocPrintPartial(DocPut,"$ID,14$");
  };
  if (StrCmp(indent,"")!=0) {
    DocAnchorFind(DocPut,outdent);
    DocPrintPartial(DocPut,"$ID,-14$");
  };
  DocAnchorFind(DocPut,anchor);
  FreeHGBD;
}

U0 U_PlayWebM(U8 *anchor, U8 *url)
{
  DCFill;
  DocAnchorFind(DocPut,anchor);
  I64 webm_x = ms.pos.x;
  I64 webm_y = ms.pos.y;
  I64 frame=0;
  I64 mframes,size;
  ZeroParamBuf;
  StrCpy(HGBD_PARAM_BUF,URIEL_USER_AGENT);
  WriteParamBuf;
  BlkWrite(HGBD,url,1,(StrLen(url)/BLK_SIZE)+1);
  HGExec(URIEL_WEBM);
  ReadParamBuf;
  size = Str2I64(HGBD_PARAM_BUF);
  if (size<1) {
    PopUpOk("Error loading WebM.");
    FreeHGBD;
    return;
  };
  mframes = Str2I64(HGBD_PARAM_BUF+128);
  if (mframes<1) {
    PopUpOk("Error loading WebM.");
    FreeHGBD;
    return;
  };
  BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
  DocAnchorFind(DocPut,anchor);
  while (!ScanKey) {
    U_ZeroWebMFrameBuf;
    MemCpy(URIEL_WEBM_FRAME, HGFS_BUF+(frame*(size/mframes)), (size/mframes));
    URIEL_WEBM_DC = U_WebMFrame;
    GrBlot(,webm_x,webm_y,URIEL_WEBM_DC);
    if (URIEL_WEBM_DC==NULL) { frame=0; };
    DCDel(URIEL_WEBM_DC);   
    Sleep(30);
    frame++;
    if (frame>(mframes-1)) { frame=0; };
  };
  DCFill;
  FreeHGBD;
}

U0 U_Browser(U8 *url)
{
  Bool savefile=FALSE;
  U8 localfile[StrLen(URIEL_DL_PATH)+28];
  U8 msg[128];
  U8 savemsg[1024];
  I64 size;
  U8 *cmd;
  ZeroParamBuf;
  StrCpy(HGBD_PARAM_BUF,URIEL_USER_AGENT);
  WriteParamBuf;
  BlkWrite(HGBD,url,1,(StrLen(url)/BLK_SIZE)+1);
  HGExec(URIEL_GETPAGE);
  ReadParamBuf;
  size = Str2I64(HGBD_PARAM_BUF);
  if (size<1) {
    PopUpOk("Bad URL.");
    FreeHGBD;
    return;
  };
  if (StrCmp(HGBD_PARAM_BUF+128,"download://")==0) {
    StrCpy(localfile,URIEL_DL_PATH);
    if (StrLastOcc(url,"/")>0) {
      StrCpy(localfile+StrLen(localfile), StrLastOcc(url,"/")+1);
    } else {
      StrCpy(localfile+StrLen(localfile),url);
    };
    StrCpy(savemsg,"Download file: ");
    if (StrLastOcc(url,"/")>0) {
      StrCpy(savemsg+StrLen(savemsg),StrLastOcc(url,"/")+1);
    } else {
      StrCpy(savemsg+StrLen(savemsg),url);
    };
    StrCpy(savemsg+StrLen(savemsg)," (");
    StrCpy(savemsg+StrLen(savemsg),HGBD_PARAM_BUF);
    StrCpy(savemsg+StrLen(savemsg)," bytes)");
    savefile = PopUpCancelOk(savemsg);
    if (savefile==TRUE) {
      BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
      if (StrCmp(localfile+StrLen(localfile)-2,".Z")==0) {
        U8 uzlocalfile[StrLen(URIEL_DL_PATH)+28];
        MemCpy(uzlocalfile,localfile,StrLen(localfile)-2);
        uzlocalfile[StrLen(localfile)-1] = 0x0;
        FileWrite(uzlocalfile, HGFS_BUF, size);
        Move(uzlocalfile, localfile);
      } else {
        FileWrite(localfile, HGFS_BUF, size);
      };
      StrCpy(msg, "Downloaded file: ");
      StrCpy(msg+StrLen(msg), localfile);
      PopUpOk(msg);
    };
  } else {
    BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
    MemSetU8(ToI64(HGFS_BUF)+size, 0x0, 1);
    DocClear;
    DocPutS(DocPut,HGFS_BUF);
    DocTop;
    if (URIEL_INSTANCE==FALSE) {
      StrCpy(Fs->task_title, HGBD_PARAM_BUF+128);
      FreeHGBD;
      URIEL_INSTANCE=TRUE;
      while (TRUE) {
        cmd = GetStr;
        if (StrCmp(cmd,"x")==0) { break; };
      };
      Free(cmd);
      URIEL_INSTANCE=FALSE;
    } else {
      StrCpy(Fs->parent_task->task_title, HGBD_PARAM_BUF+128);
      FreeHGBD;
    };
  };
}

U0 U_HistNav(I64 index)
{
  I64 size;
  ZeroParamBuf;
  if (index==0) { HGExec(URIEL_NAVBACK); };
  if (index==1) { HGExec(URIEL_NAVFWD); };
  ReadParamBuf;
  size = Str2I64(HGBD_PARAM_BUF);
  if (size<1) {
    PopUpOk("Bad URL.");
    FreeHGBD;
    return;
  };
  StrCpy(Fs->parent_task->task_title, HGBD_PARAM_BUF+128);
  BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
  MemSetU8(ToI64(HGFS_BUF)+size, 0x0, 1);
  DocClear;
  DocPutS(DocPut,HGFS_BUF);
  DocTop;
  FreeHGBD;
}

U0 U_Navigate(U8 *anchor, U8 *url) {
    DocAnchorFind(DocPut,anchor);
    U_Browser(url);
}

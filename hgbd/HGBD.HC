#define HGC_PORT 0x02F8
#define HGC_COPYG 0x01
#define HGC_COPYH 0x02
#define HGC_SCREENSHOT 0x03
#define HGC_DIRH 0x04
#define HGC_GETURL 0x05
#define HGC_DELH 0x07
#define HGC_CDH 0x08
#define HGC_DIRCURH 0x09
#define HGC_HCOPY 0x0A
#define HGC_HPASTE 0x0B
#define HGC_NOOP 0xFF

#define HGFS_BUF_SIZE 0x4000000

#define SCREENSHOT_FILE "::/Tmp/ScreenShot.bmp"

CBlkDev *HGBD_DEV;
CDrv *HGBD;
I64 HGBD_OP=0;
U8 *HGFS_BUF[HGFS_BUF_SIZE];
U8 HGBD_PARAM_BUF[BLK_SIZE];

HGBD_DEV = BlkDevNextFreeSlot(0x69,BDT_ATA);
HGBD_DEV->unit=1;
HGBD_DEV->base0=496;
HGBD_DEV->base1=1012;
BlkDevAdd(HGBD_DEV,0,1,1);

HGBD = Let2Drv(HGBD_DEV->first_drv_let);

U0 FreeHGBD()
{
  HGBD_OP=0;
}

U0 HGExec(I64 cmd, Bool chain=FALSE)
{
  while (HGBD_OP>0 && !chain) { Sleep(1+(RandU16/8192)); };
  HGBD_OP=cmd;
  OutU8(HGC_PORT,HGC_NOOP);
  while (InU8(HGC_PORT)!=HGC_NOOP) { Sleep(0); };
  OutU8(HGC_PORT,cmd);
  while (InU8(HGC_PORT)!=cmd) { Sleep(0); };
}

U0 ReadParamBuf() { DskCacheInvalidate(HGBD); BlkRead(HGBD,HGBD_PARAM_BUF,0,1); }

U0 PrintParamBuf() { ReadParamBuf; Print(HGBD_PARAM_BUF); } 

U0 WriteParamBuf() { BlkWrite(HGBD,HGBD_PARAM_BUF, 0, 1); }

U0 ZeroParamBuf()
{
  I64 z=0;
  while (z<BLK_SIZE) {
    HGBD_PARAM_BUF[z] = 0x0;
    z++;
  }
  WriteParamBuf;
}

I64 CdH(U8 *pathname)
{
  I64 result;
  ZeroParamBuf;
  StrCpy(HGBD_PARAM_BUF,pathname);
  WriteParamBuf;
  HGExec(HGC_CDH);
  ReadParamBuf;
  result = Str2I64(HGBD_PARAM_BUF);
  if (result==0) { Print("%s ", pathname); PrintErr("Path not found.\n"); };
  FreeHGBD;
  return result;
}

I64 CopyG(U8 *filename)
{
  I64 size;
  ZeroParamBuf;
  StrCpy(HGBD_PARAM_BUF,filename);
  WriteParamBuf;
  HGExec(HGC_COPYG);
  ReadParamBuf;
  size = Str2I64(HGBD_PARAM_BUF);
  if (size==-1) { FreeHGBD; return 0; };
  Print("Copying %s to Guest\n",filename);
  BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
  if (StrCmp(filename+StrLen(filename)-2,".Z")==0) {
    U8 uzfilename[28];
    MemCpy(uzfilename,filename,StrLen(filename)-2);
    uzfilename[StrLen(filename)-1] = 0x0;
    FileWrite(uzfilename, HGFS_BUF, size);
    Move(uzfilename, filename);
  } else {
    FileWrite(filename, HGFS_BUF, size);
  };
  FreeHGBD;
  return 1;
}

I64 CopyH(U8 *filename)
{
  I64 size;
  CDirEntry *de = FilesFind(filename);
  if (de==NULL) { FreeHGBD; return 0; };
  Print("Copying %s to Host\n",de->full_name);
  U8 *file = FileRead(de->full_name, &size);
  ZeroParamBuf;
  MemCpy(HGBD_PARAM_BUF,&size,8);
  StrCpy(HGBD_PARAM_BUF+8,de->name);
  WriteParamBuf;
  BlkWrite(HGBD,file,1,(size/BLK_SIZE)+1);
  HGExec(HGC_COPYH);
  Free(file);
  DirEntryDel(de);
  FreeHGBD;
  return 1;
}

I64 DelH(U8 *filename)
{
  I64 result;
  ZeroParamBuf;
  StrCpy(HGBD_PARAM_BUF,filename);
  WriteParamBuf;
  HGExec(HGC_DELH);
  ReadParamBuf;
  result = Str2I64(HGBD_PARAM_BUF);
  if (result==1) { Print("DelH %s\n", filename); };
  FreeHGBD;
  return result;
}

I64 DirH() {
  I64 entries;
  I64 size;
  ZeroParamBuf;
  HGExec(HGC_DIRH);
  ReadParamBuf;
  entries = Str2I64(HGBD_PARAM_BUF);
  size = Str2I64(HGBD_PARAM_BUF+128);
  BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
  MemSetU8(ToI64(HGFS_BUF)+size, 0x0, 1);
  Print(HGFS_BUF);
  FreeHGBD;
  return entries;
}

I64 CopyFindH(U8 *files)
{
  I64 cnt=0;
  CDirEntry *res = FilesFind(files);
  while (StrCmp(res->name,"")!=0) {
    if (res->size>0) {
      cnt += CopyH(res->full_name);
    };
    res=res->next;
  };
  DirEntryDel(res);
  return cnt;
}

U8 *DirCurH() 
{
  U8 StrDCH[1024];
  ZeroParamBuf;
  HGExec(HGC_DIRCURH);
  ReadParamBuf;
  StrCpy(StrDCH,HGBD_PARAM_BUF);
  FreeHGBD;
  return StrDCH;
}

U0 ScrShot()
{
  I64 size;
  BMPScrnCapture(SCREENSHOT_FILE);
  CDirEntry *de = FilesFind(SCREENSHOT_FILE);
  if (de==NULL) { FreeHGBD; return; };
  U8 *file = FileRead(de->full_name, &size);
  ZeroParamBuf;
  MemCpy(HGBD_PARAM_BUF,&size,8);
  StrCpy(HGBD_PARAM_BUF+8,de->name);
  WriteParamBuf;
  BlkWrite(HGBD,file,1,(size/BLK_SIZE)+1);
  HGExec(HGC_SCREENSHOT);
  OutU8(0x03F8, 0x99);
  Free(file);
  DirEntryDel(de);
  FreeHGBD;
}

U0 GetURL(U8 *url)
{
  Print("Downloading %s\n",url);
  I64 size;
  U8 localfile[28];
  if (StrLen(StrLastOcc(url,"/")+1)>0) { 
    StrCpy(localfile, StrLastOcc(url,"/")+1);
  } else {
    StrCpy(localfile, "GetURL.OUT");
  };
  ZeroParamBuf;
  StrCpy(HGBD_PARAM_BUF,url);
  WriteParamBuf;
  HGExec(HGC_GETURL);
  ReadParamBuf;
  size = Str2I64(HGBD_PARAM_BUF);
  if (size==-1) { PrintErr("Bad URL.\n"); FreeHGBD; return; };
  BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
  if (StrCmp(localfile+StrLen(localfile)-2,".Z")==0) {
    U8 uzlocalfile[28];
    MemCpy(uzlocalfile,localfile,StrLen(localfile)-2);
    uzlocalfile[StrLen(localfile)-1] = 0x0;
    FileWrite(uzlocalfile, HGFS_BUF, size);
    Move(uzlocalfile, localfile);
  } else {
    FileWrite(localfile, HGFS_BUF, size);
  };
  FreeHGBD;
}

U0 HCopy()
{
  I64 size;
  U8 *clip = Doc2PlainText(sys_clip_doc,sys_clip_doc->head.next);
  size = StrLen(clip);
  ZeroParamBuf;
  MemCpy(HGBD_PARAM_BUF,&size,8);
  WriteParamBuf;
  BlkWrite(HGBD,clip,1,(size/BLK_SIZE)+1);
  HGExec(HGC_HCOPY);
  Free(clip);
  FreeHGBD;
}

U0 HPaste()
{
  I64 size;
  ZeroParamBuf;
  HGExec(HGC_HPASTE);
  ReadParamBuf;
  size = Str2I64(HGBD_PARAM_BUF);
  BlkRead(HGBD,HGFS_BUF,1,(size/BLK_SIZE)+1);
  MemSetU8(ToI64(HGFS_BUF)+size, 0x0, 1);
  Print(HGFS_BUF);
  FreeHGBD;
}

U0 HGBDInit()
{
  ZeroParamBuf;
  Print("HGBD Initialized\n");
}

HGBDInit;

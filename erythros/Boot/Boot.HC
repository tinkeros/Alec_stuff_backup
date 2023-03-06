#define include_noreindex #include

I64 tos_nist_offset = 5603; // UTC -4

#define NIST_TIME_OFFSET (tos_nist_offset - local_time_offset / CDATE_FREQ)

public
I64 CDate2Unix(CDate dt) { // TempleOS datetime to Unix timestamp.
  return ToI64((dt - Str2Date("1/1/1970")) / CDATE_FREQ + NIST_TIME_OFFSET);
}

public
CDate Unix2CDate(I64 timestamp) { // Unix timestamp to TempleOS datetime.
  return (timestamp - NIST_TIME_OFFSET) * CDATE_FREQ + Str2Date("1/1/1970");
}

// FIXME: Put these in a "Builtin" library?
U0 FifoU8Cpy(CFifoU8 *f, U8 *s) {
  if (!f || !s)
    return;
  while (*s)
    FifoU8Ins(f, *s++);
}
Bool KeyDown(I64 sc) return Bt(kbd.down_bitmap, sc);
I64 T(Bool _condition, I64 _true, I64 _false) {
  if (_condition)
    return _true;
  return _false;
}

asm
    {
_MEMCPY_U16::
        PUSH    RBP
        MOV     RBP,RSP
        PUSH    RSI
        PUSH    RDI
        CLD
        MOV     RDI,U64 SF_ARG1[RBP]
        MOV     RSI,U64 SF_ARG2[RBP]
        MOV     RCX,U64 SF_ARG3[RBP]
        REP_MOVSW
        MOV     RAX,RDI
        POP     RDI
        POP     RSI
        POP     RBP
        RET1    24    
_MEMCPY_U32::
        PUSH    RBP
        MOV     RBP,RSP
        PUSH    RSI
        PUSH    RDI
        CLD
        MOV     RDI,U64 SF_ARG1[RBP]
        MOV     RSI,U64 SF_ARG2[RBP]
        MOV     RCX,U64 SF_ARG3[RBP]
        REP_MOVSD
        MOV     RAX,RDI
        POP     RDI
        POP     RSI
        POP     RBP
        RET1    24    
_MEMCPY_U64::
        PUSH    RBP
        MOV     RBP,RSP
        PUSH    RSI
        PUSH    RDI
        CLD
        MOV     RDI,U64 SF_ARG1[RBP]
        MOV     RSI,U64 SF_ARG2[RBP]
        MOV     RCX,U64 SF_ARG3[RBP]
        REP_MOVSQ
        MOV     RAX,RDI
        POP     RDI
        POP     RSI
        POP     RBP
        RET1    24
}

public _extern _MEMCPY_U16 U16 *MemCpyU16(U16 *dst, U16 *src, I64 cnt);
public
_extern _MEMCPY_U32 U32 *MemCpyU32(U32 *dst, U32 *src, I64 cnt);
public
_extern _MEMCPY_U64 U64 *MemCpyU64(U64 *dst, U64 *src, I64 cnt);

U0 EnableSSE() {
  asm
  {
  MOV_EAX_CR0
  AND AX, 0xFFFB // clear coprocessor emulation CR0.EM
  OR AX, 0x2 // set coprocessor monitoring  CR0.MP
  MOV_CR0_EAX
  MOV_EAX_CR4
  OR AX, 3 << 9 // set CR4.OSFXSR and CR4.OSXMMEXCPT at the same time
  MOV_CR4_EAX
  }
}

EnableSSE;

U8 **@boot_init_split(U8 *s, U8 ch = '\n', I64 *cnt) {
  U8 *p = s;
  cnt[0] = 0;
  while (*p) {
    if (*p == ch)
      cnt[0]++;
    p++;
  }
  if (!(cnt[0]))
    return NULL;
  cnt[0]++;
  I64 i = -1;
  U8 **arr = CAlloc(sizeof(U8 *) * cnt[0]);
  p = s;
  while (*p) {
    if (*p == ch || i < 0) {
      i++;
      arr[i] = p;
      if (*p == ch) {
        arr[i]++;
        *p = NULL;
      }
    }
    p++;
  }
  return arr;
}

U0 @boot_init_path(U8 *path, U8 *hints = NULL) {
  CDoc *doc;
  CDirEntry *de;
  CDirEntry *tmpde;
  de = FilesFind(path);
  if (hints) {
    I64 i;
    I64 hintsc = 0;
    U8 **hintsv = @boot_init_split(StrNew(hints), '|', &hintsc);
    for (i = 0; i < hintsc; i++) {
      tmpde = de->next->next;
      while (tmpde) {
        if (!StrCmp(tmpde->name, hintsv[i])) {
          doc = DocRead(tmpde->full_name);
          ExeDoc(doc);
          DocDel(doc);
        }
        tmpde = tmpde->next;
      }
    }
    Free(hintsv);
  }
  tmpde = de->next->next;
  while (tmpde) {
    if (!hints) {
      doc = DocRead(tmpde->full_name);
      ExeDoc(doc);
      DocDel(doc);
    } else {
      if (!StrFind(tmpde->name, hints)) {
        doc = DocRead(tmpde->full_name);
        ExeDoc(doc);
        DocDel(doc);
      }
    }
    tmpde = tmpde->next;
  }
  DirTreeDel(de);
  "\n\n";
}

U0 @boot_erythros() {
  WinMax(Fs);
  "$FG,7$$WW,1$";

  "Starting Erythros\n"

  "Loading drivers:   ";
  @boot_init_path("Drivers", "Dummy.HC|Pci.HC|Audio.HC");
  "Loading libraries: ";
  @boot_init_path(
      "Libraries",
      "String.HC|Util.HC|Function.HC|Ipc.HC|System.HC|User.HC|FileSystem.HC|"
      "Aes256.HC|Curve25519.HC|Sha256.HC|Hmac-Sha256.HC|Sha1.HC|Hmac-Sha1.HC|"
      "Net.HC|Tls12.HC|BitmapFont.HC|Graphics2D.HC");
  "Loading core components: ";
  @boot_init_path("Core", "Animation2D.HC|Compositor.HC|SystemTray.HC");

  ExeDoc(DocRead("Init.HC"));
}

@boot_erythros;
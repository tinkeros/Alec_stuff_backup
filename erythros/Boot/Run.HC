#define include_noreindex #include

// FIXME: Put these in a "Builtin" library?
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

U0 @boot_init_path(U8 *path, U8 *hints = NULL) {
  CDoc *doc;
  CDirEntry *de;
  CDirEntry *tmpde;
  de = FilesFind(path);
  if (hints) {
    tmpde = de->next->next;
    while (tmpde) {
      if (StrFind(tmpde->name, hints)) {
        doc = DocRead(tmpde->full_name);
        ExeDoc(doc);
        DocDel(doc);
      }
      tmpde = tmpde->next;
    }
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
  @boot_init_path("Drivers");
  "Loading libraries: ";
  @boot_init_path("Libraries", "Function.HC|Ipc.HC|String.HC|System.HC");
  "Loading core components: ";
  @boot_init_path("Core", "Compositor.HC|SystemTray.HC");

  ExeDoc(DocRead("Init.HC"));
}

@boot_erythros;
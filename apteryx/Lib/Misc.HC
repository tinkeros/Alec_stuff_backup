I64 frames;
extern U0 Print2D(Context2D *ctx, I64 x, I64 y, U32 fg = 0xFFFFFFFF, U32 bg = 0,
                  U8 *fmt, ...);

Bool T(I64 val, I64 if_true, I64 if_false) {
  if (val) {
    return if_true;
  } else {
    return if_false;
  }
}

Bool KeyDown(I64 sc) { return Bt(kbd.down_bitmap, sc); }

U64 append(U64 str) { return str + StrLen(str); }

I64 fps_frames = frames;
I64 fps_jiffies = cnts.jiffies;

U0 UpdateTOSMenuBar(Context2D *ctx) {
  if (cnts.jiffies >= fps_jiffies + 1000) {
    winmgr.fps = frames - fps_frames;
    fps_frames = frames;
    fps_jiffies = cnts.jiffies;
  }
  U8 *st;
  CCPU *c;
  I64 i;
  *wall->top_line = NULL;
  WallPaper(Fs);
  Rect2D(ctx, 0, 0, 640, 8, 0x0000a800);
  Print2D(ctx, 0, 0, , 0x0000a800, wall->top_line);
  WinCalcIdles;
  for (i = 0; i < mp_cnt; i++) {
    c = &cpu_structs[i];
    if (i & 1)
      Print2D(ctx, 8 * 44 + (8 * (i * 2)), 0, , 0x0000a800, "%2tf",
              100.0 * (1.0 - c->idle_factor));
    else
      Print2D(ctx, 8 * 44 + (8 * (i * 2)), 0, 0xffff5700, 0x0000a800, "%2tf",
              100.0 * (1.0 - c->idle_factor));
  }
  st = ScanCode2KeyName(kbd.last_down_scan_code);
  Print2D(ctx, 640 - (18 * 8), 0, 0xffff5700, 0x0000a800, "%18ts", st);
  Free(st);
}

asm
    {
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
}

public _extern _MEMCPY_U32 U32 *MemCpyU32(U32 *dst, U32 *src, I64 cnt);
class @system {
  Bool text_mode;
  CFifoI64 *log_fifo;
  U8 *build_info;
  U8 *(*BuildInfo)();
  U0 (*Init)();
  U0 (*Log)(CTask * task, U8 * fmt, ...);
  U0 (*PowerOff)();
};

@system System;

U0 @system_lex_warn(CCmpCtrl *cc,
                    U8 *str = NULL) { // Print warn msg, then, LexPutPos().
  if (!MemCmp(str, "Assign U0 ", 10))
    return; // suppress "Assign U0 " warnings
  if (str)
    PrintWarn(str);
  if (cc->htc.fun) {
    "in fun '%s'.\n", cc->htc.fun->str;
    if (IsRaw)
      "%s\n", cc->htc.fun->src_link;
    else {
      "$LK,\"%s\"$\n", cc->htc.fun->src_link;
      AdamErr("%s\n", cc->htc.fun->src_link);
    }
  } else
    LexPutPos(cc);
  cc->warning_cnt++;
}

U0 @system_print_warn(U8 *fmt, ...) { // Print "Warn:" and msg in blinking red.
  if (!MemCmp(fmt, "Unused var", 10))
    return; // suppress "Unused var" warnings
  if (!MemCmp(fmt, "Using 64-bit reg var.", 21))
    return; // suppress "Using 64-bit reg var." warnings
  U8 *buf = StrPrintJoin(NULL, fmt, argc, argv);
  GetOutOfDollar;
  "%,p %,p %,p %,p " ST_WARN_ST "%s", Caller, Caller(2), Caller(3), Caller(4),
      buf;
  Free(buf);
}

Function.Patch(&LexWarn, &@system_lex_warn);
Function.Patch(&PrintWarn, &@system_print_warn);

U8 *@system_build_info() { return System.build_info; }

U0 @system_log(CTask *task, U8 *fmt, ...) {
  U8 *buf = StrPrintJoin(NULL, fmt, argc, argv);
  U8 *str = buf;
  U32 color;
  MemCpyU32(&color, &task->task_name, 1);
  if (!color) {
    color = RandU32 * 1048576;
    MemCpyU32(&task->pad, &color, 1);
  }
  U8 *log_msg = MAlloc(1024);
  StrPrint(log_msg, "[\x1b[38;2;%d;%d;%dm%16s\x1b[0m] %s\n",
           color.u8[3] << 5 & 0xFF, color.u8[2] << 4 & 0xFF,
           color.u8[1] << 3 & 0xFF, Fs->task_name, buf);
  FifoI64Ins(System.log_fifo, log_msg);
  Free(buf);
}

U0 @system_log_task() {
  I64 log_msg;
  while (1) {
    while (FifoI64Cnt(System.log_fifo)) {
      FifoI64Rem(System.log_fifo, &log_msg);
      "%s", log_msg;
      Free(log_msg);
    }
    Sleep(1);
  }
}

U0 @system_power_off() {
  OutU16(0x4004, 0x3400);
  OutU16(0x0604, 0x2000);
  OutU16(0xB004, 0x2000);
}

U0 @system_init() {
  System.build_info = FileRead("build_info.TXT");
  System.log_fifo = FifoI64New(1024);
  Spawn(&@system_log_task, , , T(mp_cnt, 1, 0));
}

System.BuildInfo = &@system_build_info;
System.Init = &@system_init;
System.Log = &@system_log;
System.PowerOff = &@system_power_off;

System.Init();

"system ";
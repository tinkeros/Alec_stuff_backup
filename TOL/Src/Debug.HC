U0 @debug(U8 *fmt, ...) {
  U8 *buf = StrPrintJoin(NULL, fmt, argc, argv);
  PutS(buf);
  Free(buf);
}

U0 @vbox_debug_print(U8 *s) {
  while (*s)
    OutU8(0x504, *s++);
}
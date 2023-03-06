U0 @debug(U8 *fmt, ...) {
  U8 *buf = StrPrintJoin(NULL, fmt, argc, argv);
  PutS(buf);
  Free(buf);
}

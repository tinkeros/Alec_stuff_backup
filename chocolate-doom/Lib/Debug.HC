class Debug {
  Bool enabled;
  I64 bookmark;
  I64 counter;
};

Debug debug;
// debug.bookmark = 466900;
// debug.bookmark = 17000;
debug.bookmark = 1838479;
debug.counter = 0;
debug.enabled = FALSE;

U0 debug_print(U8 *fmt, ...) {
  if (!debug.enabled || debug.counter < debug.bookmark) {
    debug.counter++;
    return;
  }
  U8 *buf = StrPrintJoin(NULL, fmt, argc, argv);
  "[%05d] %s", debug.counter, buf;
  Free(buf);
  debug.counter++;
}

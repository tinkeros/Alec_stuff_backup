I64 @shell_cmd_clear(@shell *sh, I64 argc, U8 **argv) {
  if (argc > 1) {
    Stdio.WriteLine(sh, "esh: clear: too many arguments\n");
    return 1;
  }
  Stdio.WriteLine(sh, "\x1b[2J\x1b[0;0H");
  return 0;
}
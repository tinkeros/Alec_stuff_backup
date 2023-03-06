I64 @shell_cmd_echo(@shell *sh, I64 argc, U8 **argv) {
  I64 i;
  for (i = 1; i < argc; i++) {
    Stdio.WriteLine(sh, argv[i]);
    Stdio.WriteLine(sh, " ");
  }
  Stdio.WriteLine(sh, "\n");
  return 0;
}
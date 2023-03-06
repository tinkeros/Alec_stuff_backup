I64 @shell_cmd_open(@shell *sh, I64 argc, U8 **argv) {
  if (argc < 2) {
    Stdio.WriteLine(sh, "open: path required\n");
    return 1;
  }
  return @systemstarter_open(sh, argc, argv);
}
I64 @shell_cmd_sh(@shell *sh, I64 argc, U8 **argv) {
  return @shell_cmd_esh(sh, argc, argv);
}
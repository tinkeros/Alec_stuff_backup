I64 @shell_cmd_esh(@shell *sh, I64 argc, U8 **argv) {
  @shell_input_loop(sh);
  return 0;
}
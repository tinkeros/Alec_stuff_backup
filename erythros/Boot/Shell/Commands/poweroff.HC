I64 @shell_cmd_poweroff(@shell *sh, I64 argc, U8 **argv) {
  System.PowerOff();
  return 0;
}
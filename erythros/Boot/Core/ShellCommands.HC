I64 @shell_cmd_clear(@shell *sh, I64 argc, U8 **argv) {
  if (argc > 1) {
    Stdio.WriteLine(sh, "esh: clear: too many arguments\n");
    return 1;
  }
  Stdio.WriteLine(sh, "\x1b[2J\x1b[0;0H");
  return 0;
}

I64 @shell_cmd_echo(@shell *sh, I64 argc, U8 **argv) {
  I64 i;
  for (i = 1; i < argc; i++) {
    Stdio.WriteLine(sh, argv[i]); // TODO: Environment variables
    Stdio.WriteLine(sh, " ");
  }
  Stdio.WriteLine(sh, "\n");
  return 0;
}

I64 @shell_cmd_esh(@shell *sh, I64 argc, U8 **argv) {
  @shell_input_loop(sh);
  return 0;
}

I64 @shell_cmd_poweroff(@shell *sh, I64 argc, U8 **argv) {
  System.PowerOff();
  return 0;
}

I64 @shell_cmd_reboot(@shell *sh, I64 argc, U8 **argv) {
  Reboot;
  return 0;
}

I64 @shell_cmd_sh(@shell *sh, I64 argc, U8 **argv) {
  return @shell_cmd_esh(sh, argc, argv);
}

"shellcommands ";
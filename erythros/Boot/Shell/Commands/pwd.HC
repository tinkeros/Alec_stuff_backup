I64 @shell_cmd_pwd(@shell *sh, I64 argc, U8 **argv) {
  U8 buf[512];
  StrPrint(&buf, "%s\n", &sh->cwd);
  Stdio.WriteLine(sh, &buf);
  return 0;
}
I64 @shell_cmd_history(@shell *sh, I64 argc, U8 **argv) {
  I64 i;
  I64 j;
  U8 buf[512];
  for (i = 0; i < sh->history.pos; i++) {
    StrPrint(&buf, "%05d  %s\n", i + 1, sh->history.entries[i]);
    j = 0;
    while (buf[j] == '0')
      buf[j++] = ' ';
    Stdio.WriteLine(sh, &buf);
  }
  return 0;
}
class @stdio {
  U0 (*ReadLine)(@shell * sh, U8 * str);
  U0 (*WriteLine)(@shell * sh, U8 * str);
};

U0 @stdio_write_line(@shell *sh, U8 *str) {
  if (!str || !sh->output)
    return;
  I64 i;
  for (i = 0; i < StrLen(str); i++)
    FifoU8Ins(sh->output, str[i]);
}

U0 @stdio_read_line(@shell *sh, U8 *str) {
  U8 char = NULL;
  U8 line[4096];
  I64 pos = 0;
  if (!str)
    return;
  while (char != '\x3' && char != '\n') {
    while (FifoU8Cnt(sh->input)) {
      FifoU8Rem(sh->input, &char);
      switch (char) {
      case 3:
        @stdio_write_line(sh, "^C");
        break;
      case 8:
        if (pos > 0) {
          line[StrLen(line) - 1] = NULL;
          FifoU8Ins(sh->output, '\x8');
          pos--;
        } else
          FifoU8Ins(sh->output, '\x7');
        break;
      case 13:
        break;
      case 27:
        break;
      case 32...127:
        line[pos] = char;
        FifoU8Ins(sh->output, char);
        pos++;
        break;
      };
    }
    Sleep(1);
  }
  line[pos] = NULL;
  switch (char) {
  case '\x3':
    StrCpy(str, "");
    break;
  case '\n':
    StrCpy(str, &line);
    break;
  };
  FifoU8Ins(sh->output, '\n');
}

@stdio Stdio;

Stdio.ReadLine = &@stdio_read_line;
Stdio.WriteLine = &@stdio_write_line;

"stdio ";
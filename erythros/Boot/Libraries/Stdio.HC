class @stdio {
  U0 (*ReadLine)(@shell * sh, U8 * str);
  U0 (*WriteLine)(@shell * sh, U8 * str);
};

U0 @stdio_write_line(@shell *sh, U8 *str) {
  if (!sh)
    return;
  if (!str || !sh->output)
    return;
  I64 i;
  for (i = 0; i < StrLen(str); i++)
    FifoU8Ins(sh->output, str[i]);
}

I64 @stdio_handle_control_chars(@shell *sh) {
  if (!FifoU8Cnt(sh->input))
    return 0;
  U8 char;
  FifoU8Rem(sh->input, &char);
  switch (char) {
  case '[':
    if (!FifoU8Cnt(sh->input))
      return 0;
    FifoU8Rem(sh->input, &char);
    switch (char) {
    case 'A':
      return SC_CURSOR_UP;
      break;
    case 'B':
      return SC_CURSOR_DOWN;
      break;
    case 'D':
      return SC_CURSOR_LEFT;
      break;
    case 'C':
      return SC_CURSOR_RIGHT;
      break;
    default:
      return 0;
      break;
    }
    break;
  default:
    return 0;
    break;
  }
}

U0 @stdio_read_line_history_back(@shell *sh, I64 pos) {
  if (sh->history.index < 0)
    sh->history.index = 0;
  while (pos > 0) {
    FifoU8Ins(sh->input, '\x8');
    pos--;
  }
  U8 *char = sh->history.entries[sh->history.index];
  while (*char)
    FifoU8Ins(sh->input, *char ++);
  if (sh->history.index > -1) {
    sh->history.index--;
  }
}

U0 @stdio_read_line_history_fwd(@shell *sh, I64 pos) {
  if (sh->history.index < sh->history.pos) {
    sh->history.index++;
  }
  if (sh->history.index > sh->history.pos)
    sh->history.index = sh->history.pos;
  while (pos > 0) {
    FifoU8Ins(sh->input, '\x8');
    pos--;
  }
  U8 *char = sh->history.entries[sh->history.index];
  while (*char)
    FifoU8Ins(sh->input, *char ++);
}

U0 @stdio_read_line(@shell *sh, U8 *str) {
  U8 char = NULL;
  U8 line[4096];
  I64 pos = 0;
  if (!str || !sh)
    return;
  sh->history.index = sh->history.pos - 1;
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
        switch (@stdio_handle_control_chars(sh)) {
        case SC_CURSOR_UP:
          @stdio_read_line_history_back(sh, pos);
          break;
        case SC_CURSOR_DOWN:
          @stdio_read_line_history_fwd(sh, pos);
          break;
        default:
          break;
        }
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
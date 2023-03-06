U0 @dbg_put_char(I64 ch) {
  OutU8(0x504, ch);
  if (!System.text_mode)
    return;
  Context2D *fb = Graphics2D.FrameBufferContext2D();
  text.raw_flags &= ~RWF_SHOW_DOLLAR;
  if (ch > '~' && ch != 219)
    ch = ' ';
  I64 row, col;
  if (!(text.raw_flags & RWF_SHOW_DOLLAR)) {
    if (ch == '$$') {
      if (text.raw_flags & RWF_IN_DOLLAR) {
        text.raw_flags &= ~RWF_IN_DOLLAR;
        if (!(text.raw_flags & RWF_LAST_DOLLAR)) {
          text.raw_flags &= ~RWF_LAST_DOLLAR;
          return;
        }
      } else {
        text.raw_flags |= RWF_IN_DOLLAR | RWF_LAST_DOLLAR;
        return;
      }
    }
    text.raw_flags &= ~RWF_LAST_DOLLAR;
    if (text.raw_flags & RWF_IN_DOLLAR)
      return;
  }
  if (ch == '\t') {
    @dbg_put_char(CH_SPACE);
    while (text.raw_col & 7)
      @dbg_put_char(CH_SPACE);
  } else if (ch == CH_BACKSPACE) {
    text.raw_col--;
    @dbg_put_char(CH_SPACE);
    text.raw_col--;
  } else if (ch == '\n') {
    @dbg_put_char(CH_SPACE);
    while (text.raw_col % text.cols)
      @dbg_put_char(CH_SPACE);
  } else if (Bt(char_bmp_displayable, ch)) {
    row = text.raw_col / text.cols % text.rows;
    col = text.raw_col % text.cols;
    if (text.raw_flags & RWF_SCROLL && text.raw_col && !row && !col) {
      CopyRect2D(fb, 0, -16, fb);
      Rect2D(fb, 0, Display.Height() - 16, Display.Width(), 16, 0x0);
      text.raw_col -= text.cols;
      row = text.rows - 1;
    }
    ConsolePrint2D(fb, col * 8, row * 16, , , "%c", ch);
    text.raw_col++;
  }
}

Bool @kd_raw_putkey(I64 ch, I64) {
  if (IsRaw) {
    @dbg_put_char(ch);
    return TRUE;
  } else
    return FALSE;
}

Bool @kd_raw_puts(U8 *st) {
  I64 ch;
  if (IsRaw) {
    while (ch = *st++)
      @dbg_put_char(ch);
    return TRUE;
  } else
    return FALSE;
}

U0 @rawdr_dummy(CTask *) {}

CKeyDevEntry *tmp_kde = keydev.put_key_head;
while (tmp_kde->put_s != &KDRawPutS)
  tmp_kde = tmp_kde->next;
tmp_kde->put_key = &@kd_raw_putkey;
tmp_kde->put_s = &@kd_raw_puts;

Function.Patch(&RawDr, &@rawdr_dummy);

"rawtext ";
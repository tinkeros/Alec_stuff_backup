tmpdoc = DocNew;
origdoc = Fs->put_doc;
Fs->put_doc = tmpdoc;

U0 DbgPlot2D(I64 x, I64 y, U32 color) {
  U64 i = Display.fb;
  I64 pos = (Display.width * y) * Display.bpp / 8;
  pos += x * Display.bpp / 8;
  (i + pos)(U8 *)[0] = color.u8[1];
  (i + pos)(U8 *)[1] = color.u8[2];
  (i + pos)(U8 *)[2] = color.u8[3];
}

U0 DbgChar2D(I64 x, I64 y, I64 ch, U32 fg = 0xFFFFFF00, U32 bg = BLACK) {
  U64 *char = sys_font_std;
  I64 xx, yy;
  I64 ii = 0;
  for (yy = 0; yy < 8; yy++) {
    xx = 0;
    for (xx = 0; xx < 8; xx++) {
      if (char[ch].u8[ii] & 1 << xx) {
        DbgPlot2D(x + xx, y + yy, fg);
      } else {
        DbgPlot2D(x + xx, y + yy, bg);
      }
    }
    ii++;
    if (ii > 8) {
      ch++;
      ii = 0;
    }
  }
}

U0 DbgPutChar(I64 ch) {
  // OutU8(0x3F8, ch);
  // Busy(20);
  if (!IsSingleUser) {
    return;
  };
  text.raw_flags &= ~RWF_SHOW_DOLLAR;
  if (ch > '~' && ch != 219) {
    ch = ' ';
  }
  I64 i, row, col;
  I64 raw_pos;
  I64 raw_y;
  U8 *ptr, *ptr1, *ptr2;

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
    DbgPutChar(CH_SPACE);
    while (text.raw_col & 7)
      DbgPutChar(CH_SPACE);
  } else if (ch == CH_BACKSPACE) {
    text.raw_col--;
    DbgPutChar(CH_SPACE);
    text.raw_col--;
  } else if (ch == '\n') {
    DbgPutChar(CH_SPACE);
    while (text.raw_col % text.cols)
      DbgPutChar(CH_SPACE);

  } else if (Bt(char_bmp_displayable, ch)) {
    row = text.raw_col / text.cols % text.rows;
    col = text.raw_col % text.cols;
    if (text.raw_flags & RWF_SCROLL && text.raw_col && !row && !col) {
      for (raw_y = 0; raw_y < (text.rows * 8) - 8; raw_y++) {
        MemCpy(Display.fb + (raw_y * Display.width * (Display.bpp / 8)),
               Display.fb + ((raw_y + 8) * Display.width * (Display.bpp / 8)),
               (text.cols * 8) * (Display.bpp / 8));
      }
      for (raw_y = (text.rows * 8) - 8; raw_y < (text.rows * 8); raw_y++) {
        MemSet(Display.fb + (raw_y * Display.width * (Display.bpp / 8)), 0,
               (text.cols * 8) * (Display.bpp / 8));
      }
      text.raw_col -= text.cols;
      row = text.rows - 1;
    }
    DbgChar2D(col * 8, row * 8, ch);
    text.raw_col++;
  }
}

Bool EKDRawPutKey(I64 ch, I64) {
  if (IsRaw) {
    DbgPutChar(ch);
    return TRUE;
  } else
    return FALSE;
}

Bool EKDRawPutS(U8 *st) {
  I64 ch;
  if (IsRaw) {
    while (ch = *st++)
      DbgPutChar(ch);
    return TRUE;
  } else
    return FALSE;
}

U0 RawDrNull(CTask *task = NULL) {}

CKeyDevEntry *tmp_kde = keydev.put_key_head;
while (tmp_kde->put_s != &KDRawPutS) {
  tmp_kde = tmp_kde->next;
}
tmp_kde->put_key = &EKDRawPutKey;
tmp_kde->put_s = &EKDRawPutS;

MemCpy(&RawDr, &RawDrNull, sizeof(RawDrNull));

Bool Debug = FALSE;
U0 resume() {
  Debug = FALSE;
  G2;
};

Fs->put_doc = origdoc;
DocDel(tmpdoc);
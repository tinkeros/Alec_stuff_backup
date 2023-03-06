#include "T:/Include/Gui"; // kludge

#define DS_LINE_LEN 512
#define DS_SYNTAX_HOLYC 1

#define DS_TOKEN_CONSUME 0
#define DS_TOKEN_CONSUME_COMMENT 1
#define DS_TOKEN_CONSUME_ML_COMMENT 2

#exe {
StreamPrint("#define DS_APP_FOLDER \"/home/%s/repos/DevStudio.app\"\n",
            Compositor.session.user.name);
}

class @ds_buffer {
  U8 **lines;
  I64 rows;
  I64 alloced;
};

class @ds_pos {
  I64 x;
  I64 y;
};

class @ds_origin {
  I64 row;
  I64 col;
};

class @ds_syntax {
  I64 state;
  I64 type;
}

class @ds_editor {
  @ds_buffer buffer;
  @ds_origin origin;
  @ds_pos pos;
  @ds_syntax syntax;
  U8 filename[512];
  U8 scratch_buf[DS_LINE_LEN];
};

class @ds_resource {
  U8 *data;
  I64 size;
};

class @ds_icon {
  Context2D *blur;
  Context2D *hover;
};

Context2D *ds_pointer;

Bool window_maximized = FALSE;
Bool overwrite = FALSE;
I64 vscroll_trough_height = NULL;
Window *modal_window = NULL;

@window_origin window_state;

@ds_editor ed;

U0 @ds_free_resource(@ds_resource *res) {
  if (res->data)
    Free(res->data);
  if (res)
    Free(res);
}

@ds_resource *@ds_load_resource(U8 *path) {
  @ds_resource *res = CAlloc(sizeof(@ds_resource));
  res->data = FileSystem.ReadFile(path, &res->size);
  return res;
}

Context2D *@ds_context2d_from_png(U8 *path) {
  @ds_resource *res = @ds_load_resource(path);
  Context2D *ctx = PNG.BufferToContext2D(res->data, res->size);
  @ds_free_resource(res);
  return ctx;
}

Window *win = Compositor.CreateWindow(256, 256, 920, 532, WIN_FLAGS_DEFAULT);

Window *modal_goto = Compositor.CreateWindow(
    -999, -999, 256, 32, WIN_FLAGS_NOHILIGHT | WIN_FLAGS_SKIP);
Compositor.HideWindow(modal_goto);
TextLabelWidget *lbl_gotoline = Gui.CreateWidget(
    modal_goto, WIDGET_TYPE_LABEL, 4, -8 + modal_goto->height / 2, 192, 24);
Gui.Widget.SetFont(lbl_gotoline, "Eight Bit Dragon");
Gui.Widget.SetText(lbl_gotoline, "Go to line: ");
TextInputWidget *txt_gotoline =
    Gui.CreateWidget(modal_goto, WIDGET_TYPE_INPUT, 76,
                     -13 + modal_goto->height / 2, modal_goto->width - 88, 24);
Gui.Widget.SetFont(txt_gotoline, "Eight Bit Dragon");
Gui.Widget.SetText(txt_gotoline, "");

U0 @ds_load_file(@ds_editor *ed, U8 *filename) {
  I64 i;
  I64 size = NULL;
  U8 *buf = NULL;
  U8 buf2[512];
  if (filename)
    buf = FileSystem.ReadFile(filename, &size);
  I64 split_lines_cnt = 0;
  U8 **split_lines = NULL;
  if (buf)
    split_lines = String.Split(buf, '\n', &split_lines_cnt);
  ed->syntax.type = DS_SYNTAX_HOLYC;
  ed->pos.x = 0;
  ed->pos.y = 0;
  ed->origin.row = 0;
  ed->origin.col = 0;
  ed->buffer.rows = split_lines_cnt;
  ed->buffer.alloced = CeilI64(split_lines_cnt, 128);
  ed->buffer.lines = CAlloc(sizeof(U64) * ed->buffer.alloced);
  if (split_lines)
    for (i = 0; i < split_lines_cnt; i++) {
      ed->buffer.lines[i] = CAlloc(DS_LINE_LEN);
      StrCpy(ed->buffer.lines[i], split_lines[i]);
    }
  else
    ed->buffer.lines[0] = CAlloc(DS_LINE_LEN);
  ed->buffer.rows = Max(1, split_lines_cnt);
  Free(buf);
  StrPrint(&buf2, "DevStudio - %s", StrLastOcc(filename, "/") + 1);
  Gui.Window.SetTitle(win, &buf2);
}

U0 @ds_save_file(@ds_editor *ed, U8 *filename) {
  I64 i;
  I64 buf_size = 0;
  for (i = 0; i < ed->buffer.rows; i++)
    buf_size += StrLen(ed->buffer.lines[i]);
  buf_size += ed->buffer.rows * 16;
  buf_size += CeilI64(buf_size, 128);
  U8 *buf = CAlloc(buf_size);
  for (i = 0; i < ed->buffer.rows; i++) {
    String.Append(buf, ed->buffer.lines[i]);
    String.Append(buf, "\n");
  }
  buf[StrLen(buf) - 1] = NULL;
  FileSystem.WriteFile(filename, buf, StrLen(buf));
  Free(buf);
}

Context2DWidget *cw_panel =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 0, 0, 48, Display.Height());
cw_panel->ctx = NewContext2D(cw_panel->width, cw_panel->height);
Fill2D(cw_panel->ctx, Color(38, 54, 71));

Context2DWidget *cw_doc =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 8, 8, 32, 42);
Context2DWidget *cw_find =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 8, 16 + 32, 32, 42);
Context2DWidget *cw_src =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 8, 24 + 64, 32, 42);
Context2DWidget *cw_settings =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 8, 32 + 96, 32, 42);

@ds_icon icon_doc;
@ds_icon icon_find;
@ds_icon icon_src;
@ds_icon icon_settings;

icon_doc.blur = @ds_context2d_from_png(DS_APP_FOLDER "/doc.png");
icon_find.blur = @ds_context2d_from_png(DS_APP_FOLDER "/find.png");
icon_src.blur = @ds_context2d_from_png(DS_APP_FOLDER "/src.png");
icon_settings.blur = @ds_context2d_from_png(DS_APP_FOLDER "/settings.png");

icon_doc.hover = @ds_context2d_from_png(DS_APP_FOLDER "/doc_hover.png");
icon_find.hover = @ds_context2d_from_png(DS_APP_FOLDER "/find_hover.png");
icon_src.hover = @ds_context2d_from_png(DS_APP_FOLDER "/src_hover.png");
icon_settings.hover =
    @ds_context2d_from_png(DS_APP_FOLDER "/settings_hover.png");

cw_doc->ctx = icon_doc.blur;
cw_find->ctx = icon_find.blur;
cw_src->ctx = icon_src.blur;
cw_settings->ctx = icon_settings.blur;

cw_doc->pointer = Compositor.theme.pointer.link;
cw_find->pointer = Compositor.theme.pointer.link;
cw_src->pointer = Compositor.theme.pointer.link;
cw_settings->pointer = Compositor.theme.pointer.link;

Context2DWidget *cw_file_explorer = Gui.CreateWidget(
    win, WIDGET_TYPE_CONTEXT2D, cw_panel->x + cw_panel->width + 4, 0, 256,
    Display.Height());
cw_file_explorer->ctx =
    NewContext2D(cw_file_explorer->width, cw_file_explorer->height);
Fill2D(cw_file_explorer->ctx, Color(38, 54, 71));

TextLabelWidget *label1 =
    Gui.CreateWidget(win, WIDGET_TYPE_LABEL, cw_file_explorer->x + 4,
                     cw_file_explorer->y + 2, 192, 24);
label1->color = Color(255, 255, 255);
Gui.Widget.SetText(label1, "OPEN EDITORS");

TerminalWidget *t =
    Gui.CreateWidget(win, WIDGET_TYPE_TERMINAL,
                     cw_file_explorer->x + cw_file_explorer->width + 4, 0,
                     Display.Width(), Display.Height());
CFifoU8 *tmp_fifo_u8 = t->input;
t->input = FifoU8New(1048576 * 4);
FifoU8Del(tmp_fifo_u8);

VerticalScrollBarWidget *vscroll =
    Gui.CreateWidget(win, WIDGET_TYPE_VERT_SCROLLBAR, 0, 0, 20, 128);
vscroll->height = 128;

@shell *sh = CAlloc(sizeof(@shell));
sh->env = CAlloc(sizeof(@shell_env_var));
sh->history.limit = SHELL_HISTORY_LIMIT;
sh->history.pos = 0;
sh->history.entries = CAlloc(sizeof(U64) * SHELL_HISTORY_LIMIT);
sh->input = FifoU8New(SHELL_INPUT_FIFO_SIZE);
sh->session = &Compositor.session;
t->output = sh->input;
sh->output = t->input;

t->color.background = Color(38, 54, 71);
t->cursor.hidden = TRUE;
t->pointer = Compositor.theme.pointer.text;

Context2DWidget *ds_cursor =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 0, 0, 8, 16);
ds_cursor->ctx = NewContext2D(2, 16);
Line2D(ds_cursor->ctx, 0, 0, 0, 16, Color(200, 200, 255));
Line2D(ds_cursor->ctx, 1, 0, 1, 16, Color(200, 200, 255));

TextLabelWidget *label_ins_mode =
    Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 0, 0, 16, 24);
Gui.Widget.SetText(label_ins_mode, "");

TextLabelWidget *label_line_col =
    Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 0, 0, 16, 24);
Gui.Widget.SetText(label_line_col, "");

U0 @ds_update_ins_mode() {
  label_ins_mode->x = win->width - 40;
  label_ins_mode->y = win->height - 40;
  switch (overwrite) {
  case TRUE:
    Gui.Widget.SetText(label_ins_mode, "OVR");
    Gui.Window.Refresh(win);
    break;
  case FALSE:
    Gui.Widget.SetText(label_ins_mode, "INS");
    Gui.Window.Refresh(win);
    break;
  }
}

U0 @ds_realign_cursor(@ds_editor *ed) {
  if (ed->pos.x > StrLen(ed->buffer.lines[ed->origin.row + ed->pos.y]))
    ed->pos.x = StrLen(ed->buffer.lines[ed->origin.row + ed->pos.y]);
}

U0 @ds_window_close(Window *win) {
  Compositor.UnregisterForGlobalInputEvents(win);
  Compositor.DestroyWindow(win);
  Compositor.DestroyWindow(modal_goto);
}

U0 @ds_redraw_line_number(@ds_editor *ed, I64 row) {
  I64 i;
  U8 buf[8];
  FifoU8Cpy(t->input, "\x1b[38;5;151m");
  StrPrint(&buf, "%05d  ", row + 1);
  i = 0;
  while (buf[i] == '0') {
    buf[i] = ' ';
    i++;
  }
  for (i = 0; i < 7; i++)
    FifoU8Ins(t->input, buf[i]);
  FifoU8Cpy(t->input, "\x1b[38;5;251m");
}

I64 @ds_highlight_symbol(U8 *str) {
  I64 i;
  CHashTable *lookup_table;
  CHashSrcSym *lookup_symbol;
  if (str[0] == '#')
    str++;
  lookup_table = adam_task->hash_table;
  while (lookup_table) {
    for (i = 0; i < lookup_table->mask; i++) {
      lookup_symbol = lookup_table->body[i];
      while (lookup_symbol) {
        if (!StrCmp(lookup_symbol->str, str)) {
          if (lookup_symbol->type & HTT_KEYWORD)
            return 93;
          if (lookup_symbol->type & HTT_CLASS ||
              lookup_symbol->type & HTT_ASM_KEYWORD ||
              lookup_symbol->type & HTT_INTERNAL_TYPE)
            return 105;
          if (lookup_symbol->type & HTT_GLBL_VAR)
            return 104;
          if (lookup_symbol->type & HTT_FUN ||
              lookup_symbol->type & HTT_DEFINE_STR)
            return 112;
        }
        lookup_symbol = lookup_symbol->next;
      }
    }
    lookup_table = lookup_table->next;
  }
  if (String.IsNumber(str))
    return 172;
  return NULL;
}

U0 @ds_process_fragment(@ds_editor *ed, U8 *str, I64 i) {
  U8 buf[512];
  if (!StrLen(str))
    return;
  I64 color = @ds_highlight_symbol(str);
  if (color) {
    StrPrint(&buf, "\x1b[38;5;%dm", color);
    if (i >= ed->origin.row)
      FifoU8Cpy(t->input, &buf);
  }
  if (i >= ed->origin.row)
    FifoU8Cpy(t->input, str);
  if (color)
    FifoU8Cpy(t->input, "\x1b[38;5;251m");
  StrCpy(str, "");
}

U0 @ds_syntax_highlight(@ds_editor *ed) {
  U8 char[2];
  U8 buf[512];
  U8 consumed[512];
  // Render up to visible row_cnt
  I64 visible_row_cnt = (win->height - t->y - 40) / 16;
  I64 visible_col_cnt = (win->width - t->x) / 8);
  I64 i;
  I64 j;
  I64 last_fg_col = 251;
  I64 token;

  ed->syntax.state = DS_TOKEN_CONSUME;
  StrCpy(&consumed, "");

  i = T(ed->origin.row > visible_row_cnt, ed->origin.row - 4, 0);
  while (i < ed->origin.row + visible_row_cnt && i < ed->buffer.rows) {
    j = 0;
    if (i >= ed->origin.row)
      @ds_redraw_line_number(ed, i);
    StrPrint(&buf, "\x1b[38;5;%dm", last_fg_col);
    if (i >= ed->origin.row)
      FifoU8Cpy(t->input, &buf);
    while (ed->buffer.lines[i][j]) {
      token = ed->buffer.lines[i][j];
      switch (ed->syntax.state) {
      case DS_TOKEN_CONSUME_ML_COMMENT:
        switch (token) {
        case '*':
          if (ed->buffer.lines[i][j + 1] == '/') {
            String.Append(&consumed, "*/");
            if (i >= ed->origin.row) {
              FifoU8Cpy(t->input, &consumed);
              StrCpy(&consumed, "");
              FifoU8Cpy(t->input, "\x1b[38;5;251m");
              ed->syntax.state = DS_TOKEN_CONSUME;
              last_fg_col = 251;
              j++;
            }
          } else
            String.Append(&consumed, "%c", token);
          break;
        default:
          String.Append(&consumed, "%c", token);
          break;
        }
        break;
      case DS_TOKEN_CONSUME_COMMENT:
        String.Append(&consumed, "%c", token);
        break;
      case DS_TOKEN_CONSUME:
        switch (token) {
        case '/':
          if (ed->buffer.lines[i][j + 1] == '/')
            if (i >= ed->origin.row) {
              FifoU8Cpy(t->input, "\x1b[38;5;240m");
              ed->syntax.state = DS_TOKEN_CONSUME_COMMENT;
            }
          if (ed->buffer.lines[i][j + 1] == '*')
            if (i >= ed->origin.row) {
              FifoU8Cpy(t->input, "\x1b[38;5;240m");
              ed->syntax.state = DS_TOKEN_CONSUME_ML_COMMENT;
              last_fg_col = 240;
            }
          String.Append(&consumed, "%c", token);
          break;
        case ' ':
        case '(':
        case ')':
        case '.':
        case ':':
        case ';':
        case ',':
          @ds_process_fragment(ed, &consumed, i);
          if (i >= ed->origin.row)
            FifoU8Ins(t->input, token);
          break;
        case '+':
        case '-':
        case '*':
        case '|':
        case '!':
        case '=':
          @ds_process_fragment(ed, &consumed, i);
          if (i >= ed->origin.row) {
            FifoU8Cpy(t->input, "\x1b[38;5;132m");
            FifoU8Ins(t->input, token);
            FifoU8Cpy(t->input, "\x1b[38;5;251m");
          }
          break;
        default:
          String.Append(&consumed, "%c", token);
          break;
        }
        break;
      }
      j++;
    }
    @ds_process_fragment(ed, &consumed, i);
    if (i >= ed->origin.row)
      FifoU8Ins(t->input, '\n');
    if (ed->syntax.state == DS_TOKEN_CONSUME_COMMENT)
      ed->syntax.state = DS_TOKEN_CONSUME;
    i++;
  }
}

U0 @ds_redraw_document_lines(@ds_editor *ed) {
  I64 i;
  I64 j;
  U8 buf[512];
  I64 visible_row_cnt = (win->height - t->y - 40) / 16;
  I64 visible_col_cnt = (win->width - t->x) / 8);

  FifoU8Cpy(t->input, "\x1b[2J\x1b[0H"); // Reset terminal

  if (ed->syntax.type)
    @ds_syntax_highlight(ed);
  else {
    for (i = ed->origin.row;
         i < ed->origin.row + visible_row_cnt && i < ed->buffer.rows; i++) {
      @ds_redraw_line_number(ed, i);
      for (j = ed->origin.col; j < ed->origin.col + visible_col_cnt; j++) {
        if (ed->buffer.lines[i][j])
          FifoU8Ins(t->input, ed->buffer.lines[i][j]);
        else {
          j = ed->origin.col + visible_col_cnt;
        }
      }
      FifoU8Ins(t->input, '\n');
    }
  }
}

U0 @ds_window_toggle_max(Window *win) {
  switch (window_maximized) {
  case FALSE:
    window_state.x = win->x;
    window_state.y = win->y;
    window_state.width = win->width;
    window_state.height = win->height;
    win->x = 0;
    win->y = 32;
    win->width = Display.Width() - 2;
    win->height = Display.Height() - 33;
    break;
  case TRUE:
    win->x = window_state.x;
    win->y = window_state.y;
    win->width = window_state.width;
    win->height = window_state.height;
    break;
  }
  window_maximized = !window_maximized;
  @ds_redraw_document_lines(&ed);
  Gui.Window.Refresh(win);
}

U0 @ds_set_sidebar_icon(Context2DWidget *widget, @ds_icon *icon) {
  if (Gui.Widget.IsHovered(win, widget)) {
    widget->ctx = icon->hover;
    ds_pointer = Compositor.theme.pointer.link;
  } else
    widget->ctx = icon->blur;
}

U0 @ds_insert_char(@ds_editor *ed, I64 ch) {
  if (ch < 32)
    return;
  MemSet(&ed->scratch_buf, 0, DS_LINE_LEN);
  if (overwrite) {
    StrCpy(&ed->scratch_buf, ed->buffer.lines[ed->origin.row + ed->pos.y]);
    ed->scratch_buf[ed->origin.col + ed->pos.x] = ch;
    StrCpy(ed->buffer.lines[ed->origin.row + ed->pos.y], &ed->scratch_buf);
    ed->pos.x++;
  } else {
    MemCpy(&ed->scratch_buf, ed->buffer.lines[ed->origin.row + ed->pos.y],
           ed->origin.col + ed->pos.x);
    String.Append(&ed->scratch_buf, "%c", ch);
    String.Append(&ed->scratch_buf,
                  ed->buffer.lines[ed->origin.row + ed->pos.y] +
                      ed->origin.col + ed->pos.x);
    StrCpy(ed->buffer.lines[ed->origin.row + ed->pos.y], &ed->scratch_buf);
    ed->pos.x++;
  }
  @ds_redraw_document_lines(ed);
  Gui.Window.Refresh(win);
}

U0 @ds_delete_line(@ds_editor *ed, I64 line) {
  U8 *prev_line = ed->buffer.lines[line];
  MemCpyU64(&ed->buffer.lines[line], &ed->buffer.lines[line + 1],
            ed->buffer.rows - line);
  ed->buffer.rows--;
  Free(prev_line);
}

U0 @ds_backspace_char(@ds_editor *ed, Bool overwrite) {
  I64 prev_pos_x;
  MemSet(&ed->scratch_buf, 0, DS_LINE_LEN);
  if (ed->pos.x > 0) {
    MemCpy(&ed->scratch_buf, ed->buffer.lines[ed->origin.row + ed->pos.y],
           ed->origin.col + ed->pos.x - 1);
    String.Append(&ed->scratch_buf,
                  ed->buffer.lines[ed->origin.row + ed->pos.y] +
                      ed->origin.col + ed->pos.x);
    StrCpy(ed->buffer.lines[ed->origin.row + ed->pos.y], &ed->scratch_buf);
    ed->pos.x--;
  } else {
    if (ed->origin.row + ed->pos.y > 0) {
      StrCpy(&ed->scratch_buf,
             ed->buffer.lines[ed->origin.row + ed->pos.y - 1]);
      ed->origin.col = 0;
      prev_pos_x = ed->pos.x;
      ed->pos.x = StrLen(&ed->scratch_buf);
      String.Append(&ed->scratch_buf,
                    ed->buffer.lines[ed->origin.row + ed->pos.y] +
                        ed->origin.col + prev_pos_x);
      StrCpy(ed->buffer.lines[ed->origin.row + ed->pos.y - 1],
             &ed->scratch_buf);
      @ds_delete_line(ed, ed->origin.row + ed->pos.y);
      ed->pos.y--;
    }
  }
  @ds_redraw_document_lines(ed);
  Gui.Window.Refresh(win);
}

U0 @ds_enter_char(@ds_editor *ed) {
  I64 i;
  I64 visible_row_cnt = (win->height - t->y - 40) / 16;
  ed->buffer.rows++;
  if (ed->buffer.rows > ed->buffer.alloced) {
    ed->buffer.alloced = CeilI64(ed->buffer.rows, 128);
    U8 **new_buf = CAlloc(sizeof(U64) * ed->buffer.alloced);
    U8 **old_buf = ed->buffer.lines;
    MemCpyU64(new_buf, ed->buffer.lines, ed->buffer.rows);
    ed->buffer.lines = new_buf;
    Free(old_buf);
  }
  for (i = ed->buffer.rows - 1; i > ed->origin.row + ed->pos.y; i--)
    ed->buffer.lines[i + 1] = ed->buffer.lines[i];
  ed->pos.y++;
  ed->buffer.lines[ed->origin.row + ed->pos.y] = CAlloc(DS_LINE_LEN);
  StrCpy(ed->buffer.lines[ed->origin.row + ed->pos.y],
         &ed->buffer.lines[ed->origin.row + ed->pos.y - 1]
                          [ed->origin.col + ed->pos.x]);
  ed->buffer.lines[ed->origin.row + ed->pos.y - 1][ed->origin.col + ed->pos.x] =
      NULL;
  ed->pos.x = 0;
  if (ed->pos.y > visible_row_cnt - 1) {
    ed->origin.row++;
    ed->pos.y--;
  }
  @ds_redraw_document_lines(ed);
  Gui.Window.Refresh(win);
}

U0 @ds_keypress_callback(Window *win, I64 key) {
  if (modal_goto == Compositor.active_win) {
    if (KeyDown(SC_ESC)) {
      Compositor.HideWindow(modal_goto);
      modal_window = NULL;
      Gui.Widget.SetText(txt_gotoline, "");
      Gui.Window.SetFocus(win);
    }
    if (KeyDown(SC_ENTER)) {
      I64 goto_row = Str2I64(&txt_gotoline->text);
      goto_row = Min(goto_row, ed.buffer.rows);
      ed.origin.row = goto_row - 1;
      ed.pos.x = 0;
      ed.pos.y = 0;
      Compositor.HideWindow(modal_goto);
      modal_window = NULL;
      Gui.Widget.SetText(txt_gotoline, "");
      Gui.Window.SetFocus(win);
      @ds_redraw_document_lines(&ed);
      @ds_realign_cursor(&ed);
      Gui.Window.Refresh(win);
      goto keypress_realign_cursor;
    }
    return;
  }
  if (win != Compositor.active_win)
    return;
  Bool go_to_end_of_line = FALSE;
  I64 ch;
  if (KeyDown(SC_CTRL)) {
    switch (ScanCode2Char(key)) {
    case 'g':
      modal_goto->x = win->x + (win->width / 2) - (modal_goto->width / 2);
      modal_goto->y = win->y + 26;
      modal_goto->focused_widget = txt_gotoline;
      Compositor.ShowWindow(modal_goto);
      modal_window = modal_goto;
      break;
    default:
      break;
    }
    return;
  }
  if (KeyDown(SC_F9)) {
    @ds_save_file(&ed, &ed.filename);
    return;
  }
  if (KeyDown(SC_ENTER)) {
    @ds_enter_char(&ed);
    goto keypress_realign_cursor;
  }
  if (KeyDown(SC_BACKSPACE)) {
    @ds_backspace_char(&ed, overwrite);
    goto keypress_realign_cursor;
  }
  if (KeyDown(SC_INS)) {
    overwrite = !overwrite;
    @ds_update_ins_mode;
    return;
  }
  I64 visible_row_cnt = (win->height - t->y - 40) / 16;
  I64 visible_col_cnt = (win->width - t->x) / 8);
  if (KeyDown(SC_PAGE_UP)) {
    if (ed.pos.y > 0)
      ed.pos.y = 0;
    else {
      ed.origin.row = Max(0, ed.origin.row - visible_row_cnt);
      @ds_redraw_document_lines(&ed);
    }
    goto keypress_realign_cursor;
  }
  if (KeyDown(SC_PAGE_DOWN)) {
    if (ed.pos.y < visible_row_cnt - 1) {
      ed.pos.y = visible_row_cnt - 1;
    } else {
      ed.origin.row += visible_row_cnt;
      while (ed.origin.row + visible_row_cnt > ed.buffer.rows)
        ed.origin.row--;
      @ds_redraw_document_lines(&ed);
    }
    goto keypress_realign_cursor;
  }
  if (KeyDown(SC_CURSOR_UP)) {
  event_cursor_up:
    ed.pos.y--;
    if (ed.pos.y < 0) {
      if (ed.origin.row > 0)
        ed.origin.row--;
      ed.pos.y = 0;
      @ds_redraw_document_lines(&ed);
    }
    if (go_to_end_of_line)
      while (ed.pos.x < StrLen(ed.buffer.lines[ed.origin.row + ed.pos.y]))
        ed.pos.x++;
    goto keypress_realign_cursor;
  }
  if (KeyDown(SC_CURSOR_DOWN)) {
  event_cursor_down:
    ed.pos.y++;
    if (ed.origin.row + ed.pos.y >= ed.buffer.rows) {
      ed.pos.y--;
      goto keypress_realign_cursor;
    }
    if (ed.pos.y > visible_row_cnt - 1) {
      ed.origin.row++;
      ed.pos.y--;
      @ds_redraw_document_lines(&ed);
    }
    goto keypress_realign_cursor;
  }
  if (KeyDown(SC_CURSOR_LEFT)) {
    ed.pos.x--;
    if (ed.pos.x < 0) {
      ed.pos.x = 0;
      if (ed.origin.row + ed.pos.y) {
        go_to_end_of_line = TRUE;
        goto event_cursor_up;
      }
    }
    goto keypress_realign_cursor;
  }
  if (KeyDown(SC_CURSOR_RIGHT)) {
    ed.pos.x++;
    if (ed.pos.x > StrLen(ed.buffer.lines[ed.origin.row + ed.pos.y])) {
      ed.pos.x = 0;
      goto event_cursor_down;
    }
    goto keypress_realign_cursor;
  }
  if (!KeyDown(SC_SHIFT)) {
    ch = NORMAL_KEY_SCAN_DECODE_TABLE(U8 *)[key];
  } else {
    if (key == 0x39) // Handle TempleOS SHIFT-SPACE character.
      ch = ' ';
    else {
      ch = SHIFT_KEY_SCAN_DECODE_TABLE(U8 *)[key];
    }
  };
  @ds_insert_char(&ed, ch);
keypress_realign_cursor:
  @ds_realign_cursor(&ed);
  ds_cursor->x = t->x + 2 + (8 * (ed.pos.x + 7));
  ds_cursor->y = t->y + 2 + (16 * ed.pos.y);
  Gui.Window.Refresh(win);
}

U0 @ds_vscroll_change(Widget *) {
  ed.pos.x = 0;
  I64 i = 0;
  I64 max_scroll = vscroll_trough_height;
  I64 visible_row_cnt = (win->height - t->y - 40) / 16;
  F64 f1 = (ToF64(max_scroll) / ToF64(ed.buffer.rows));
  while (vscroll->scroll > ToI64(i * f1))
    i++;
  ed.origin.row = i;
  while (ed.origin.row + visible_row_cnt > ed.buffer.rows)
    ed.origin.row--;
  @ds_redraw_document_lines(&ed);
  @ds_realign_cursor(&ed);
  Gui.Window.Refresh(win);
}

U0 Main() {
#exe {
  if (HashFind("@exe_argv_filename", Fs->hash_table, HTT_GLBL_VAR))
    StreamPrint("StrCpy(&ed.filename, @exe_argv_filename);\n");
  else
    StrCpy(&ed.filename, DS_APP_FOLDER "/Untitled.HC");
}
@ds_load_file(&ed, &ed.filename);
U8 buf[512];
Gui.Window.Refresh(win);
Compositor.RegisterForGlobalInputEvents(win);
Gui.Window.SetCallback(win, "close", &@ds_window_close);
Gui.Window.SetCallback(win, "maximize", &@ds_window_toggle_max);
Gui.Window.SetCallback(win, "keypress", &@ds_keypress_callback);
Gui.Widget.SetCallback(vscroll, "change", &@ds_vscroll_change);
Gui.Window.SetFocus(win);
Gui.Window.Refresh(win);
I64 prev_origin_row = -1;
I64 prev_width = -1;
I64 prev_height = -1;
I64 prev_line = -1;
I64 prev_col = -1;
I64 cur_line;
I64 cur_col;
I64 visible_row_cnt;
I64 max_scroll;
F64 f1;
F64 f2;

while (win) {
  // FIXME: This should be event-driven...
  label_line_col->y = win->height - 40;
  if (win->width != prev_width || win->height != prev_height) {
    win->width = 3 + RoundI64(win->width, 8);
    win->height = RoundI64(win->height, 16);
    prev_width = win->width;
    prev_height = win->height;
    if (t) {
      t->width = win->width;
      t->backing_store->height = win->height - 48;
      cw_panel->ctx->height = win->height - 48;
      cw_file_explorer->ctx->height = win->height - 48;
    }
    @ds_redraw_document_lines(&ed);
    @ds_realign_cursor(&ed);
    ds_cursor->x = t->x + 2 + (8 * (ed.pos.x + 7));
    ds_cursor->y = t->y + 2 + (16 * ed.pos.y);
    @ds_update_ins_mode;
    Gui.Window.Refresh(win);
  }

  if (t && ed.buffer.rows) {
    // Calculate vertical scroll thumb height
    visible_row_cnt = (win->height - t->y - 40) / 16;
    vscroll->x = win->width - 29;
    vscroll->height = t->backing_store->height;
    vscroll_trough_height = vscroll->height - 40;
    f1 = (ToF64(visible_row_cnt) / ToF64(ed.buffer.rows));
    vscroll->length = ToI64(vscroll_trough_height * f1);
  }

  if (ed.buffer.rows && prev_origin_row != ed.origin.row) {
    // Calculate vertical scroll thumb position, based on origin row
    prev_origin_row = ed.origin.row;
    max_scroll = vscroll_trough_height;
    f1 = (ToF64(max_scroll) / ToF64(ed.buffer.rows));
    vscroll->scroll = ToI64(ed.origin.row * f1);
  }

  cur_line = ed.origin.row + ed.pos.y;
  cur_col = ed.origin.col + ed.pos.x;
  if (cur_line != prev_line || cur_col != prev_col) {
    prev_line = cur_line;
    prev_col = cur_col;
    StrPrint(&buf, "Line: %d, Col: %d", cur_line + 1, cur_col + 1);
    Gui.Widget.SetText(label_line_col, &buf);
    Gui.Window.Refresh(win);
  }

  if (FifoU8Cnt(t->input))
    Gui.Window.Refresh(win);
  if (sh->exit) {
    win->callback.close(win);
    return;
  }

  @ds_set_sidebar_icon(cw_doc, &icon_doc);
  @ds_set_sidebar_icon(cw_find, &icon_find);
  @ds_set_sidebar_icon(cw_src, &icon_src);
  @ds_set_sidebar_icon(cw_settings, &icon_settings);

  if (ed.buffer.rows < visible_row_cnt)
    vscroll->y = win->height;
  else
    vscroll->y = t->y;

  if (modal_window)
    if (modal_window != Compositor.active_win) {
      Gui.Window.SetFocus(win);
      Gui.Window.SetFocus(modal_window);
    }

  Sleep(10);
}
}

Main;
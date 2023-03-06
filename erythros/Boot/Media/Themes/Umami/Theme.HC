Context2D *umami_min_max_close =
    @png_file_to_context2d("T:/Media/Themes/Umami/Window/min_max_close.png");
Context2D *umami_min_max_close_pressed = PNG.FileToContext2D(
    "T:/Media/Themes/Umami/Window/min_max_close_pressed.png");
Context2D *umami_title_bar_button = NewContext2D(16, 14);
Context2D *umami_default_icon =
    @png_file_to_context2d("T:/Media/Themes/Umami/Icon/default.png");
Context2D *umami_corner_resize =
    @png_file_to_context2d("T:/Media/Themes/Umami/Window/corner_resize.png");

Context2D *umami_widget_checkbox =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/checkbox.png");
Context2D *umami_widget_checkbox_active =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/checkbox_active.png");
Context2D *umami_widget_checkbox_checked =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/checkbox_checked.png");
Context2D *umami_widget_checkbox_checked_active = @png_file_to_context2d(
    "T:/Media/Themes/Umami/Widget/checkbox_checked_active.png");

Context2D *umami_widget_radio =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/radio.png");
Context2D *umami_widget_radio_active =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/radio_active.png");
Context2D *umami_widget_radio_selected =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/radio_selected.png");

Context2D *umami_widget_horz_slider =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/horz_slider.png");
Context2D *umami_widget_vert_slider =
    @png_file_to_context2d("T:/Media/Themes/Umami/Widget/vert_slider.png");

U0 @umami_render_truetype_text(TrueTypeTextLabelWidget *widget) {
  Context2D *render = @truetype_TextRect2D(
      widget->width, @truetype_point_to_size(widget->size), 2, truetype_fonts,
      widget->font, widget->text, widget->color, widget->bgcolor);
  Context2D *free_ctx = NULL;
  if (widget->backing_store)
    free_ctx = widget->backing_store;
  widget->backing_store = render;
  // if (free_ctx)
  // DelContext2D(free_ctx);
}

U0 @umami_button_repaint(Window *win, ButtonWidget *widget, I64 x, I64 y) {
  I64 text_offset;
  I64 text_width;
  Rect2D(win->render_ctx, x + 1, y + 1, widget->width - 2, widget->height - 2,
         Color(232, 232, 232));
  Line2D(win->render_ctx, x + 1, y, x + widget->width - 1, y,
         Color(96, 96, 96));
  Line2D(win->render_ctx, x + 1, y + widget->height - 1, x + widget->width - 1,
         y + widget->height - 1, Color(96, 96, 96));
  Line2D(win->render_ctx, x, y + 1, x, y + widget->height - 2,
         Color(96, 96, 96));
  Line2D(win->render_ctx, x + widget->width - 1, y + 1, x + widget->width - 1,
         y + widget->height - 2, Color(96, 96, 96));
  if (widget == win->mouse_down_widget && Mouse.left &&
      @widget_is_hovered(win->x + x, win->y + y, widget)) {
    Line2D(win->render_ctx, x + 1, y + 1, x + widget->width - 2, y + 1,
           Color(152, 152, 152));
    Line2D(win->render_ctx, x + 1, y + 1, x + 1, y + widget->height - 3,
           Color(152, 152, 152));
    Line2D(win->render_ctx, x + 2, y + 2, x + widget->width - 3, y + 2,
           Color(216, 216, 216));
    Line2D(win->render_ctx, x + 2, y + 2, x + 2, y + widget->height - 4,
           Color(216, 216, 216));
    Line2D(win->render_ctx, x + 2, y + widget->height - 3,
           x + widget->width - 2, y + widget->height - 3, Color(255, 255, 255));
    Line2D(win->render_ctx, x + 3, y + widget->height - 4,
           x + widget->width - 2, y + widget->height - 4, Color(255, 255, 255));
    Line2D(win->render_ctx, x + widget->width - 3, y + 2, x + widget->width - 3,
           y + widget->height - 3, Color(255, 255, 255));
    Line2D(win->render_ctx, x + widget->width - 4, y + 3, x + widget->width - 4,
           y + widget->height - 3, Color(255, 255, 255));
  } else {
    Line2D(win->render_ctx, x + 2, y + 2, x + widget->width - 2, y + 2,
           Color(255, 255, 255));
    Line2D(win->render_ctx, x + 2, y + 3, x + widget->width - 3, y + 3,
           Color(255, 255, 255));
    Line2D(win->render_ctx, x + 2, y + 2, x + 2, y + widget->height - 3,
           Color(255, 255, 255));
    Line2D(win->render_ctx, x + 3, y + 2, x + 3, y + widget->height - 4,
           Color(255, 255, 255));
    Line2D(win->render_ctx, x + 3, y + widget->height - 3,
           x + widget->width - 3, y + widget->height - 3, Color(216, 216, 216));
    Line2D(win->render_ctx, x + widget->width - 3, y + 3, x + widget->width - 3,
           y + widget->height - 3, Color(216, 216, 216));
    Line2D(win->render_ctx, x + 2, y + widget->height - 2,
           x + widget->width - 2, y + widget->height - 2, Color(152, 152, 152));
    Line2D(win->render_ctx, x + widget->width - 2, y + 2, x + widget->width - 2,
           y + widget->height - 2, Color(152, 152, 152));
  }
  if (StrLen(&widget->text)) {
    text_offset = T(widget == win->mouse_down_widget && Mouse.left &&
                        @widget_is_hovered(win->x + x, win->y + y, widget),
                    1, 0);
    text_width = PutS2D(NULL, Compositor.theme.font.sans, 0, 0, Color(0, 0, 0),
                        , &widget->text);
    PutS2D(win->render_ctx, Compositor.theme.font.sans,
           x + text_offset + (widget->width / 2) - (text_width / 2),
           y + text_offset + (widget->height / 2) -
               (Compositor.theme.font.sans->line_height / 2),
           Color(0, 0, 0), , &widget->text);
  }
}

U0 @umami_checkbox_repaint(Window *win, CheckBoxWidget *widget, I64 x, I64 y) {

  if (widget == win->mouse_down_widget &&
      @widget_is_hovered(win->x + x, win->y + y, widget)) {
    Blot2D(win->render_ctx, x, y,
           T(widget->checked, umami_widget_checkbox_checked_active,
             umami_widget_checkbox_active));
    return;
  }
  if (widget == win->mouse_down_widget->echo &&
      widget != win->mouse_down_widget &&
      @widget_is_hovered(win->x + x, win->y + y, win->mouse_down_widget)) {
    Blot2D(win->render_ctx, x, y,
           T(widget->checked, umami_widget_checkbox_checked_active,
             umami_widget_checkbox_active));
    return;
  }
  Blot2D(
      win->render_ctx, x, y,
      T(widget->checked, umami_widget_checkbox_checked, umami_widget_checkbox));
}

U0 @umami_terminal_calculate_size(Window *win, TerminalWidget *widget) {
  widget->size.cols = RoundI64(win->width, 8) / 8;
  widget->size.rows = RoundI64(win->width, 16) / 16; // FIXME
}

U32 @umami_terminal_256_color_lookup(I64 index) {
  U32 *color_table = TERMINAL_COLOR_TABLE;
  return color_table[index];
}

U0 @umami_terminal_set_256_color_foreground(Window *win, TerminalWidget *widget,
                                            I64 argc, U8 **argv) {
  if (argc != 3 && !StrCmp(argv[1], "5"))
    return;
  widget->color.foreground = @umami_terminal_256_color_lookup(Str2I64(argv[2]));
}

U0 @umami_terminal_set_256_color_background(Window *win, TerminalWidget *widget,
                                            I64 argc, U8 **argv) {
  if (argc != 3 && !StrCmp(argv[1], "5"))
    return;
  widget->color.background = @umami_terminal_256_color_lookup(Str2I64(argv[2]));
  widget->color.background.u8[3] = win->opacity;
}

U0 @umami_terminal_cleanup_strings(I64 argc, U8 **argv) {
  I64 i;
  for (i = 0; i < argc - 1; i++)
    Free(argv[i]);
}

I64 @umami_ansi_16_color_table[8] = {0, 4, 2, 6, 1, 5, 3, 7};

U0 @umami_terminal_set_16_color_fg_value(TerminalWidget *widget) {
  I64 val = widget->last_fg_color_set;
  if (val > 15)
    return;
  widget->color.foreground =
      Color(T(widget->attr.bold,
              gr_palette_std[8 + @umami_ansi_16_color_table[val]].r & 0xFF,
              gr_palette_std[@umami_ansi_16_color_table[val]].r & 0xFF),
            T(widget->attr.bold,
              gr_palette_std[8 + @umami_ansi_16_color_table[val]].g & 0xFF,
              gr_palette_std[@umami_ansi_16_color_table[val]].g & 0xFF),
            T(widget->attr.bold,
              gr_palette_std[8 + @umami_ansi_16_color_table[val]].b & 0xFF,
              gr_palette_std[@umami_ansi_16_color_table[val]].b & 0xFF));
}

U0 @umami_terminal_ctrl_seq_sgr(Window *win, TerminalWidget *widget) {
  I64 argc;
  I64 i;
  I64 val;
  U8 **argv = String.Split(&widget->consumed_chars, ';', &argc);
  if (!argc && StrLen(&widget->consumed_chars)) {
    argc = 1;
    argv[0] = &widget->consumed_chars;
  }
  if (!argc && !StrLen(&widget->consumed_chars)) {
    widget->color.background = Color(0, 0, 0);
    widget->color.foreground = Color(217, 217, 217);
    return;
  }
  for (i = 0; i < argc; i++) {
    val = Str2I64(argv[i]);
    switch (val) {
    case 0:
      widget->color.background = Color(0, 0, 0);
      widget->color.foreground = Color(217, 217, 217);
      break;
    case 1:
      widget->attr.bold = TRUE;
      if (widget->last_fg_color_set < 16)
        @umami_terminal_set_16_color_fg_value(widget);
      break;
    case 2:
      widget->attr.bold = FALSE;
      if (widget->last_fg_color_set < 16)
        @umami_terminal_set_16_color_fg_value(widget);
      break;
    // 16 colors
    case 30...37:
      widget->last_fg_color_set = val - 30;
      @umami_terminal_set_16_color_fg_value(widget);
      break;
    case 40...47:
      widget->color.background =
          Color(gr_palette_std[@umami_ansi_16_color_table[(val - 40)]].r & 0xFF,
                gr_palette_std[@umami_ansi_16_color_table[(val - 40)]].g & 0xFF,
                gr_palette_std[@umami_ansi_16_color_table[(val - 40)]].b & 0xFF,
                win->opacity);
      break;
    // 256 colors
    case 38:
      widget->last_fg_color_set = 256;
      @umami_terminal_set_256_color_foreground(win, widget, argc, argv);
      i += 2;
      break;
    case 48:
      @umami_terminal_set_256_color_background(win, widget, argc, argv);
      i += 2;
      break;
    case 39:
      // FIXME: Set default foreground color
      widget->color.foreground = Color(217, 217, 217);
      break;
    case 49:
      // FIXME: Set default background color
      widget->color.background = Color(0, 0, 0);
      break;
    default:
      System.Log("Unrecognized attribute in ctrl_seq_sgr: %d", val);
      break;
    }
  }
  // if (argc)
  //  @umami_terminal_cleanup_strings(argc, argv);
}

U0 @umami_terminal_set_col(Window *win, TerminalWidget *widget, I64 row,
                           I64 col, U8 char) {
  widget->row[row].col[col].foreground = widget->color.foreground;
  widget->row[row].col[col].background = widget->color.background;
  widget->row[row].col[col].char = char;
}

U0 @umami_terminal_set_row(Window *win, TerminalWidget *widget, I64 row,
                           U8 char) {
  I64 col;
  for (col = 0; col < TERMINAL_MAX_COLS - 1; col++)
    @umami_terminal_set_col(win, widget, row, col, char);
}

U0 @umami_terminal_set_rows(Window *win, TerminalWidget *widget, U8 char) {
  I64 row;
  for (row = 0; row < widget->size.rows - 1; row++)
    @umami_terminal_set_row(win, widget, row, char);
}

U0 @umami_terminal_repaint_col(Window *win, TerminalWidget *widget, I64 row,
                               I64 col) {
  U8 char[2];
  char[1] = NULL;
  U32 col_bg_color;
  char[0] = widget->row[row].col[col].char;
  col_bg_color = widget->row[row].col[col].background;
  col_bg_color.u8[3] = win->opacity;
  Rect2D(widget->backing_store, 2 + (col * 8), 2 + (row * 16), 8, 16,
         col_bg_color);
  PutS2D(widget->backing_store, Compositor.theme.font.monospace, 2 + (col * 8),
         2 + (row * 16), widget->row[row].col[col].foreground, , &char);
}

U0 @umami_terminal_repaint_row(Window *win, TerminalWidget *widget, I64 row) {
  I64 col;
  for (col = 0; col < TERMINAL_MAX_COLS - 1; col++)
    @umami_terminal_repaint_col(win, widget, row, col);
}

U0 @umami_terminal_repaint_rows(Window *win, TerminalWidget *widget) {
  I64 row;
  for (row = 0; row < widget->size.rows - 1; row++)
    @umami_terminal_repaint_row(win, widget, row);
}

U0 @umami_terminal_ctrl_seq_cursor_move(Window *win, TerminalWidget *widget,
                                        I64 dir) {
  I64 pos = Str2I64(&widget->consumed_chars);
  switch (dir) {
  case 'A':
    widget->cursor.y = Max(0, widget->cursor.y - pos);
    break;
  case 'B':
    widget->cursor.y = Min(widget->cursor.y + pos, widget->size.rows - 1);
    break;
  case 'C':
    widget->cursor.x = Min(widget->cursor.x + pos, widget->size.cols - 1);
    break;
  case 'D':
    widget->cursor.x = Max(0, widget->cursor.x - pos);
    break;
  };
}

U0 @umami_terminal_ctrl_seq_cursor_pos(Window *win, TerminalWidget *widget) {
  I64 argc;
  I64 i;
  I64 val;
  U8 **argv = String.Split(&widget->consumed_chars, ';', &argc);
  if (!argc) {
    @umami_terminal_repaint_col(win, widget, widget->cursor.y,
                                widget->cursor.x);
    widget->cursor.x = 0;
    widget->cursor.y = 0;
    return;
  }
  if (argc == 2) {
    @umami_terminal_repaint_col(win, widget, widget->cursor.y,
                                widget->cursor.x);
    widget->cursor.y = Str2I64(argv[0]) - 1;
    widget->cursor.x = Str2I64(argv[1]) - 1;
    widget->cursor.y = Min(widget->size.rows - 2, widget->cursor.y);
    widget->cursor.x = Min(widget->size.cols - 2, widget->cursor.x);
    widget->cursor.y = Max(0, widget->cursor.y);
    widget->cursor.x = Max(0, widget->cursor.x);
    //@umami_terminal_cleanup_strings(argc, argv);
    return;
  }
}

U0 @umami_terminal_ctrl_seq_erase_screen(Window *win, TerminalWidget *widget) {
  if (!StrLen(&widget->consumed_chars)) {
    // TODO: clear from cursor to end of the screen
    return;
  }
  I64 val = Str2I64(&widget->consumed_chars);
  switch (val) {
  case 0:
    // TODO: clear from cursor to end of the screen
    break;
  case 1:
    // TODO: clear from cursor to beginning of the screen
    break;
  case 2:
    @umami_terminal_set_rows(win, widget, ' ');
    @umami_terminal_repaint_rows(win, widget);
    break;
  default:
    System.Log("Unrecognized attribute in ctrl_seq_erase_screen: %d", val);
    break;
  };
}

U0 @umami_terminal_ctrl_seq_erase_line(Window *win, TerminalWidget *widget) {
  if (!StrLen(&widget->consumed_chars)) {
    // TODO: clear from cursor to end of the line
    return;
  }
  I64 val = Str2I64(&widget->consumed_chars);
  switch (val) {
  case 0:
    // TODO: clear from cursor to end of the line
    break;
  case 1:
    // TODO: clear from cursor to beginning of the line
    break;
  case 2:
    @umami_terminal_set_row(win, widget, widget->cursor.y, ' ');
    @umami_terminal_repaint_rows(win, widget);
    break;
  default:
    System.Log("Unrecognized attribute in ctrl_seq_erase_line: %d", val);
    break;
  };
}

U0 @umami_terminal_send_response_string(Window *win, TerminalWidget *widget,
                                        U8 *string) {
  if (!string || !widget->output)
    return;
  I64 i;
  for (i = 0; i < StrLen(string); i++)
    FifoU8Ins(widget->output, string[i]);
}

U0 @umami_terminal_ctrl_seq_set_func(Window *win, TerminalWidget *widget,
                                     Bool bool) {
  if (!StrCmp(&widget->consumed_chars, "?25")) {
    @umami_terminal_repaint_col(win, widget, widget->cursor.y,
                                widget->cursor.x);
    widget->cursor.hidden = T(bool, FALSE, TRUE);
  }
}

U0 @umami_terminal_ctrl_seq_dev_attr_report(Window *win,
                                            TerminalWidget *widget) {
  if (!widget->output)
    return;
  if (StrFind("=", &widget->consumed_chars)) {
    // Tertiary device attributes
    @umami_terminal_send_response_string(win, widget, "\x1bP!|7E565445\x1b\\");
    return;
  }
  if (StrFind(">", &widget->consumed_chars)) {
    // Secondary device attributes
    @umami_terminal_send_response_string(win, widget, "\x1b[>65;6201;1c");
    return;
  }
  // Primary device attributes
  @umami_terminal_send_response_string(win, widget, "\x1b[?65;1;9c");
}

U0 @umami_terminal_ctrl_seq_ecp_report(Window *win, TerminalWidget *widget) {
  if (!widget->output)
    return;
  U8 resp_str[32];
  StrPrint(&resp_str, "\x1b[%d;%dR", widget->cursor.y + 1,
           widget->cursor.x + 1);
  if (!StrCmp(&widget->consumed_chars, "5"))
    @umami_terminal_send_response_string(win, widget, "\x1b[0n");
  if (!StrCmp(&widget->consumed_chars, "6"))
    @umami_terminal_send_response_string(win, widget, &resp_str);
}

U0 @umami_terminal_ctrl_seq_req_tparm(Window *win, TerminalWidget *widget) {
  // FIXME: allow unsolicited DECREPTPARMs
  if (!StrCmp(&widget->consumed_chars, "1")) {
    @umami_terminal_send_response_string(win, widget,
                                         "\x1b[3;1;1;120;120;1;0x");
    return;
  }
  @umami_terminal_send_response_string(win, widget, "\x1b[2;1;1;120;120;1;0x");
}

U0 @umami_terminal_os_cmd(Window *win, TerminalWidget *widget) {
  I64 argc;
  I64 i;
  I64 val;
  U8 **argv = String.Split(&widget->consumed_chars, ';', &argc);
  if (!argc)
    return;
  val = Str2I64(argv[0]);
  switch (val) {
  case 0:
    // Test set window title
    StrPrint(win->title, "Terminal - %s", argv[1]);
    break;
  default:
    break;
  }
  //@umami_terminal_cleanup_strings(argc, argv);
}

U0 @umami_terminal_consume_char(Window *win, TerminalWidget *widget) {
  U8 char[2];
  char[1] = NULL;
  FifoU8Rem(widget->input, &char);

  switch (widget->state) {
  case TERMINAL_STATE_CONSUME_BEGIN:
    StrCpy(&widget->consumed_chars, "");
    switch (char[0]) {
    case '7': // DEC Save Cursor
      MemCpy(&widget->stored.attr, &widget->attr,
             sizeof(@terminal_widget_attr));
      MemCpy(&widget->stored.color, &widget->color,
             sizeof(@terminal_widget_color));
      MemCpy(&widget->stored.cursor, &widget->cursor,
             sizeof(@terminal_widget_cursor));
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case '8': // Dec Restore Cursor
      MemCpy(&widget->attr, &widget->stored.attr,
             sizeof(@terminal_widget_attr));
      MemCpy(&widget->color, &widget->stored.color,
             sizeof(@terminal_widget_color));
      MemCpy(&widget->cursor, &widget->stored.cursor,
             sizeof(@terminal_widget_cursor));
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case '[':
      widget->state = TERMINAL_STATE_CONSUME_CTRL_SEQ;
      break;
    case ']':
      widget->state = TERMINAL_STATE_CONSUME_OS_CMD;
      break;
    default:
      System.Log(Fs, "Undefined C1 control code: %c", char[0]);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    };
    break;
  case TERMINAL_STATE_CONSUME_CTRL_SEQ:
    switch (char[0]) {
    case '0' ... '9':
    case ';':
    case '?':
    case '>':
    case '=':
      String.Append(&widget->consumed_chars, &char);
      break;
    case 'A' ... 'D':
      @umami_terminal_ctrl_seq_cursor_move(win, widget, char[0]);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'H':
      @umami_terminal_ctrl_seq_cursor_pos(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'J':
      @umami_terminal_ctrl_seq_erase_screen(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'K':
      @umami_terminal_ctrl_seq_erase_line(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'c':
      @umami_terminal_ctrl_seq_dev_attr_report(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'h':
      @umami_terminal_ctrl_seq_set_func(win, widget, 1);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'l':
      @umami_terminal_ctrl_seq_set_func(win, widget, 0);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'm':
      @umami_terminal_ctrl_seq_sgr(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'n':
      @umami_terminal_ctrl_seq_ecp_report(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 't':
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    case 'x':
      @umami_terminal_ctrl_seq_req_tparm(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    default:
      System.Log(Fs,
                 "Invalid or unimplemented character in control sequence: '%c'",
                 char[0]);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    }
    break;
  case TERMINAL_STATE_CONSUME_OS_CMD:
    switch (char[0]) {
    case 7:
    case '\\':
      @umami_terminal_os_cmd(win, widget);
      widget->state = TERMINAL_STATE_CONSUME_END;
      break;
    default:
      String.Append(&widget->consumed_chars, &char);
      break;
    };
    break;
  };
}

U0 @umami_terminal_output_char(Window *win, TerminalWidget *widget) {
  U8 char[2];
  char[1] = NULL;
  FifoU8Rem(widget->input, &char);
  switch (char[0]) {
  case 27:
    StrCpy(&widget->consumed_chars, "");
    widget->state = TERMINAL_STATE_CONSUME_BEGIN;
    return;
    break;
  case 7:
    Audio.Beep();
    break;
  case 8:
    widget->row[widget->cursor.y].col[widget->cursor.x].char = ' ';
    widget->cursor.x--;
    if (widget->cursor.x < 0) {
      widget->cursor.y--;
      widget->cursor.x = widget->size.cols - 2;
    }
    break;
  case 10:
    widget->cursor.y++;
    widget->cursor.x = 0;
    break;
  case 13:
    widget->cursor.x = 0;
    break;
  case 32...127:
    widget->row[widget->cursor.y].col[widget->cursor.x].foreground =
        widget->color.foreground;
    widget->row[widget->cursor.y].col[widget->cursor.x].background =
        widget->color.background;
    widget->row[widget->cursor.y].col[widget->cursor.x].char = char[0];
    widget->cursor.x++;
    break;
  default:
    widget->row[widget->cursor.y].col[widget->cursor.x].foreground =
        widget->color.foreground;
    widget->row[widget->cursor.y].col[widget->cursor.x].background =
        widget->color.background;
    widget->row[widget->cursor.y].col[widget->cursor.x].char = '?';
    widget->cursor.x++;
    break;
  };
  if (widget->cursor.x >= widget->size.cols - 1) {
    widget->cursor.y++;
    widget->cursor.x = 0;
  }
}

U0 @umami_terminal_repaint(Window *win, TerminalWidget *widget, I64 x, I64 y) {

  I64 current_col = NULL;
  I64 current_row = NULL;

  @umami_terminal_calculate_size(win, widget);
  while (FifoU8Cnt(widget->input)) {
    current_col = widget->cursor.x;
    current_row = widget->cursor.y;
    switch (widget->state) {
    case TERMINAL_STATE_OUTPUT:
      @umami_terminal_output_char(win, widget);
      break;
    case TERMINAL_STATE_CONSUME_BEGIN:
    case TERMINAL_STATE_CONSUME_CTRL_SEQ:
    case TERMINAL_STATE_CONSUME_OS_CMD:
      @umami_terminal_consume_char(win, widget);
      break;
    }
    if (widget->state == TERMINAL_STATE_OUTPUT)
      @umami_terminal_repaint_col(win, widget, current_row, current_col);
    if (widget->state == TERMINAL_STATE_CONSUME_END)
      widget->state = TERMINAL_STATE_OUTPUT;
  }
  if (widget->state == TERMINAL_STATE_OUTPUT && !widget->cursor.hidden)
    Rect2D(widget->backing_store, 2 + (widget->cursor.x * 8),
           2 + (widget->cursor.y * 16), 8, 16, widget->color.cursor);
}

I64 @umami_input_get_text_width(BitmapFontTextInputWidget *widget) {
  I64 x;
  I64 y;
  I64 text_width =
      PutS2D(NULL, widget->font, 0, 0, Color(0, 0, 0), -1, &widget->text);

  Context2D *ctx = NewContext2D(text_width, widget->font->line_height);
  Fill2D(ctx, 0);
  PutS2D(ctx, widget->font, 0, 0, Color(128, 255, 255), -1, &widget->text);

  for (x = ctx->width - 1; x > -1; x--) {
    for (y = 0; y < ctx->height - 1; y++) {
      if (ctx->fb[(ctx->width * y) + x]) {
        DelContext2D(ctx);
        return x + 2;
      }
    }
  }
  DelContext2D(ctx);
  return x;
}

U0 @umami_input_draw_cursor(Window *win, BitmapFontTextInputWidget *widget,
                            I64 index, I64 x, I64 y, I64 pos) {
  if (widget->selected_region_start != -1 && widget->selected_region_end != -1)
    return;
  if (widget == win->focused_widget) {
    if (Blink && index == widget->cursor_index) {
      VLine2D(win->render_ctx, x + 2 + pos, y + 2,
              y + 2 + widget->font->line_height, Color(0, 0, 0));
    }
  }
}

U0 @umami_input_repaint(Window *win, I64 event,
                        BitmapFontTextInputWidget *widget, I64 x, I64 y) {

  if (!widget->font)
    widget->font = Compositor.theme.font.sans;
  U8 *text;
  U8 ch[2];
  I64 index;
  I64 text_width;
  I64 text_x_pos;
  ch[1] = NULL;
  widget->height = widget->font->line_height + 6;

  HLine2D(win->render_ctx, x, y, x + widget->width, Color(156, 156, 156));
  VLine2D(win->render_ctx, x, y, y + widget->height, Color(156, 156, 156));
  HLine2D(win->render_ctx, x + 1, y + widget->height, x + widget->width,
          Color(190, 190, 190));
  VLine2D(win->render_ctx, x + widget->width, y + 1, y + widget->height,
          Color(190, 190, 190));
  Rect2D(win->render_ctx, x + 1, y + 1, widget->width - 1, widget->height - 1,
         Color(255, 255, 255));

  if (widget == win->focused_widget) {
    HLine2D(win->render_ctx, x + 1, y + 1, x + widget->width - 1,
            Color(0, 0, 0));
    VLine2D(win->render_ctx, x + 1, y + 1, y + widget->height - 2,
            Color(0, 0, 0));
    HLine2D(win->render_ctx, x + 1, y + widget->height - 1,
            x + widget->width - 1, Color(0, 0, 0));
    VLine2D(win->render_ctx, x + widget->width - 1, y + 1,
            y + widget->height - 1, Color(0, 0, 0));
  } else {
    widget->in_drag = FALSE;
  }

  if (!Mouse.left) {
    widget->in_drag = FALSE;
    widget->mouse_drag_index = -1;
  }

  Context2D *text_input_ctx = NewContext2D(widget->width - 4, widget->height);

  text = &widget->text;
  index = 0;
  text_width;
  text_x_pos = 0;
  while (*text) {
    ch[0] = *text;
    text_width = PutS2D(NULL, widget->font, 0, 0, Color(0, 0, 0), -1, &ch) + 2;

    if (event == CPZ_MSG_WIN_LEFT_BTN_DOWN && !widget->in_drag &&
        Mouse.x >= win->x + widget->x + -widget->x_offset + text_x_pos &&
        Mouse.x <=
            win->x + widget->x + -widget->x_offset + text_x_pos + text_width) {
      widget->cursor_index = index;
      widget->mouse_drag_index = widget->cursor_index - 1;
      widget->mouse_drag_origin_x =
          Mouse.x - win->x - widget->x + widget->x_offset;
    }

    if (widget->in_drag) {
      if (Mouse.x - win->x - widget->x < widget->mouse_drag_origin_x &&
          Mouse.x >= win->x + widget->x + -widget->x_offset + text_x_pos &&
          Mouse.x <= win->x + widget->x + -widget->x_offset + text_x_pos +
                         text_width) {
        widget->selected_region_start = index;
        widget->selected_region_end = widget->mouse_drag_index;
      }
      if (Mouse.x - win->x - widget->x >= widget->mouse_drag_origin_x &&
          Mouse.x >= win->x + widget->x + -widget->x_offset + text_x_pos +
                         text_width) {
        widget->selected_region_start = widget->mouse_drag_index + 1;
        widget->selected_region_end = index;
      }
    }

    if (index >= widget->selected_region_start &&
        index <= widget->selected_region_end) {
      Rect2D(text_input_ctx, -widget->x_offset + text_x_pos, 0, text_width,
             widget->font->line_height + 3, Compositor.theme.color.hilight);
    }
    if (index >= widget->selected_region_start &&
        index <= widget->selected_region_end)
      PutS2D(text_input_ctx, widget->font, -widget->x_offset + text_x_pos, 2,
             Color(255, 255, 255), -1, &ch);
    else
      PutS2D(text_input_ctx, widget->font, -widget->x_offset + text_x_pos, 2,
             widget->color, -1, &ch);

    @umami_input_draw_cursor(win, widget, index, x, y,
                             -widget->x_offset + text_x_pos);
    text_x_pos += text_width;

    text++;
    index++;
  }

  if (event == CPZ_MSG_WIN_LEFT_BTN_DOWN && !widget->in_drag &&
      Mouse.x > win->x + widget->x + -widget->x_offset + text_x_pos &&
      widget == win->focused_widget) {
    widget->cursor_index = StrLen(&widget->text);
    widget->mouse_drag_index = widget->cursor_index;
    widget->mouse_drag_origin_x = Mouse.x - win->x - widget->x;
  }

  if (event == CPZ_MSG_WIN_LEFT_BTN_DOWN && widget == win->focused_widget) {
    @widget_input_clear_selected_region(widget);
    widget->in_drag = TRUE;
  }

  if (-widget->x_offset + text_x_pos < text_input_ctx->width)
    @umami_input_draw_cursor(win, widget, index, x, y,
                             -widget->x_offset + text_x_pos);

  Blot2D(win->render_ctx, x + 3, y + 2, text_input_ctx);
  DelContext2D(text_input_ctx);
}

U0 @umami_label_repaint(Window *win, BitmapFontTextLabelWidget *widget, I64 x,
                        I64 y) {
  if (!widget->font)
    widget->font = Compositor.theme.font.sans;
  if (widget->text)
    PutS2D(win->render_ctx, widget->font, x, y, widget->color, -1,
           widget->text);
}

U0 @umami_radio_repaint(Window *win, RadioButtonWidget *widget, I64 x, I64 y) {
  if (widget == win->mouse_down_widget &&
      @widget_is_hovered(win->x + x, win->y + y, widget)) {
    Blot2D(win->render_ctx, x, y,
           T(widget->selected, umami_widget_radio_selected,
             umami_widget_radio_active));
    return;
  }
  if (widget == win->mouse_down_widget->echo &&
      widget != win->mouse_down_widget && !widget->selected &&
      @widget_is_hovered(win->x + x, win->y + y, win->mouse_down_widget)) {
    Blot2D(win->render_ctx, x, y,
           T(win->mouse_down_widget(RadioButtonWidget *)->selected,
             umami_widget_radio_selected, umami_widget_radio_active));
    return;
  }
  Blot2D(win->render_ctx, x, y,
         T(widget->selected, umami_widget_radio_selected, umami_widget_radio));
}

U0 @umami_radio_select(Window *win, RadioButtonWidget *widget) {
  @window_widgets_list *widgets_list;
  widgets_list = win->widget;
  while (widgets_list) {
    if (widgets_list->widget && widgets_list->widget->type == WIDGET_TYPE_RADIO)
      if (widgets_list->widget(RadioButtonWidget *)->group == widget->group)
        widgets_list->widget(RadioButtonWidget *)->selected =
            T(widgets_list->widget == widget, TRUE, FALSE);
    widgets_list = widgets_list->next;
  }
}

Bool @umami_horz_slider_bar_is_hovered(I64 x, I64 y, Widget *widget) {
  no_warn y;
  if (Mouse.x > x - 7 && Mouse.x < x + widget->width + 7)
    return TRUE;
  return FALSE;
}

Bool @umami_horz_slider_is_hovered(Window *win, HorizontalSliderWidget *widget,
                                   I64 x, I64 y, I64 scroll_pos) {
  if (@widget_is_hovered(win->x + x, win->y + y - 24, widget) &&
      Mouse.x > -4 + (win->x + widget->x - 7) + scroll_pos &&
      Mouse.x < (win->x + widget->x - 7) + scroll_pos + 16)
    return TRUE;
  return FALSE;
}

U0 @umami_horz_slider_repaint(Window *win, I64 event,
                              HorizontalSliderWidget *widget, I64 x, I64 y) {
  I64 scroll = widget->scroll;
  widget->height = 12;
  if (widget->in_drag &&
      @umami_horz_slider_bar_is_hovered(win->x + x, win->y + y - 24, widget)) {
    if (widget->origin.mouse_x != Mouse.x) {
      widget->scroll += (Mouse.x - widget->origin.mouse_x);
      widget->origin.mouse_x = Mouse.x;
    }
  }

  Rect2D(win->render_ctx, x, y + 5, widget->width, 4, Color(156, 156, 156));
  if (@umami_horz_slider_is_hovered(win, widget, x, y, widget->scroll) &&
      event == CPZ_MSG_WIN_LEFT_BTN_DOWN) {
    win->mouse_down_widget = widget;
    widget->origin.mouse_x = Mouse.x;
    widget->in_drag = TRUE;
  } else {
    if (@widget_is_hovered(win->x + x, win->y + y, widget) &&
        event == CPZ_MSG_WIN_LEFT_BTN_DOWN) {
      widget->scroll = (Mouse.x - win->x - x + 2);
      widget->origin.mouse_x = Mouse.x;
      widget->in_drag = TRUE;
    }
  }

  if (@widget_is_hovered(win->x + x, win->y + y, widget) &&
      event == CPZ_MSG_WIN_MOUSE_WHEEL) {
    widget->scroll += Compositor.mouse.z;
  }

  widget->scroll = Max(0, widget->scroll);
  widget->scroll = Min(widget->width - 1, widget->scroll);
  widget->value = ToI64((widget->max * 1.0) / (widget->width * 1.0) *
                        (widget->scroll * 1.0));

  if (!Mouse.left)
    widget->in_drag = FALSE;

  HLine2D(win->render_ctx, x, y + 1, x + widget->width, Color(190, 190, 190));
  HLine2D(win->render_ctx, x + 1, y + 4, x + widget->width, Color(0, 0, 0));
  VLine2D(win->render_ctx, x + 1, y + 4, y + 8, Color(0, 0, 0));
  VLine2D(win->render_ctx, x, y + 4, y + 9, Color(190, 190, 190));
  HLine2D(win->render_ctx, x, y + 9, x + widget->width, Color(255, 255, 255));
  VLine2D(win->render_ctx, x + widget->width, y + 4, y + 9,
          Color(255, 255, 255));

  VLine2D(win->render_ctx, x, y + 11, y + 16, Color(190, 190, 190));
  VLine2D(win->render_ctx, x + 1, y + 11, y + 16, Color(255, 255, 255));

  VLine2D(win->render_ctx, x + (widget->width / 2) - 1, y + 11, y + 16,
          Color(190, 190, 190));
  VLine2D(win->render_ctx, x + (widget->width / 2), y + 11, y + 16,
          Color(255, 255, 255));

  VLine2D(win->render_ctx, x + widget->width - 1, y + 11, y + 16,
          Color(190, 190, 190));
  VLine2D(win->render_ctx, x + widget->width, y + 11, y + 16,
          Color(255, 255, 255));

  Blot2D(win->render_ctx, (x - 7) + widget->scroll, y,
         umami_widget_horz_slider);

  if (widget->scroll != scroll)
    widget->change = TRUE;
}

Bool @umami_vert_slider_bar_is_hovered(I64 x, I64 y, Widget *widget) {
  no_warn x;
  if (Mouse.y > y - 7 && Mouse.y < y + widget->height + 7)
    return TRUE;
  return FALSE;
}

Bool @umami_vert_slider_is_hovered(Window *win, VerticalSliderWidget *widget,
                                   I64 x, I64 y, I64 scroll_pos) {
  if (@widget_is_hovered(win->x + x - 24, win->y + y, widget) &&
      Mouse.y > -4 + (win->y + widget->y - 7) + scroll_pos &&
      Mouse.y < (win->y + widget->y - 7) + scroll_pos + 16)
    return TRUE;
  return FALSE;
}

U0 @umami_vert_slider_repaint(Window *win, I64 event,
                              VerticalSliderWidget *widget, I64 x, I64 y) {
  I64 scroll = widget->scroll;
  widget->width = 12;
  if (widget->in_drag &&
      @umami_vert_slider_bar_is_hovered(win->x + x, win->y + y, widget)) {
    if (widget->origin.mouse_y != Mouse.y) {
      widget->scroll += (Mouse.y - widget->origin.mouse_y);
      widget->origin.mouse_y = Mouse.y;
    }
  }
  Rect2D(win->render_ctx, x + 5, y, 4, widget->height, Color(156, 156, 156));
  if (@umami_horz_slider_is_hovered(win, widget, x, y, widget->scroll) &&
      event == CPZ_MSG_WIN_LEFT_BTN_DOWN) {
    win->mouse_down_widget = widget;
    widget->origin.mouse_y = Mouse.y;
    widget->in_drag = TRUE;
  } else {
    if (@widget_is_hovered(win->x + x, win->y + y, widget) &&
        event == CPZ_MSG_WIN_LEFT_BTN_DOWN) {
      widget->scroll = (Mouse.y - win->y - y + 1);
      widget->origin.mouse_y = Mouse.y;
      widget->in_drag = TRUE;
    }
  }
  if (@widget_is_hovered(win->x + x, win->y + y, widget) &&
      event == CPZ_MSG_WIN_MOUSE_WHEEL) {
    widget->scroll += Compositor.mouse.z;
  }
  widget->scroll = Max(0, widget->scroll);
  widget->scroll = Min(widget->height - 1, widget->scroll);
  widget->value = ToI64((widget->max * 1.0) / (widget->height * 1.0) *
                        (widget->scroll * 1.0));
  if (!Mouse.left)
    widget->in_drag = FALSE;
  VLine2D(win->render_ctx, x + 1, y, y + widget->height, Color(190, 190, 190));
  VLine2D(win->render_ctx, x + 4, y + 1, y + widget->height, Color(0, 0, 0));
  HLine2D(win->render_ctx, x + 4, y, x + 9, Color(0, 0, 0));
  VLine2D(win->render_ctx, x + 9, y, y + widget->height, Color(255, 255, 255));
  HLine2D(win->render_ctx, x + 4, y + widget->height, x + 9,
          Color(255, 255, 255));
  HLine2D(win->render_ctx, x + 11, y, x + 16, Color(190, 190, 190));
  HLine2D(win->render_ctx, x + 11, y + 1, x + 16, Color(255, 255, 255));
  HLine2D(win->render_ctx, x + 11, y + (widget->height / 2) - 1, x + 16,
          Color(190, 190, 190));
  HLine2D(win->render_ctx, x + 11, y + (widget->height / 2), x + 16,
          Color(255, 255, 255));
  HLine2D(win->render_ctx, x + 11, y + widget->height - 1, x + 16,
          Color(190, 190, 190));
  HLine2D(win->render_ctx, x + 11, y + widget->height, x + 16,
          Color(255, 255, 255));
  Blot2D(win->render_ctx, x, (y - 7) + widget->scroll,
         umami_widget_vert_slider);

  if (widget->scroll != scroll)
    widget->change = TRUE;
}

U0 @umami_widgets_repaint(Window *win, I64 event, I64 origin_x, I64 origin_y) {
  @window_widgets_list *widgets_list;
  Widget *widget;
  Context2D *ctx;
  I64 x, y;
  F64 ttf_point_to_size;
  no_warn ctx;
  no_warn ttf_point_to_size;

  if (event == CPZ_MSG_WIN_LEFT_BTN_DOWN)
    win->focused_widget = NULL;

  widgets_list = win->widget;
  while (widgets_list) {
    if (widgets_list->widget) {
      widget = widgets_list->widget;
      x = win->x + origin_x + widget->x;
      y = win->y + origin_y + widget->y;

      if (@widget_is_hovered(x, y, widget) &&
          event == CPZ_MSG_WIN_LEFT_BTN_DOWN) {
        win->focused_widget = widget;
        win->mouse_down_widget = widget;
        break;
      }
    }
    widgets_list = widgets_list->next;
  }

  if (!Mouse.left && win->mouse_down_widget) {
    widget = win->mouse_down_widget;
    x = win->x + origin_x + widget->x;
    y = win->y + origin_y + widget->y;
    if (@widget_is_hovered(x, y, widget) && widget->callback.clicked)
      widget->callback.clicked(widget);
    if (@widget_is_hovered(x, y, widget) && widget->echo) {
      if (widget->echo->callback.clicked)
        widget->echo->callback.clicked(widget->echo);
    }
    if (@widget_is_hovered(x, y, widget)) {
      switch (widget->type) {
      case WIDGET_TYPE_CHECKBOX:
        widget(CheckBoxWidget *)->checked = !widget(CheckBoxWidget *)->checked;
        break;
      case WIDGET_TYPE_RADIO:
        @umami_radio_select(win, widget);
        break;
      default:
        break;
      }
    }
    if (@widget_is_hovered(x, y, widget) && widget->echo) {
      switch (widget->echo->type) {
      case WIDGET_TYPE_CHECKBOX:
        widget->echo(CheckBoxWidget *)->checked =
            !widget->echo(CheckBoxWidget *)->checked;
        break;
      case WIDGET_TYPE_RADIO:
        @umami_radio_select(win, widget->echo);
        break;
      default:
        break;
      }
    }
    win->mouse_down_widget = NULL;
  }

  widgets_list = win->widget;
  while (widgets_list) {
    if (widgets_list->widget) {
      widget = widgets_list->widget;
      x = origin_x + widget->x;
      y = origin_y + widget->y;
      if (x > win->width - 12 || y > win->height - 12)
        goto @umami_skip_widget_repaint;
      switch (widget->type) {
      case NULL:
        break;
      case WIDGET_TYPE_BUTTON:
        @umami_button_repaint(win, widget, x, y);
        break;
      case WIDGET_TYPE_CHECKBOX:
        @umami_checkbox_repaint(win, widget, x, y);
        break;
      case WIDGET_TYPE_TERMINAL:
        @umami_terminal_repaint(win, widget, x, y);
        if (widget->backing_store)
          CopyRect2D(win->render_ctx, x, y, widget->backing_store);
        break;
      case WIDGET_TYPE_CONTEXT2D:
        if (widget(Context2DWidget *)->ctx)
          Blot2D(win->render_ctx, x, y, widget(Context2DWidget *)->ctx);
        break;
      case WIDGET_TYPE_RADIO:
        @umami_radio_repaint(win, widget, x, y);
        break;
      case WIDGET_TYPE_INPUT:
        @umami_input_repaint(win, event, widget, x, y);
        break;
      case WIDGET_TYPE_LABEL:
        @umami_label_repaint(win, widget, x, y);
        break;
      case WIDGET_TYPE_HORZ_SLIDER:
        @umami_horz_slider_repaint(win, event, widget, x, y);
        break;
      case WIDGET_TYPE_VERT_SLIDER:
        @umami_vert_slider_repaint(win, event, widget, x, y);
        break;
      /*
      case WIDGET_TYPE_TTF_LABEL:
        if (widget(TrueTypeTextLabelWidget *)->text) {
          if (!widget(TrueTypeTextLabelWidget *)->prev_text ||
              StrCmp(widget(TrueTypeTextLabelWidget *)->prev_text,
                     widget(TrueTypeTextLabelWidget *)->text)) {
            // ttf_point_to_size =
            // @truetype_point_to_size(widget(TrueTypeTextLabelWidget*)->size);
            Spawn(&@umami_render_truetype_text, widget, , 1);
            // widget->backing_store = @truetype_TextRect2D(widget->width,
            // ttf_point_to_size, 2, truetype_fonts,
            // widget(TrueTypeTextLabelWidget*)->font,
            //    widget(TrueTypeTextLabelWidget*)->text,
            //    widget(TrueTypeTextLabelWidget*)->color,
            //    widget(TrueTypeTextLabelWidget*)->bgcolor);
            if (widget(TrueTypeTextLabelWidget *)->prev_text)
              Free(widget(TrueTypeTextLabelWidget *)->prev_text);
            widget(TrueTypeTextLabelWidget *)->prev_text =
                StrNew(widget(TrueTypeTextLabelWidget *)->text);
          }
        }
        if (widget->backing_store)
          CopyRect2D(win->render_ctx, x, y, widget->backing_store);
        break;
      */
      default:
        break;
      }
      if (widget->change) {
        if (widget->callback.change)
          widget->callback.change(widget);
        if (widget->echo) {
          if (widget->echo->callback.change)
            widget->echo->callback.change(widget);
        }
        widget->change = FALSE;
      }
    }
    @umami_skip_widget_repaint : widgets_list = widgets_list->next;
  }
}

U0 @umami_window_repaint(Window *win, I64 event) {
  if (!win)
    return;

  win->repainting = TRUE;

  win->render_ctx->width = win->width;
  win->render_ctx->height = win->height;
  if (!@gui_window_flag_is_set(win, WIN_FLAGS_NOFILL))
    MemSetU32(win->render_ctx->fb, Color(204, 204, 204, win->opacity),
              win->width * win->height);

  I64 title_bar_x;
  I64 title_bar_y;
  I64 title_bar_width;
  I64 title_bar_height = 0;
  I64 window_button_x;
  I64 origin_title_width;
  I64 pass;
  Bool repaint;
  U8 window_title[1024];

  if (@gui_window_flag_is_set(win, WIN_FLAGS_TITLE_BAR)) {
    title_bar_height = 17;
  }

  I64 widget_origin_x = 4;
  I64 widget_origin_y = 4;
  if (title_bar_height)
    widget_origin_y = 7 + title_bar_height;

  @umami_widgets_repaint(win, event, widget_origin_x, widget_origin_y);

  // Draw window margins
  Rect2D(win->render_ctx, 0, 0, win->width, 4,
         Color(204, 204, 204, win->opacity));
  Rect2D(win->render_ctx, 0, win->height - 4, win->width, 4,
         Color(204, 204, 204, win->opacity));
  Rect2D(win->render_ctx, 0, 0, 4, win->height,
         Color(204, 204, 204, win->opacity));
  Rect2D(win->render_ctx, win->width - 5, 0, 4, win->height,
         Color(204, 204, 204, win->opacity));

  // Draw window border
  Line2D(win->render_ctx, 0, 0, win->width - 1, 0,
         Color(255, 255, 255, win->opacity));
  Line2D(win->render_ctx, 0, 0, 0, win->height - 2,
         Color(255, 255, 255, win->opacity));
  Line2D(win->render_ctx, 1, win->height - 1, win->width - 1, win->height - 1,
         Color(156, 156, 156, win->opacity));
  Line2D(win->render_ctx, win->width - 1, 1, win->width - 1, win->height - 1,
         Color(156, 156, 156, win->opacity));

  title_bar_width = 0;

  if (@gui_window_flag_is_set(win, WIN_FLAGS_TITLE_BAR)) {
    title_bar_x = 4;
    title_bar_y = 4;
    title_bar_width = win->width - 8;

    if (@gui_window_flag_is_set(win, WIN_FLAGS_ICON)) {
      if (win->icon)
        Blot2D(win->render_ctx, 4, 4, win->icon);
      else
        Blot2D(win->render_ctx, 4, 4, umami_default_icon);
      title_bar_x = 24;
      title_bar_width -= 20;
    }

    origin_title_width = title_bar_width;

    repaint = FALSE;

    for (pass = 0; pass < 2; pass++) {
      title_bar_width = origin_title_width;
      window_button_x = win->width - 20;
      if (@gui_window_flag_is_set(win, WIN_FLAGS_CLOSE_BUTTON)) {
        if (pass) {
          if (win->mouse.x > window_button_x &&
              win->mouse.x < window_button_x + 16 && win->mouse.y > 5 &&
              win->mouse.y < 21 && win->button.close) {
            CopyRect2D(umami_title_bar_button, -32, -1,
                       umami_min_max_close_pressed);
            if (!Mouse.left && win->callback.close)
              win->callback.close(win);
          } else
            CopyRect2D(umami_title_bar_button, -32, -1, umami_min_max_close);
          CopyRect2D(win->render_ctx, window_button_x, 5,
                     umami_title_bar_button);
        }
        if (win->left_btn_down.x > window_button_x &&
            win->left_btn_down.x < window_button_x + 16 &&
            win->left_btn_down.y > 5 && win->left_btn_down.y < 21 &&
            Mouse.left && !win->button.close) {
          win->button.close = TRUE;
          repaint = TRUE;
        }
        window_button_x -= 16;
        title_bar_width -= 17;
      }
      if (@gui_window_flag_is_set(win, WIN_FLAGS_MAX_BUTTON)) {
        if (pass) {
          if (win->mouse.x > window_button_x &&
              win->mouse.x < window_button_x + 16 && win->mouse.y > 5 &&
              win->mouse.y < 21 && win->button.maximize) {
            CopyRect2D(umami_title_bar_button, -16, -1,
                       umami_min_max_close_pressed);
            if (!Mouse.left && win->callback.maximize)
              win->callback.maximize(win);
          }

          else
            CopyRect2D(umami_title_bar_button, -16, -1, umami_min_max_close);
          CopyRect2D(win->render_ctx, window_button_x, 5,
                     umami_title_bar_button);
        }
        if (win->left_btn_down.x > window_button_x &&
            win->left_btn_down.x < window_button_x + 16 &&
            win->left_btn_down.y > 5 && win->left_btn_down.y < 21 &&
            Mouse.left && !win->button.maximize) {
          win->button.maximize = TRUE;
          repaint = TRUE;
        }
        window_button_x -= 16;
        title_bar_width -= 17;
      }
      if (@gui_window_flag_is_set(win, WIN_FLAGS_MIN_BUTTON)) {
        if (pass) {
          if (win->mouse.x > window_button_x &&
              win->mouse.x < window_button_x + 16 && win->mouse.y > 5 &&
              win->mouse.y < 21 && win->button.minimize) {
            CopyRect2D(umami_title_bar_button, 0, -1,
                       umami_min_max_close_pressed);
            if (!Mouse.left && win->callback.minimize)
              win->callback.minimize(win);
          } else
            CopyRect2D(umami_title_bar_button, 0, -1, umami_min_max_close);
          CopyRect2D(win->render_ctx, window_button_x, 5,
                     umami_title_bar_button);
        }
        if (win->left_btn_down.x > window_button_x &&
            win->left_btn_down.x < window_button_x + 16 &&
            win->left_btn_down.y > 5 && win->left_btn_down.y < 21 &&
            Mouse.left && !win->button.minimize) {
          win->button.minimize = TRUE;
          repaint = TRUE;
        }
        window_button_x -= 16;
        title_bar_width -= 17;
      }
    }

    if (!Mouse.left) {
      if (win->button.close)
        repaint = TRUE;
      if (win->button.maximize)
        repaint = TRUE;
      if (win->button.minimize)
        repaint = TRUE;
      win->button.close = FALSE;
      win->button.maximize = FALSE;
      win->button.minimize = FALSE;
    }

    if (repaint) {
      @umami_window_repaint(win, event);
      return;
    }

    if (title_bar_width) {
      win->title_bar_x = title_bar_x;
      win->title_bar_width = title_bar_width;
    }

    StrCpy(&window_title, &win->title);
    if (win == Compositor.active_win) {
      HGradientRect2D(win->render_ctx, title_bar_x, title_bar_y,
                      title_bar_width, title_bar_height,
                      Color(85, 18, 132, win->opacity),
                      Color(233, 15, 240, win->opacity));
      PutS2D(win->render_ctx, Compositor.theme.font.menu, title_bar_x + 4,
             title_bar_y + 4, Color(255, 255, 255, win->opacity),
             title_bar_width, &window_title);
    } else {
      Rect2D(win->render_ctx, title_bar_x, title_bar_y, title_bar_width,
             title_bar_height, Color(235, 235, 235, win->opacity));
      PutS2D(win->render_ctx, Compositor.theme.font.menu, title_bar_x + 4,
             title_bar_y + 4, Color(156, 156, 156, win->opacity),
             title_bar_width, &window_title);
    }

    Line2D(win->render_ctx, title_bar_x, title_bar_y,
           title_bar_x + title_bar_width - 1, title_bar_y,
           Color(156, 156, 156, win->opacity));
    Line2D(win->render_ctx, title_bar_x, title_bar_y, title_bar_x,
           title_bar_y + title_bar_height - 2,
           Color(156, 156, 156, win->opacity));

    Line2D(win->render_ctx, title_bar_x + title_bar_width - 1, title_bar_y,
           title_bar_x + title_bar_width - 1,
           title_bar_y + title_bar_height - 1,
           Color(255, 255, 255, win->opacity));
    Line2D(win->render_ctx, title_bar_x, title_bar_y + title_bar_height - 1,
           title_bar_x + title_bar_width - 1,
           title_bar_y + title_bar_height - 1,
           Color(255, 255, 255, win->opacity));

    if (@gui_window_flag_is_set(win, WIN_FLAGS_RESIZABLE))
      Blot2D(win->render_ctx, win->width - 16, win->height - 16,
             umami_corner_resize);
  }

  win->backing_store->width = win->render_ctx->width;
  win->backing_store->height = win->render_ctx->height;
  if (!@gui_window_flag_is_set(win, WIN_FLAGS_NOFILL))
    MemCpyU32(win->backing_store->fb, win->render_ctx->fb,
              win->render_ctx->width * win->render_ctx->height);
  if (@gui_window_flag_is_set(win, WIN_FLAGS_NOFILL))
    MemCpyU32(win->backing_store->fb, win->render_ctx->fb, (win->width) * 20);

  win->repainting = FALSE;
}

Compositor.theme.color.active_border = Color(0, 0, 0);
Compositor.theme.color.hilight = Color(233, 15, 240);

BitmapFont *@umami_theme_bitmapfont_001 = @bitmapfont_new_from_context2d(
    PNG.FileToContext2D("T:/Media/Themes/Umami/BitmapFont/menu.png"),
    "Eight Bit Dragon",
    "`1234567890-=[]\;',./"
    "~!@#\d%^&*()_+{}|:\"<>?"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz");
@umami_theme_bitmapfont_001->line_height = 12;
BitmapFonts.Add(@umami_theme_bitmapfont_001);

BitmapFont *@umami_theme_bitmapfont_002 = @bitmapfont_new_from_context2d(
    PNG.FileToContext2D("T:/Media/Themes/Umami/BitmapFont/sans.png"),
    "Nineteen Ninety Three",
    "`1234567890-=[]\;',./"
    "~!@#\d%^&*()_+{}|:\"<>?"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz");
@umami_theme_bitmapfont_002->line_height = 10;
BitmapFonts.Add(@umami_theme_bitmapfont_002);

BitmapFont *@umami_theme_bitmapfont_003 = @bitmapfont_new_from_context2d(
    PNG.FileToContext2D("T:/Media/Themes/Umami/BitmapFont/monospace.png"),
    "Spleen",
    " !\"#\d%&'()*+,-./"
    "0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`"
    "abcdefghijklmnopqrstuvwxyz{|}~",
    7);
@umami_theme_bitmapfont_003->line_height = 16;
BitmapFonts.Add(@umami_theme_bitmapfont_003);

Compositor.theme.font.menu = BitmapFonts.GetByName("Eight Bit Dragon");
Compositor.theme.font.sans = BitmapFonts.GetByName("Nineteen Ninety Three");
Compositor.theme.font.monospace = BitmapFonts.GetByName("Spleen");

Compositor.theme.window.min_width = 128;
Compositor.theme.window.min_height = 128;

Compositor.theme.window_repaint = &@umami_window_repaint;
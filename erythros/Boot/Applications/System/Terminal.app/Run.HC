Gui.App();

Window *win = Compositor.CreateWindow(18, 62, 684, 474, WIN_FLAGS_DEFAULT);
Gui.Window.EnableAlphaChannel(win);
Gui.Window.SetOpacity(win, 224);
Gui.Window.SetIcon(win, PNG.FileToContext2D("Icon.png"));
Gui.Window.SetTitle(win, "Terminal");

TerminalWidget *active_term = NULL;
@shell *sh = NULL;

U0 @terminal_keypress_callback(Window *win, I64 key) {
  if (!active_term || Compositor.active_win != win)
    return;
  I64 i;
  U8 send_key[4];
  MemSetU32(&send_key, 0, 1);
  switch (key) {
  case SC_CURSOR_UP:
    send_key[0] = '\x1b';
    send_key[1] = '[';
    send_key[2] = 'A';
    break;
  case SC_CURSOR_DOWN:
    send_key[0] = '\x1b';
    send_key[1] = '[';
    send_key[2] = 'B';
    break;
  case SC_CURSOR_LEFT:
    send_key[0] = '\x1b';
    send_key[1] = '[';
    send_key[2] = 'D';
    break;
  case SC_CURSOR_RIGHT:
    send_key[0] = '\x1b';
    send_key[1] = '[';
    send_key[2] = 'C';
    break;
  case SC_DELETE:
    send_key[0] = 21;
    break;
  case SC_BACKSPACE:
    send_key[0] = 8;
    break;
  case SC_TAB:
    send_key[0] = 9;
    break;
  case SC_ENTER:
    send_key[0] = 10;
    break;
  case SC_HOME:
    send_key[0] = 22;
    break;
  case SC_END:
    send_key[0] = 23;
    break;
  case SC_PAGE_UP:
    send_key[0] = 24;
    break;
  case SC_PAGE_DOWN:
    send_key[0] = 25;
    break;
  case SC_ESC:
    send_key[0] = 27;
    break;
  case 0x02 ... 0x0D:
  case 0x10 ... 0x1B:
  case 0x1E ... 0x29:
  case 0x2B ... 0x35:
  case 0x39:
    if (!KeyDown(SC_SHIFT)) {
      if (KeyDown(SC_CTRL)) {
        switch (key) {
        case Char2ScanCode('c'):
          send_key[0] = 0x03;
          sh->break = TRUE;
          break;
        default:
          break;
        }
      } else {
        send_key[0] = NORMAL_KEY_SCAN_DECODE_TABLE(U8 *)[key];
      }
    } else {
      if (key == 0x39) // Handle TempleOS SHIFT-SPACE character.
        send_key[0] = ' ';
      else {
        if (KeyDown(SC_CTRL)) {
          // terminal copy paste handling
        } else {
          send_key[0] = SHIFT_KEY_SCAN_DECODE_TABLE(U8 *)[key];
        }
      }
    };
    break;
  default:
    return;
    break;
  }
  for (i = 0; i < 4; i++)
    if (send_key[i] && active_term->output)
      FifoU8Ins(active_term->output, send_key[i]);
}

TerminalWidget *t = Gui.CreateWidget(win, WIDGET_TYPE_TERMINAL, 0, 0, 120, 120);
t->pointer = Compositor.theme.pointer.text;
VerticalScrollBarWidget *vscroll =
    Gui.CreateWidget(win, WIDGET_TYPE_VERT_SCROLLBAR, 0, 0, 16, 128);
vscroll->height = 128;
Context2DWidget *status =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 0, 0, Display.Width(), 44);
status->ctx = NewContext2D(Display.Width(), 44);
Fill2D(status->ctx, Color(204, 204, 204, win->opacity));

U0 @terminal_create_new_instance() {
  U32 init_bg_color = t->color.background;
  init_bg_color.u8[3] = win->opacity;
  Fill2D(t->backing_store, init_bg_color);
  active_term = t;
  sh = @shell_new;
  sh->session = &Compositor.session;
  t->output = sh->input;
  sh->output = t->input;
}

U0 window_close(Window *win) {
  if (sh)
    if (sh->task && sh->exit)
      Free(sh);
  if (win == Compositor.active_win)
    Gui.Window.SetFocus(Compositor.GetWindowByTitle("Wallpaper"));
  Compositor.UnregisterForGlobalInputEvents(win);
  Compositor.DestroyWindow(win);
}

U0 @terminal_vscroll_change(Widget *) {
  I64 i = 0;
  I64 max_scroll = vscroll->height - 32;
  F64 f1 = (ToF64(max_scroll) / ToF64(t->cursor.y + t->max.y - 2));
  while (vscroll->scroll > ToI64(i * f1))
    i++;
  t->scroll.y = i;
  t->refresh = TRUE;
  Gui.Window.Refresh(win);
}

U0 Main() {
  Compositor.RegisterForGlobalInputEvents(win);
  Gui.Window.SetCallback(win, "keypress", &@terminal_keypress_callback);
  Gui.Widget.SetCallback(vscroll, "change", &@terminal_vscroll_change);
  I64 prev_width = -1;
  I64 prev_height = -1;
  I64 prev_max_x = -1;
  I64 prev_max_y = -1;
  F64 f1;
  Gui.Window.SetFocus(win);
  Gui.Window.SetCallback(win, "close", &window_close);

  @terminal_create_new_instance;

  while (win) {
    // FIXME: This should be event-driven...
    if (win->width != prev_width || win->height != prev_height) {
      win->width = 3 + RoundI64(win->width, 8);
      win->height = RoundI64(win->height, 16);
      prev_width = win->width;
      prev_height = win->height;
      if (active_term) {
        active_term->width = win->width;
        active_term->height = win->height;
      }
      status->y = win->height - 44;
      goto terminal_update_vscroll;
    }
    if (prev_max_x != t->max.x || prev_max_y != t->max.y) {
    terminal_update_vscroll:
      if (!t->max.y) {
        vscroll->x = Display.Width(); // Hide
      } else {
        vscroll->x = win->width - vscroll->width - 9;
        vscroll->height = win->height - 44;
        f1 = (ToF64(t->size.rows) / ToF64(1 + t->cursor.y + t->max.y));
        vscroll->length = ToI64((vscroll->height - 32) * f1);
        vscroll->scroll = vscroll->height;
      }
      prev_max_x = t->max.x;
      prev_max_y = t->max.y;
      // System.Log(Fs, "vscroll->scroll: %d", vscroll->scroll);

      Gui.Window.Refresh(win);
    }
    if (FifoU8Cnt(active_term->input))
      Gui.Window.Refresh(win);
    if (sh->exit) {
      win->callback.close(win);
      return;
    }
    Sleep(10);
  }
}

Main;
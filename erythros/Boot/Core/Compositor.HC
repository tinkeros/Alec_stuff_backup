#define CPZ_MSG_WIN_CREATE 0x1001
#define CPZ_MSG_WIN_DESTROY 0x1002
#define CPZ_MSG_WIN_REPAINT 0x1003
#define CPZ_MSG_WIN_MOVE_TO 0x1004
#define CPZ_MSG_WIN_RESIZE_TO 0x1005
#define CPZ_MSG_WIN_MOUSE_AT 0x1006
#define CPZ_MSG_WIN_MOUSE_WHEEL 0x1007
#define CPZ_MSG_WIN_LEFT_BTN_UP 0x1008
#define CPZ_MSG_WIN_LEFT_BTN_DOWN 0x1009
#define CPZ_MSG_WIN_RIGHT_BTN_UP 0x100A
#define CPZ_MSG_WIN_RIGHT_BTN_DOWN 0x100B
#define CPZ_MSG_WIN_KEY_PRESS 0x100C
#define CPZ_MSG_WIN_WIDGET_DESTROY 0x100D
#define CPZ_MSG_WIN_SET_Z_INDEX 0x100E
#define CPZ_MSG_SET_WALLPAPER 0x100F

#define CPZ_WALLPAPER_CENTERED 0x0
#define CPZ_WALLPAPER_AUTORESIZE 0x1
#define CPZ_WALLPAPER_REPEAT 0x2

class @compositor_menubar {
  Window *win;
  CTask *task;
  TextInputWidget *title;
};

class @compositor_windows_list {
  @compositor_windows_list *prev;
  @compositor_windows_list *next;
  Window *window;
};

class @compositor {
  I64 next_id;
  I64 max_z_index;
  Window *active_win;
  Context2D *blend_ctx;
  Context2D *ctx;
  Context2D *pointer;
  @compositor_menubar menubar;
  @compositor_windows_list *windows;
  @compositor_windows_list *global_input_event_listeners;
  Bounds2D bounds;
  @mouse mouse;
  @session session;
  @theme theme;
  Bool in_drag;
  Bool in_resize;
  CTask *task;
  U0(*Init)
  ();
  Window *(*CreateWindow)(I64 x, I64 y, I64 width, I64 height,
                          I64 flags = WIN_FLAGS_DEFAULT, U8 *title = NULL,
                          Context2D *icon = NULL);
  U0 (*DestroyWindow)(Window * win);
  Window (*GetWindowByTitle)(U8 * title);
  Window (*GetWindowByZIndex)(I64 index);
  U0 (*HideWindow)(Window * win);
  U0 (*ShowWindow)(Window * win);
  U0 (*RegisterForGlobalInputEvents)(Window * win);
  U0 (*UnregisterForGlobalInputEvents)(Window * win);
  U0 (*SetWallpaper)(Context2D *ctx, U32 mode = CPZ_WALLPAPER_AUTORESIZE, U32 background = Color(0, 0, 0));
  U0(*Task)
  ();
};

@compositor Compositor;

U0 @compositor_add_window_to_list(Window *win) {
  @compositor_windows_list *win_list = Compositor.windows;
  @compositor_windows_list *win_next = CAlloc(sizeof(@compositor_windows_list));
  while (win_list->next) {
    win_list = win_list->next;
  }
  win_next->window = win;
  win_next->prev = win_list;
  win_list->next = win_next;
}

U0 @compositor_add_global_input_event_listener_to_list(Window *win) {
  @compositor_windows_list *win_list = Compositor.global_input_event_listeners;
  @compositor_windows_list *win_next = CAlloc(sizeof(@compositor_windows_list));
  while (win_list->next) {
    win_list = win_list->next;
  }
  win_next->window = win;
  win_next->prev = win_list;
  win_list->next = win_next;
}

U0 @compositor_remove_global_input_event_listener_from_list(Window *win) {
  @compositor_windows_list *win_list = Compositor.global_input_event_listeners;
  @compositor_windows_list *win_list_prev = NULL;
  @compositor_windows_list *win_list_next = NULL;

  while (win_list) {
    if (win_list->window == win) {
      win_list_prev = win_list->prev;
      win_list_next = win_list->next;
      win_list_prev->next = win_list_next;
      win_list_next->prev = win_list_prev;
      Free(win_list);
      return;
    }
    win_list = win_list->next;
  }
}

U0 @compositor_refresh(Window *win) {
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  msg->client = win->client;
  msg->type = CPZ_MSG_WIN_REPAINT;
  msg->payload = win;
  Ipc.MsgSend(msg->client, msg);
}

U0 @compositor_set_z_index(Window *win, I64 index) {
  if (!win)
    return;
  I64 i = 0;
  @compositor_windows_list *win_index = NULL;
  @compositor_windows_list *win_list = Compositor.windows->next;
  @compositor_windows_list *prev = NULL;
  @compositor_windows_list *next = NULL;
  while (win_list) {
    if (win_list->window == win) {
      win_index = win_list;
      if (win_index->prev)
        prev = win_index->prev;
      if (win_index->next)
        next = win_index->next;
      if (prev)
        prev->next = next;
      if (next)
        next->prev = prev;
      break;
    }
    win_list = win_list->next;
  }

  win_list = Compositor.windows->next;
  prev = NULL;

  while (win_list) {
    if (i == index) {
      prev = win_list->prev;
      if (prev)
        prev->next = win_index;
      win_index->prev = prev;
      win_index->next = win_list;
      win_list->prev = win_index;
      break;
    }
    i++;
    win_list = win_list->next;
  }
}

U0 @compositor_set_z_index_send_msg(Window *win, I64 index) {
  if (!win)
    return;
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  msg->client = win->client;
  msg->type = CPZ_MSG_WIN_SET_Z_INDEX;
  msg->payload = win;
  msg->i64 = index;
  Ipc.MsgSend(Compositor.task, msg);
}

U0 @compositor_set_wallpaper(Context2D *ctx, U32 mode, U32 background) { // Sets the wallpaper, doesn't Free the Context, you need to Free it after.
  if(!ctx) {
    return;
  }
  Window *win = Compositor.GetWindowByTitle("Wallpaper");
  Context2D *tmp = ctx;

  if(!win) { // Please, don't call this if the system isn't initialized 
    System.Log(Fs, "Trying to set the Wallpaper, but the System isn't initialized completely!");
    return;
  }

  if(Display.Width() != ctx->width || Display.Height() != ctx->height) {
    if(Display.Width() > ctx->width && Display.Height() > ctx->height) { 
      switch(mode) {
        case CPZ_WALLPAPER_CENTERED:
          tmp = NewContext2D(Display.Width(), Display.Height());
          Fill2D(tmp, background);
          CopyRect2D(tmp, 
                    (Display.Width() / 2) - (ctx->width / 2),
                    (Display.Height() / 2) - (ctx->height / 2),
                     ctx);
          break;
        case CPZ_WALLPAPER_REPEAT:
          tmp = NewContext2D(Display.Width(), Display.Height());
          I64 x = 0;
          I64 y = 0;
          while(TRUE) {
            CopyRect2D(tmp, x, y, ctx);
            x += ctx->width;
            if(x >= Display.Width()) {
              x = 0;
              y += ctx->height;
              if(y >= Display.Height())
                break;
            }
          }
          break;
        case CPZ_WALLPAPER_AUTORESIZE:
        default:
          tmp = Scale2D(tmp, Display.Width() / ToF64(ctx->width), Display.Height() / ToF64(ctx->height));
          break;
      }
    } else { 
      tmp = Scale2D(tmp, Display.Width() / ToF64(ctx->width), Display.Height() / ToF64(ctx->height));
    }
  }

  MemCpyU32(win->backing_store->fb, tmp->fb,
            Display.Width() * Display.Height());
  if(tmp != ctx) // We don't want to delete the context so it can be reused later (If necessary)
    DelContext2D(tmp);
}

U0 @compositor_set_wallpaper_send_msg(Context2D *ctx, U32 mode = CPZ_WALLPAPER_AUTORESIZE, U32 background = Color(0, 0, 0)) {
  if (!ctx)
    return;
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  msg->client = Fs;
  msg->type = CPZ_MSG_SET_WALLPAPER;
  msg->payload = ctx;
  msg->i64.u32[0] = mode;
  msg->i64.u32[1] = background;
  Ipc.MsgSend(Compositor.task, msg);
}

U0 @compositor_ipc_queue_process() {
  Window *win;
  IpcMessage *msg;
  @compositor_windows_list *win_list = Compositor.windows->next;
  @compositor_windows_list *prev;
  @compositor_windows_list *next;
  msg = Ipc.MsgRecv();
  if (msg) {
    switch (msg->type) {
    case CPZ_MSG_WIN_CREATE:
      win = msg->payload;
      win->client = msg->client;
      win->render_ctx = NewContext2D(Display.Width(), Display.Height());
      win->backing_store = NewContext2D(Display.Width(), Display.Height());
      win->backing_store->width = win->width;
      win->backing_store->height = win->height;
      @compositor_add_window_to_list(win);
      System.Log(Fs, "Received message ← CreateWindow (%dx%d at %d, %d)",
                 win->width, win->height, win->x, win->y);
      Free(msg);
      msg = CAlloc(sizeof(IpcMessage));
      msg->client = win->client;
      msg->type = CPZ_MSG_WIN_REPAINT;
      msg->payload = win;
      Ipc.MsgSend(msg->client, msg);
      break;
    case CPZ_MSG_WIN_DESTROY:
      win = msg->payload;
      while (win_list) {
        if (win_list->window == win) {
          prev = win_list->prev;
          next = win_list->next;
          prev->next = next;
          next->prev = prev;
          if (win_list->window->backing_store)
            DelContext2D(win_list->window->backing_store);
          if (win_list->window->render_ctx)
            DelContext2D(win_list->window->render_ctx);
          // FIXME: free Widgets
          Free(win_list->window);
          Free(win_list);
          Compositor.active_win = NULL;
          System.Log(Fs, "Received message ← DestroyWindow 0x%08x", win);
          break;
        }
        win_list = win_list->next;
      }
      break;
    case CPZ_MSG_WIN_SET_Z_INDEX:
      @compositor_set_z_index(msg->payload, msg->i64);
      System.Log(Fs, "Received message ← SetZIndex (%08X, %d)", msg->payload,
                 msg->i64);
      Free(msg);
      break;
    case CPZ_MSG_SET_WALLPAPER:
      Context2D *ctx = msg->payload;
      U32 mode = msg->i64.u32[0];
      U32 background = msg->i64.u32[1];
      System.Log(Fs, "Received message ← SetWallpaper (%08X, Mode: %d, Background: %d)", ctx,
                 mode, background);
      @compositor_set_wallpaper(ctx, mode, background);
      Free(msg);
      break;
    default:
      Free(msg);
      break;
    }
  }
}

Window *@compositor_get_window_by_title(U8 *title) {
  @compositor_windows_list *win_list = Compositor.windows->next;
  while (win_list) {
    if (win_list->window)
      if (!StrCmp(&win_list->window->title, title))
        return win_list->window;
    win_list = win_list->next;
  }
  return NULL;
}

Window *@compositor_get_window_by_z_index(I64 index) {
  @compositor_windows_list *win_list = Compositor.windows->next;
  I64 i = 0;
  while (win_list) {
    if (i == index)
      return win_list->window;
    i++;
    win_list = win_list->next;
  }
  return NULL;
}

U0 @compositor_handle_active_window_flags() {
  if (!Compositor.active_win)
    return;
  if (Compositor.active_win->flags & WIN_FLAGS_MINIMIZED) {
    Compositor.active_win = Compositor.GetWindowByTitle("Wallpaper");
    if (Compositor.menubar.win) {
      Gui.Widget.SetText(Compositor.menubar.title,
                         &Compositor.active_win->title);
      Gui.Window.Refresh(Compositor.menubar.win);
    }
  }
}

Context2D *@compositor_set_theme_pointer(U8 *path, U8 *pointer) {
  U8 file_path[512];
  StrPrint(&file_path, "%sPointer/%s.png", path, pointer);
  Context2D *ctx = PNG.FileToContext2D(&file_path);
  return ctx;
}

U0 @compositor_set_theme_wallpaper(U8 *path) {
  U8 file_path[512];
  StrPrint(&file_path, "%s%s", path, "wallpaper.png");
  Compositor.theme.wallpaper = PNG.FileToContext2D(file_path);
  if (!Compositor.theme.wallpaper) {
    Compositor.theme.wallpaper = NewContext2D(Display.Width(), Display.Height());
  }
}

U0 @compositor_set_theme(U8 *theme) {
  U8 theme_path[512];
  U8 exec_path[512];
  StrPrint(&theme_path, "T:/Media/Themes/%s/", theme);
  if (!IsDir(&theme_path)) {
    System.Log(Fs, "SetTheme failed: Theme does not exist: '%s'", theme);
    return;
  }
  // FIXME: This is disgusting
  Compositor.theme.pointer.pointer =
      @compositor_set_theme_pointer(&theme_path, "pointer");
  Compositor.theme.pointer.pen =
      @compositor_set_theme_pointer(&theme_path, "pen");
  Compositor.theme.pointer.move =
      @compositor_set_theme_pointer(&theme_path, "move");
  Compositor.theme.pointer.link =
      @compositor_set_theme_pointer(&theme_path, "link");
  Compositor.theme.pointer.horz =
      @compositor_set_theme_pointer(&theme_path, "horz");
  Compositor.theme.pointer.vert =
      @compositor_set_theme_pointer(&theme_path, "vert");
  Compositor.theme.pointer.text =
      @compositor_set_theme_pointer(&theme_path, "text");
  Compositor.theme.pointer.cross =
      @compositor_set_theme_pointer(&theme_path, "cross");
  Compositor.theme.pointer.dgn1 =
      @compositor_set_theme_pointer(&theme_path, "dgn1");
  Compositor.theme.pointer.dgn2 =
      @compositor_set_theme_pointer(&theme_path, "dgn2");
  Compositor.theme.pointer.help =
      @compositor_set_theme_pointer(&theme_path, "help");
  Compositor.theme.pointer.alternate =
      @compositor_set_theme_pointer(&theme_path, "alternate");
  Compositor.theme.pointer.unavailable =
      @compositor_set_theme_pointer(&theme_path, "unavailable");

  @compositor_set_theme_wallpaper(&theme_path);

  StrPrint(&exec_path, "%sTheme.HC", &theme_path);
  ExeDoc(DocRead(exec_path));
}

Bool @compositor_active_win_flag_is_set(U64 flag) {
  if (@gui_window_flag_is_set(Compositor.active_win, flag))
    return TRUE;
  return FALSE;
}

U0 @compositor_set_pointer(Context2D *pointer = NULL) {
  if (!pointer)
    pointer = Compositor.theme.pointer.pointer;
  if (Animation2D.IsAnimation(pointer))
    Compositor.pointer = Animation2D.Frame(pointer);
  else
    Compositor.pointer = pointer;
  Mouse.PointerSet(Compositor.pointer->fb, Compositor.pointer->width,
                   Compositor.pointer->height);
}

U0 @compositor_set_active_window(Window *win) {
  if (!win)
    return;
  if (Compositor.active_win == win)
    return;
  IpcMessage *msg;
  @compositor_windows_list *win_list = Compositor.windows->next;
  @compositor_windows_list *prev;
  @compositor_windows_list *next;
  while (win_list) {
    if (!(win->flags & WIN_FLAGS_NO_REINDEX)) {
      if (win_list->window == win && win_list->next) {
        prev = win_list->prev;
        next = win_list->next;
        prev->next = next;
        next->prev = prev;
        while (next->next) {
          next = next->next;
        }
        win_list->prev = next;
        win_list->next = NULL;
        next->next = win_list;
        break;
      }
    }
    win_list = win_list->next;
  }
  if (Compositor.active_win && Compositor.active_win != win) {
    msg = CAlloc(sizeof(IpcMessage));
    msg->client = Compositor.active_win->client;
    msg->type = CPZ_MSG_WIN_REPAINT;
    msg->payload = Compositor.active_win;
    Ipc.MsgSend(msg->client, msg);
  }
  Compositor.active_win = win;
  if (Compositor.menubar.win && Compositor.menubar.title) {
    Gui.Widget.SetText(Compositor.menubar.title, win->title);
    Gui.Window.Refresh(Compositor.menubar.win);
  }
  System.Log(Fs, "SetActiveWindow (%dx%d at %d, %d)", win->width, win->height,
             win->x, win->y);
  msg = CAlloc(sizeof(IpcMessage));
  msg->client = win->client;
  msg->type = CPZ_MSG_WIN_REPAINT;
  msg->payload = win;
  Ipc.MsgSend(msg->client, msg);
  @compositor_set_pointer();
}

U0 @compositor_handle_window_resize() {
  if (!Compositor.active_win)
    return;
  if (Compositor.active_win->signature != WIN_SIGNATURE)
    return;
  if (!(@compositor_active_win_flag_is_set(WIN_FLAGS_RESIZABLE)))
    goto resize_set_pointer;

  Bool set_pointer_to_resize = FALSE;
  I64 new_width;
  I64 new_height;

  // Bottom right
  if (Mouse.x > Compositor.active_win->x + Compositor.active_win->width - 16 &&
      Mouse.x < Compositor.active_win->x + Compositor.active_win->width &&
      Mouse.y > Compositor.active_win->y + Compositor.active_win->height - 16 &&
      Mouse.y < Compositor.active_win->y + Compositor.active_win->height) {
    @compositor_set_pointer(Compositor.theme.pointer.dgn1);
    set_pointer_to_resize = TRUE;
  }

  if (Mouse.left && !Compositor.mouse.left && Compositor.active_win) {
    if (Mouse.x >
            Compositor.active_win->x + Compositor.active_win->width - 16 &&
        Mouse.x < Compositor.active_win->x + Compositor.active_win->width &&
        Mouse.y >
            Compositor.active_win->y + Compositor.active_win->height - 16 &&
        Mouse.y < Compositor.active_win->y + Compositor.active_win->height) {
      Compositor.active_win->origin.x = Compositor.active_win->x;
      Compositor.active_win->origin.y = Compositor.active_win->y;
      Compositor.active_win->origin.width = Compositor.active_win->width;
      Compositor.active_win->origin.height = Compositor.active_win->height;
      Compositor.active_win->origin.mouse_x = Mouse.x;
      Compositor.active_win->origin.mouse_y = Mouse.y;
      Compositor.in_resize = TRUE;
    }
  }

  if (!Mouse.left) {
    Compositor.in_drag = FALSE;
    Compositor.in_resize = FALSE;
  }

  if (Compositor.in_resize) {
    // FIXME: Set minimum width and height in Compositor.theme or Window.
    new_width = Max(16, Compositor.active_win->origin.width +
                            (Mouse.x - Compositor.active_win->origin.mouse_x));
    new_height = Max(16, Compositor.active_win->origin.height +
                             (Mouse.y - Compositor.active_win->origin.mouse_y));
    new_width = Max(Compositor.theme.window.min_width, new_width);
    new_height = Max(Compositor.theme.window.min_height, new_height);
    if (Compositor.active_win->width != new_width ||
        Compositor.active_win->height != new_height &&
            !Compositor.active_win->repainting) {
      Window *win = Compositor.active_win;
      IpcMessage *msg = CAlloc(sizeof(IpcMessage));
      System.Log(Fs,
                 "Sent message → WindowResizeTo (%dx%d at %d, %d) to (%dx%d)",
                 Compositor.active_win->width, Compositor.active_win->height,
                 Compositor.active_win->x, Compositor.active_win->y, new_width,
                 new_height);

      if (win->signature != WIN_SIGNATURE)
        return;

      win->width = new_width;
      win->height = new_height;
      msg->client = Compositor.active_win->client;
      msg->type = CPZ_MSG_WIN_RESIZE_TO;
      msg->payload = win;
      Ipc.MsgSend(msg->client, msg);
    }
  }

resize_set_pointer:
  // FIXME: Move this to @compositor_set_pointer_for_window() or somewhere more
  // appropriate?
  if (!set_pointer_to_resize) {
    if (Compositor.active_win)
      if (@gui_window_is_hovered(Compositor.active_win))
        if (Compositor.active_win->hovered_widget)
          if (Compositor.active_win->hovered_widget->pointer)
            @compositor_set_pointer(
                Compositor.active_win->hovered_widget->pointer);
          else {
            if (Compositor.active_win->pointer)
              @compositor_set_pointer(Compositor.active_win->pointer);
            else
              @compositor_set_pointer();
          }
        else {
          if (Compositor.active_win->pointer)
            @compositor_set_pointer(Compositor.active_win->pointer);
          else
            @compositor_set_pointer();
        }
      else
        @compositor_set_pointer();
    else
      @compositor_set_pointer();
  }
}

U0 @compositor_handle_window_drag() {
  if (!(@compositor_active_win_flag_is_set(WIN_FLAGS_MOVABLE)))
    return;

  I64 title_length;
  I64 title_offset;
  I64 new_x;
  I64 new_y;

  // FIXME: Get title_length and title_offset values from theme and Window
  // flags.
  title_offset = 0;
  title_length = Compositor.active_win->width;

  if (@compositor_active_win_flag_is_set(WIN_FLAGS_TITLE_BAR)) {
    title_offset = Compositor.active_win->title_bar_x;
    title_length = Compositor.active_win->title_bar_width;
  }

  if (Mouse.left && !Compositor.mouse.left && Compositor.active_win) {
    if (Mouse.x > Compositor.active_win->x + title_offset &&
        Mouse.x < Compositor.active_win->x + title_offset + title_length &&
        Mouse.y > Compositor.active_win->y &&
        Mouse.y < Compositor.active_win->y + 18) {
      Compositor.active_win->origin.x = Compositor.active_win->x;
      Compositor.active_win->origin.y = Compositor.active_win->y;
      Compositor.active_win->origin.width = Compositor.active_win->width;
      Compositor.active_win->origin.height = Compositor.active_win->height;
      Compositor.active_win->origin.mouse_x = Mouse.x;
      Compositor.active_win->origin.mouse_y = Mouse.y;
      Compositor.in_drag = TRUE;
    }
  }

  if (!Mouse.left) {
    Compositor.in_drag = FALSE;
    Compositor.in_resize = FALSE;
  }

  if (Compositor.in_drag) {
    new_x = Compositor.active_win->origin.x +
            (Mouse.x - Compositor.active_win->origin.mouse_x);
    new_y = Compositor.active_win->origin.y +
            (Mouse.y - Compositor.active_win->origin.mouse_y);
    if (Compositor.active_win->x != new_x ||
        Compositor.active_win->y != new_y) {
      Window *win = Compositor.active_win;
      IpcMessage *msg = CAlloc(sizeof(IpcMessage));
      System.Log(
          Fs, "Sent message → WindowMoveTo (%dx%d at %d, %d) to (%d, %d)",
          Compositor.active_win->width, Compositor.active_win->height,
          Compositor.active_win->x, Compositor.active_win->y, new_x, new_y);
      win->x = Min(Compositor.bounds.x2, Max(Compositor.bounds.x1, new_x));
      win->y = Min(Compositor.bounds.y2, Max(Compositor.bounds.y1, new_y));
      msg->client = Compositor.active_win->client;
      msg->type = CPZ_MSG_WIN_MOVE_TO;
      msg->payload = win;
      Ipc.MsgSend(msg->client, msg);
    }
  }
}

U0 @compositor_handle_window_select() {
  Window *win;
  @compositor_windows_list *win_list;
  if (Mouse.left && !Compositor.mouse.left) {
    if (((Mouse.x < Compositor.active_win->x ||
          Mouse.x > Compositor.active_win->x + Compositor.active_win->width) ||
         (Mouse.y < Compositor.active_win->y ||
          Mouse.y >
              Compositor.active_win->y + Compositor.active_win->height)) ||
        @compositor_active_win_flag_is_set(WIN_FLAGS_NO_REINDEX)) {
      win_list = Compositor.windows->next;
      while (win_list->next) {
        win_list = win_list->next;
      }
      while (win_list) {
        if (Mouse.x > win_list->window->x &&
            Mouse.x < win_list->window->x + win_list->window->width &&
            Mouse.y > win_list->window->y &&
            Mouse.y < win_list->window->y + win_list->window->height) {
          if (Compositor.active_win != win_list->window &&
              !(@gui_window_flag_is_set(win_list->window,
                                        WIN_FLAGS_MINIMIZED)) &&
              !(@gui_window_flag_is_set(win_list->window, WIN_FLAGS_HIDDEN))) {
            @compositor_set_active_window(win_list->window);
            return;
          }
        }
        win_list = win_list->prev;
      }
    }
  }
}

U0 @compositor_handle_global_input_events() {
  // FIXME: Handle registered global input events
  IpcMessage *msg;
  I64 mouse_x;
  I64 mouse_y;
  I64 type = NULL;
  Bool mouse_left = Mouse.left;
  Bool mouse_right = Mouse.right;

  I64 key = Keyboard.active_key;
  I64 tS = Keyboard.active_key_tS;

  if (key && tS != Keyboard.last_key_tS) {

    @compositor_windows_list *win_list =
        Compositor.global_input_event_listeners->next;
    while (win_list) {
      msg = CAlloc(sizeof(IpcMessage));
      System.Log(Fs, "Sent message → WinKeyPress [%08x] to window 0x%08x", key,
                 win_list->window);
      msg->client = win_list->window->client;
      msg->type = CPZ_MSG_WIN_KEY_PRESS;
      msg->payload = win_list->window;
      msg->i64 = key;
      Ipc.MsgSend(msg->client, msg);
      win_list = win_list->next;
    }
  }
}

U0 @compositor_register_global_input_event_listener(Window *win) {
  @compositor_add_global_input_event_listener_to_list(win);
}

U0 @compositor_unregister_global_input_event_listener(Window *win) {
  @compositor_remove_global_input_event_listener_from_list(win);
}

U0 @compositor_handle_window_input_events(Window *win) {
  if (!win)
    return;

  IpcMessage *msg;
  I64 mouse_x;
  I64 mouse_y;
  I64 type = NULL;
  Bool mouse_left = Mouse.left;
  Bool mouse_right = Mouse.right;

  if (win->focused_widget) {
    if (win->focused_widget->type == WIDGET_TYPE_INPUT) {
      if (@widget_input_handle_key(win->focused_widget)) {
        msg = CAlloc(sizeof(IpcMessage));
        System.Log(Fs, "Sent message → WinKeyPress");
        msg->client = win->client;
        msg->type = CPZ_MSG_WIN_KEY_PRESS;
        msg->payload = win;
        Ipc.MsgSend(msg->client, msg);
      }
      if (win->focused_widget(BitmapFontTextInputWidget *)
                  ->selected_region_start == -1 ||
          win->focused_widget(BitmapFontTextInputWidget *)
                  ->selected_region_end == -1) {
        if (win->focused_widget(BitmapFontTextInputWidget *)->blink != Blink) {
          win->focused_widget(BitmapFontTextInputWidget *)->blink =
              !win->focused_widget(BitmapFontTextInputWidget *)->blink;
          @compositor_refresh(win);
        }
      }
    }
  }

  if (Mouse.z != Compositor.mouse.delta_z) {
    msg = CAlloc(sizeof(IpcMessage));
    System.Log(Fs, "Sent message → WindowMouseWheel");
    msg->client = win->client;
    msg->type = CPZ_MSG_WIN_MOUSE_WHEEL;
    msg->payload = win;
    Ipc.MsgSend(msg->client, msg);
  }

  if (Mouse.x != Compositor.mouse.x || Mouse.y != Compositor.mouse.y ||
      Mouse.left != Compositor.mouse.left ||
      Mouse.right != Compositor.mouse.right) {
    if (Mouse.x != Compositor.mouse.x || Mouse.y != Compositor.mouse.y) {
      mouse_x = Mouse.x - win->x;
      mouse_y = Mouse.y - win->y;
      if (Mouse.x >= win->x && Mouse.x <= win->x + win->width &&
          Mouse.y >= win->y && Mouse.y <= win->y + win->height &&
          (mouse_x != win->mouse.x || mouse_y != win->mouse.y)) {
        win->mouse.x = mouse_x;
        win->mouse.y = mouse_y;
        msg = CAlloc(sizeof(IpcMessage));
        System.Log(Fs, "Sent message → WindowMouseAt (%dx%d)", mouse_x,
                   mouse_y);
        msg->client = win->client;
        msg->type = CPZ_MSG_WIN_MOUSE_AT;
        msg->payload = win;
        Ipc.MsgSend(msg->client, msg);
      }
    }
    if (mouse_left != win->mouse.left) {
      switch (mouse_left) {
      case MS_UP:
        System.Log(Fs, "Sent message → WindowMouseLeftBtnUp");
        type = CPZ_MSG_WIN_LEFT_BTN_UP;
        break;
      case MS_DOWN:
        System.Log(Fs, "Sent message → WindowMouseLeftBtnDown");
        type = CPZ_MSG_WIN_LEFT_BTN_DOWN;
        break;
      default:
        break;
      }
      win->mouse.left = mouse_left;
      win->left_btn_down.x = Mouse.x - win->x;
      win->left_btn_down.y = Mouse.y - win->y;
      msg = CAlloc(sizeof(IpcMessage));
      msg->client = win->client;
      msg->type = type;
      msg->payload = win;
      Ipc.MsgSend(msg->client, msg);
    }
    if (mouse_right != win->mouse.right) {
      switch (mouse_right) {
      case MS_UP:
        System.Log(Fs, "Sent message → WindowMouseRightBtnUp");
        type = CPZ_MSG_WIN_RIGHT_BTN_UP;
        break;
      case MS_DOWN:
        System.Log(Fs, "Sent message → WindowMouseRightBtnDown");
        type = CPZ_MSG_WIN_RIGHT_BTN_DOWN;
        break;
      default:
        break;
      }
      win->mouse.right = mouse_right;
      win->right_btn_down.x = Mouse.x - win->x;
      win->right_btn_down.y = Mouse.y - win->y;
      msg = CAlloc(sizeof(IpcMessage));
      msg->client = win->client;
      msg->type = type;
      msg->payload = win;
      Ipc.MsgSend(msg->client, msg);
    }
  }
}

U0 @compositor_handle_windows_input_events() {
  if (Compositor.active_win)
    @compositor_handle_window_input_events(Compositor.active_win);
  @compositor_windows_list *win_list = Compositor.windows;
  Compositor.max_z_index = 0;
  while (win_list) {
    if (win_list->window) {
      if (win_list->window->flags & WIN_FLAGS_MENU &&
          win_list->window != Compositor.active_win &&
          Gui.Window.IsVisible(win_list->window))
        @compositor_handle_window_input_events(win_list->window);
    }
    Compositor.max_z_index++;
    win_list = win_list->next;
  }
}

U0 @compositor_reset_input_event_timestamps() {
  Keyboard.last_key_tS = Keyboard.active_key_tS;
}

Window *@compositor_create_window(I64 x, I64 y, I64 width, I64 height,
                                  I64 flags = WIN_FLAGS_DEFAULT,
                                  U8 *title = NULL, Context2D *icon = NULL) {
  Window *win = CAlloc(sizeof(Window));
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  win->x = x;
  win->y = y;
  win->width = width;
  win->height = height;
  win->opacity = 255;
  win->flags = flags;
  win->icon = icon;
  win->client = Fs;
  win->signature = WIN_SIGNATURE;
  win->widget = CAlloc(sizeof(@window_widgets_list));
  win->callback.close = &@gui_window_callback_close;
  win->callback.maximize = &@gui_window_callback_maximize;
  win->callback.minimize = &@gui_window_callback_minimize;
  win->callback.repaint = NULL;

  if (title)
    StrCpy(&win->title, title);
  else
    StrCpy(&win->title, "Untitled window");
  msg->client = Fs;
  msg->type = CPZ_MSG_WIN_CREATE;
  msg->payload = win;
  Ipc.MsgSend(Compositor.task, msg);
  while (!win->backing_store) {
    Sleep(1);
  };
  return win;
}

U0 @compositor_destroy_window(Window *win) {
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  msg->client = Fs;
  msg->type = CPZ_MSG_WIN_DESTROY;
  msg->payload = win;
  Ipc.MsgSend(Compositor.task, msg);
}

U0 @compositor_hide_window(Window *win) {
  @gui_window_hide(win);
  Compositor.active_win = NULL;
}

U0 @compositor_show_window(Window *win) { @gui_window_show(win); }

Context2D *@compositor_win_select_backing_store(Window *win) {
  I64 iterations = 0;
  while (Compositor.in_resize && win == Compositor.active_win &&
         (win->width != win->backing_store->width ||
          win->height != win->backing_store->height) &&
         iterations < 64) {
    iterations++;
    if (!(iterations % 8))
      @compositor_refresh(win);
    Sleep(1);
  }
  return win->backing_store;
}

U0 @compositor_blit_window_backing_stores() {
  @compositor_windows_list *win_list;
  win_list = Compositor.windows;
  while (win_list) {
    if (win_list->window) {
      if (!(@gui_window_flag_is_set(win_list->window, WIN_FLAGS_MINIMIZED)) &&
          !(@gui_window_flag_is_set(win_list->window, WIN_FLAGS_HIDDEN)) &&
          win_list->window->signature == WIN_SIGNATURE) {
        if (@compositor_win_select_backing_store(win_list->window) ==
            win_list->window->resize_ctx) {
          CopyRect2D(Compositor.ctx, win_list->window->x, win_list->window->y,
                     win_list->window->resize_ctx);
        } else {
          if (win_list->window->alpha) {
            Compositor.blend_ctx->width = win_list->window->width;
            Compositor.blend_ctx->height = win_list->window->height;
            CopyRect2D(Compositor.blend_ctx, -win_list->window->x,
                       -win_list->window->y, Compositor.ctx);
            BlendRect2D(win_list->window->backing_store, Compositor.blend_ctx);
            CopyRect2D(Compositor.ctx, win_list->window->x, win_list->window->y,
                       Compositor.blend_ctx);
          } else {
            CopyRect2D(Compositor.ctx, win_list->window->x, win_list->window->y,
                       win_list->window->backing_store);
          }
        }
        if (win_list->window == Compositor.active_win &&
            !(@gui_window_flag_is_set(win_list->window, WIN_FLAGS_NOHILIGHT))) {
          // Top border
          Line2D(Compositor.ctx, win_list->window->x - 1,
                 win_list->window->y - 1,
                 win_list->window->x - 1 + win_list->window->width + 2,
                 win_list->window->y - 1, Compositor.theme.color.active_border);
          // Left border
          Line2D(Compositor.ctx, win_list->window->x - 1,
                 win_list->window->y - 1, win_list->window->x - 1,
                 win_list->window->y + win_list->window->height,
                 Compositor.theme.color.active_border);
          // Bottom border
          Line2D(Compositor.ctx, win_list->window->x - 1,
                 win_list->window->y + win_list->window->height,
                 win_list->window->x - 1 + win_list->window->width + 2,
                 win_list->window->y + win_list->window->height,
                 Compositor.theme.color.active_border);
          // Right border
          Line2D(Compositor.ctx,
                 win_list->window->x - 1 + win_list->window->width + 1,
                 win_list->window->y - 1,
                 win_list->window->x - 1 + win_list->window->width + 1,
                 win_list->window->y + win_list->window->height,
                 Compositor.theme.color.active_border);
          // Bottom shadow
          Line2D(Compositor.ctx, win_list->window->x + 1,
                 win_list->window->y + win_list->window->height + 1,
                 win_list->window->x + win_list->window->width + 2,
                 win_list->window->y + win_list->window->height + 1,
                 Compositor.theme.color.active_border);
          // Right shadow
          Line2D(Compositor.ctx,
                 win_list->window->x - 1 + win_list->window->width + 2,
                 win_list->window->y + 1,
                 win_list->window->x - 1 + win_list->window->width + 2,
                 win_list->window->y + win_list->window->height + 1,
                 Compositor.theme.color.active_border);
        }
      }
    }
    win_list = win_list->next;
  }
}

U0 @compositor_init() {
  Compositor.blend_ctx = NewContext2D(Display.Width(), Display.Height());
  Compositor.ctx = NewContext2D(Display.Width(), Display.Height());
  Compositor.windows = CAlloc(sizeof(@compositor_windows_list));
  Compositor.global_input_event_listeners =
      CAlloc(sizeof(@compositor_windows_list));
  Compositor.bounds.x1 = -Display.Width();
  Compositor.bounds.y1 = 33;
  Compositor.bounds.x2 = Display.Width();
  Compositor.bounds.y2 = Display.Height();
  Compositor.active_win = NULL;
  Compositor.menubar.win = NULL;
  Compositor.menubar.task = NULL;
  Compositor.menubar.title = NULL;
  Compositor.next_id = 0;
  Compositor.session.user.uid = 1;
  StrCpy(&Compositor.session.home, "/home/alec");
  StrCpy(&Compositor.session.hostname, "erythros");
  StrCpy(&Compositor.session.user.name, "alec");
  StrCpy(&Compositor.session.user.fullname, "Alec Murphy");
  @compositor_set_theme("Umami");
  @compositor_set_pointer();
}

U0 @compositor_task() {
  Window *win;
  Ipc.InitQueue(Fs);
  Compositor.task = Fs;
  System.Log(Fs, "Task running at 0x%08x", Fs);

  I64 total_mem;
  I64 free_mem;

  while (1) {
    // Process client IpcMessages.
    @compositor_ipc_queue_process();

    // Handle active window flags
    @compositor_handle_active_window_flags();

    // Handle window resize
    @compositor_handle_window_resize();

    // Handle window drag
    @compositor_handle_window_drag();

    // Handle window select
    @compositor_handle_window_select();

    // Handle global input events
    @compositor_handle_global_input_events();

    // Handle windows input events
    @compositor_handle_windows_input_events();

    // Reset input event timestamps
    @compositor_reset_input_event_timestamps();

    // Blit window backing stores
    @compositor_blit_window_backing_stores();

    // Draw Mouse Pointer (if no mouse integration).
    if (!Mouse.Update || Mouse.integration_type == MI_QEMU)
      Blot2D(Compositor.ctx, Mouse.X(), Mouse.Y(), Compositor.pointer);

    // Debug stuff
    I64 debug_row;

    if (KeyDown(SC_F12)) {
      debug_row = 2;

      total_mem = sys_code_bp->alloced_u8s;
      if (sys_data_bp) {
        total_mem += sys_data_bp->alloced_u8s;
      }
      free_mem = sys_code_bp->alloced_u8s - sys_code_bp->used_u8s;
      if (sys_data_bp) {
        free_mem += sys_data_bp->alloced_u8s - sys_data_bp->used_u8s;
      }

      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Total Memory : 0x%08x", total_mem);
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Free Memory  : 0x%08x", free_mem);
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Mouse.X() : %d", Mouse.X());
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Mouse.Y() : %d", Mouse.Y());
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Mouse.Z() : %d", Mouse.z);
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Compositor.mouse.z : %d", Compositor.mouse.z);
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Mouse.left()  : %d", Compositor.mouse.left);
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Mouse.right() : %d", Compositor.mouse.right);
      ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                     "Active window: 0x%08x", Compositor.active_win);
      if (Compositor.active_win) {
        ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                       "[+]        x : %d", Compositor.active_win->x);
        ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                       "           y : %d", Compositor.active_win->y);
        ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                       "       width : %d", Compositor.active_win->width);
        ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                       "      height : %d", Compositor.active_win->height);
        ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                       "      title  : %s", Compositor.active_win->title);
        ConsolePrint2D(Compositor.ctx, 08 * 03, 16 * debug_row++, , ,
                       "      flags  : %016b", Compositor.active_win->flags);
      }
    }

    // Flip off-screen context to framebuffer.
    Graphics2D.Flip(Compositor.ctx);

    // Update Compositor mouse button state
    Compositor.mouse.x = Mouse.x;
    Compositor.mouse.y = Mouse.y;
    if (Compositor.mouse.delta_z != Mouse.z)
      Compositor.mouse.z = (Mouse.z - Compositor.mouse.delta_z) *
                           T(Mouse.natural_scroll, -Mouse.wheel_sensitivity,
                             Mouse.wheel_sensitivity);
    Compositor.mouse.delta_z = Mouse.z;
    Compositor.mouse.left = Mouse.left;
    Compositor.mouse.right = Mouse.right;

    if (Display.Update)
      Display.Update();
    Sleep(1);
  }
}

Gui.Window.Refresh = &@compositor_refresh;
Gui.Window.SetFocus = &@compositor_set_active_window;
Gui.Window.SetZIndex = &@compositor_set_z_index_send_msg;

Compositor.GetWindowByTitle = &@compositor_get_window_by_title;
Compositor.GetWindowByZIndex = &@compositor_get_window_by_z_index;
Compositor.Init = &@compositor_init;
Compositor.CreateWindow = &@compositor_create_window;
Compositor.DestroyWindow = &@compositor_destroy_window;
Compositor.HideWindow = &@compositor_hide_window;
Compositor.RegisterForGlobalInputEvents =
    &@compositor_register_global_input_event_listener;
Compositor.ShowWindow = &@compositor_show_window;
Compositor.Task = &@compositor_task;
Compositor.UnregisterForGlobalInputEvents =
    &@compositor_unregister_global_input_event_listener;
Compositor.SetWallpaper = &@compositor_set_wallpaper_send_msg;

"compositor ";
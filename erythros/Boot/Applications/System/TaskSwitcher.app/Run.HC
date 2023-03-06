Gui.App();
#define MAX_THUMBS_PER_LINE 10

Window *win = Compositor.CreateWindow(120, 120, 640, 192, WIN_FLAGS_SKIP);
Window *to_be_focused_win = NULL;
Bool task_switcher_active = FALSE;
Bool task_switcher_invoke = FALSE;

I64 caption_width = 0;
F64 win_scale = 0.0;
I64 win_thumb_size = 128;
I64 win_thumb_container_size = win_thumb_size + 32;
I64 win_index = -1;
I64 win_items = 0;
I64 cur_index = 0;
U8 *cur_win_title = NULL;
Context2D *win_scaled = NULL;

@compositor_windows_list *win_list = NULL;

TextLabelWidget *caption =
    Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 8, 8, 256, 64);
Gui.Widget.SetFont(caption, "Eight Bit Dragon");

Context2DWidget *cursor = NULL;

U0 keypress_callback(Window *win, I64) {
  I64 i;
  if (!task_switcher_active) {
    if ((KeyDown(SC_CTRL) && KeyDown(Char2ScanCode('w'))) ||
        (KeyDown(SC_ALT) && KeyDown(SC_F4)))
      if (Compositor.active_win != win && Compositor.active_win->callback.close)
        Compositor.active_win->callback.close(Compositor.active_win);
    return;
  }
  if (KeyDown(SC_TAB)) {
    if (KeyDown(SC_SHIFT))
      win_index--;
    else
      win_index += T(win_items > 1 && task_switcher_invoke, 2, 1);
  }

  if (!win_items)
    return;

  @window_widgets_list *set_item = win->widget->next->next->next;
  if (win_index < 0)
    win_index = win_items - 1;
  if (win_index >= win_items)
    win_index = 0;
  for (i = 0; i < win_index; i++)
    set_item = set_item->next;

  cursor->x = set_item->widget->x;
  cursor->y = set_item->widget->y;

  to_be_focused_win = set_item->widget->id;
  Gui.Widget.SetText(caption, set_item->widget->tag);
  caption->width =
      Print2D(NULL, Compositor.theme.font.menu, 0, 0, , , &caption->text);
  caption->x = (win->width / 2) - (caption->width / 2);
  caption->y = win->height - 24;

  Gui.Window.Refresh(win);
  task_switcher_invoke = FALSE;
}

U0 @taskswitcher_clear_win_thumbs(Window *win) {
  @window_widgets_list *iter_widget = win->widget;
  @window_widgets_list *del_widget = NULL;
  while (iter_widget->next)
    iter_widget = iter_widget->next;
  while (iter_widget->widget->type == WIDGET_TYPE_CONTEXT2D) {
    iter_widget = iter_widget->prev;
    del_widget = iter_widget->next;
    iter_widget->next = NULL;
    if (del_widget->widget(Context2DWidget *)->ctx)
      DelContext2D(del_widget->widget(Context2DWidget *)->ctx);
    Free(del_widget->widget->tag);
    Free(del_widget->widget);
    Free(del_widget);
  }
  Gui.Widget.SetText(caption, "");
}

U0 @taskswitcher_render_win_thumbs(Window *win) {
  @compositor_windows_list *origin_list;
  @compositor_windows_list *iter_list;
  Context2DWidget *widget = NULL;
  cursor = Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, -999, -999,
                            win_thumb_container_size, win_thumb_container_size);
  cursor->ctx =
      NewContext2D(win_thumb_container_size, win_thumb_container_size);
  Fill2D(cursor->ctx, Compositor.theme.color.hilight);

  I64 min_caption_width = 0;
  win_items = 0;
  I64 cur_item = 0;
  I64 item_offset = 0;

  origin_list = Compositor.windows->next;
  while (origin_list->next)
    origin_list = origin_list->next;

  iter_list = origin_list;
  while (iter_list) {
    if (iter_list->window)
      if (!@gui_window_flag_is_set(iter_list->window, WIN_FLAGS_SKIP)) {
        min_caption_width =
            Max(min_caption_width,
                Print2D(NULL, Compositor.theme.font.menu, 0, 0, , ,
                        "%s - [%dx%d] at [%d, %d]", iter_list->window->title,
                        iter_list->window->width, iter_list->window->height,
                        iter_list->window->x, iter_list->window->y));
        win_items++;
      }
    iter_list = iter_list->prev;
  }

  win->width = Max((win_thumb_container_size * win_items) + T(win_items, 4, 0),
                   64 + min_caption_width);

  item_offset =
      (win->width / 2) -
      (((win_thumb_container_size * win_items) + T(win_items, 0, 0)) / 2);

  iter_list = origin_list;
  while (iter_list) {
    if (iter_list->window)
      if (!@gui_window_flag_is_set(iter_list->window, WIN_FLAGS_SKIP)) {
        widget = Gui.CreateWidget(
            win, WIDGET_TYPE_CONTEXT2D,
            (win_thumb_container_size * cur_item) + item_offset, 0,
            win_thumb_container_size, win_thumb_container_size);
        widget->ctx =
            NewContext2D(win_thumb_container_size, win_thumb_container_size);
        Fill2D(widget->ctx, NULL);
        win_scale = 1.0;
        while (iter_list->window->backing_store->width * win_scale >
                   win_thumb_size ||
               iter_list->window->backing_store->height * win_scale >
                   win_thumb_size)
          win_scale -= 0.001;

        win_scaled =
            Scale2D(iter_list->window->backing_store, win_scale, win_scale);
        Fill2D(widget->ctx, NULL);
        Blot2D(widget->ctx,
               (win_thumb_container_size / 2) - (win_scaled->width / 2),
               (win_thumb_container_size / 2) - (win_scaled->height / 2),
               win_scaled);
        DelContext2D(win_scaled);
        widget->tag = CAlloc(256);
        StrPrint(widget->tag, "%s - [%dx%d] at [%d, %d]",
                 iter_list->window->title, iter_list->window->width,
                 iter_list->window->height, iter_list->window->x,
                 iter_list->window->y);
        widget->id = iter_list->window; // FIXME: We are abusing this property,
                                        // introduce a better way to do this

        cur_item++;
      }
    iter_list = iter_list->prev;
  }
}

U0 Main() {
  Gui.Window.SetTitle(win, "TaskSwitcher");
  Gui.Window.EnableAlphaChannel(win);
  Gui.Window.SetOpacity(win, 224);
  Compositor.RegisterForGlobalInputEvents(win);
  Gui.Window.SetCallback(win, "keypress", &keypress_callback);
  Gui.Window.Hide(win);

  while (1) {
    if (KeyDown(SC_ALT) && KeyDown(SC_TAB))
      task_switcher_active = TRUE;
    if (!KeyDown(SC_ALT))
      task_switcher_active = FALSE;
    switch (task_switcher_active) {
    case TRUE:
      if (!to_be_focused_win) {
        to_be_focused_win = Compositor.active_win;
        task_switcher_invoke = TRUE;
        @taskswitcher_render_win_thumbs(win);
        Gui.Window.Center(win);
        Gui.Window.SetFocus(win);
        Gui.Window.Show(win);
      }
      break;
    case FALSE:
      if (to_be_focused_win) {
        Gui.Window.SetFocus(to_be_focused_win);
        Gui.Window.Show(to_be_focused_win);
        to_be_focused_win = NULL;
        Gui.Window.Hide(win);
        @taskswitcher_clear_win_thumbs(win);
        win_index = -1;
      }
      break;
    }
    Sleep(1);
  }
}

Main;
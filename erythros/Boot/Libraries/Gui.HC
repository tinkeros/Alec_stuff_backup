extern class Widget;
extern class Window;

#define WIN_FLAGS_NULL 0x0
#define WIN_FLAGS_NO_REINDEX 0x1 // Wallpaper, taskbar, etc.
#define WIN_FLAGS_RESIZABLE 0x2
#define WIN_FLAGS_MOVABLE 0x4
#define WIN_FLAGS_ICON 0x8
#define WIN_FLAGS_TITLE_BAR 0x10
#define WIN_FLAGS_MIN_BUTTON 0x20
#define WIN_FLAGS_MAX_BUTTON 0x40
#define WIN_FLAGS_CLOSE_BUTTON 0x80

#define WIN_FLAGS_MINIMIZED 0x100
#define WIN_FLAGS_MAXIMIZED 0x200
#define WIN_FLAGS_HIDDEN 0x400
#define WIN_FLAGS_NOHILIGHT 0x800

#define WIN_FLAGS_SKIP 0x1000
#define WIN_FLAGS_NOFILL 0x2000
#define WIN_FLAGS_MENU 0x4000

#define WIN_FLAGS_MAX 0x10000

#define WIN_SIGNATURE 0x1596e3c1c62c34b929d75cded8c0

#define WIN_FLAGS_DEFAULT                                                      \
  (WIN_FLAGS_RESIZABLE | WIN_FLAGS_MOVABLE | WIN_FLAGS_ICON |                  \
   WIN_FLAGS_TITLE_BAR | WIN_FLAGS_MIN_BUTTON | WIN_FLAGS_MAX_BUTTON |         \
   WIN_FLAGS_CLOSE_BUTTON)

class @widget_callbacks {
  U0 (*change)(Widget * widget);
  U0 (*clicked)(Widget * widget);
  U0 (*repaint)(Widget * widget);
};

class @widget_origin {
  I64 x;
  I64 y;
  I64 width;
  I64 height;
  I64 mouse_x;
  I64 mouse_y;
};

class Widget {
  Bool change;
  I64 id;
  I64 type;
  I64 x;
  I64 y;
  I64 width;
  I64 height;
  I64 opacity;
  U64 flags;
  U8 *tag;
  Widget *echo;
  Window *parent_win;
  Context2D *backing_store;
  Context2D *pointer;
  @widget_callbacks callback;
  @widget_origin origin;
};

class @window_widgets_list {
  @window_widgets_list *prev;
  @window_widgets_list *next;
  Widget *widget;
};

class @window_origin {
  I64 x;
  I64 y;
  I64 width;
  I64 height;
  I64 mouse_x;
  I64 mouse_y;
};

class @window_position {
  I64 x;
  I64 y;
}

class @window_buttons {
  Bool minimize;
  Bool maximize;
  Bool close;
};

class @window_callbacks {
  U0 (*minimize)(Window * win);
  U0 (*maximize)(Window * win);
  U0 (*mouseat)(Window * win);
  U0 (*keypress)(Window * win, I64 key);
  U0 (*repaint)(Window * win);
  U0 (*close)(Window * win);
};

class @window_mouse {
  I64 x;
  I64 y;
  Bool left;
  Bool right;
};

class @window_event { // FIXME: Better name?
  I64 x;
  I64 y;
  Bool left;
  Bool right;
};

class Window {
  U64 signature;
  Bool alpha;
  Bool refresh;
  Bool repainting;
  CTask *client;
  I64 x;
  I64 y;
  I64 width;
  I64 height;
  I64 opacity;
  U64 flags;
  U8 title[512];
  I64 title_bar_x;
  I64 title_bar_width;
  I64 min_width;
  I64 min_height;
  Context2D *icon;
  Context2D *backing_store;
  Context2D *pointer;
  Context2D *render_ctx;
  Context2D *resize_ctx;
  Widget *mouse_down_widget;
  Widget *focused_widget;
  Widget *hovered_widget;
  @window_buttons button;
  @window_callbacks callback;
  @window_origin origin;
  @window_mouse mouse;
  @window_event left_btn_down; // FIXME: put these in a Window.event.xxx class?
  @window_event left_btn_up;
  @window_event right_btn_down;
  @window_event right_btn_up;
  @window_widgets_list *widget;
};

class @gui_widget {
  Bool (*IsHovered)(Window * win, Widget * widget);
  U0 (*SetCallback)(Widget * widget, U8 * name, U64 callback);
  U0 (*SetEcho)(Widget * widget, Widget * echo);
  U0 (*SetFont)(Widget * widget, U8 * font_name);
  U0 (*SetMousePointer)(Widget * widget, Context2D * pointer);
  U0 (*ClearMousePointer)(Widget * widget);
  U0 (*SetOpacity)(Widget * widget, I64 opacity);
  U0 (*SetText)(Widget * widget, U8 * text);
};

class @gui_window {
  U0 (*Center)(Window * win, Bool horz = TRUE, Bool vert = TRUE);
  U0 (*DisableAlphaChannel)(Window * win);
  U0 (*EnableAlphaChannel)(Window * win);
  U0 (*Hide)(Window * win);
  Bool (*IsHovered)(Window * win);
  Bool (*IsVisible)(Window * win);
  U0 (*SetCallback)(Window * win, U8 * name, U64 callback);
  U0 (*SetFocus)(Window * win);
  U0 (*SetIcon)(Window * win, Context2D * icon);
  U0 (*SetMousePointer)(Window * win, Context2D * pointer);
  U0 (*ClearMousePointer)(Window * win);
  U0 (*SetOpacity)(Window * win, I64 opacity);
  U0 (*SetTitle)(Window * win, U8 * text);
  U0 (*SetPosition)(Window * win, I64 x, I64 y);
  U0 (*SetZIndex)(Window * win, I64 index);
  U0 (*Show)(Window * win);
  U0 (*Refresh)(Window * win);
};

class @gui {
  @gui_widget Widget;
  @gui_window Window;
  U0 (*App)();
  Widget *(*InitWidget)(Widget * widget, Window * win, I64 type, I64 x, I64 y,
                        I64 width, I64 height);
  Widget *(*CreateWidget)(Window * win, I64 type, I64 x, I64 y, I64 width,
                          I64 height);
};

@gui Gui;

I64 @gui_app_header_size;
U8 *@gui_app_header_data = FileRead("T:/Include/Gui.HC", &@gui_app_header_size);

U0 @gui_app() {
  CDoc *@gui_app_header_doc = DocNew;
  DocLoad(@gui_app_header_doc, @gui_app_header_data, @gui_app_header_size);
  ExeDoc(@gui_app_header_doc);
}

Bool @gui_window_flag_is_set(Window *win, U64 flag) {
  if (!win)
    return FALSE;
  if (win->flags & flag == flag)
    return TRUE;
  return FALSE;
}

Bool @gui_window_is_hovered(Window *win) {
  if (Mouse.x > win->x && Mouse.x < win->x + win->width && Mouse.y > win->y &&
      Mouse.y < win->y + win->height)
    return TRUE;
  return FALSE;
}

Bool @gui_window_is_visible(Window *win) {
  if (!win)
    return NULL;
  return !@gui_window_flag_is_set(win, WIN_FLAGS_HIDDEN);
}

U0 @gui_widget_destroy(Widget *widget) {
  Window *win = widget->parent_win;
  @window_widgets_list *widgets = win->widget;
  @window_widgets_list *prev;
  @window_widgets_list *next;
  while (widgets) {
    if (widgets->widget == widget) {
      prev = widgets->prev;
      next = widgets->next;
      if (prev)
        prev->next = next;
      if (next)
        next->prev = prev;
      // FIXME: Free widget and child data
      widget->type = NULL;
    }
    widgets = widgets->next;
  }
}

U0 @gui_widget_repaint(Window *win, Widget *widget, I64 type) {}

U0 @gui_window_repaint(Window *win, I64 type) {
  @system_log(Fs, "Repainting window 0x%08x [%s]", win, win->title);
}

U0 @gui_window_center(Window *win, Bool horz = TRUE, Bool vert = TRUE) {
  if (!win)
    return;
  I64 x = win->x;
  I64 y = win->y;
  if (horz)
    x = (Display.Width() / 2) - (win->width / 2);
  if (vert)
    y = (Display.Height() / 2) - (win->height / 2);
  win->x = x;
  win->y = y;
}

U0 @gui_window_set_position(Window *win, I64 x, I64 y) {
  if (!win)
    return;
  win->x = x;
  win->y = y;
}

U0 @gui_window_set_icon(Window *win, Context2D *icon) {
  if (!win || !icon)
    return;
  Bool refresh = FALSE;
  if (win->icon != icon)
    refresh = TRUE;
  win->icon = icon;
  if (refresh)
    Gui.Window.Refresh(win);
}

U0 @gui_window_set_mouse_pointer(Window *win, Context2D *pointer) {
  if (!win)
    return;
  win->pointer = pointer;
}

U0 @gui_window_clear_mouse_pointer(Window *win) {
  if (!win)
    return;
  win->pointer = NULL;
}

U0 @gui_window_set_opacity(Window *win, I64 opacity) {
  if (!win)
    return;
  Bool refresh = FALSE;
  if (win->opacity != opacity)
    refresh = TRUE;
  win->opacity = ClampI64(opacity, 0, 255);
  if (refresh)
    Gui.Window.Refresh(win);
}

U0 @gui_window_set_title(Window *win, U8 *text) {
  if (!win || !text)
    return;
  if (!StrLen(text))
    return;
  if (StrLen(text) > 511) {
    MemCpy(&win->title, text, 512);
    win->title[511] = NULL;
    return;
  }
  StrCpy(&win->title, text);
  Gui.Window.Refresh(win);
}

U0 @gui_window_callback_close(Window *win) {}

U0 @gui_window_callback_maximize(Window *win) {
  win->flags |= WIN_FLAGS_MAXIMIZED;
}

U0 @gui_window_callback_minimize(Window *win) {
  win->flags |= WIN_FLAGS_MINIMIZED;
}

U0 @gui_window_disable_alpha_channel(Window *win) { win->alpha = FALSE; }

U0 @gui_window_enable_alpha_channel(Window *win) { win->alpha = TRUE; }

U0 @gui_window_hide(Window *win) { win->flags |= WIN_FLAGS_HIDDEN; }

U0 @gui_window_show(Window *win) {
  win->flags &= ~WIN_FLAGS_HIDDEN;
  win->flags &= ~WIN_FLAGS_MINIMIZED;
}

U0 @gui_window_set_callback(Window *win, U8 *name, U64 callback) {
  if (!win || !name || !callback)
    return;
  if (!StrCmp(name, "minimize"))
    win->callback.minimize = callback;
  if (!StrCmp(name, "maximize"))
    win->callback.maximize = callback;
  if (!StrCmp(name, "mouseat"))
    win->callback.mouseat = callback;
  if (!StrCmp(name, "keypress"))
    win->callback.keypress = callback;
  if (!StrCmp(name, "repaint"))
    win->callback.repaint = callback;
  if (!StrCmp(name, "close"))
    win->callback.close = callback;
}

Gui.App = &@gui_app;
Gui.Window.Center = &@gui_window_center;
Gui.Window.DisableAlphaChannel = &@gui_window_disable_alpha_channel;
Gui.Window.EnableAlphaChannel = &@gui_window_enable_alpha_channel;
Gui.Window.Hide = &@gui_window_hide;
Gui.Window.IsHovered = &@gui_window_is_hovered;
Gui.Window.IsVisible = &@gui_window_is_visible;
Gui.Window.SetCallback = &@gui_window_set_callback;
Gui.Window.SetIcon = &@gui_window_set_icon;
Gui.Window.SetMousePointer = &@gui_window_set_mouse_pointer;
Gui.Window.ClearMousePointer = &@gui_window_clear_mouse_pointer;
Gui.Window.SetOpacity = &@gui_window_set_opacity;
Gui.Window.SetTitle = &@gui_window_set_title;
Gui.Window.SetPosition = &@gui_window_set_position;
Gui.Window.Show = &@gui_window_show;

"gui ";
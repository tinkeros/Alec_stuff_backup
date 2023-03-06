// Core component for Menu functions

#define MENU_ITEM_MIN_HEIGHT 24
#define MENU_ITEM_MIN_WIDTH 256

I64 @menu_get_items_count(Window *win) {
  I64 count = 0;
  @window_widgets_list *wl = win->widget;
  while (wl) {
    if (wl->widget) {
      if (wl->widget->type == WIDGET_TYPE_MENU_ITEM)
        count++;
    }
    wl = wl->next;
  }
  return count;
}

MenuItemWidget *@menu_add_item(Window *win, U8 *text, Context2D *icon,
                               U64 callback, U8 *path = NULL,
                               Window *submenu = NULL) {
  I64 items_count = @menu_get_items_count(win);
  win->height = 8;
  win->height += MENU_ITEM_MIN_HEIGHT * (items_count + 1);
  MenuItemWidget *item = Gui.CreateWidget(
      win, WIDGET_TYPE_MENU_ITEM, 0, MENU_ITEM_MIN_HEIGHT * items_count,
      MENU_ITEM_MIN_WIDTH, MENU_ITEM_MIN_HEIGHT);
  Gui.Widget.SetText(item, text);
  if (icon)
    item->icon = icon;
  if (path)
    item->path = StrNew(path);
  if (submenu)
    item->submenu = submenu;
  if (callback)
    Gui.Widget.SetCallback(item, "clicked", callback);
  return item;
}

Window *@menu_new(U8 *title = NULL) {
  Window *menu = Compositor.CreateWindow(
      0, 0, MENU_ITEM_MIN_WIDTH, MENU_ITEM_MIN_HEIGHT,
      WIN_FLAGS_NOHILIGHT | WIN_FLAGS_SKIP | WIN_FLAGS_MENU);
  Gui.Window.Hide(menu);
  if (title)
    Gui.Window.SetTitle(menu, title);
  else
    Gui.Window.SetTitle(menu, "");
  return menu;
}

class @menu {
  MenuItemWidget *(*AddItem)(Window * win, U8 * text, Context2D * icon,
                             U64 callback, U8 *path = NULL,
                             Window *submenu = NULL);
  Window *(*New)(U8 * title);
};

@menu Menu;
Menu.AddItem = &@menu_add_item;
Menu.New = &@menu_new;

"menu ";
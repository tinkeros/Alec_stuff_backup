Gui.App();

Window *sys_menu = Menu.New("System Menu");

U0 @system_menu_item_clicked(MenuItemWidget *widget) {
  if (!widget->path)
    return;
  SystemStarter.CreateTask(widget->path, &widget->text);
}

U0 @system_menu_init() {
  U8 *str = FileRead("T:/Config/system_menu.json");
  JsonElement *json = Json.Parse(str);
  JsonArray *items = Json.Get(json, "items");
  JsonArray *subitems = NULL;
  Window *submenu = NULL;
  I64 i;
  I64 j;
  // System Menu supports 2 levels of nesting to separate groups of Applications
  // into categories.
  for (i = 0; i < items->length; i++) {
    if (Json.Get(Json.ArrayIndex(items, i), "name")) {
      if (Json.Get(Json.ArrayIndex(items, i), "path")) {
        Menu.AddItem(
            sys_menu, Json.Get(Json.ArrayIndex(items, i), "name"),
            @png_file_to_context2d(Json.Get(Json.ArrayIndex(items, i), "icon")),
            &@system_menu_item_clicked,
            Json.Get(Json.ArrayIndex(items, i), "path"));
      }
      if (Json.Get(Json.ArrayIndex(items, i), "items")) {
        submenu = Menu.New(Json.Get(Json.ArrayIndex(items, i), "name"));
        submenu->x = sys_menu->width;
        submenu->y = 35 + sys_menu->y + (MENU_ITEM_MIN_HEIGHT * i);
        subitems = Json.Get(Json.ArrayIndex(items, i), "items");
        for (j = 0; j < subitems->length; j++) {
          if (Json.Get(Json.ArrayIndex(subitems, j), "name")) {
            if (Json.Get(Json.ArrayIndex(subitems, j), "path")) {
              Menu.AddItem(submenu,
                           Json.Get(Json.ArrayIndex(subitems, j), "name"),
                           @png_file_to_context2d(
                               Json.Get(Json.ArrayIndex(subitems, j), "icon")),
                           &@system_menu_item_clicked,
                           Json.Get(Json.ArrayIndex(subitems, j), "path"));
            }
          }
        }
        Menu.AddItem(
            sys_menu, Json.Get(Json.ArrayIndex(items, i), "name"),
            @png_file_to_context2d(Json.Get(Json.ArrayIndex(items, i), "icon")),
            NULL, NULL, submenu);
      }
    }
  }
}

U0 @system_menu_show(Context2DWidget *widget) {
  sys_menu->x = 0;
  sys_menu->y = 32;
  if (widget->width == 30 && widget->height == 30)
    Fill2D(widget->ctx, Color(192, 192, 192));
  Gui.Window.Show(sys_menu);
  Gui.Window.SetFocus(sys_menu);
  Gui.Window.Refresh(sys_menu);
}

U0 Main() {
  Window *win = Compositor.CreateWindow(0, 0, Display.Width(), 32,
                                        WIN_FLAGS_NOHILIGHT | WIN_FLAGS_SKIP);
  Gui.Window.SetTitle(win, "MenuBar");

  ButtonWidget *system_menu_btn =
      Gui.CreateWidget(win, WIDGET_TYPE_BUTTON, 0, 0, 58, 24);
  Gui.Widget.SetText(system_menu_btn, "");
  system_menu_btn->image = @png_file_to_context2d("system_menu.png");
  system_menu_btn->width = system_menu_btn->image->width + 8;

  Context2DWidget *separator = Gui.CreateWidget(
      win, WIDGET_TYPE_CONTEXT2D,
      system_menu_btn->x + system_menu_btn->width + 4, 2, 2, 20);
  separator->ctx = NewContext2D(2, 20);
  Line2D(separator->ctx, 0, 0, 0, 20, Color(224, 224, 224));
  Line2D(separator->ctx, 1, 0, 1, 20, Color(128, 128, 128));

  TextInputWidget *active_app_title = Gui.CreateWidget(
      win, WIDGET_TYPE_LABEL, separator->x + separator->width + 8, 8, 192, 64);

  if (!Compositor.active_win)
    Gui.Window.SetFocus(Compositor.GetWindowByTitle("Wallpaper"));

  Gui.Widget.SetFont(active_app_title, "Eight Bit Dragon");
  Gui.Widget.SetText(active_app_title, Compositor.active_win->title);

  CDateStruct ds;
  U8 clock_text[32];
  TextInputWidget *clock =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, Display.Width() - 94, 8, 64, 32);
  Gui.Widget.SetFont(clock, "Eight Bit Dragon");
  Gui.Window.Refresh(win);

  // FIXME: This is an ugly way to do this...
  Compositor.menubar.win = win;
  Compositor.menubar.task = Fs;
  Compositor.menubar.title = active_app_title;

  Gui.Widget.SetCallback(system_menu_btn, "clicked", &@system_menu_show);

  // System Clock
  I64 min = -1;
  while (1) {
    Date2Struct(&ds, Now);
    if (ds.min != min) {
      StrPrint(&clock_text, "%02d %03tZ, %02d:%02d", ds.day_of_mon, ds.mon - 1,
               "ST_MONTHS", ds.hour, ds.min);
      Gui.Widget.SetText(clock, &clock_text);
      Gui.Window.Refresh(win);
      min = ds.min;
    }
    if (Compositor.active_win != sys_menu && Gui.Window.IsVisible(sys_menu))
      Gui.Window.Hide(sys_menu);
    Sleep(1);
  }
}

@system_menu_init;
Main;
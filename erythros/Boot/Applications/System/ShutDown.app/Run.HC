Gui.App();

U0 @shutdown_callback(U64 o) {
  if (!o)
    return;
  if (o(Window *)->signature == WIN_SIGNATURE) {
    Compositor.DestroyWindow(o(Window *));
    Gui.Window.SetFocus(Compositor.GetWindowByTitle("Wallpaper"));
    return;
  }
  switch (o(Widget *)->tag) {
  case TRUE:
    System.PowerOff();
    break;
  default:
    Compositor.DestroyWindow(o(Widget *)->parent_win);
    Gui.Window.SetFocus(Compositor.GetWindowByTitle("Wallpaper"));
    return;
    break;
  }
}

MessageBox.Alert("Do you want to shut down this computer?",
                 "[\"OK\",\"Cancel\"]", &@shutdown_callback);
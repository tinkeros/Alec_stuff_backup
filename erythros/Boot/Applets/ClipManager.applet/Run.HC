Gui.App();

Context2DWidget *clipmanager_icon = SystemTray.RegisterItem();

Context2D *ctx_clip_icon =
    PNG.FileToContext2D("T:/Media/Themes/Umami/Icon/clipboard.png");

CopyRect2D(clipmanager_icon->ctx, 0, 0, ctx_clip_icon);

U0 Main() {
  I64 length = 0;
  I64 text_width = 0;
  while (1) {
    if (length < Clipboard.Length()) {
      CopyRect2D(clipmanager_icon->ctx, 0, 0, ctx_clip_icon);
      Rect2D(clipmanager_icon->ctx, 12, 12, 12, 12, Color(255, 0, 0));
      text_width = Print2D(NULL, Compositor.theme.font.sans, 0, 0,
                           Color(255, 255, 255), , "%02d", Clipboard.Length());
      Print2D(clipmanager_icon->ctx, Compositor.theme.font.sans,
              11 + 6 - (text_width / 2), 13, Color(255, 255, 255), , "%02d",
              Clipboard.Length());
      Print2D(clipmanager_icon->ctx, Compositor.theme.font.sans,
              11 + 7 - (text_width / 2), 13, Color(255, 255, 255), , "%02d",
              Clipboard.Length());
      length = Clipboard.Length();
      Gui.Window.Refresh(Compositor.menubar.win);
    }
    Sleep(1);
  }
}

Main;

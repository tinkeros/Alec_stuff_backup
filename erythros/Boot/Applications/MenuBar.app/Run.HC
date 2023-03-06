#include "T:/Include/Gui";

U0 Main() {
  Window *win = Compositor.CreateWindow(0, 0, Display.Width(), 32,
                                        WIN_FLAGS_NOHILIGHT | WIN_FLAGS_SKIP);
  Gui.Window.SetTitle(win, "MenuBar");

  TextInputWidget *active_app_title =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 8, 8, 192, 64);

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
    Sleep(1);
  }
}

Main;
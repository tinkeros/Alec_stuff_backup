#include "T:/Include/Gui";

Window *win = Compositor.CreateWindow(Display.Width(), 32, 256, 32,
                                      WIN_FLAGS_NOHILIGHT | WIN_FLAGS_SKIP);

Context2DWidget *volume_slider_icon =
    Gui.CreateWidget(win, WIDGET_TYPE_CONTEXT2D, 0, 0, 24, 24);
volume_slider_icon->ctx = NewContext2D(24, 24);
HorizontalSliderWidget *volume_slider =
    Gui.CreateWidget(win, WIDGET_TYPE_HORZ_SLIDER, 32, 4, 212, 24);
volume_slider->max = 100;
volume_slider->scroll = volume_slider->width / 8;

Context2DWidget *tray_icon = SystemTray.RegisterItem();

Context2D *ctx_volume_muted = PNG.FileToContext2D(
    "T:/Media/Themes/Umami/Icon/status/audio-volume-muted.png");
Context2D *ctx_volume_low = PNG.FileToContext2D(
    "T:/Media/Themes/Umami/Icon/status/audio-volume-low.png");
Context2D *ctx_volume_medium = PNG.FileToContext2D(
    "T:/Media/Themes/Umami/Icon/status/audio-volume-medium.png");
Context2D *ctx_volume_high = PNG.FileToContext2D(
    "T:/Media/Themes/Umami/Icon/status/audio-volume-high.png");

U0 @volumeslider_show(Widget *) {
  win->x = Display.Width() - 256;
  Compositor.ShowWindow(win);
  Gui.Window.SetFocus(win);
}

U0 @volumeslider_change(Widget *) {
  I64 volume = Min(ToI64(volume_slider->scroll * 0.47), 100);
  Audio.mixer.left = volume;
  Audio.mixer.right = volume;
  Context2D *update_slider_icon = NULL;
  switch (volume) {
  case 0:
    update_slider_icon = ctx_volume_muted;
    break;
  case 1...24:
    update_slider_icon = ctx_volume_low;
    break;
  case 25...74:
    update_slider_icon = ctx_volume_medium;
    break;
  case 75...100:
  default:
    update_slider_icon = ctx_volume_high;
    break;
  }
  CopyRect2D(volume_slider_icon->ctx, 0, 0, update_slider_icon);
  CopyRect2D(tray_icon->ctx, 0, 0, update_slider_icon);
  Gui.Window.Refresh(Compositor.menubar.win);
}
@volumeslider_change(NULL);

U0 Main() {
  Gui.Window.SetTitle(win, "VolumeSlider");
  Compositor.HideWindow(win);
  Gui.Widget.SetCallback(tray_icon, "clicked", &@volumeslider_show);
  Gui.Widget.SetCallback(volume_slider, "change", &@volumeslider_change);

  while (1) {
    if (Gui.Window.IsVisible(win) && Compositor.active_win != win)
      Compositor.HideWindow(win);
    Sleep(1);
  }
}

Main;
#include "T:/Include/Gui";

U0 window_close(Window *win) { Compositor.DestroyWindow(win); }

U0 btn1_click(Widget *widget) {
  no_warn widget;
  Window *win =
      Compositor.CreateWindow(Rand * Display.Width(), Rand * Display.Height(),
                              320, 240, WIN_FLAGS_DEFAULT);
  win->callback.close = &window_close;
  Gui.Window.SetTitle(win, "New Window");
  Gui.Window.SetFocus(win);
}

U0 btn2_click(Widget *) {
  System.text_mode = TRUE;
  Dbg;
}

U0 hs1_change(HorizontalSliderWidget *widget) {
  Gui.Window.SetOpacity(widget->parent_win,
                        ClampI64(1.4 * widget->scroll, 0, 255));
}

U0 Main() {
  Window *win = Compositor.CreateWindow(240, 240, 662, 504, WIN_FLAGS_DEFAULT);
  win->alpha = TRUE;
  Gui.Window.Center(win);
  Gui.Window.SetTitle(win, "Test Application");

  TextInputWidget *label1 =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 8, 0, 192, 64);
  Gui.Widget.SetText(label1,
                     "\n"
                     "Welcome to Erythros desktop environment for TempleOS!\n"
                     "\n"
                     "This is a test application for Gui Widgets. "
                     "There will be bugs. Please report them! :)\n"
                     "\n");

  ButtonWidget *btn1 =
      Gui.CreateWidget(win, WIDGET_TYPE_BUTTON, 8, 56, 192, 32);
  Gui.Widget.SetText(btn1, "Click me for a new Window");

  ButtonWidget *btn2 =
      Gui.CreateWidget(win, WIDGET_TYPE_BUTTON, 224, 56, 256, 32);
  Gui.Widget.SetText(btn2, "Click me to open TempleOS Debugger");

  btn1->callback.clicked = &btn1_click;
  btn2->callback.clicked = &btn2_click;

  CheckBoxWidget *cb1 =
      Gui.CreateWidget(win, WIDGET_TYPE_CHECKBOX, 8, 160, 14, 14);
  TextInputWidget *label2 =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 32, 162, 100, 14);
  Gui.Widget.SetText(label2, "Some random checkbox");

  RadioButtonWidget *radio1 =
      Gui.CreateWidget(win, WIDGET_TYPE_RADIO, 192, 160, 14, 14);
  RadioButtonWidget *radio2 =
      Gui.CreateWidget(win, WIDGET_TYPE_RADIO, 192, 180, 14, 14);
  RadioButtonWidget *radio3 =
      Gui.CreateWidget(win, WIDGET_TYPE_RADIO, 192, 200, 14, 14);
  TextInputWidget *label3 =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 216, 162, 192, 14);
  Gui.Widget.SetText(label3, "Radio #1");
  TextInputWidget *label4 =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 216, 182, 192, 14);
  Gui.Widget.SetText(label4, "Radio #2");
  TextInputWidget *label5 =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 216, 202, 192, 14);
  Gui.Widget.SetText(label5, "Radio #3");

  Gui.Widget.SetEcho(label2, cb1);
  Gui.Widget.SetEcho(label3, radio1);
  Gui.Widget.SetEcho(label4, radio2);
  Gui.Widget.SetEcho(label5, radio3);

  HorizontalSliderWidget *hs1 =
      Gui.CreateWidget(win, WIDGET_TYPE_HORZ_SLIDER, 338, 192, 192, 64);
  hs1->max = 100;
  hs1->scroll = (hs1->width / 5) * 4.25;
  hs1->callback.change = &hs1_change;
  TextInputWidget *label6 =
      Gui.CreateWidget(win, WIDGET_TYPE_LABEL, 398, 220, 192, 64);
  Gui.Widget.SetText(label6, "Window Opacity");

  VerticalSliderWidget *vs1 =
      Gui.CreateWidget(win, WIDGET_TYPE_VERT_SLIDER, 576, 192, 64, 192);
  vs1->max = 100;
  vs1->scroll = hs1->height / 2;

  Gui.Widget.SetEcho(vs1, hs1);

  TextInputWidget *input1 =
      Gui.CreateWidget(win, WIDGET_TYPE_INPUT, 8, 320, 256, 64);
  input1->font = BitmapFonts.GetByName("Eight Bit Dragon");
  Gui.Widget.SetText(input1, "this is some sample text");

  Gui.Window.SetFocus(win);
  Gui.Window.Refresh(win);

  Gui.Window.SetOpacity(win, ClampI64(1.4 * hs1->scroll, 0, 255));

  Suspend;
}

Main;
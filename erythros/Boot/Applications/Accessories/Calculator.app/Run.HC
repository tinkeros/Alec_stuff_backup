Gui.App();

#define CALC_OP_ADD 0
#define CALC_OP_SUB 1
#define CALC_OP_MUL 2
#define CALC_OP_DIV 3

class @calc_entry {
  I64 op;
  F64 entry;
};

Window *win = NULL;
TextInputWidget *result = NULL;

U8 *calc_font = "Eight Bit Dragon";
U8 *@calc_button_label[27] = {"Back", "CE",   "C",   "MC", "7", "8", "9",
                              "/",    "sqrt", "MR",  "4",  "5", "6", "*",
                              "%",    "MS",   "1",   "2",  "3", "-", "1/x",
                              "M+",   "0",    "+/-", ".",  "+", "="};

U0 @calc_keypress_callback(Window *, I64 key) {
  if (win != Compositor.active_win)
    return;
  U8 *res_text = result->text;
  switch (ScanCode2Char(key)) {
  case '0' ... '9':
    StrPrint(res_text + StrLen(res_text), "%c", ScanCode2Char(key));
    break;
  }
}

U0 @calc_btn_callback(ButtonWidget *widget) {
  U8 *res_text = result->text;
  if (Str2I64(widget->text)) {
    StrCpy(res_text + StrLen(res_text), widget->text);
  }
  if (!StrCmp(widget->text, "0"))
    StrCpy(res_text + StrLen(res_text), widget->text);
}

U0 window_close(Window *win) {
  if (win == Compositor.active_win)
    Gui.Window.SetFocus(Compositor.GetWindowByTitle("Wallpaper"));
  Compositor.UnregisterForGlobalInputEvents(win);
  Compositor.DestroyWindow(win);
}

U0 Main() {
  I64 i;
  I64 j;
  I64 k;
  U64 flags = WIN_FLAGS_DEFAULT;
  flags &= ~WIN_FLAGS_RESIZABLE;
  flags &= ~WIN_FLAGS_MAX_BUTTON;
  win = Compositor.CreateWindow(224, 224, 233, 240, flags);
  Gui.Window.SetTitle(win, "Calculator");
  Compositor.RegisterForGlobalInputEvents(win);
  Gui.Window.SetIcon(win, PNG.FileToContext2D("window_icon_16x16.png"));
  Gui.Window.SetFocus(win);
  Gui.Window.SetCallback(win, "close", &window_close);
  Gui.Window.SetCallback(win, "keypress", &@calc_keypress_callback);

  result = Gui.CreateWidget(win, WIDGET_TYPE_INPUT, 4, 4, 246, 24);
  Gui.Widget.SetFont(result, calc_font);

  ButtonWidget *calc_btn[27];

  for (i = 0; i < 4; i++) {
    if (i < 3) {
      calc_btn[i] =
          Gui.CreateWidget(win, WIDGET_TYPE_BUTTON, 46 + (60 * i), 32, 56, 32);
      calc_btn[i]->color = Color(255, 0, 0);
      Gui.Widget.SetText(calc_btn[i], @calc_button_label[i]);
      Gui.Widget.SetFont(calc_btn[i], calc_font);
      Gui.Widget.SetCallback(calc_btn[i], "clicked", &@calc_btn_callback);
    }
    j = 3 + (6 * i);
    calc_btn[j] =
        Gui.CreateWidget(win, WIDGET_TYPE_BUTTON, 4, 68 + (36 * i), 32, 32);
    calc_btn[j]->color = Color(255, 0, 0);
    Gui.Widget.SetText(calc_btn[j], @calc_button_label[j]);
    Gui.Widget.SetFont(calc_btn[j], calc_font);
    Gui.Widget.SetCallback(calc_btn[j], "clicked", &@calc_btn_callback);
    for (k = 1; k < 6; k++) {
      calc_btn[j + k] = Gui.CreateWidget(win, WIDGET_TYPE_BUTTON, 10 + (36 * k),
                                         68 + (36 * i), 32, 32);
      calc_btn[j + k]->color =
          T(k == 4 || k == 5 && i == 3, Color(255, 0, 0), Color(0, 0, 255));
      Gui.Widget.SetText(calc_btn[j + k], @calc_button_label[j + k]);
      Gui.Widget.SetFont(calc_btn[j + k], calc_font);
      Gui.Widget.SetCallback(calc_btn[j + k], "clicked", &@calc_btn_callback);
    }
  }
  Suspend;
}

Main;
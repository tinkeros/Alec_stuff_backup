#define TextInputWidget BitmapFontTextInputWidget
#define TextLabelWidget BitmapFontTextLabelWidget

#define WIDGET_TYPE_NULL 0
#define WIDGET_TYPE_BUTTON 1
#define WIDGET_TYPE_CHECKBOX 2
#define WIDGET_TYPE_RADIO 3
#define WIDGET_TYPE_INPUT 4
#define WIDGET_TYPE_LABEL 5
#define WIDGET_TYPE_CONTEXT2D 6
#define WIDGET_TYPE_TTF_INPUT 7
#define WIDGET_TYPE_TTF_LABEL 8
#define WIDGET_TYPE_HORZ_SLIDER 9
#define WIDGET_TYPE_VERT_SLIDER 10
#define WIDGET_TYPE_TERMINAL 11
#define WIDGET_TYPE_HORZ_SCROLLBAR 12
#define WIDGET_TYPE_VERT_SCROLLBAR 13
#define WIDGET_TYPE_MENU_ITEM 14
#define WIDGET_TYPE_LISTVIEW 15

#define TERMINAL_MAX_COLS 1920 / 8

#define TERMINAL_STATE_OUTPUT 0
#define TERMINAL_STATE_CONSUME_BEGIN 1
#define TERMINAL_STATE_CONSUME_CTRL_SEQ 2
#define TERMINAL_STATE_CONSUME_OS_CMD 3
#define TERMINAL_STATE_CONSUME_END 99

asm {
TERMINAL_COLOR_TABLE::
DU32 0xff000000, 0xff800000, 0xff008000, 0xff808000, 0xff000080, 0xff800080, 0xff008080, 0xffc0c0c0, 0xff808080, 0xffff0000, 0xff00ff00, 0xffffff00, 0xff0000ff, 0xffff00ff, 0xff00ffff, 0xffffffff, 0xff000000, 0xff00005f, 0xff000087, 0xff0000af, 0xff0000d7, 0xff0000ff, 0xff005f00, 0xff005f5f, 0xff005f87, 0xff005faf, 0xff005fd7, 0xff005fff, 0xff008700, 0xff00875f, 0xff008787, 0xff0087af, 0xff0087d7, 0xff0087ff, 0xff00af00, 0xff00af5f, 0xff00af87, 0xff00afaf, 0xff00afd7, 0xff00afff, 0xff00d700, 0xff00d75f, 0xff00d787, 0xff00d7af, 0xff00d7d7, 0xff00d7ff, 0xff00ff00, 0xff00ff5f, 0xff00ff87, 0xff00ffaf, 0xff00ffd7, 0xff00ffff, 0xff5f0000, 0xff5f005f, 0xff5f0087, 0xff5f00af, 0xff5f00d7, 0xff5f00ff, 0xff5f5f00, 0xff5f5f5f, 0xff5f5f87, 0xff5f5faf, 0xff5f5fd7, 0xff5f5fff, 0xff5f8700, 0xff5f875f, 0xff5f8787, 0xff5f87af, 0xff5f87d7, 0xff5f87ff, 0xff5faf00, 0xff5faf5f, 0xff5faf87, 0xff5fafaf, 0xff5fafd7, 0xff5fafff, 0xff5fd700, 0xff5fd75f, 0xff5fd787, 0xff5fd7af, 0xff5fd7d7, 0xff5fd7ff, 0xff5fff00, 0xff5fff5f, 0xff5fff87, 0xff5fffaf, 0xff5fffd7, 0xff5fffff, 0xff870000, 0xff87005f, 0xff870087, 0xff8700af, 0xff8700d7, 0xff8700ff, 0xff875f00, 0xff875f5f, 0xff875f87, 0xff875faf, 0xff875fd7, 0xff875fff, 0xff878700, 0xff87875f, 0xff878787, 0xff8787af, 0xff8787d7, 0xff8787ff, 0xff87af00, 0xff87af5f, 0xff87af87, 0xff87afaf, 0xff87afd7, 0xff87afff, 0xff87d700, 0xff87d75f, 0xff87d787, 0xff87d7af, 0xff87d7d7, 0xff87d7ff, 0xff87ff00, 0xff87ff5f, 0xff87ff87, 0xff87ffaf, 0xff87ffd7, 0xff87ffff, 0xffaf0000, 0xffaf005f, 0xffaf0087, 0xffaf00af, 0xffaf00d7, 0xffaf00ff, 0xffaf5f00, 0xffaf5f5f, 0xffaf5f87, 0xffaf5faf, 0xffaf5fd7, 0xffaf5fff, 0xffaf8700, 0xffaf875f, 0xffaf8787, 0xffaf87af, 0xffaf87d7, 0xffaf87ff, 0xffafaf00, 0xffafaf5f, 0xffafaf87, 0xffafafaf, 0xffafafd7, 0xffafafff, 0xffafd700, 0xffafd75f, 0xffafd787, 0xffafd7af, 0xffafd7d7, 0xffafd7ff, 0xffafff00, 0xffafff5f, 0xffafff87, 0xffafffaf, 0xffafffd7, 0xffafffff, 0xffd70000, 0xffd7005f, 0xffd70087, 0xffd700af, 0xffd700d7, 0xffd700ff, 0xffd75f00, 0xffd75f5f, 0xffd75f87, 0xffd75faf, 0xffd75fd7, 0xffd75fff, 0xffd78700, 0xffd7875f, 0xffd78787, 0xffd787af, 0xffd787d7, 0xffd787ff, 0xffd7af00, 0xffd7af5f, 0xffd7af87, 0xffd7afaf, 0xffd7afd7, 0xffd7afff, 0xffd7d700, 0xffd7d75f, 0xffd7d787, 0xffd7d7af, 0xffd7d7d7, 0xffd7d7ff, 0xffd7ff00, 0xffd7ff5f, 0xffd7ff87, 0xffd7ffaf, 0xffd7ffd7, 0xffd7ffff, 0xffff0000, 0xffff005f, 0xffff0087, 0xffff00af, 0xffff00d7, 0xffff00ff, 0xffff5f00, 0xffff5f5f, 0xffff5f87, 0xffff5faf, 0xffff5fd7, 0xffff5fff, 0xffff8700, 0xffff875f, 0xffff8787, 0xffff87af, 0xffff87d7, 0xffff87ff, 0xffffaf00, 0xffffaf5f, 0xffffaf87, 0xffffafaf, 0xffffafd7, 0xffffafff, 0xffffd700, 0xffffd75f, 0xffffd787, 0xffffd7af, 0xffffd7d7, 0xffffd7ff, 0xffffff00, 0xffffff5f, 0xffffff87, 0xffffffaf, 0xffffffd7, 0xffffffff, 0xff080808, 0xff121212, 0xff1c1c1c, 0xff262626, 0xff303030, 0xff3a3a3a, 0xff444444, 0xff4e4e4e, 0xff585858, 0xff626262, 0xff6c6c6c, 0xff767676, 0xff808080, 0xff8a8a8a, 0xff949494, 0xff9e9e9e, 0xffa8a8a8, 0xffb2b2b2, 0xffbcbcbc, 0xffc6c6c6, 0xffd0d0d0, 0xffdadada, 0xffe4e4e4, 0xffeeeeee;
}

U8 widget_self_set1[0x1F] = {0x55, 0x48, 0x8B, 0xEC, 0x56, 0x48, 0x8B, 0x75,
                             0x10, 0x56, 0x48, 0xBB, 0x0,  0x0,  0x0,  0x0,
                             0x0,  0x0,  0x0,  0x0,  0x53, 0xE8, 0x0,  0x0,
                             0x0,  0x0,  0x5E, 0x5D, 0xC2, 0x08, 0x0};

class ButtonWidget : Widget {
  BitmapFont *font;
  U8 text[1024];
  Context2D *image;
  U32 color;
};

class MenuItemWidget : Widget {
  BitmapFont *font;
  U8 text[128];
  Context2D *icon;
  U32 color;
  U8 *path;
  Window *submenu;
};

class Context2DWidget : Widget {
  Bool fast_copy;
  Context2D *ctx;
};

class CheckBoxWidget : Widget {
  Bool checked;
};

class RadioButtonWidget : Widget {
  I64 group;
  Bool selected;
};

class @terminal_widget_attr {
  Bool bold;
  Bool underline;
  Bool blink;
  Bool negative;
  Bool invisible;
}

class @terminal_widget_col {
  U32 background;
  U32 foreground;
  U8 char;
};

class @terminal_widget_color {
  U32 background;
  U32 foreground;
  U32 cursor;
};

class @terminal_widget_cursor {
  I64 x;
  I64 y;
  Bool hidden;
};

class @terminal_widget_row {
  @terminal_widget_col col[TERMINAL_MAX_COLS];
};

class @terminal_widget_scroll {
  I64 x;
  I64 y;
};

class @terminal_widget_size {
  I64 rows;
  I64 cols;
};

class @terminal_widget_stored {
  @terminal_widget_attr attr;
  @terminal_widget_color color;
  @terminal_widget_cursor cursor;
};

class TerminalWidget : Widget {
  CFifoU8 *input;
  CFifoU8 *output;
  Bool refresh;
  U8 consumed_chars[256];
  I64 state;
  I64 last_fg_color_set;
  @terminal_widget_attr attr;
  @terminal_widget_color color;
  @terminal_widget_cursor cursor;
  @terminal_widget_row *row;
  @terminal_widget_scroll scroll;
  @terminal_widget_scroll max;
  @terminal_widget_size size;
  @terminal_widget_stored stored;
};

class BitmapFontTextInputWidget : Widget {
  BitmapFont *font;
  Bool blink;
  Bool in_drag;
  Bool is_password;
  I64 cursor_index;
  I64 mouse_drag_origin_x;
  I64 mouse_drag_index;
  I64 selected_region_start;
  I64 selected_region_end;
  I64 x_offset;
  U32 color;
  U8 text[1024];
  U8 password[1024];
  U0 (*SetFont)(U8 *font);
  U0 (*SetText)(U8 *text);
}

class BitmapFontTextLabelWidget : Widget {
  BitmapFont *font;
  U32 color;
  U8 text[1024];
  U0 (*SetFont)(U8 *font);
  U0 (*SetText)(U8 *text);
};

class TrueTypeTextInputWidget : Widget {
  U8 *font;
  U32 color;
  U32 bgcolor;
  I64 size;
  U8 *text;
  U8 *prev_text;
};

class TrueTypeTextLabelWidget : Widget {
  U8 *font;
  U32 color;
  U32 bgcolor;
  I64 size;
  U8 *text;
  U8 *prev_text;
};

class HorizontalSliderWidget : Widget {
  Bool in_drag;
  I64 scroll;
  I64 max;
  I64 value;
};

class VerticalSliderWidget : Widget {
  Bool in_drag;
  I64 scroll;
  I64 max;
  I64 value;
};

class HorizontalScrollBarWidget : Widget {
  Bool in_drag;
  I64 scroll;
  I64 max;
  I64 value;
};

class VerticalScrollBarWidget : Widget {
  Bool in_drag;
  I64 scroll;
  I64 length;
  I64 max;
  I64 value;
};

class @list_view_item {
  @list_view_item *prev;
  @list_view_item *next;
  Context2D *icon;
  U8 text[1024];
};

class ListViewWidget : Widget {
  BitmapFont *font;
  U32 color;
  @list_view_item *items;
};

U0 @gui_widget_set_echo(Widget *widget, U8 *echo) {
  if (!widget || !echo)
    return;
  widget->echo = echo;
}

U0 @gui_widget_set_font(Widget *widget, U8 *font_name) {
  if (!widget || !font_name)
    return;
  if (!StrLen(font_name))
    return;
  switch (widget->type) {
  case WIDGET_TYPE_BUTTON:
    widget(ButtonWidget *)->font = BitmapFonts.GetByName(font_name);
    break;
  case WIDGET_TYPE_INPUT:
    widget(BitmapFontTextInputWidget *)->font =
        BitmapFonts.GetByName(font_name);
    break;
  case WIDGET_TYPE_LABEL:
    widget(BitmapFontTextLabelWidget *)->font =
        BitmapFonts.GetByName(font_name);
    break;
  case WIDGET_TYPE_LISTVIEW:
    widget(ListViewWidget *)->font = BitmapFonts.GetByName(font_name);
    break;
  default:
    break;
  }
}

U0 @gui_widget_set_mouse_pointer(Widget *widget, Context2D *pointer) {
  if (!widget)
    return;
  widget->pointer = pointer;
}

U0 @gui_widget_clear_mouse_pointer(Widget *widget) {
  if (!widget)
    return;
  widget->pointer = NULL;
}

U0 @gui_widget_set_opacity(Widget *widget, I64 opacity) {
  if (!widget)
    return;
  widget->opacity = ClampI64(opacity, 0, 255);
}

U0 @gui_widget_set_callback(Widget *widget, U8 *name, U64 callback) {
  if (!widget || !name || !callback)
    return;
  if (!StrCmp(name, "change"))
    widget->callback.change = callback;
  if (!StrCmp(name, "clicked"))
    widget->callback.clicked = callback;
  if (!StrCmp(name, "repaint"))
    widget->callback.repaint = callback;
}

U0 @gui_widget_set_text(Widget *widget, U8 *text) {
  if (!widget)
    return;
  switch (widget->type) {
  case WIDGET_TYPE_BUTTON:
    StrCpy(&widget(ButtonWidget *)->text, text);
    break;
  case WIDGET_TYPE_INPUT:
    StrCpy(&widget(TextInputWidget *)->text, text);
    break;
  case WIDGET_TYPE_LABEL:
    StrCpy(&widget(TextLabelWidget *)->text, text);
    break;
  case WIDGET_TYPE_MENU_ITEM:
    StrCpy(&widget(MenuItemWidget *)->text, text);
    break;
  default:
    break;
  }
}

Bool @widget_is_hovered(I64 x, I64 y, Widget *widget) {
  if (Mouse.x > x && Mouse.x < x + widget->width && Mouse.y > y &&
      Mouse.y < y + widget->height)
    return TRUE;
  return FALSE;
}

Bool @gui_widget_is_hovered(Window *win, Widget *widget) {
  return @widget_is_hovered(win->x + widget->x, win->y + widget->y, widget);
}

U0 @widget_add_widget_to_list(Window *win, Widget *widget) {
  if (!win || !widget)
    return;
  @window_widgets_list *widgets_list = win->widget;
  while (widgets_list->next) {
    widgets_list = widgets_list->next;
  }
  @window_widgets_list *widget_list_item = CAlloc(sizeof(@window_widgets_list));
  widget_list_item->widget = widget;
  widget_list_item->prev = widgets_list;
  widgets_list->next = widget_list_item;
}

U0 @widget_input_backspace(BitmapFontTextInputWidget *widget) {
  I64 i;
  I64 len = StrLen(&widget->text);
  for (i = widget->cursor_index - 1; i < len; i++) {
    widget->text[i] = widget->text[i + 1];
  }
}

U0 @widget_input_clear_selected_region(BitmapFontTextInputWidget *widget) {
  widget->selected_region_start = -1;
  widget->selected_region_end = -1;
}
Bool @widget_input_delete_selected_region(BitmapFontTextInputWidget *widget) {
  I64 i;
  I64 j;
  if (widget->selected_region_start != -1 &&
      widget->selected_region_end != -1) {
    j = widget->selected_region_start;
    for (i = widget->selected_region_end + 1; i < StrLen(&widget->text) + 1;
         i++) {
      widget->text[j++] = widget->text[i];
    }
    widget->text[j] = NULL;
    widget->cursor_index = widget->selected_region_start;
    @widget_input_clear_selected_region(widget);
    return TRUE;
  }
  return FALSE;
}

U0 @widget_input_delete_at_cursor(BitmapFontTextInputWidget *widget) {
  I64 i;
  I64 len = StrLen(&widget->text);
  for (i = widget->cursor_index; i < len; i++)
    widget->text[i] = widget->text[i + 1];
  @widget_input_clear_selected_region(widget);
}

U0 @widget_input_insert_char(BitmapFontTextInputWidget *widget, I64 char) {
  U8 buf[1024];
  U8 *pos;
  I64 i, j, k;
  j = 0;
  for (i = widget->cursor_index; i < StrLen(&widget->text); i++) {
    buf[j++] = widget->text[i];
  }
  buf[j] = NULL;
  for (i = widget->cursor_index; i < 1024; i++) {
    widget->text[i] = NULL;
  }
  widget->text[StrLen(&widget->text)] = char;
  pos = &buf;
  while (*pos) {
    widget->text[StrLen(&widget->text)] = *pos;
    pos++;
  }
  @widget_input_clear_selected_region(widget);
  widget->cursor_index++;
}

U0 @widget_input_insert_scancode(BitmapFontTextInputWidget *widget, I64 key) {
  U8 buf[1024];
  U8 *pos;
  I64 i, j, k;
  j = 0;
  for (i = widget->cursor_index; i < StrLen(&widget->text); i++) {
    buf[j++] = widget->text[i];
  }
  buf[j] = NULL;
  for (i = widget->cursor_index; i < 1024; i++) {
    widget->text[i] = NULL;
  }
  if (!Bt(kbd.down_bitmap, SC_SHIFT))
    widget->text[StrLen(&widget->text)] =
        NORMAL_KEY_SCAN_DECODE_TABLE(U8 *)[key];
  else
    widget->text[StrLen(&widget->text)] =
        SHIFT_KEY_SCAN_DECODE_TABLE(U8 *)[key];
  pos = &buf;
  while (*pos) {
    widget->text[StrLen(&widget->text)] = *pos;
    pos++;
  }
  @widget_input_clear_selected_region(widget);
  widget->cursor_index++;
}

U0 @widget_input_insert_text(BitmapFontTextInputWidget *widget, U8 *text) {
  while (*text) {
    @widget_input_insert_char(widget, *text);
    text++;
  }
}

Bool @widget_input_handle_key(BitmapFontTextInputWidget *widget) {
  I64 key = Keyboard.active_key;
  I64 tS = Keyboard.active_key_tS;
  if (widget->cursor_index > StrLen(&widget->text) || widget->cursor_index < 0)
    widget->cursor_index = 0;
  if (widget->selected_region_start > widget->selected_region_end) {
    @widget_input_clear_selected_region(widget);
  }
  if (key && tS != Keyboard.last_key_tS) {
    switch (key) {
    case SC_DELETE:
      if (widget->selected_region_start != -1 &&
          widget->selected_region_end != -1) {
        @widget_input_delete_selected_region(widget);
      } else {
        @widget_input_delete_at_cursor(widget);
      }
      break;
    case SC_HOME:
      if (Bt(kbd.down_bitmap, SC_SHIFT) && widget->selected_region_start) {
        widget->selected_region_start = 0;
        if (widget->selected_region_end == -1)
          widget->selected_region_end = widget->cursor_index - 1;
      } else {
        @widget_input_clear_selected_region(widget);
        widget->cursor_index = 0;
      }
      break;
    case SC_CURSOR_LEFT:
      /*
      "widget->selected_region_start : %d \n", widget->selected_region_start;
      "widget->selected_region_end : %d \n", widget->selected_region_end;
      "widget->cursor_index : %d \n", widget->cursor_index;
      */
      if (widget->cursor_index)
        widget->cursor_index--;
      if (!Bt(kbd.down_bitmap, SC_SHIFT)) {
        if (widget->selected_region_start != -1)
          widget->cursor_index = widget->selected_region_start;
        @widget_input_clear_selected_region(widget);
      } else {
        if (Bt(kbd.down_bitmap, SC_CTRL) && widget->selected_region_start) {
          widget->selected_region_start = 0;
          if (widget->selected_region_end == -1)
            widget->selected_region_end = widget->cursor_index;
          break;
        }
        switch (widget->selected_region_start) {
        case -1:
          widget->selected_region_start = widget->cursor_index;
          widget->selected_region_end = widget->cursor_index;
          break;
        // case 0:
        //  break;
        default:
          if (widget->cursor_index > widget->selected_region_start) {
            widget->selected_region_end = widget->cursor_index - 1;
          } else {
            widget->selected_region_start = widget->cursor_index;
            if (widget->selected_region_start == widget->selected_region_end) {
              @widget_input_clear_selected_region(widget);
            }
          }
          break;
        }
      }
      break;
    case SC_END:
      if (Bt(kbd.down_bitmap, SC_SHIFT)) {
        widget->selected_region_start = widget->cursor_index;
        widget->selected_region_end = StrLen(&widget->text) - 1;
      } else {
        @widget_input_clear_selected_region(widget);
        widget->cursor_index = StrLen(&widget->text);
      }
      break;
    case SC_CURSOR_RIGHT:
      /*
      "widget->selected_region_start : %d \n", widget->selected_region_start;
      "widget->selected_region_end : %d \n", widget->selected_region_end;
      "widget->cursor_index : %d \n", widget->cursor_index;
      */
      if (!Bt(kbd.down_bitmap, SC_SHIFT)) {
        if (widget->selected_region_end != -1)
          widget->cursor_index = widget->selected_region_end;
        @widget_input_clear_selected_region(widget);
      } else {
        if (Bt(kbd.down_bitmap, SC_CTRL)) {
          widget->selected_region_start = widget->cursor_index;
          widget->selected_region_end = StrLen(&widget->text) - 1;
          break;
        }
        switch (widget->selected_region_start) {
        case -1:
          widget->selected_region_start = widget->cursor_index;
          widget->selected_region_end = widget->cursor_index;
          break;
        default:
          if (widget->cursor_index == widget->selected_region_start) {
            widget->selected_region_start = widget->cursor_index + 1;
          } else
            widget->selected_region_end = widget->cursor_index;
          break;
        }
      }
      if (widget->cursor_index < StrLen(&widget->text))
        widget->cursor_index++;
      break;

    case SC_BACKSPACE:
      if (@widget_input_delete_selected_region(widget))
        return TRUE;
      if (widget->cursor_index < 1)
        break;
      @widget_input_backspace(widget);
      @widget_input_clear_selected_region(widget);
      widget->cursor_index--;
      break;

    case 0x02 ... 0x0D:
    case 0x10 ... 0x1B:
    case 0x1E ... 0x29:
    case 0x2B ... 0x35:
    case 0x39:
      if (Bt(kbd.down_bitmap, SC_CTRL)) {
        switch (ScanCode2Char(key)) {
        case 'a':
          if (StrLen(&widget->text)) {
            widget->selected_region_start = 0;
            widget->selected_region_end = StrLen(&widget->text) - 1;
          }
          break;
        case 'c':
        case 'x':
          if (widget->selected_region_start != -1 &&
              widget->selected_region_end != -1) {
            U64 pos = &widget->text;
            pos += widget->selected_region_start;
            U8 *text = StrNew(pos);
            text[widget->selected_region_end - widget->selected_region_start +
                 1] = NULL;
            Clipboard.Insert(CLIP_TYPE_TEXT, text);
            if (ScanCode2Char(key) == 'x')
              @widget_input_delete_selected_region(widget);
          }
          break;
        case 'v':
          // FIXME: Clipboard.Paste?
          if (Clipboard.length) {
            @widget_input_delete_selected_region(widget);
            if (Clipboard.items->prev) {
              if (Clipboard.items->prev->item->type == CLIP_TYPE_TEXT) {
                @widget_input_insert_text(
                    widget,
                    Clipboard.items->prev->item(ClipboardTextItem *)->text);
              }
            }
          }
          break;
        }
        break;
      }
      @widget_input_delete_selected_region(widget);
      @widget_input_insert_scancode(widget, key);
      break;
    default:
      //@widget_input_delete_selected_region(widget);
      break;
    };
    return TRUE;
  }
  return FALSE;
}

Widget *@widget_create_widget(Window *win, I64 type, I64 x, I64 y, I64 width,
                              I64 height) {
  if (!win || !type)
    return NULL;

  I64 size_of_widget;
  Widget *widget;

  switch (type) {
  case WIDGET_TYPE_NULL:
    return NULL;
  case WIDGET_TYPE_BUTTON:
    size_of_widget = sizeof(ButtonWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_CHECKBOX:
    size_of_widget = sizeof(CheckBoxWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_TERMINAL:
    size_of_widget = sizeof(TerminalWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_RADIO:
    size_of_widget = sizeof(RadioButtonWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_INPUT:
    size_of_widget = sizeof(TextInputWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_LABEL:
    size_of_widget = sizeof(TextLabelWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_LISTVIEW:
    size_of_widget = sizeof(ListViewWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_MENU_ITEM:
    size_of_widget = sizeof(MenuItemWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_TTF_LABEL:
    size_of_widget = sizeof(TrueTypeTextLabelWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_CONTEXT2D:
    size_of_widget = sizeof(Context2DWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_HORZ_SLIDER:
    size_of_widget = sizeof(HorizontalSliderWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_VERT_SLIDER:
    size_of_widget = sizeof(VerticalSliderWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_HORZ_SCROLLBAR:
    size_of_widget = sizeof(HorizontalScrollBarWidget) * 2;
    goto @widget_create_set_values;
  case WIDGET_TYPE_VERT_SCROLLBAR:
    size_of_widget = sizeof(VerticalScrollBarWidget) * 2;
    goto @widget_create_set_values;
  default:
    return NULL;
  }
  @widget_create_set_values : widget = CAlloc(size_of_widget);
  widget->type = type;
  widget->x = x;
  widget->y = y;
  widget->width = width;
  widget->height = height;
  widget->parent_win = win;

  switch (type) {
  case WIDGET_TYPE_TERMINAL:
    widget(TerminalWidget *)->backing_store =
        NewContext2D(Display.Width(), Display.Height());
    widget(TerminalWidget *)->input = FifoU8New(1024);
    widget(TerminalWidget *)->color.background = Color(0, 0, 0);
    widget(TerminalWidget *)->color.foreground = Color(217, 217, 217);
    widget(TerminalWidget *)->color.cursor = Color(217, 217, 0);
    widget(TerminalWidget *)->row = CAlloc(sizeof(@terminal_widget_row) * 2000);
    break;
  case WIDGET_TYPE_INPUT:
    widget(TextInputWidget *)->color = Color(0, 0, 0);
    widget(TextInputWidget *)->cursor_index = -1;
    widget(TextInputWidget *)->mouse_drag_index = -1;
    widget(TextInputWidget *)->selected_region_start = -1;
    widget(TextInputWidget *)->selected_region_end = -1;
    break;
  case WIDGET_TYPE_LABEL:
    widget(TextLabelWidget *)->color = Color(0, 0, 0);
    widget(TextLabelWidget *)->SetText = CAlloc(0x1F, Fs->code_heap);
    I32 addr = widget(TextLabelWidget *)->SetText;
    MemCpy(addr, widget_self_set1, 0x1F);
    MemCpy(addr + 12, &widget, 8);
    Function.InsertCall(addr + 21, Gui.Widget.SetText);
    break;
  case WIDGET_TYPE_LISTVIEW:
    widget(ListViewWidget *)->color = Color(0, 0, 0);
    widget(ListViewWidget *)->items = CAlloc(sizeof(@list_view_item));
    break;
  }

  @widget_add_widget_to_list(win, widget);
  return widget;
}

U0 @widget_init_widget(Widget *widget, Window *win, I64 type, I64 x, I64 y,
                       I64 width, I64 height) {
  if (!win || !widget || !type)
    return;

  I64 size_of_widget = 0;
  I32 addr = NULL;

  switch (type) {
  case WIDGET_TYPE_NULL:
    return;
  case WIDGET_TYPE_BUTTON:
    size_of_widget = sizeof(ButtonWidget);
    break;
  case WIDGET_TYPE_CHECKBOX:
    size_of_widget = sizeof(CheckBoxWidget);
    break;
  case WIDGET_TYPE_TERMINAL:
    size_of_widget = sizeof(TerminalWidget);
    break;
  case WIDGET_TYPE_RADIO:
    size_of_widget = sizeof(RadioButtonWidget);
    break;
  case WIDGET_TYPE_INPUT:
    size_of_widget = sizeof(TextInputWidget);
    break;
  case WIDGET_TYPE_LABEL:
    size_of_widget = sizeof(TextLabelWidget);
    break;
  case WIDGET_TYPE_LISTVIEW:
    size_of_widget = sizeof(ListViewWidget);
    break;
  case WIDGET_TYPE_MENU_ITEM:
    size_of_widget = sizeof(MenuItemWidget);
    break;
  case WIDGET_TYPE_TTF_LABEL:
    size_of_widget = sizeof(TrueTypeTextLabelWidget);
    break;
  case WIDGET_TYPE_CONTEXT2D:
    size_of_widget = sizeof(Context2DWidget);
    break;
  case WIDGET_TYPE_HORZ_SLIDER:
    size_of_widget = sizeof(HorizontalSliderWidget);
    break;
  case WIDGET_TYPE_VERT_SLIDER:
    size_of_widget = sizeof(VerticalSliderWidget);
    break;
  case WIDGET_TYPE_HORZ_SCROLLBAR:
    size_of_widget = sizeof(HorizontalScrollBarWidget);
    break;
  case WIDGET_TYPE_VERT_SCROLLBAR:
    size_of_widget = sizeof(VerticalScrollBarWidget);
    break;
  default:
    break;
  }

  MemSet(widget, NULL, size_of_widget);

  widget->type = type;
  widget->x = x;
  widget->y = y;
  widget->width = width;
  widget->height = height;
  widget->parent_win = win;

  switch (type) {
  case WIDGET_TYPE_TERMINAL:
    widget(TerminalWidget *)->backing_store =
        NewContext2D(Display.Width(), Display.Height());
    widget(TerminalWidget *)->input = FifoU8New(1024);
    widget(TerminalWidget *)->color.background = Color(0, 0, 0);
    widget(TerminalWidget *)->color.foreground = Color(217, 217, 217);
    widget(TerminalWidget *)->color.cursor = Color(217, 217, 0);
    widget(TerminalWidget *)->row = CAlloc(sizeof(@terminal_widget_row) * 2000);
    break;
  case WIDGET_TYPE_INPUT:
    widget(TextInputWidget *)->color = Color(0, 0, 0);
    widget(TextInputWidget *)->cursor_index = -1;
    widget(TextInputWidget *)->mouse_drag_index = -1;
    widget(TextInputWidget *)->selected_region_start = -1;
    widget(TextInputWidget *)->selected_region_end = -1;
    widget(TextInputWidget *)->color = Color(0, 0, 0);
    widget(TextInputWidget *)->SetText = CAlloc(0x1F, Fs->code_heap);
    addr = widget(TextInputWidget *)->SetFont;
    MemCpy(addr, widget_self_set1, 0x1F);
    MemCpy(addr + 12, &widget, 8);
    Function.InsertCall(addr + 21, Gui.Widget.SetFont);
    addr = widget(TextInputWidget *)->SetText;
    MemCpy(addr, widget_self_set1, 0x1F);
    MemCpy(addr + 12, &widget, 8);
    Function.InsertCall(addr + 21, Gui.Widget.SetText);
    break;
  case WIDGET_TYPE_LABEL:
    widget(TextLabelWidget *)->color = Color(0, 0, 0);
    widget(TextLabelWidget *)->SetText = CAlloc(0x1F, Fs->code_heap);
    addr = widget(TextLabelWidget *)->SetFont;
    MemCpy(addr, widget_self_set1, 0x1F);
    MemCpy(addr + 12, &widget, 8);
    Function.InsertCall(addr + 21, Gui.Widget.SetFont);
    addr = widget(TextLabelWidget *)->SetText;
    MemCpy(addr, widget_self_set1, 0x1F);
    MemCpy(addr + 12, &widget, 8);
    Function.InsertCall(addr + 21, Gui.Widget.SetText);
    break;
  case WIDGET_TYPE_LISTVIEW:
    widget(ListViewWidget *)->color = Color(0, 0, 0);
    widget(ListViewWidget *)->items = CAlloc(sizeof(@list_view_item));
    break;
  }

  @widget_add_widget_to_list(win, widget);
}

Gui.CreateWidget = &@widget_create_widget;
Gui.InitWidget = &@widget_init_widget;

Gui.Widget.IsHovered = &@gui_widget_is_hovered;
Gui.Widget.SetCallback = &@gui_widget_set_callback;
Gui.Widget.SetEcho = &@gui_widget_set_echo;
Gui.Widget.SetFont = &@gui_widget_set_font;
Gui.Widget.SetMousePointer = &@gui_widget_set_mouse_pointer;
Gui.Widget.ClearMousePointer = &@gui_widget_clear_mouse_pointer;
Gui.Widget.SetOpacity = &@gui_widget_set_opacity;
Gui.Widget.SetText = &@gui_widget_set_text;

"widget ";
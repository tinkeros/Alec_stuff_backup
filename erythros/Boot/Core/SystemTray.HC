#define SYSTRAY_MSG_NULL 0x0
#define SYSTRAY_MSG_REGISTER 0x1
#define SYSTRAY_MSG_UNREGISTER 0x2

class @systemtray {
  CTask *task;
  @window_widgets_list *item;
  U0 (*Init)();
  U0 (*Task)();
  Context2DWidget *(*RegisterItem)();
  U0 (*UnregisterItem)(Widget * widget);
  U0 (*SetIcon)(Context2DWidget * widget, U8 * path);
};

@systemtray SystemTray;

U0 @systemtray_register_item(I64 addr) {
  Context2DWidget *item = Gui.CreateWidget(
      Compositor.menubar.win, WIDGET_TYPE_CONTEXT2D, -24, 0, 24, 24);
  item->ctx = NewContext2D(item->width, item->height);
  Fill2D(item->ctx, Color(0, 0, 0, 0));
  MemSetI64(addr, item, 1);
}

U0 @systemtray_unregister_item(Widget *item) {
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  msg->client = NULL;
  msg->type = CPZ_MSG_WIN_WIDGET_DESTROY;
  msg->payload = item;
  System.Log(Fs, "Sent message → WidgetDestroy");
  Ipc.MsgSend(Compositor.menubar.task, msg);
}

U0 @systemtray_reindex_items() {
  I64 x = Display.Width() - 100;
  @window_widgets_list *item = Compositor.menubar.win->widget;
  while (item) {
    if (item->widget->type == WIDGET_TYPE_CONTEXT2D) {
      x -= item->widget->width + 4;
      item->widget->x = x;
    }
    item = item->next;
  }
  Gui.Window.Refresh(Compositor.menubar.win);
}

U0 @systemtray_ipc_queue_process() {
  IpcMessage *msg;
  msg = Ipc.MsgRecv();
  if (msg) {
    switch (msg->type) {
    case SYSTRAY_MSG_REGISTER:
      @systemtray_register_item(msg->payload);
      @systemtray_reindex_items;
      break;
    case SYSTRAY_MSG_UNREGISTER:
      @systemtray_unregister_item(msg->payload);
      @systemtray_reindex_items;
      break;
    default:
      break;
    }
    Free(msg);
  }
}

U0 @systemtray_init() {}

U0 @systemtray_task() {
  Ipc.InitQueue(Fs);
  SystemTray.task = Fs;
  System.Log(Fs, "Task running at 0x%08x", Fs);
  while (!Compositor.menubar.win) // Wait for instance
    Sleep(1);
  while (1) {
    @systemtray_ipc_queue_process();
    Sleep(1);
  }
}

Context2DWidget *@systemtray_client_register_item() {
  Context2DWidget *item = NULL;
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  msg->client = NULL;
  msg->type = SYSTRAY_MSG_REGISTER;
  msg->payload = &item;
  System.Log(Fs, "Sent message → SystrayRegisterItem");
  Ipc.MsgSend(SystemTray.task, msg);
  while (!item)
    Sleep(1);
  return item;
}

U0 @systemtray_client_unregister_item(Widget *item) {
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  msg->client = NULL;
  msg->type = SYSTRAY_MSG_UNREGISTER;
  msg->payload = item;
  System.Log(Fs, "Sent message → SystrayUnRegisterItem");
  Ipc.MsgSend(SystemTray.task, msg);
  while (item->type)
    Sleep(1);
  @systemtray_reindex_items;
}

U0 @systemtray_set_icon(Context2DWidget *widget, U8 *path) {
  if (!widget || !path)
    return;
  U8 full_path[512];
  if (2 == 3) // FIXME
    StrCpy(&full_path, path);
  else {
    StrCpy(&full_path, "T:/Media/Themes/Umami/Icon/");
    String.Append(&full_path, path);
  }
  if (!FileFind(&full_path))
    return;
  Context2D *icon = PNG.FileToContext2D(&full_path);
  CopyRect2D(widget->ctx, 0, 0, icon);
  DelContext2D(icon);
  Gui.Window.Refresh(Compositor.menubar.win);
}

SystemTray.Init = &@systemtray_init;
SystemTray.RegisterItem = &@systemtray_client_register_item;
SystemTray.SetIcon = &@systemtray_set_icon;
SystemTray.Task = &@systemtray_task;
SystemTray.UnregisterItem = &@systemtray_client_unregister_item;

"systemtray ";
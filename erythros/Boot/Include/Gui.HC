U0 @gui_event_loop(CTask *task) {
  Fs->ipc = task->ipc;
  IpcMessage *msg;
  while (1) {
    msg = Ipc.MsgRecv();
    if (msg) {
      switch (msg->type) {
      // TODO:
      case CPZ_MSG_WIN_WIDGET_DESTROY:
        @gui_widget_destroy(msg->payload);
      case CPZ_MSG_WIN_MOVE_TO:
        break;
      case CPZ_MSG_WIN_KEY_PRESS:
        if (msg->payload(Window *)->callback.keypress)
          msg->payload(Window *)->callback.keypress(msg->payload, msg->i64);
        @gui_window_repaint(msg->payload, msg->type);
        Compositor.theme.window_repaint(msg->payload, msg->type);
        if (msg->payload(Window *)->callback.repaint)
          msg->payload(Window *)->callback.repaint(msg->payload);
        break;
      case CPZ_MSG_WIN_MOUSE_AT:
        if (msg->payload(Window *)->callback.mouseat)
          msg->payload(Window *)->callback.mouseat(msg->payload);
        @gui_window_repaint(msg->payload, msg->type);
        Compositor.theme.window_repaint(msg->payload, msg->type);
        if (msg->payload(Window *)->callback.repaint)
          msg->payload(Window *)->callback.repaint(msg->payload);
        break;
      case CPZ_MSG_WIN_MOUSE_WHEEL:
      case CPZ_MSG_WIN_LEFT_BTN_UP:
      case CPZ_MSG_WIN_LEFT_BTN_DOWN:
      case CPZ_MSG_WIN_RIGHT_BTN_UP:
      case CPZ_MSG_WIN_RIGHT_BTN_DOWN:
      case CPZ_MSG_WIN_REPAINT:
        @gui_window_repaint(msg->payload, msg->type);
        Compositor.theme.window_repaint(msg->payload, msg->type);
        if (msg->payload(Window *)->callback.repaint)
          msg->payload(Window *)->callback.repaint(msg->payload);
        break;
      // FIXME: add CPZ_MSG_WIN_RESIZE
      default:
        break;
      }
      Free(msg);
    }
    Sleep(1);
  }
}

Ipc.InitQueue(Fs);
Spawn(&@gui_event_loop, Fs, Fs->task_name, 1);
System.Log(Fs, "Task running at 0x%08x", Fs);
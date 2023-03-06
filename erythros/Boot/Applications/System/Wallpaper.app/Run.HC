// Gui.App();

U0 @event_loop(CTask *task) {
  Fs->ipc = task->ipc;
  IpcMessage *msg;
  while (1) {
    msg = Ipc.MsgRecv();
    if (msg) {
      Free(msg);
    }
    Sleep(1);
  }
}

Ipc.InitQueue(Fs);
Spawn(&@event_loop, Fs);

U0 Main() {
  System.Log(Fs, "Task running at 0x%08x", Fs);
  Window *win = Compositor.CreateWindow(0, 0, Display.Width(), Display.Height(),
                                        WIN_FLAGS_NO_REINDEX | WIN_FLAGS_SKIP,
                                        "Wallpaper");
  Compositor.SetWallpaper(Compositor.theme.wallpaper);
  Suspend;
}

Main;
// Save pointer to TempleOS system-wide (CTRL-ALT) callbacks
U64 tos_fp_cbs_enabled = keydev.fp_ctrl_alt_cbs;
U64 tos_fp_cbs_disabled = CAlloc(0xD0);

U0 @init_erythros() {
  I64 err;

  // Initialize Display
  if (!Display.Driver())
    err = Display.Init(1920, 1080, 32, FB_VMSVGA);

  if (err) {
    DocClear(Fs->put_doc);
    "No supported display device found.";
    while (1) {
      Sleep(1);
    };
  }

  // Enable debug output
  Raw(ON);
  DocDump(adam_task->put_doc);

  // Disable TempleOS system-wide (CTRL-ALT) callbacks
  keydev.fp_ctrl_alt_cbs = tos_fp_cbs_disabled;

  // Suspend TempleOS Window Manager task
  Suspend(sys_winmgr_task);

  // Reassign VGA writes to a random buffer to avoid collision with SVGA FB
  text.vga_alias = MAlloc(1048576);

  // Initialize Graphics2D Library
  Graphics2D.Init();

  "\x1b[2J\x1b[H";
  "%s\n", System.BuildInfo();

  switch (Display.Driver()) {
  case FB_VMSVGA:
    "Display driver is: VMSVGA\n";
    break;
  }

  // Initialize Mouse
  Mouse.Init();
  Spawn(Mouse.Task, , "Mouse");

  if (!Mouse.Update)
    VBoxGuest.Init(); // Detect VBox mouse integration
  if (!Mouse.Update)
    VirtioTablet.Init(); // Detect QEMU mouse integration

  // Initialize Network
  @virtio_net_init;
  Spawn(&@virtio_net_handler_task, , "Virtio-net", mp_cnt - 1);
  Spawn(&Netcfg, , "Netcfg");

  // Initialize FileSystem
  FileSystem.Init();

  // Initialize Compositor
  Compositor.Init();

  // Spawn Compositor
  Spawn(Compositor.Task, , "Compositor");

  // Spawn SystemStarter
  Spawn(SystemStarter.Task, , "SystemStarter", 1);
}

@init_erythros;
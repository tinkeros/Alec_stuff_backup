#define SYSSTART_MSG_NULL 0
#define SYSSTART_MSG_SPAWN 1
#define SYSSTART_MSG_KILL 2

class @systemtask {
  U8 *path;
  U8 *name;
};

class @systemstarter {
  CTask *task;
  U0 (*CreateTask)(U8 * path, U8 * name);
  U0 (*Init)();
  U0 (*Spawn)(U8 * path, U8 * name);
  U0 (*Task)();
};

@systemstarter SystemStarter;

U32 @systemstarter_ext(U8 *path) {
  U32 res = NULL;
  U8 *ext = FileSystem.GetFileExtension(path);
  MemCpy(&res, ext, StrLen(ext));
  return res;
}

U0 @systemstarter_init() {}

I64 @systemstarter_open(@shell *sh, I64 argc, U8 **argv) {
  U8 buf[512];
  U8 *path = @shell_expand_relative_path(sh, argv[1]);
  if (!FileSystem.PathExists(path)) {
    Stdio.WriteLine(sh, "error: path does not exist: ");
    Stdio.WriteLine(sh, path);
    Stdio.WriteLine(sh, "\n");
    Free(path);
    return 1;
  }

  switch (@systemstarter_ext(path)) {
  case 'app':
    StrCpy(&buf, "");
    String.Append(&buf, "I64 @exe_doc_buf_size = NULL; ");
    String.Append(&buf,
                  "U8 *@exe_doc_buf = FileSystem.ReadFile(\"%s/Run.HC\", "
                  "&@exe_doc_buf_size); ",
                  path);
    String.Append(&buf, "ExePutS(@exe_doc_buf); ");
    String.Append(&buf, "Free(@exe_doc_buf); ");
    // System.Log(Fs, &buf);
    CTask *task = User;
    TaskExe(task, NULL, "Raw(ON);\n", 0);
    TaskExe(task, NULL, &buf, 0);
    return 0;
    break;
  default:
    Stdio.WriteLine(sh, "error: unknown or unsupported file type.\n");
    // Free(path);
    return 1;
    break;
  };
}

U0 @systemstarter_spawn(U8 *path, U8 *name) {
  CTask *task = User;
  U8 change_path_str[512];
  StrPrint(task->task_name, name);
  StrPrint(change_path_str, "Cd(\"%s\");\n", path);
  TaskExe(task, NULL, "Raw(ON);\n", 0);
  TaskExe(task, NULL, change_path_str, 0);
  TaskExe(task, NULL, "ExeFile(\"Run.HC\");\n", 0);
}

U0 @systemstarter_load_applets() {
  U8 applet_name[512];
  CDirEntry *de = FilesFind("T:/Applets/*.applet");
  CDirEntry *tmpde = de;
  while (tmpde) {
    StrCpy(&applet_name, StrLastOcc(tmpde->full_name, "/") + 1);
    *(StrFirstOcc(&applet_name, ".")) = NULL;
    SystemStarter.Spawn(tmpde->full_name, &applet_name);
    tmpde = tmpde->next;
  }
  DirTreeDel(de);
}

U0 @systemstarter_play_user_startup_sound() {
  U8 path[512];
  StrPrint(&path, "/home/%s/.sounds/startup.wav",
           &Compositor.session.user.name);
  U8 **argv = CAlloc(sizeof(U64) * 2);
  argv[0] = "aplay";
  argv[1] = &path;
  @shell *sh = @shell_new(TRUE);
  sh->session = &Compositor.session;
  @shell_cmd_aplay(sh, 2, argv);
  Free(sh);
}

U0 @systemstarter_set_user_wallpaper() {
  U8 path[512];
  StrPrint(&path, "/home/%s/.wallpaper/wallpaper.png",
           &Compositor.session.user.name);
  U8 **argv = CAlloc(sizeof(U64) * 2);
  argv[0] = "wpset";
  argv[1] = &path;
  @shell_cmd_wpset(NULL, 2, argv);
}

U0 @systemstarter_user_startup() {
  // Set User wallpaper
  @systemstarter_set_user_wallpaper();

  // Play User startup sound
  @systemstarter_play_user_startup_sound();
}

U0 @systemstarter_startup() {

  // Set user-specific startup preferences
  Spawn(&@systemstarter_user_startup);

  // Initialize Clipboard
  Clipboard.Init();

  // Spawn Clipboard Task
  Spawn(Clipboard.Task, , "Clipboard", T(mp_cnt > 3, 2, 1));

  // Initialize SystemTray
  SystemTray.Init();

  // Spawn SystemTray Task
  Spawn(SystemTray.Task, , "SystemTray", T(mp_cnt > 3, 2, 1));

  SystemStarter.Spawn("T:/Applications/System/Wallpaper.app", "Wallpaper");
  SystemStarter.Spawn("T:/Applications/System/MenuBar.app", "MenuBar");
  SystemStarter.Spawn("T:/Applications/System/TaskSwitcher.app",
                      "TaskSwitcher");

  // Load SystemTray Applets
  @systemstarter_load_applets;
}

U0 @systemstarter_ipc_queue_process() {
  IpcMessage *msg;
  @systemtask *st = NULL;
  msg = Ipc.MsgRecv();
  if (msg) {
    switch (msg->type) {
    case SYSSTART_MSG_SPAWN:
      if (msg->payload) {
        st = msg->payload;
        if (st->path && st->name) {
          SystemStarter.Spawn(st->path, st->name);
          System.Log(Fs, "Received message ← CreateTask (%s)", st->name);
          Free(st->name);
          Free(st->path);
        }
        Free(st);
      }
      break;
    case SYSSTART_MSG_KILL:
      break;
    default:
      break;
    }
    Free(msg);
  }
}

U0 @systemstarter_task() {
  Ipc.InitQueue(Fs);
  System.Log(Fs, "Task running at 0x%08x", Fs);
  SystemStarter.task = Fs;
  Spawn(&@systemstarter_startup, , , T(mp_cnt, 1, 0));

  while (1) {
    @systemstarter_ipc_queue_process;
    Sleep(1);
  }
}

U0 @systemstarter_create_task(U8 *path, U8 *name) {
  @systemtask *st = CAlloc(sizeof(@systemtask));
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  st->path = StrNew(path);
  st->name = StrNew(name);
  msg->client = NULL;
  msg->type = SYSSTART_MSG_SPAWN;
  msg->payload = st;
  Ipc.MsgSend(SystemStarter.task, msg);
}

SystemStarter.CreateTask = &@systemstarter_create_task;
SystemStarter.Init = &@systemstarter_init;
SystemStarter.Spawn = &@systemstarter_spawn;
SystemStarter.Task = &@systemstarter_task;

"systemstarter ";

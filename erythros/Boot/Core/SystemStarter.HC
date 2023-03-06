#define SYSSTART_MSG_NULL 0
#define SYSSTART_MSG_SPAWN 1
#define SYSSTART_MSG_KILL 2

class @systemstarter {
  U0 (*Init)();
  U0 (*Spawn)(U8 * path, U8 * name);
  U0 (*Task)();
};

@systemstarter SystemStarter;

U0 @systemstarter_init() {}

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

U0 @systemstarter_startup() {

  // Play Startup sound, if it exists
  Sound *@snd_startup = NULL;
  U8 *@fn_snd_startup = "T:/Media/Sounds/Startup.wav";
  if (FileFind(@fn_snd_startup))
    @snd_startup = Audio.SoundFromFile(@fn_snd_startup);
  if (@snd_startup)
    Audio.PlaySound(@snd_startup);

  // Initialize Clipboard
  Clipboard.Init();

  // Spawn Clipboard Task
  Spawn(Clipboard.Task, , "Clipboard", T(mp_cnt > 3, 2, 1));

  // Initialize SystemTray
  SystemTray.Init();

  // Spawn SystemTray Task
  Spawn(SystemTray.Task, , "SystemTray", T(mp_cnt > 3, 2, 1));

  SystemStarter.Spawn("T:/Applications/Wallpaper.app", "Wallpaper");
  SystemStarter.Spawn("T:/Applications/MenuBar.app", "MenuBar");
  SystemStarter.Spawn("T:/Applications/TaskSwitcher.app", "TaskSwitcher");

  // Load SystemTray Applets
  @systemstarter_load_applets;

  SystemStarter.Spawn("T:/Applications/TestApplication.app", "TestApplication");
}

U0 @systemstarter_ipc_queue_process() {
  IpcMessage *msg;
  msg = Ipc.MsgRecv();
  if (msg) {
    switch (msg->type) {
    case SYSSTART_MSG_SPAWN:
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
  Spawn(&@systemstarter_startup, , , T(mp_cnt, 1, 0));

  while (1) {
    @systemstarter_ipc_queue_process;
    Sleep(1);
  }
}

SystemStarter.Init = &@systemstarter_init;
SystemStarter.Spawn = &@systemstarter_spawn;
SystemStarter.Task = &@systemstarter_task;

"systemstarter ";
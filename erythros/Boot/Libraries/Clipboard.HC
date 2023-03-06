#define CLIP_MSG_NULL 0
#define CLIP_MSG_INSERT 1
#define CLIP_MSG_REMOVE 2

#define CLIP_TYPE_NULL 0
#define CLIP_TYPE_TEXT 1
#define CLIP_TYPE_DATA 2

class @clipboard_item {
  I64 length;
  I64 type;
};

class ClipboardTextItem : @clipboard_item {
  U8 *text;
}

class ClipboardDataItem : @clipboard_item {
  U8 *data;
}

class @clipboard_list_item {
  @clipboard_list_item *prev;
  @clipboard_list_item *next;
  @clipboard_item *item;
};

class @clipboard {
  CTask *task;
  I64 length;
  @clipboard_list_item *items;
  U0 (*Init)();
  U0 (*Insert)(I64 type, U8 * data);
  I64 (*Length)();
  U0(*Task)
  ();
};

@clipboard Clipboard;

U0 @clipboard_add(@clipboard_item *item) {
  @clipboard_list_item *items = Clipboard.items;
  while (items->next) {
    items = items->next;
  }
  @clipboard_list_item *new_item = CAlloc(sizeof(@clipboard_list_item));
  new_item->prev = items;
  new_item->item = item;
  items->next = new_item;
  Clipboard.length++;
  Clipboard.items->prev = new_item;
}

U0 @clipboard_init() { Clipboard.items = CAlloc(sizeof(@clipboard_list_item)); }

I64 @clipboard_length() { return Clipboard.length; }

U0 @clipboard_ipc_queue_process() {
  IpcMessage *msg;
  msg = Ipc.MsgRecv();
  if (msg) {
    switch (msg->type) {
    case CLIP_MSG_INSERT:
      @clipboard_add(msg->payload);
      break;
    case CLIP_MSG_REMOVE:
      // FIXME: Handle this
      break;
    default:
      break;
    }
    Free(msg);
  }
}

U0 @clipboard_insert_text(U8 *text) {
  IpcMessage *msg = CAlloc(sizeof(IpcMessage));
  ClipboardTextItem *item = CAlloc(sizeof(ClipboardTextItem));
  item->length = StrLen(text);
  item->type = CLIP_TYPE_TEXT;
  item->text = text;
  msg->client = NULL; // FIXME: Do we care about client here? :/
  msg->type = CLIP_MSG_INSERT;
  msg->payload = item;
  System.Log(Fs, "Sent message → ClipInsert -> \"%s\"", text);
  Ipc.MsgSend(Clipboard.task, msg);
}

U0 @clipboard_insert(I64 type, U8 *data) {
  switch (type) {
  case CLIP_TYPE_TEXT:
    @clipboard_insert_text(data);
    break;
  case CLIP_TYPE_DATA:
    // Reserved
    break;
  default:
    break;
  }
}

U0 @clipboard_task() {
  Ipc.InitQueue(Fs);
  Clipboard.task = Fs;
  System.Log(Fs, "Task running at 0x%08x", Fs);
  while (1) {
    @clipboard_ipc_queue_process();
    Sleep(1);
  }
}

Clipboard.Init = &@clipboard_init;
Clipboard.Insert = &@clipboard_insert;
Clipboard.Length = &@clipboard_length;
Clipboard.Task = &@clipboard_task;

"clipboard ";

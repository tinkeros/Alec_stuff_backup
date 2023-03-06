#define ipc user_data
#define IPC_QUEUE_SIZE 1024

class IpcMessage {
  CTask *client;
  I64 type;
  U64 payload;
  I64 i64;
};

class @ipc {
  U0 (*InitQueue)(CTask * task);
  IpcMessage *(*MsgRecv)();
  U0 (*MsgSend)(CTask * task, IpcMessage * msg);
};

U0 @ipc_queue_init(CTask *task) { // Initialize a task's IpcMessage Queue
  MemSetU32(task->pad, 0, 1);
  if (!task->ipc) {
    task->ipc = FifoI64New(IPC_QUEUE_SIZE);
  }
}

IpcMessage *@ipc_msg_recv() { // Receive a IpcMessage from current task's
                              // message queue.
  U64 msg_ptr;
  if (!FifoI64Cnt(Fs->ipc))
    return FALSE;
  FifoI64Rem(Fs->ipc, &msg_ptr);
  return msg_ptr;
}

U0 @ipc_msg_send(
    CTask *task,
    IpcMessage *msg) { // Send a IpcMessage to a task (client or server)
  FifoI64Ins(task->ipc, msg);
}

@ipc Ipc;

Ipc.InitQueue = &@ipc_queue_init;
Ipc.MsgRecv = &@ipc_msg_recv;
Ipc.MsgSend = &@ipc_msg_send;

"ipc ";
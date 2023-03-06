#define VBOX_REQUEST_HEADER_VERSION 0x10001
#define VBOX_REQUEST_GUEST_INFO 50
#define VBOX_REQUEST_GET_MOUSE 1
#define VBOX_REQUEST_SET_MOUSE 2
#define VBOX_VMMDEV_VERSION 0x00010003

class @vboxguest_header {
  U32 size;
  U32 version;
  U32 requestType;
  I32 rc;
  U32 reserved1;
  U32 reserved2;
};

class @vboxguest_info {
  @vboxguest_header header;
  U32 version;
  U32 ostype;
};

class @vboxguest_mouse_absolute {
  @vboxguest_header header;
  U32 features;
  I32 x;
  I32 y;
};

class @vboxguest {
  U32 port;
  U32 vmmdev;
  U32 irq;
  @vboxguest_mouse_absolute *mouse;
  U0 (*Init)();
};

@vboxguest VBoxGuest;

U0 @vboxguest_mouse_update() {
  I64 x, y;
  OutU32(VBoxGuest.port, VBoxGuest.mouse);
  x = (VBoxGuest.mouse->x * GR_WIDTH) / 0xFFFF;
  y = (VBoxGuest.mouse->y * GR_HEIGHT) / 0xFFFF;
  ms.pos.x = x;
  ms.pos.y = y;
  ms.pos_text.x = ms.pos.x / FONT_WIDTH;
  if (ms.pos_text.x >= text.cols) {
    ms.pos_text.x = text.cols - 1;
    ms.pos.x = text.cols * FONT_WIDTH - 1;
  }
  ms.pos_text.y = ms.pos.y / FONT_HEIGHT;
  if (ms.pos_text.y >= text.rows) {
    ms.pos_text.y = text.rows - 1;
    ms.pos.y = text.rows * FONT_HEIGHT - 1;
  }
}

U0 @vboxguest_init() {
  I64 j;
  // Scan for device
  j = PCIClassFind(0x088000, 0);
  if (j < 0) {
    "\nVBoxGuest device not found.\n";
    return;
  }
  VBoxGuest.port = PCIReadU32(j.u8[2], j.u8[1], j.u8[0], 0x10) & 0xFFFFFFFC;
  VBoxGuest.vmmdev = PCIReadU32(j.u8[2], j.u8[1], j.u8[0], 0x14) & 0xFFFFFFF0;
  VBoxGuest.irq = PCIReadU8(j.u8[2], j.u8[1], j.u8[0], 0x3C);
  @vboxguest_info *guest_info =
      MAllocAligned(sizeof(@vboxguest_info), 16, Fs->code_heap);
  VBoxGuest.mouse =
      CAllocAligned(sizeof(@vboxguest_mouse_absolute), 16, Fs->code_heap);
  guest_info->header.size = sizeof(@vboxguest_info);
  guest_info->header.version = VBOX_REQUEST_HEADER_VERSION;
  guest_info->header.requestType = VBOX_REQUEST_GUEST_INFO;
  guest_info->header.rc = 0;
  guest_info->header.reserved1 = 0;
  guest_info->header.reserved2 = 0;
  guest_info->version = VBOX_VMMDEV_VERSION;
  guest_info->ostype = 0;
  OutU32(VBoxGuest.port, guest_info);
  VBoxGuest.mouse->header.size = sizeof(@vboxguest_mouse_absolute);
  VBoxGuest.mouse->header.version = VBOX_REQUEST_HEADER_VERSION;
  VBoxGuest.mouse->header.requestType = VBOX_REQUEST_SET_MOUSE;
  VBoxGuest.mouse->header.rc = 0;
  VBoxGuest.mouse->header.reserved1 = 0;
  VBoxGuest.mouse->header.reserved2 = 0;
  VBoxGuest.mouse->features = (1 << 0) | (1 << 4);
  VBoxGuest.mouse->x = 0;
  VBoxGuest.mouse->y = 0;
  OutU32(VBoxGuest.port, VBoxGuest.mouse);
  VBoxGuest.mouse->header.requestType = VBOX_REQUEST_GET_MOUSE;
  Free(guest_info);
  "\nVBoxGuest device detected, enabling mouse integration\n";
}

U0 @mouse_task() {
  while (1) {
    @vboxguest_mouse_update;
    Sleep(1);
  }
}

@vboxguest_init;
Spawn(&@mouse_task, , "VBoxGuest Mouse Driver");
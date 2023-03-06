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
  OutU32(VBoxGuest.port, VBoxGuest.mouse);
  Mouse.x = (VBoxGuest.mouse->x * Display.Width()) / 0xFFFF;
  Mouse.y = (VBoxGuest.mouse->y * Display.Height()) / 0xFFFF;
  Mouse.left = ms.lb;
  Mouse.right = ms.rb;
}

U0 @vboxguest_init() {
  I64 j;
  // Scan for device
  j = PCIClassFind(0x088000, 0);
  if (j < 0) {
    //"\nVBoxGuest device not found.\n";
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
  Mouse.Update = &@vboxguest_mouse_update;
  @mouse_integration_type_set(MI_VBOX);
  "\x1b[33mVBoxGuest device detected, enabling mouse integration\x1b[0m\n";
}

VBoxGuest.Init = &@vboxguest_init;

"vboxguest ";
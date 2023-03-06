// FIXME: This should be an Input driver which contains both Keyboard/Mouse
// classes.
extern U0 @vmsvga_mouse_pointer_set(U32 *pointer, I64 width, I64 height);

#define MI_QEMU 0x01
#define MI_VBOX 0x02
#define MS_UPDATE_INTERVAL 10

#define MS_UP 0
#define MS_DOWN 1

class @mouse {
  I64 x;
  I64 y;
  I64 z;
  I64 delta_z;
  I64 wheel_sensitivity;
  U32 *pointer;
  I64 integration_type;
  Bool left;
  Bool right;
  Bool natural_scroll;
  I64 (*X)();
  I64 (*Y)();
  U0 (*PointerSet)(U32 * pointer, I64 width, I64 height);
  U0 (*Init)();
  U0 (*Update)();
  U0 (*Task)();
};

class @keyboard {
  I64 active_key;
  I64 active_key_tS;
  I64 last_key_tS;
  U0 (*Update)();
};

@mouse Mouse;
@keyboard Keyboard;

U0 @keyboard_update() {
  I64 sc;
  if (FifoI64Rem(kbd.scan_code_fifo, &sc)) {
    if (!(sc & SCF_KEY_UP)) {
      Keyboard.active_key = sc(U8);
      Keyboard.active_key_tS = cnts.jiffies;
      return;
    }
  }
  Keyboard.active_key = 0;
}

Keyboard.Update = &@keyboard_update;

I64 @mouse_x() { return Mouse.x; }

I64 @mouse_y() { return Mouse.y; }

U0 @mouse_integration_type_set(I64 type) { Mouse.integration_type = type; }

U0 @mouse_pointer_set(U32 *pointer, I64 width, I64 height) {
  if (Mouse.pointer != pointer) {
    Mouse.pointer = pointer;
    if (Mouse.integration_type == MI_VBOX) {
      @vmsvga_mouse_pointer_set(pointer, width, height);
    }
  }
}

U0 @mouse_init() {
  Mouse.x = Display.Width() / 2;
  Mouse.y = Display.Height() / 2;
  Mouse.z = ms.pos.z;
  Mouse.wheel_sensitivity = 2;
  Mouse.pointer = NULL;
  Mouse.left = OFF;
  Mouse.right = OFF;
}

U0 @mouse_task() {
  while (1) {
    WinMsUpdate;
    KbdMsHndlr(0, 0);
    Keyboard.Update();
    if (Mouse.Update)
      Mouse.Update();
    if (!Mouse.Update) {
      Mouse.x = ms.pos.x * (Display.Width() / GR_WIDTH);
      Mouse.y = ms.pos.y * (Display.Height() / (GR_HEIGHT / 1.025));
      Mouse.left = ms.lb;
      Mouse.right = ms.rb;
    }
    Mouse.z = ms.pos.z;
    Sleep(MS_UPDATE_INTERVAL);
  }
}

Mouse.X = &@mouse_x;
Mouse.Y = &@mouse_y;
Mouse.PointerSet = &@mouse_pointer_set;
Mouse.Init = &@mouse_init;
Mouse.Update = NULL;
Mouse.Task = &@mouse_task;

"mouse ";
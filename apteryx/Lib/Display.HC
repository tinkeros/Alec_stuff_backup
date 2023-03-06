#define DISPLAY_DRIVER_VMSVGA 0x030000

class @display {
  I64 width;
  I64 height;
  I64 bpp;
  I64 driver;
  U64 fb;

  U0(*Init)
  (I64 width, I64 height, I64 bpp, I64 driver);
  I64(*Width)
  ();
  I64(*Height)
  ();
  I64(*Bpp)
  ();
  I64(*Driver)
  ();
  U0 (*Update)();
};

@display Display;
Display.driver = NULL;
Display.Update = NULL;

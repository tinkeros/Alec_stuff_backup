#define FB_NONE 0x00
#define FB_VMSVGA 0x01

I64 @display_init(I64 width, I64 height, I64 bpp, I64 driver) {
  I64 err;
  Display.width = width;
  Display.height = height;
  Display.bpp = bpp;
  Display.driver = driver;
  Display.fb = NULL;
  switch (Display.driver) {
  case FB_VMSVGA:
    err = VMSVGA.Init(Display.width, Display.height, Display.bpp);
    if (err)
      return err;
    Display.fb = VMSVGA.FrameBuffer();
    break;
  default:
    //"Unsupported display driver\n";
    return -1;
    break;
  }
  text.cols = Display.width / 8;
  text.rows = Display.height / 16;
  text.raw_col = 0;
  return 0;
}

I64 @display_get_width() { return Display.width; }

I64 @display_get_height() { return Display.height; }

I64 @display_get_bpp() { return Display.bpp; }

I64 @display_get_driver() { return Display.driver; }

Display.Init = &@display_init;
Display.Width = &@display_get_width;
Display.Height = &@display_get_height;
Display.Bpp = &@display_get_bpp;
Display.Driver = &@display_get_driver;

"display ";
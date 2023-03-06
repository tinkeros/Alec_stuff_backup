class Display
{
    I64 width;
    I64 height;
    I64 bpp;
};

Display display;

U0 DisplayInit()
{
    display.width = 640;
    display.height = 480;
    display.bpp = 32;
}

DisplayInit;
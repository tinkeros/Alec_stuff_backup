Bool MM_EDIT_MODE = FALSE;
CDC *Buffer = DCAlias();
CDC *BgrImage = GRRead("Graphics/Bgr1");
CDC *BgrMap = GRRead("DemoLevel.LVL");
CDC *BgrLayer = DCNew(640, 480);

I64 PtrMsGrab, PtrMsStd;
U8 ScanCode;

PtrMsGrab = *gr.fp_draw_grab_ms;
PtrMsStd = *gr.fp_draw_ms;

#include "Font";
#include "Palette";
#include "Sound";
#include "Sprite";
#include "Bgr";

U0 HideMs() { MsSet(639,479,0); };

#include "Game";

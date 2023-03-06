#include "Lib/VMSVGA";
#include "Lib/Display";
#include "Lib/Graphics2D";
#include "Lib/uPNG";

#include "Lib/Misc";

#include "Lib/Debugger";

Context2D *screen_ctx = NewContext2D(640, 480, 32);
Context2D *pixel_ctx = NewContext2D(512, 480, 32);

#include "Font";
#include "Snes";
#include "LoROM";

#include "MMU";
#include "CPU";
#include "PPU";

U0 cpu_task()
{
    while (1) { if (!Debug && !KeyDown(SC_F1)) cycle(0); };
}

U0 gfx_task()
{
    while (1)
    {
        if (yPos>238 && !Debug)
        {
            setPixels(pixel_ctx->fb);        
            CopyRect2D(screen_ctx, (screen_ctx->width/2)-(pixel_ctx->width/2), 0, pixel_ctx);
            UpdateTOSMenuBar(screen_ctx);
            Flip2D(screen_ctx);
        }
    }
}

U0 input_loop()
{
    while (1)
    {
        WinMsUpdate;
        KbdMsHndlr(0, 0);
        if (KeyDown(SC_ESC))
        {
            FifoI64Flush(kbd.down_bitmap);
            Debug = TRUE;
            Dbg;
        }
        if (KeyDown(Char2ScanCode('`')))
        {
            cpu_reset;
            ppu_reset;
        }
        Joypad1Update;
        Sleep(1);
    }
}

U0 LoadCart(U8 *filename)
{
    // FIXME: Add sanity checks
    LoROM(filename);
    U8 *info_string=CAlloc(1024);

    StrPrint(append(info_string), "Loaded ROM: \"%s\"; \n", header.name);
    StrPrint(append(info_string), "Type: LoROM\n");
    StrPrint(append(info_string), "Banks: %d; Sram size: 0x%04X\n", header.banks, header.sramSize);
    PopUpOk(info_string);

    VMSVGA_Start;
    SysFrameBufferInit;
    
    cpu_reset;

    Spawn(&cpu_task,,,1);
    Spawn(&gfx_task,,,2);

    input_loop;
    Free(info_string);
}

U0 Bahamut(U8 *filename)
{
    if (IsDir(filename))
    {
        PopUpOk("That's a directory...");
        return;
    }
    CDirEntry *file = FilesFind(filename);
    if (file)
    {
        DirTreeDel(file);
        LoadCart(filename);
        return;
    }
    else
    {
        PopUpOk("File not found...");
        return;
    }
}

while (1) Bahamut(PopUpPickFile("T:/ROMs/"));

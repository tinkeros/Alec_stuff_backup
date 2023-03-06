#define include_noreindex #include
include_noreindex "Lib/Function";
include_noreindex "Lib/Display";
include_noreindex "Lib/Graphics2D";
include_noreindex "Lib/Misc";
include_noreindex "Lib/Audio";
include_noreindex "Lib/HDAudio";
include_noreindex "Lib/VMSVGA";
include_noreindex "Lib/uPNG";
include_noreindex "Lib/JUnzip";

I64 rom_data = NULL;
I64 rom_size = 0;

U0 jzFileWrite(U8 *filename, U8 *data, I64 size) {
  if (!filename || !data || !size)
    return;
  if (!StrFind(".bin", filename))
    return;
  rom_size = size;
  rom_data = CAlloc(rom_size);
  MemCpy(rom_data, data, size);
}

include_noreindex "Lib/Debugger";

include_noreindex "Font";

Context2D *screen_ctx = NewContext2D(640, 480, 32);
Context2D *pixel_ctx = NewContext2D(320, 240, 32);
Context2D *pixel_ctx0 = NewContext2D(320, 240, 32);

tmpdoc = DocNew;
origdoc = Fs->put_doc;
Fs->put_doc = tmpdoc;

include_noreindex "m68k";
include_noreindex "z80";
include_noreindex "VDP";
include_noreindex "input";
include_noreindex "megadrive";

Free(pixel_ctx->fb);
pixel_ctx->fb = screen;

Fill2D(pixel_ctx, 0);
Fill2D(pixel_ctx0, 0);

U0 cpu_task() {
  I64 cnt = cnts.jiffies;
  while (1) {
    frame;
    while (cnts.jiffies < cnt + 12)
      Busy(.5);
    cnt = cnts.jiffies;
  }
}

U8 *m68ki_str_lookup(I64 index) {
  I64 i;
  CHashTable *tbl = Fs->parent_task->hash_table;
  CHashFun *sym;
  while (tbl) {
    for (i = 0; i <= tbl->mask; i++) {
      sym = tbl->body[i];
      while (sym) {
        if ((sym->type & HTT_FUN) == HTT_FUN)
          if (sym->exe_addr == m68ki_instruction_jump_table[index])
            return sym->str;
        sym = sym->next;
      }
    }
    tbl = tbl->next;
  }
  return "";
}

U0 gfx_task() {
  I64 i;
  I64 j;
  U64 color;
  while (1) {
    /*
    Print2D(screen_ctx, 0, 8 * 4, , , "PC: %08X", m68ki_cpu.ppc);
    Print2D(screen_ctx, 0, 8 * 5, , ,
            "                                                   ");
    Print2D(screen_ctx, 0, 8 * 5, , , "IR: %08X (%s)", m68ki_cpu.ir,
            m68ki_str_lookup(m68ki_cpu.ir));
            */
    for (i = 0; i < pixel_ctx0->width; i++)
      for (j = 0; j < pixel_ctx0->height; j++) {
        color = Peek2D(pixel_ctx0, i, j);
        
        Plot2D(screen_ctx, i*2,     j*2,     color);
        Plot2D(screen_ctx, i*2 + 1, j*2,     color);
        Plot2D(screen_ctx, i*2,     j*2 + 1, color);
        Plot2D(screen_ctx, i*2 + 1, j*2 + 1, color);
      }
    UpdateTOSMenuBar(screen_ctx);
    Flip2D(screen_ctx);
  }
}

U0 input_loop() {
  I64 i;
  while (1) {
    for (i = 0; i < 8; i++) {
      pad_release_button(0, i);
      pad_release_button(1, i);
      pad_release_button(2, i);
      pad_release_button(3, i);
    }
    if (KeyDown(SC_CURSOR_UP))
      pad_press_button(0, PAD_UP);
    if (KeyDown(SC_CURSOR_DOWN))
      pad_press_button(0, PAD_DOWN);
    if (KeyDown(SC_CURSOR_LEFT))
      pad_press_button(0, PAD_LEFT);
    if (KeyDown(SC_CURSOR_RIGHT))
      pad_press_button(0, PAD_RIGHT);
    if (KeyDown(Char2ScanCode('s')))
      pad_press_button(0, PAD_B);
    if (KeyDown(Char2ScanCode('d')))
      pad_press_button(0, PAD_C);
    if (KeyDown(Char2ScanCode('a')))
      pad_press_button(0, PAD_A);
    if (KeyDown(SC_ENTER))
      pad_press_button(0, PAD_S);
    Sleep(1);
  }
}

U0 LoadCart(U8 *filename) {

  StdioJZFile *f;
  junzip_err = FALSE;
  if (StrFind(".zip", filename)) {
    JZFile *zip;
    JZEndRecord endRecord;
    zip = jzfile_from_file(filename);
    if (jzReadEndRecord(zip, &endRecord)) {
      PopUpOk("Couldn't read ZIP file end record.");
      junzip_err = TRUE;
    }
    if (jzReadCentralDirectory(zip, &endRecord)) {
      PopUpOk("Couldn't read ZIP file central record.");
      junzip_err = TRUE;
    }
    f = zip->addr;
    Free(f->buf);
    Free(f);
    if (junzip_err)
      return;
  }

  if (StrFind(".bin", filename))
    rom_data = FileRead(filename, &rom_size);

  if (!rom_data || !rom_size) {
    PopUpOk("Error loading file...");
    return;
  }

  set_rom(rom_data, rom_size);

  Display.Init(640, 480, 32, DISPLAY_DRIVER_VMSVGA);
  SysFrameBufferInit;

  m68k_pulse_reset;
  Spawn(&cpu_task, , , 1, Fs);
  Spawn(&gfx_task, , , 2, Fs);

  while (1) {
    input_loop;
    Sleep(1);
  }
}

U0 Apteryx(U8 *filename) {
  if (IsDir(filename)) {
    PopUpOk("That's a directory...");
    return;
  }
  CDirEntry *file = FilesFind(filename);
  if (file) {
    DirTreeDel(file);
    if (StrFind(".bin", filename) || StrFind(".zip", filename)) {
      LoadCart(filename);
    } else {
      PopUpOk("Unsupported filename...");
    }
    return;
  } else {
    PopUpOk("File not found...");
    return;
  }
}

while (!fp_snd_fill_buf)
  fp_snd_fill_buf = Audio.MixOutput;

while (1)
  Apteryx(PopUpPickFile("T:/ROMs/"));

Fs->put_doc = origdoc;
DocDel(tmpdoc);
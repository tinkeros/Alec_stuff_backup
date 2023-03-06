#define SDL_APPACTIVE 0x04
#define SDL_APPINPUTFOCUS 0x02
#define SDL_APPMOUSEFOCUS 0x01

#define SDL_KEYDOWN 2
#define SDL_KEYUP 3

#define SDL_RELEASED 0
#define SDL_PRESSED 1

U8 sdl_key_state[256];
MemSet(&sdl_key_state, NULL, 256);

Bool sdl_initial_palette_set = FALSE;
U32 sdl_game_colors[256];

CFifoI64 *sdl_event_fifo = FifoI64New(1024);

CDC *dc_gamescreen = DCNew(320, 200);

U16 sdl_mouse_x = 0;
U16 sdl_mouse_y = 0;

class SDL_keysym {
  U32 scancode;
  U32 sym;
  U32 mod;
  U16 unicode;
};

class SDL_KeyboardEvent {
  U16 type;
  U16 state;
  SDL_keysym keysym;
};

class SDL_Rect {
  I16 x, y;
  U16 w, h;
};

class SDL_Color {
  U8 r;
  U8 g;
  U8 b;
  U8 a;
};

class SDL_Palette {
  I32 ncolors;
  SDL_Color *colors;
};

class SDL_PixelFormat {
  SDL_Palette *palette;
  U8 BitsPerPixel;
  U8 BytesPerPixel;
  U8 Rloss, Gloss, Bloss, Aloss;
  U8 Rshift, Gshift, Bshift, Ashift;
  U32 Rmask, Gmask, Bmask, Amask;
  U32 colorkey;
  U8 alpha;
};

class SDL_Surface {
  U64 flags;
  SDL_PixelFormat *format;
  I32 w, h;
  U16 pitch;
  U16 pad;
  U32 pad2;
  U8 *pixels;
  SDL_Rect clip_rect;
  I32 refcount;
};

class SDL_VideoInfo {
  U32 hw_available;
  U32 wm_available;
  U32 blit_hw;
  U32 blit_hw_CC;
  U32 blit_hw_A;
  U32 blit_sw;
  U32 blit_sw_CC;
  U32 blit_sw_A;
  U32 blit_fill;
  U32 video_mem;
  SDL_PixelFormat *vfmt;
};

class @sdl {
  I32 ticks_init;
};

@sdl sdl;

SDL_Surface *game_surface = NULL;

I64 @SDL_Init() { return 0; }

I64 @SDL_CreateCursor() { return NULL; }

U0 SDL_CreateCursor() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_GetCursor(0x%08x, 0x%08x, %d, %d, %d, %d)\n", p0, p1,
              p2, p3, p4, p5);
  @SDL_CreateCursor;
  POP_SYSV_REGS
}

U0 SDL_Delay() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_Delay(%d)\n", p0);
  Sleep(p0);
  POP_SYSV_REGS
}

I32 @SDL_EnableKeyRepeat(I32 delay, I32 interval) {
  no_warn delay;
  no_warn interval;
  return 0;
}

U0 SDL_EnableKeyRepeat() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_EnableKeyRepeat(%d)\n", p0, p1);
  @SDL_EnableKeyRepeat(p0, p1);
  POP_SYSV_REGS
}

U0 game_start_set_colors() {
  I64 i;
  for (i = 0; i < 256; i++)
    TG_ColorSet(i, sdl_game_colors[i].u8[0], sdl_game_colors[i].u8[1],
                sdl_game_colors[i].u8[2]);
}

I32 @SDL_EnableUNICODE(I32 i) { return i; }

U0 SDL_EnableUNICODE() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_EnableUNICODE(%d)\n", p0);
  game_start_set_colors;
  sdl_initial_palette_set = TRUE;
  TG_Start;
  @SDL_EnableUNICODE(p0);
  POP_SYSV_REGS
}

I64 @SDL_FillRect(SDL_Surface *surface, SDL_Rect *rect, U32 color) {
  no_warn rect;
  MemSet(surface->pixels, color, surface->w * surface->h);
  return NULL;
}

U0 SDL_FillRect() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_FillRect(0x%08x, 0x%08x, 0x%04x", p0, p1, p2);
  POP_SYSV_REGS
}

I64 @SDL_Flip(SDL_Surface *surface) {
  // dc_gamescreen->body = surface->pixels;
  // GrBlot(gr.dc, 0, 0, dc_gamescreen);

  while ((InU8(VGA_INSTAT_READ) & 1))
    ;
  while (!(InU8(VGA_INSTAT_READ) & 1))
    ;
  MemCpy(VGAM_GRAPHICS, surface->pixels, TG_WIDTH * TG_HEIGHT);

  return 0;
}

U0 SDL_Flip() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_Flip(0x%08x)\n", p0);
  @SDL_Flip(p0);
  POP_SYSV_REGS
}

U0 SDL_UpdateRect() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_UpdateRect(0x%08x, %d, %d, %d, %d)\n", p0, p1, p2,
              p3, p4);
  @SDL_Flip(p0);
  POP_SYSV_REGS
}

U0 SDL_Init() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_Init()\n");
  sdl.ticks_init = cnts.jiffies;
  @SDL_Init;
  POP_SYSV_REGS
}

I64 @SDL_GetAppState() { return SDL_APPACTIVE | SDL_APPINPUTFOCUS; }

U0 SDL_GetAppState() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_GetAppState()\n");
  @SDL_GetAppState;
  POP_SYSV_REGS
}

I64 @SDL_GetCursor() { return NULL; }

U0 SDL_GetCursor() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_GetCursor()\n");
  @SDL_GetCursor;
  POP_SYSV_REGS
}

U8 @SDL_GetRelativeMouseState(I32 *x, I32 *y) {
  no_warn x;
  no_warn y;
  return NULL;
}

U0 SDL_GetRelativeMouseState() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_GetRelativeMouseState(0x%08x, 0x%08x)\n", p0, p1);
  @SDL_GetRelativeMouseState(p0, p1);
  POP_SYSV_REGS
}

I32 @SDL_GetTicks() { return cnts.jiffies - sdl.ticks_init; }

U0 SDL_GetTicks() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_GetTicks()\n");
  @SDL_GetTicks;
  POP_SYSV_REGS
}

SDL_VideoInfo *@SDL_GetVideoInfo() {
  SDL_VideoInfo *vinfo = CAlloc(sizeof(SDL_VideoInfo), Fs->code_heap);
  vinfo->hw_available = 1;
  vinfo->wm_available = 1;
  vinfo->blit_hw = 1;
  vinfo->blit_hw_CC = 1;
  vinfo->blit_hw_A = 1;
  vinfo->blit_sw = 1;
  vinfo->blit_sw_CC = 1;
  vinfo->blit_sw_A = 1;
  vinfo->blit_fill = 1;
  vinfo->video_mem = 1048576;
  vinfo->vfmt = CAlloc(sizeof(SDL_PixelFormat), Fs->code_heap);
  vinfo->vfmt->palette = CAlloc(sizeof(SDL_Palette), Fs->code_heap);
  vinfo->vfmt->palette->ncolors = 256;
  vinfo->vfmt->palette->colors = CAlloc(sizeof(SDL_Color) * 256, Fs->code_heap);
  vinfo->vfmt->BitsPerPixel = 8;
  vinfo->vfmt->BytesPerPixel = 1;
  return vinfo;
}

U0 SDL_GetVideoInfo() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_GetVideoInfo()\n");
  @SDL_GetVideoInfo;
  POP_SYSV_REGS
}

SDL_Rect **@SDL_ListModes() {
  SDL_Rect **modes = CAlloc(sizeof(SDL_Rect *) * 2, Fs->code_heap);
  modes[0] = CAlloc(sizeof(SDL_Rect), Fs->code_heap);
  modes[0]->w = 320;
  modes[0]->h = 200;
  return modes;
}

U0 SDL_ListModes() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_ListModes()\n");
  @SDL_ListModes;
  POP_SYSV_REGS
}

I64 @SDL_PollEvent(SDL_KeyboardEvent *event) {
  I64 ev = NULL;
  if (FifoI64Cnt(sdl_event_fifo)) {
    FifoI64Rem(sdl_event_fifo, &ev);
    MemCpy(event, ev, sizeof(SDL_KeyboardEvent));
    Free(ev);
    return 1;
  } else
    return 0;
}

U0 SDL_PollEvent() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_PollEvent(0x%08x)\n", p0);
  @SDL_PollEvent(p0);
  POP_SYSV_REGS
}

U32 sdl_get_sym_for_scancode(I64 sc) {
  switch (sc) {
  case SC_ENTER:
    return '\r';
    break;
  case SC_CURSOR_UP:
    return 273;
    break;
  case SC_CURSOR_DOWN:
    return 274;
    break;
  case SC_CURSOR_LEFT:
    return 276;
    break;
  case SC_CURSOR_RIGHT:
    return 275;
    break;
  case SC_SHIFT:
    return 304;
    break;
  case SC_CTRL:
    return 306;
    break;
  case SC_ALT:
    return 308;
    break;
  default:
    return ScanCode2Char(sc);
    break;
  }
}

U0 @SDL_PumpEvents() {
  KbdMsHndlr(FALSE, FALSE);
  I64 i;
  Bool key_state;
  SDL_KeyboardEvent *event;
  for (i = 0; i < 256; i++) {
    key_state = TG_KeyDown(i);
    if (key_state != sdl_key_state[i]) {
      sdl_key_state[i] = key_state;
      event = CAlloc(sizeof(SDL_KeyboardEvent));
      switch (key_state) {
      case 1:
        event->type = SDL_KEYDOWN;
        event->state = SDL_PRESSED;
        event->keysym.sym = sdl_get_sym_for_scancode(i);
        break;
      case 0:
        event->type = SDL_KEYUP;
        event->state = SDL_RELEASED;
        event->keysym.sym = sdl_get_sym_for_scancode(i);
        break;
      }
      FifoI64Ins(sdl_event_fifo, event);
    }
  }
}

U0 SDL_PumpEvents() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_PumpEvents()\n");
  @SDL_PumpEvents;
  POP_SYSV_REGS
}

I64 @SDL_SetColors(SDL_Surface *surface, SDL_Color *colors, I64 firstcolor,
                   I64 ncolors) {
  I64 i;
  SDL_Color *dst_colors = surface->format->palette->colors;
  for (i = firstcolor; i < ncolors; i++) {
    if (sdl_initial_palette_set)
      TG_ColorSet(i, colors->r, colors->g, colors->b);
    sdl_game_colors[i].u8[0] = colors->r;
    sdl_game_colors[i].u8[1] = colors->g;
    sdl_game_colors[i].u8[2] = colors->b;
    dst_colors->r = colors->r;
    dst_colors->g = colors->g;
    dst_colors->b = colors->b;
    dst_colors++;
    colors++;
  }
  return 1;
}

U0 SDL_SetColors() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_SetColors(0x%08x, 0x%08x, %d, %d)\n", p0, p1, p2,
              p3);
  @SDL_SetColors(p0, p1, p2, p3);
  POP_SYSV_REGS
}

SDL_Surface *@SDL_SetVideoMode(I32 width, I32 height, I32 bpp, U32 flags) {
  no_warn bpp;
  SDL_Surface *surface = CAlloc(sizeof(SDL_Surface), Fs->code_heap);
  surface->flags = flags;
  surface->format = CAlloc(sizeof(SDL_PixelFormat), Fs->code_heap);
  surface->format->palette = CAlloc(sizeof(SDL_Palette), Fs->code_heap);
  surface->format->palette->ncolors = 256;
  surface->format->palette->colors =
      CAlloc(sizeof(SDL_Color) * 256, Fs->code_heap);
  surface->format->BitsPerPixel = 8;
  surface->format->BytesPerPixel = 1;
  surface->w = width;
  surface->h = height;
  surface->pitch = width;
  surface->pixels = CAlloc(width * height, Fs->code_heap);
  game_surface = surface;
  return surface;
}

U0 SDL_SetVideoMode() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_SetVideoMode(%d, %d, %d, %d)\n", p0, p1, p2, p3);
  @SDL_SetVideoMode(p0, p1, p2, p3);
  POP_SYSV_REGS
}

I64 @SDL_ShowCursor(I64 i) { return i; }

U0 SDL_ShowCursor() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_ShowCursor(%d)\n", p0);
  @SDL_ShowCursor(p0);
  POP_SYSV_REGS
}

U8 *@SDL_VideoDriverName(U8 *namebuf, I32 maxlen) {
  no_warn maxlen;
  StrCpy(namebuf, "TempleOS");
  return namebuf;
}

U0 SDL_VideoDriverName() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_VideoDriverName(0x%08x, %d)\n", p0, p1);
  @SDL_VideoDriverName(p0, p1);
  POP_SYSV_REGS
}

U0 @SDL_WarpMouse(U16 x, U16 y) {
  sdl_mouse_x = x;
  sdl_mouse_y = y;
}

U0 SDL_WarpMouse() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called SDL_WarpMouse(%d, %d)\n", p0, p1);
  @SDL_WarpMouse(p0, p1);
  POP_SYSV_REGS
}

I64 @SDL_WM_GrabInput(I64 i) { return i; }

U0 SDL_WM_GrabInput() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_WM_GrabInput(%d)\n", p0);
  @SDL_WM_GrabInput(p0);
  POP_SYSV_REGS
}

U0 SDL_WM_SetCaption() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: SDL_WM_SetCaption('%s', 0x%08x)\n", p0, p1);
  POP_SYSV_REGS
}

U0 SDL_QuitSubSystem() {
  TG_Exit;
  PaletteSetStd;
  _exit();
}
class CAnimation {
  CDC **frame;
  I32 **delays;
  I64 total_frames;
  I64 current_frame;
  I64 ticks;
};

class @animation {
  CAnimation *(*FromBuffer)(U8 * buffer, I64 len);
  CAnimation *(*Load)(U8 * filename);
  U64 func_addr[16];
};

@animation Animation;

Animation.func_addr[0] = get_symbol_address("tgl_load_gif_from_memory");

class @image {
  CDC *(*Load)(U8 * filename);
  CDC *(*FromBuffer)(U8 * buffer, I64 len);
  U64 func_addr[16];
};

@image Image;

Image.func_addr[0] = get_symbol_address("stbi_info_from_memory");
Image.func_addr[1] = get_symbol_address("stbi_load_from_memory");
Image.func_addr[2] = get_symbol_address("stbi_failure_reason");

I64 @cbgr24_to_4_bit(CBGR24 *ptr, Bool dither_probability) {
  I64 res, k;
  if (dither_probability) {
    k = RandU32;
    if (SqrI64(ptr->r) + SqrI64(ptr->g) + SqrI64(ptr->b) >= 3 * SqrI64(k.u8[0]))
      res = 8;
    else
      res = 0;
    if (ptr->r >= k.u8[1])
      res |= RED;
    if (ptr->g >= k.u8[2])
      res |= GREEN;
    if (ptr->b >= k.u8[3])
      res |= BLUE;
  } else {
    if (SqrI64(ptr->r) + SqrI64(ptr->g) + SqrI64(ptr->b) >= SqrI64(0x80)) {
      res = 8;
      if (ptr->r >= 0xC0)
        res |= RED;
      if (ptr->g >= 0xC0)
        res |= GREEN;
      if (ptr->b >= 0xC0)
        res |= BLUE;
    } else {
      res = 0;
      if (ptr->r >= 0x40)
        res |= RED;
      if (ptr->g >= 0x40)
        res |= GREEN;
      if (ptr->b >= 0x40)
        res |= BLUE;
    }
  }
  return res;
}

I32 @stbi_info_from_memory(U8 *buffer, I64 len, I64 *x, I64 *y, I64 *comp) {
  *GCC_FUNC_ADDR(U64 *) = Image.func_addr[0];
  *HOLYC_ARG1(U64 *) = buffer;
  *HOLYC_ARG2(U64 *) = len;
  *HOLYC_ARG3(U64 *) = x;
  *HOLYC_ARG4(U64 *) = y;
  *HOLYC_ARG5(U64 *) = comp;
  asm {
        MOV RDI, [HOLYC_ARG1]
        MOV RSI, [HOLYC_ARG2]
        MOV RDX, [HOLYC_ARG3]
        MOV RCX, [HOLYC_ARG4]
        MOV R8, [HOLYC_ARG5]
        MOV RAX, [GCC_FUNC_ADDR]
        CLI
        CALL RAX
        MOV [HOLYC_RES], RAX
        STI
  }
  return *HOLYC_RES(I32 *);
}

U8 *@stbi_failure_reason() {
  *GCC_FUNC_ADDR(U64 *) = Image.func_addr[2];
  asm {
        MOV RAX, [GCC_FUNC_ADDR]
        CLI
        CALL RAX
        MOV [HOLYC_RES], RAX
        STI
  }
  return *HOLYC_RES(U64 *);
}

U8 *@stbi_load_from_memory(U8 *buffer, I64 len, I64 *x, I64 *y,
                           I64 *channels_in_file, I64 desired_channels) {
  *GCC_FUNC_ADDR(U64 *) = Image.func_addr[1];
  *HOLYC_ARG1(U64 *) = buffer;
  *HOLYC_ARG2(U64 *) = len;
  *HOLYC_ARG3(U64 *) = x;
  *HOLYC_ARG4(U64 *) = y;
  *HOLYC_ARG5(U64 *) = channels_in_file;
  *HOLYC_ARG6(U64 *) = desired_channels;
  asm {
        MOV RDI, [HOLYC_ARG1]
        MOV RSI, [HOLYC_ARG2]
        MOV RDX, [HOLYC_ARG3]
        MOV RCX, [HOLYC_ARG4]
        MOV R8, [HOLYC_ARG5]
        MOV R9, [HOLYC_ARG6]
        MOV RAX, [GCC_FUNC_ADDR]
        CLI
        CALL RAX
        MOV [HOLYC_RES], RAX
        STI
  }
  return *HOLYC_RES(U64 *);
}

U8 *@tgl_load_gif_from_memory(U8 *buffer, I64 len, I64 **delays, I64 *x, I64 *y,
                              I64 *z) {
  *GCC_FUNC_ADDR(U64 *) = Animation.func_addr[0];
  *HOLYC_ARG1(U64 *) = buffer;
  *HOLYC_ARG2(U64 *) = len;
  *HOLYC_ARG3(U64 *) = delays;
  *HOLYC_ARG4(U64 *) = x;
  *HOLYC_ARG5(U64 *) = y;
  *HOLYC_ARG6(U64 *) = z;
  asm {
        MOV RDI, [HOLYC_ARG1]
        MOV RSI, [HOLYC_ARG2]
        MOV RDX, [HOLYC_ARG3]
        MOV RCX, [HOLYC_ARG4]
        MOV R8, [HOLYC_ARG5]
        MOV R9, [HOLYC_ARG6]
        MOV RAX, [GCC_FUNC_ADDR]
        CLI
        CALL RAX
        MOV [HOLYC_RES], RAX
        STI
  }
  return *HOLYC_RES(U64 *);
}

CDC *@image_generate_dc_from_pixels(U8 *pixels, I32 x, I32 y) {
  I64 i;
  I64 j;
  I64 cnt = 0;
  CBGR24 cbgr24;
  CDC *dc = DCNew(x, y);
  for (i = 0; i < y; i++)
    for (j = 0; j < x; j++) {
      cbgr24.r = pixels[cnt];
      cbgr24.g = pixels[cnt + 1];
      cbgr24.b = pixels[cnt + 2];
      if (!pixels[cnt + 3])
        dc->color = TRANSPARENT;
      else
        dc->color = @cbgr24_to_4_bit(&cbgr24, 0);
      GrPlot(dc, j, y - i - 1);
      cnt += 4;
    }
  return dc;
}

CDC *@image_load(U8 *filename) {
  if (!filename || !FileFind(filename)) {
    PrintErr("Image file not found.\n");
    return NULL;
  }
  I64 len;
  I32 x;
  I32 y;
  I32 comp;
  U8 *buffer = FileRead(filename, &len);
  I32 code = @stbi_info_from_memory(buffer, len, &x, &y, &comp);
  if (code != 1) {
    PrintErr("Image type not supported.\n");
    Free(buffer);
    return NULL;
  }
  U8 *pixels = @stbi_load_from_memory(buffer, len, &x, &y, &comp, 4);
  Free(buffer);
  CDC *dc = @image_generate_dc_from_pixels(pixels, x, y);
  Free(pixels);
  return dc;
}

CDC *@image_from_buffer(U8 *buffer, I64 len) {
  I32 x;
  I32 y;
  I32 comp;
  I32 code = @stbi_info_from_memory(buffer, len, &x, &y, &comp);
  if (code != 1) {
    PrintErr("Image type not supported.\n");
    return NULL;
  }
  U8 *pixels = @stbi_load_from_memory(buffer, len, &x, &y, &comp, 4);
  if (!pixels)
    PopUpOk(@stbi_failure_reason);
  CDC *dc = @image_generate_dc_from_pixels(pixels, x, y);
  Free(pixels);
  return dc;
}

CAnimation *@animation_load(U8 *filename) {
  if (!filename || !FileFind(filename)) {
    PrintErr("Animation file not found.\n");
    return NULL;
  }
  I64 len;
  I64 i;
  I32 x;
  I32 y;
  I32 z;
  I64 cnt = 0;
  I32 comp;
  I32 **delays;
  U8 *buffer = FileRead(filename, &len);
  I32 code = @stbi_info_from_memory(buffer, len, &x, &y, &comp);
  if (code != 1 || MemCmp(buffer, "GIF89a", 6)) {
    PrintErr("Animation type not supported.\n");
    Free(buffer);
    return NULL;
  }
  CAnimation *anim = CAlloc(sizeof(CAnimation));
  U8 *pixels = @tgl_load_gif_from_memory(buffer, len, delays, &x, &y, &z);
  Free(buffer);
  CDC *sheet = @image_generate_dc_from_pixels(pixels, x, y * z);
  Free(pixels);
  anim->total_frames = z;
  anim->frame = CAlloc(sizeof(CDC *) * anim->total_frames);
  anim->delays = delays;
  for (i = 0; i < anim->total_frames; i++) {
    anim->frame[i] = DCNew(x, y);
    GrBlot(anim->frame[i], 0, -(cnt), sheet);
    cnt += y;
  }
  DCDel(sheet);
  return anim;
}

CAnimation *@animation_from_buffer(U8 *buffer, I64 len) {
  I64 i;
  I32 x;
  I32 y;
  I32 z;
  I64 cnt = 0;
  I32 comp;
  I32 **delays;
  I32 code = @stbi_info_from_memory(buffer, len, &x, &y, &comp);
  if (code != 1 || MemCmp(buffer, "GIF89a", 6)) {
    PrintErr("Animation type not supported.\n");
    Free(buffer);
    return NULL;
  }
  CAnimation *anim = CAlloc(sizeof(CAnimation));
  U8 *pixels = @tgl_load_gif_from_memory(buffer, len, delays, &x, &y, &z);
  Free(buffer);
  CDC *sheet = @image_generate_dc_from_pixels(pixels, x, y * z);
  Free(pixels);
  anim->total_frames = z;
  anim->frame = CAlloc(sizeof(CDC *) * anim->total_frames);
  anim->delays = delays;
  for (i = 0; i < anim->total_frames; i++) {
    anim->frame[i] = DCNew(x, y);
    GrBlot(anim->frame[i], 0, -(cnt), sheet);
    cnt += y;
  }
  DCDel(sheet);
  return anim;
}

Animation.FromBuffer = &@animation_from_buffer;
Animation.Load = &@animation_load;
Image.FromBuffer = &@image_from_buffer;
Image.Load = &@image_load;

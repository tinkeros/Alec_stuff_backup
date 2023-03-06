extern class Context2D;
extern U32 Color(I64 r, I64 g, I64 b, I64 a = 255);
extern U32 Peek2D(Context2D *ctx, I64 x, I64 y);

class BitmapFont {
  U8 *name;
  U8 *char_map;
  I64 line_height;
  U16 bitmap[4096];
};

class @bitmap_font_list {
  @bitmap_font_list *prev;
  @bitmap_font_list *next;
  BitmapFont *font;
};

class @bitmapfont {
  @bitmap_font_list *fonts;
  U0 (*Add)(BitmapFont * font);
  BitmapFont *(*GetByName)(U8 * name);
  U0 (*Init)();
};

BitmapFont *@bitmapfont_new_from_bdf_data(Context2D *ctx, U8 *bdf_data) {
  BitmapFont *font = CAlloc(sizeof(BitmapFont));

  I64 bdf_lines_max = 0;
  U8 **bdf_lines = String.Split(bdf_data, , &bdf_lines_max);

  I64 char_pos = 0;
  I64 char_x_pos = 0;
  I64 i, w;
  I64 xx, yy;
  /*
  while (*char_map++) {
    // Clear character bitmap
    for (i = 0; i < 16; i++) {
      font->bitmap[(char_pos * 16) + i] = 0;
    }
    // Get character width
    w = 0;
    for (xx = 0; xx < 16; xx++) {
      if (Peek2D(ctx, char_x_pos + xx, 0) == Color(255, 0, 0)) {
        w = xx;
        break;
      }
    }
    // Extract bitmap
    for (yy = 0; yy < 16; yy++) {
      for (xx = 0; xx < w + 1; xx++) {
        if (Peek2D(ctx, char_x_pos + xx, yy) == Color(0, 0, 0)) {
          font->bitmap[(char_pos * 16) + yy] |= 0x8000 >> xx;
        }
      }
      //"%016b\n", font->bitmap[(char_pos * 16) + yy];
    }
    char_pos++;
    char_x_pos += w + 1;
  }
  */
  return font;
}

BitmapFont *@bitmapfont_new_from_context2d(Context2D *ctx, U8 *name,
                                           U8 *char_map, I64 fixed_width = 0) {
  BitmapFont *font = CAlloc(sizeof(BitmapFont));
  font->name = StrNew(name);
  font->char_map = StrNew(char_map);

  I64 char_pos = 0;
  I64 char_x_pos = 0;
  I64 i, w;
  I64 xx, yy;
  while (*char_map++) {
    // Clear character bitmap
    for (i = 0; i < 16; i++) {
      font->bitmap[(char_pos * 16) + i] = 0;
    }
    w = fixed_width;
    if (!w) {
      // Get character width
      for (xx = 0; xx < 16; xx++) {
        if (Peek2D(ctx, char_x_pos + xx, 0) == Color(255, 0, 0)) {
          w = xx;
          break;
        }
      }
    }
    // Extract bitmap
    for (yy = 0; yy < 16; yy++) {
      for (xx = 0; xx < w + 1; xx++) {
        if (Peek2D(ctx, char_x_pos + xx, yy) == Color(0, 0, 0)) {
          font->bitmap[(char_pos * 16) + yy] |= 0x8000 >> xx;
        }
      }
      //"%016b\n", font->bitmap[(char_pos * 16) + yy];
    }
    char_pos++;
    char_x_pos += w + 1;
  }
  return font;
}

@bitmapfont BitmapFonts;

U0 @bitmap_fonts_add(BitmapFont *font) {
  @bitmap_font_list *fonts = BitmapFonts.fonts;
  while (fonts->next) {
    fonts = fonts->next;
  }
  @bitmap_font_list *font_list_item = CAlloc(sizeof(@bitmap_font_list));
  font_list_item->prev = fonts;
  font_list_item->font = font;
  fonts->next = font_list_item;
}

BitmapFont *@bitmap_fonts_get_by_name(U8 *name) {
  @bitmap_font_list *fonts = BitmapFonts.fonts;
  while (fonts) {
    if (fonts->font) {
      if (!StrCmp(fonts->font->name, name))
        return fonts->font;
    }
    fonts = fonts->next;
  }
  return NULL;
}

U0 @bitmap_fonts_init() {
  BitmapFonts.fonts = CAlloc(sizeof(@bitmap_font_list));
}

BitmapFonts.Add = &@bitmap_fonts_add;
BitmapFonts.GetByName = &@bitmap_fonts_get_by_name;
BitmapFonts.Init = &@bitmap_fonts_init;
BitmapFonts.Init();

"bitmapfont ";
class @theme_colors {
  U32 active_border;
  U32 hilight;
};

class @theme_window {
  I64 min_width;
  I64 min_height;
};

class @theme_bitmap_fonts {
  BitmapFont *menu;
  BitmapFont *monospace;
  BitmapFont *sans;
}

class @theme_pointers {
  Context2D *pointer;
  Context2D *pen;
  Context2D *move;
  Context2D *link;
  AnimationContext2D *wait;
  Context2D *horz;
  Context2D *vert;
  Context2D *text;
  Context2D *cross;
  Context2D *dgn1;
  Context2D *dgn2;
  Context2D *help;
  Context2D *alternate;
  Context2D *unavailable;
};

class @theme {
  U8 *path;
  @theme_colors color;
  @theme_bitmap_fonts font;
  @theme_pointers pointer;
  @theme_window window;
  Context2D *wallpaper;
  U0 (*window_repaint)(Window * win, I64 type);
};

"theme ";
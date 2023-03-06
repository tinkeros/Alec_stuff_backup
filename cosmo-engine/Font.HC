extern U0 video_draw_font_tile(Tile *tile, U16 x, U16 y, U8 font_color);

#define FONT_WHITE 0xf

Tile *font_tiles;

U0 font_load_tiles()
{
    U16 num_tiles;
    font_tiles = load_tiles("FONTS.MNI", FONT, &num_tiles);
    "Loading %d font tiles.\n", num_tiles;
}

U0 display_number(I64 x_pos, I64 y_pos, U32 number)
{
    U8 font_color = FONT_WHITE;
    I64 i;
    U8 buf[32];
    StrPrint(buf, "%d", number);
    for(i=0;i < StrLen(buf); i++)
    {
        video_draw_font_tile(&font_tiles[buf[i]-48+26], (x_pos - StrLen(buf) + i + 1) * 8, y_pos * 8, font_color);
    }
}

U0 display_char(I64 x_pos, I64 y_pos, U8 c, U8 font_color)
{
    if(c == 0x18 || c == 0x19 || c == 0x1b || c == 0x1c) //FIXME hack to get arrow key font to render.
    {
        video_draw_font_tile(&font_tiles[c-25 + 3], x_pos * 8, y_pos * 8, font_color);
        return;
    }

    if(c >= 32 && c < 91)
    {
        video_draw_font_tile(&font_tiles[c-48+26], x_pos * 8, y_pos * 8, font_color);
    }
    else
    {
        video_draw_font_tile(&font_tiles[c-97+69], x_pos * 8, y_pos * 8, font_color);
    }
}

U0 display_text_with_color(I64 x_pos, I64 y_pos, U8 *text, U8 color)
{
    I64 len = StrLen(text);
    I64 i;
    for(i=0; i < len; i++)
    {
        display_char(x_pos + i, y_pos, text[i], color);
    }
}

U0 display_text(I64 x_pos, I64 y_pos, U8 *text)
{
    display_text_with_color(x_pos, y_pos, text, 0xf);
}

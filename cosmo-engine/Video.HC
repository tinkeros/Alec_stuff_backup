#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 200

#define DEFAULT_SCALE_FACTOR 2

Bool is_game_mode = TRUE;
Bool is_fullscreen = FALSE;
Bool video_has_initialised = FALSE;
I64 video_scale_factor = DEFAULT_SCALE_FACTOR;

CDC *game_surface = NULL;
CDC *text_surface = NULL;

CDC *game_dc = NULL;
CDC *game_dc0 = NULL;

U0 video_draw_it(CDC *)
{
    gr.dc->color = BLACK;
    GrRect(gr.dc, 0, 8, 640, 32);
    GrRect(gr.dc, 0, 480-40, 640, 40);
    MemCpy(gr.dc->body + (GR_WIDTH*40), game_dc->body, 640*400);        
}


U0 set_game_mode()
{
    if (is_game_mode)
        return;
    is_game_mode = TRUE;
}

U0 set_text_mode()
{
    if (!is_game_mode)
        return;
    is_game_mode = FALSE;
}

Bool video_init()
{
    game_surface = DCNew(SCREEN_WIDTH, SCREEN_HEIGHT);
    text_surface = DCNew(SCREEN_WIDTH*2, SCREEN_HEIGHT*2);
    game_dc = DCNew(SCREEN_WIDTH*2, SCREEN_HEIGHT*2);
    game_dc0 = DCNew(SCREEN_WIDTH*2, SCREEN_HEIGHT*2);
    DCFill(game_surface, BLACK);
    DCFill(text_surface, BLACK);

    set_game_mode;

    video_has_initialised = TRUE;
    return TRUE;
}

U0 video_shutdown()
{
    DCDel(game_surface);
    DCDel(text_surface);
}

U0 video_draw_tile(Tile *tile, U16 x, U16 y)
{
    U8 *pixel = game_surface->body + x + (y * SCREEN_WIDTH);
    U8 *tile_pixel = tile->pixels;
    I64 i, j;
    if (tile > mem_mapped_space) return; //FIXME: Workaround to stop bombs from causing Page Fault
    if(tile->type == SOLID)
    {
        for(i=0;i<TILE_HEIGHT;i++)
        {
            MemCpy(pixel, tile_pixel, TILE_WIDTH);
            pixel += SCREEN_WIDTH;
            tile_pixel += TILE_WIDTH;
        }
    }
    else
    {
        for(i=0;i<TILE_HEIGHT;i++)
        {
            for(j=0;j<TILE_WIDTH;j++)
            {
                if(*tile_pixel != TRANSPARENT_COLOR)
                {
                    *pixel = *tile_pixel;
                }
                pixel++;
                tile_pixel++;
            }
            pixel += SCREEN_WIDTH - TILE_WIDTH;
        }
    }
}

U0 video_fill_screen_with_black() {
    DCFill(game_surface, BLACK);
}

U0 video_draw_font_tile(Tile *tile, U16 x, U16 y, U8 font_color)
{
    U8 *pixel = game_surface->body + x + y * SCREEN_WIDTH;
    U8 *tile_pixel = tile->pixels;
    I64 i, j;

    for(i=0;i<TILE_HEIGHT;i++)
    {
        for(j=0;j<TILE_WIDTH;j++)
        {
            if(*tile_pixel != TRANSPARENT_COLOR)
            {
                *pixel = Cond(*tile_pixel == 0xf, font_color, *tile_pixel);
            }
            pixel++;
            tile_pixel++;
        }
        pixel += SCREEN_WIDTH - TILE_WIDTH;
    }
}

U0 video_draw_tile_with_clip_rect(Tile *tile, U16 x, U16 y, U16 clip_x, U16 clip_y, U16 clip_w, U16 clip_h)
{
    U16 tx = 0;
    U16 ty = 0;
    U16 w = TILE_WIDTH;
    U16 h = TILE_HEIGHT;
    I64 i, j;

    if (x + w < clip_x ||
        y + h < clip_y ||
        x > clip_x + clip_w ||
        y > clip_y + clip_h)
    {
        return;
    }

    if (x < clip_x)
    {
        tx = (clip_x - x);
        w = TILE_WIDTH - tx;
        x = clip_x;
    }

    if (x + w > clip_x + clip_w)
    {
        w -= ((x + w) - (clip_x + clip_w));
    }

    if (y < clip_y)
    {
        ty = (clip_y - y);
        h = TILE_HEIGHT - ty;
        y = clip_y;
    }

    if (y + h > clip_y + clip_h)
    {
        h -= ((y + h) - (clip_y + clip_h));
    }

    U8 *pixel = game_surface->body + x + (y * SCREEN_WIDTH);
    U8 *tile_pixel = &tile->pixels[tx + (ty * TILE_WIDTH)];
        for(i=0;i<h;i++)
        {
            for(j=0; j < w; j++)
            {
                if(tile_pixel[j] != TRANSPARENT_COLOR)
                {
                    pixel[j] = tile_pixel[j];
                }
            }
            pixel += SCREEN_WIDTH;
            tile_pixel += TILE_WIDTH;
        }
}

U0 video_draw_tile_flipped(Tile *tile, U16 x, U16 y)
{
    U8 *pixel = game_surface->body + x + ((y+TILE_HEIGHT-1) * SCREEN_WIDTH);
    U8 *tile_pixel = tile->pixels;
    I64 i, j;
    for(i=0;i<TILE_HEIGHT;i++)
    {
        for(j=0;j<TILE_WIDTH;j++)
        {
            if(*tile_pixel != TRANSPARENT_COLOR)
            {
                *pixel = *tile_pixel;
            }
            pixel++;
            tile_pixel++;
        }
        pixel -= (SCREEN_WIDTH + TILE_WIDTH);
    }
}

U0 video_draw_tile_white(Tile *tile, U16 x, U16 y)
{
    U8 *pixel = game_surface->body + x + (y * SCREEN_WIDTH);
    U8 *tile_pixel = tile->pixels;
    I64 i, j;
    if(tile->type == SOLID)
    {
        for(i=0;i<TILE_HEIGHT;i++)
        {
            MemCpy(pixel, tile_pixel, TILE_WIDTH);
            pixel += SCREEN_WIDTH;
            tile_pixel += TILE_WIDTH;
        }
    }
    else
    {
        for(i=0;i<TILE_HEIGHT;i++)
        {
            for(j=0;j<TILE_WIDTH;j++)
            {
                if(*tile_pixel != TRANSPARENT_COLOR)
                {
                    *pixel = 0xf;
                }
                pixel++;
                tile_pixel++;
            }
            pixel += SCREEN_WIDTH - TILE_WIDTH;
        }
    }
}

U0 video_draw_tile_mode3(Tile *tile, U16 x, U16 y)
{
    U8 *pixel = game_surface->body + x + (y * SCREEN_WIDTH);
    U8 *tile_pixel = tile->pixels;
    I64 i, j;
    if(tile->type == TRANSPARENT)
    {
        for(i=0;i<TILE_HEIGHT;i++)
        {
            for(j=0;j<TILE_WIDTH;j++)
            {
                if(*tile_pixel != TRANSPARENT_COLOR)
                {
                    *pixel |= 8;
                }
                pixel++;
                tile_pixel++;
            }
            pixel += SCREEN_WIDTH - TILE_WIDTH;
        }
    }
}

U0 video_update()
{   // FIXME: text mode stuff
    //MemCpy(game_dc->body, game_surface->body, SCREEN_WIDTH*SCREEN_HEIGHT);
    I64 x, y, c;
    for (y=0;y<SCREEN_HEIGHT;y++)
    {
        for (x=0;x<SCREEN_WIDTH;x++)
        {
            c = GrPeek(game_surface, x, y);
            game_dc0->color = c;
            GrRect(game_dc0, x*2, y*2, 2, 2);
        }
    }
    MemCpy(game_dc->body, game_dc0->body, (SCREEN_WIDTH*2) * (SCREEN_HEIGHT*2));
}

U0 fade_to_black(U16 wait_time)
{
    I64 i;
    for(i=0;i < 16; i++)
    {
        cosmo_wait(wait_time);
        set_palette_color(i, 0);
        video_update();
    }
}

U0 fade_to_white(U16 wait_time)
{
    I64 i;
    for(i=0;i < 16; i++)
    {
        cosmo_wait(wait_time);
        set_palette_color(i, 23);
        video_update();
    }
}

U0 fade_in_from_black(U16 wait_time)
{
    I64 i, j=0;
    for(i=0;i < 16; i++)
    {
        if(i == 8)
        {
            j = 8;
        }
        set_palette_color(i, i + j);
        video_update();
        cosmo_wait(wait_time);
    }
}

U0 fade_to_black_speed_3()
{
    fade_to_black(3);
}

U0 fade_in_from_black_with_delay_3()
{
    fade_in_from_black(3);
}

U0 video_draw_fullscreen_image(U8 *pixels) {
    MemCpy(game_surface->body, pixels, 320 * 200);
}

U0 video_draw_highlight_effect(U16 x, U16 y, U8 type)
{
    I64 i, j;
    U8 *pixel = game_surface->body + x + y * SCREEN_WIDTH;
    for(i=0;i<TILE_HEIGHT;i++)
    {
        for(j=0;j<TILE_WIDTH;j++)
        {
            if((type == 0 && i + j >= 7) ||
               type == 1 ||
               (type == 2 && i >= j))
            {
                *pixel |= 8; //set intensity bit
            }
            pixel++;
        }
        pixel += SCREEN_WIDTH - TILE_WIDTH;
    }
}

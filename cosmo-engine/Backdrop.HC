extern U0 video_draw_tile_with_clip_rect(Tile *tile, U16 x, U16 y, U16 clip_x, U16 clip_y, U16 clip_w, U16 clip_h);

#define BACKGROUND_WIDTH 40
#define BACKGROUND_HEIGHT 18

//Data
U16 backdrop_index = 0xff;
U8 background_x_scroll_flag = 0;
U8 background_y_scroll_flag = 0;

U8 backdrop_filename_tbl[26][13] = {
    "BDBLANK.MNI",
    "BDPIPE.MNI",
    "BDREDSKY.MNI",
    "BDROCKTK.MNI",
    "BDJUNGLE.MNI",
    "BDSTAR.MNI",
    "BDWIERD.MNI",
    "BDCAVE.MNI",
    "BDICE.MNI",
    "BDSHRUM.MNI",
    "BDTECHMS.MNI",
    "BDNEWSKY.MNI",
    "BDSTAR2.MNI",
    "BDSTAR3.MNI",
    "BDFOREST.MNI",
    "BDMOUNTN.MNI",
    "BDGUTS.MNI",
    "BDBRKTEC.MNI",
    "BDCLOUDS.MNI",
    "BDFUTCTY.MNI",
    "BDICE2.MNI",
    "BDCLIFF.MNI",
    "BDSPOOKY.MNI",
    "BDCRYSTL.MNI",
    "BDCIRCUT.MNI",
    "BDCIRCPC.MNI"
};

Tile *bg_tiles;

U0 load_backdrop_image(U8 *filename)
{
    U16 num_tiles;
    bg_tiles = load_tiles(filename, SOLID, &num_tiles);
    "Loading %d background tiles.\n", num_tiles;
}

Bool set_backdrop(U16 new_backdrop_index)
{
    U8 cur_background_x_scroll_flag = 0;
    U8 cur_background_y_scroll_flag = 0;

    if (new_backdrop_index != backdrop_index ||
            cur_background_x_scroll_flag != background_x_scroll_flag ||
            cur_background_y_scroll_flag != background_y_scroll_flag)
    {
        backdrop_index = new_backdrop_index;
        cur_background_x_scroll_flag = background_x_scroll_flag;
        cur_background_y_scroll_flag = background_y_scroll_flag;

        load_backdrop_image(backdrop_filename_tbl[backdrop_index]);
    }

    return TRUE;
}

U0 backdrop_display()
{
    I64 x_offset = 0;
    I64 y_offset = 0;
    I64 sub_tile_x = 0;
    I64 sub_tile_y = 0;
    I64 x, y;

    //background scrolls in 4 pixel increments.
    if(background_x_scroll_flag)
    {
        x_offset = mapwindow_x_offset % (BACKGROUND_WIDTH*2);
        x_offset /= 2;
        sub_tile_x = Cond(mapwindow_x_offset & 1, 4, 0);
    }

    if(background_y_scroll_flag)
    {
        y_offset = mapwindow_y_offset % (BACKGROUND_HEIGHT*2);
        y_offset /= 2;
        sub_tile_y = Cond(mapwindow_y_offset & 1, 4, 0);
    }

    for(y=0; y < MAP_WINDOW_HEIGHT + 1; y++)
    {
        for(x=0; x < MAP_WINDOW_WIDTH + 1; x++)
        {
            video_draw_tile_with_clip_rect(&bg_tiles[((x+x_offset) % BACKGROUND_WIDTH) + ((y+y_offset) % BACKGROUND_HEIGHT) * BACKGROUND_WIDTH], (x+1)*8 - sub_tile_x, (y+1)*8 - sub_tile_y, 8, 8, 8*MAP_WINDOW_WIDTH, 8*MAP_WINDOW_HEIGHT);
        }
    }
}
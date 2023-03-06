#define MAP_WINDOW_WIDTH 38
#define MAP_WINDOW_HEIGHT 18

extern U32 score;
extern U8 num_health_bars;
I64 health = 0;
extern U32 num_stars_collected;
extern U16 num_bombs;
extern CDC *game_surface;
extern U0 video_draw_tile(Tile *tile, U16 x, U16 y);

#define STATUS_BAR_HEIGHT 6
#define STATUS_BAR_WIDTH 38

Tile *status_tiles;

U0 status_load_tiles() {
    U16 num_tiles;
    status_tiles = load_tiles("STATUS.MNI", SOLID, &num_tiles);
    "Loading %d status tiles.\n", num_tiles;
}

U0 status_display()
{
    I64 x, y;
    for(y=0; y < STATUS_BAR_HEIGHT; y++)
    {
        for (x = 0; x < STATUS_BAR_WIDTH; x++)
        {
            video_draw_tile(&status_tiles[x + y * STATUS_BAR_WIDTH], (x + 1) * TILE_WIDTH, (y+MAP_WINDOW_HEIGHT+1) * TILE_HEIGHT);
        }
    }
}

U0 add_to_score_update_on_display(U32 amount_to_add_low, I64 x_pos, I64 y_pos)
{
    score += amount_to_add_low;
    display_number(x_pos, y_pos, score);
}

U0 update_health_bar_display()
{
    I64 x = 0x11;
    I64 y = 0x16;
    I64 i;
    for(i=0;i< num_health_bars;i++)
    {
        if(health - 1 > i)
        {
            video_draw_tile(&font_tiles[95], (x - i) * TILE_WIDTH, y * TILE_HEIGHT);
            video_draw_tile(&font_tiles[96], (x - i) * TILE_WIDTH, (y+1) * TILE_HEIGHT);
        }
        else
        {
            video_draw_tile(&font_tiles[9], (x - i) * TILE_WIDTH, y * TILE_HEIGHT);
            video_draw_tile(&font_tiles[8], (x - i) * TILE_WIDTH, (y+1) * TILE_HEIGHT);
        }
    }
}

U0 display_num_stars_collected()
{
    display_number(0x23,0x16,num_stars_collected);
}

U0 display_num_bombs_left()
{
    video_draw_tile(&font_tiles[97], 0x18 * TILE_WIDTH, 0x17 * TILE_HEIGHT);
    display_number(0x18, 0x17, num_bombs);
}

U0 status_panel_init()
{
    DCFill(game_surface, BLACK);
    status_display;
    add_to_score_update_on_display(0, 9, 0x16);
    update_health_bar_display;
    display_num_stars_collected;
    display_num_bombs_left;
}

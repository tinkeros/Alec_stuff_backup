extern U0 video_draw_tile(Tile *tile, U16 x, U16 y);
extern U8 palette_anim_type;
extern U0 reset_game_state();

#define MAX_MAP_TILES 32768
//Data
U16 current_level;

I64 map_width_in_tiles = 0;
I64 map_stride_bit_shift_amt;
I64 mapwindow_x_offset = 0;
I64 mapwindow_y_offset = 0;
I64 map_max_y_offset = 0;

U8 rain_flag = 0;

U16 map_data[MAX_MAP_TILES];

Tile *map_bg_tiles;
Tile *map_fg_tiles;

U16 map_get_tile_cell(I64 x, I64 y) {
    if (x + y * map_width_in_tiles >= MAX_MAP_TILES)
    {
        return 0;
    }

    return map_data[x + y * map_width_in_tiles];
}

U8 level_filename_ep1_tbl[30][13] = {
    "A1.MNI",
    "A2.MNI",
    "BONUS1.MNI",
    "BONUS2.MNI",
    "A3.MNI",
    "A4.MNI",
    "BONUS1.MNI",
    "BONUS2.MNI",
    "A5.MNI",
    "A6.MNI",
    "BONUS1.MNI",
    "BONUS2.MNI",
    "A7.MNI",
    "A8.MNI",
    "BONUS1.MNI",
    "BONUS2.MNI",
    "A9.MNI",
    "A10.MNI",
    "BONUS1.MNI",
    "BONUS2.MNI",
    "A11.MNI",
    "A12.MNI",
    "BONUS1.MNI",
    "BONUS2.MNI",
    "A13.MNI",
    "A14.MNI",
    "BONUS1.MNI",
    "BONUS2.MNI",
    "A15.MNI",
    "A16.MNI"
};

U8 level_filename_ep2_tbl[30][13] = {
    "B1.MNI",
    "B2.MNI",
    "BONUS3.MNI",
    "BONUS4.MNI",
    "B3.MNI",
    "B4.MNI",
    "BONUS3.MNI",
    "BONUS4.MNI",
    "B5.MNI",
    "B6.MNI",
    "BONUS3.MNI",
    "BONUS4.MNI",
    "B7.MNI",
    "B8.MNI",
    "BONUS3.MNI",
    "BONUS4.MNI",
    "B9.MNI",
    "B10.MNI",
    "BONUS3.MNI",
    "BONUS4.MNI",
    "B11.MNI",
    "B12.MNI",
    "BONUS3.MNI",
    "BONUS4.MNI",
    "B13.MNI",
    "B14.MNI",
    "BONUS3.MNI",
    "BONUS4.MNI",
    "B15.MNI",
    "B16.MNI"
};

U8 level_filename_ep3_tbl[30][13] = {
    "C1.MNI",
    "C2.MNI",
    "BONUS5.MNI",
    "BONUS6.MNI",
    "C3.MNI",
    "C4.MNI",
    "BONUS5.MNI",
    "BONUS6.MNI",
    "C5.MNI",
    "C6.MNI",
    "BONUS5.MNI",
    "BONUS6.MNI",
    "C7.MNI",
    "C8.MNI",
    "BONUS5.MNI",
    "BONUS6.MNI",
    "C9.MNI",
    "C10.MNI",
    "BONUS5.MNI",
    "BONUS6.MNI",
    "C11.MNI",
    "C12.MNI",
    "BONUS5.MNI",
    "BONUS6.MNI",
    "C13.MNI",
    "C14.MNI",
    "BONUS5.MNI",
    "BONUS6.MNI",
    "C15.MNI",
    "C16.MNI"
};

U8 *get_level_filename(I64 level_number)
{
    switch(get_episode_number)
    {
        case 1 : return level_filename_ep1_tbl[level_number];
        case 2 : return level_filename_ep2_tbl[level_number];
        case 3 : return level_filename_ep3_tbl[level_number];
        default : break;
    }
    return NULL;
}

U0 map_load_tiles()
{
    U16 num_tiles;
    map_bg_tiles = load_tiles("TILES.MNI", SOLID, &num_tiles);
    "Loading %d map bg tiles.\n", num_tiles;
    map_fg_tiles = load_tiles("MASKTILE.MNI", TRANSPARENT, &num_tiles);
    "Loading %d map fg tiles.\n", num_tiles;
}

U0 map_write_tile_cell(U16 map_tile_cell, I64 x, I64 y)
{
    map_data[x + y * map_width_in_tiles] = map_tile_cell;
}

U0 map_write_row_of_tiles(U16 map_tile_cell, U16 length_in_tiles, I64 x, I64 y) {
    //assert(x + length_in_tiles < map_width_in_tiles);
    I64 i;
    for(i = 0; i < length_in_tiles; i++)
    {
        map_write_tile_cell(map_tile_cell, x + i, y);
    }
}

U0 write_tile_row_to_tilemap(U16 map_tile_cell,
                               U16 map_tile_cell2,
                               U16 map_tile_cell3,
                               U16 map_tile_cell4,
                               I64 x,
                               I64 y)
{
    map_write_tile_cell(map_tile_cell, x, y);
    map_write_tile_cell(map_tile_cell2, x + 1, y);
    map_write_tile_cell(map_tile_cell3, x + 2, y);
    map_write_tile_cell(map_tile_cell4, x + 3, y);
}

Tile *map_get_bg_tile(U16 tile_num) {
    return &map_bg_tiles[tile_num];
}

U0 map_display() {
    if(mapwindow_y_offset > map_max_y_offset)
        mapwindow_y_offset = map_max_y_offset;

    I64 x, y;
    U16 tile;

    backdrop_display();
    for(y=0; y < MAP_WINDOW_HEIGHT; y++)
    {
        for(x=0; x < MAP_WINDOW_WIDTH; x++)
        {
            U16 map_cell = map_data[(x+mapwindow_x_offset) + (y+mapwindow_y_offset) * map_width_in_tiles];
            if(map_cell < 16000)
            {
                tile = map_cell/8;
                if(tile > 9) // The first 10 tiles aren't shown. They are arrows for moving platform debug.
                {
                    video_draw_tile(&map_bg_tiles[tile], (x+1)*8, (y+1)*8);
                }
            }
            else
            {
                tile =  ((map_cell/8) - 2000) / 5;
                video_draw_tile(&map_fg_tiles[tile], (x+1)*8, (y+1)*8);
            }
        }
    }
}

U0 load_level_data(I64 level_number)
{
    byte_28BE3 = 0;
    File map_file;
    I64 i, j;
    if(!open_file(get_level_filename(level_number), &map_file))
    {
        "Error: loading level data. %s\n", get_level_filename(level_number);
        return;
    }

    file_seek(&map_file, 2);
    map_width_in_tiles = file_read2(&map_file);

    "map width (in tiles): %d\n", map_width_in_tiles;

    switch(map_width_in_tiles)
    {
        case 32: map_stride_bit_shift_amt = 5; break;
        case 64: map_stride_bit_shift_amt = 6; break;
        case 128: map_stride_bit_shift_amt = 7; break;
        case 256: map_stride_bit_shift_amt = 8; break;
        case 512: map_stride_bit_shift_amt = 9; break;
        case 1024: map_stride_bit_shift_amt = 10; break;
        case 2048: map_stride_bit_shift_amt = 11; break;
        default: break;
    }


    U16 actor_data_size_in_words = file_read2(&map_file);

    total_num_actors = 0;
    num_moving_platforms = 0;
    num_mud_fountains = 0;
    clear_brightness_objs();
    brightness_effect_enabled_flag = 1;
    obj_switch_151_flag = 0;

    for(i=0;i< actor_data_size_in_words/3;i++)
    {
        U16 actor_type = file_read2(&map_file);
        U16 x = file_read2(&map_file);
        U16 y = file_read2(&map_file);
        if(total_num_actors < MAX_ACTORS)
        {
            load_actor(total_num_actors, actor_type, x, y);
        }
    }

    for(i=0;i < MAX_MAP_TILES - 4; i++)
    {
        map_data[i] = file_read2(&map_file);
    }

    for(i=0;i<num_moving_platforms;i++)
    {
        for(j = 2;j < 7;j++)
        {
            moving_platform_tbl[i].map_tiles[j-2] = map_data[moving_platform_tbl[i].x + moving_platform_tbl[i].y * map_width_in_tiles + j - 4];
        }

    }

    current_level = level_number;
    map_max_y_offset = 0x10000 / (map_width_in_tiles * 2) - 19;
}

U0 load_level(I64 level_number)
{
    if (level_number != 0 || show_one_moment_screen_flag == 0) {
        fade_to_black_speed_3();
    } else {
        display_fullscreen_image(5);
        wait_for_time_or_key(0x12c);
    }


    File map_file;
    if(!open_file(get_level_filename(level_number), &map_file))
    {
        "Error: loading level data. %s\n", get_level_filename(level_number);
        return;
    }

    U16 level_flags = file_read2(&map_file);
    file_close(&map_file);


    stop_music();
    rain_flag = (level_flags & 0x20);
    U16 backdrop_index = (level_flags & 0x1f);
    background_x_scroll_flag = (level_flags & 0x40);
    background_y_scroll_flag = (level_flags & 0x80);

    palette_anim_type = (level_flags >> 8 & 7);
    U16 music_index = ((level_flags >> 11) & 0x1f);

    "Level %d: rain=%d, backdrop_index=%d, bg_x_scroll=%d, bg_y_scroll=%d, pal_anim_type=%d, music_index=%d\n", current_level, rain_flag, backdrop_index, background_x_scroll_flag, background_y_scroll_flag, palette_anim_type, music_index;
    reset_game_state();

    set_backdrop(backdrop_index);

    load_level_data(level_number);

    if (level_number == 0 && show_one_moment_screen_flag != 0) {
        fade_to_black_speed_3();
        show_one_moment_screen_flag = 0;
    }
    if (game_play_mode == 0) {
        switch (level_number) {
            case 0:
            case 1:
            case 4:
            case 5:
            case 8:
            case 9:
            case 12:
            case 13:
            case 16:
            case 17:
                video_fill_screen_with_black();
                fade_in_from_black_with_delay_3();
                now_entering_level_n_dialog(level_number);
                wait_for_time_or_key(0x96);
                fade_to_black_speed_3();
                break;
            default:
                break;
        }
    }
    explode_effect_clear_sprites();
    struct6_clear_sprites();
    effect_clear_sprites();
    player_reset_push_variables();
    actor_toss_clear_all();
    status_panel_init();

    //write_savegame_file('T');
    load_music(music_index);

    //I Don't think this will be needed.

//    if (byte_32FEA == 0) {
//        gvar_32D12 = REGISTER_29;
//        tileattr_mni_data = &ptr + 0x1388;
//        word_28BE4 = 0x1111;
//        load_tileattr_mni("TILEATTR.MNI", REGISTER_32);
//    }

    fade_in_from_black_with_delay_3();
}
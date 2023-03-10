extern I64 palette_index;
extern I64 palette_2E1EE;
extern U0 update_palette_anim();
extern U0 fade_to_black(U16 wait_time);

I64 last_wait = cnts.jiffies;

#define COSMO_INTERVAL 100

//Data
I64 game_play_mode = PLAY_GAME;
U32 score;
U32 num_stars_collected;
I64 cheats_used_flag = 0;
I64 knows_about_powerups_flag;
I64 finished_game_flag_maybe = 0;
I64 finished_level_flag_maybe;
I64 cheat_mode_flag = 0;

U8 episode_number = 1;
Bool quick_start_mode = FALSE;

U8 get_episode_number()
{
    return episode_number;
}

Bool is_quick_start()
{
    return quick_start_mode;
}

U0 set_initial_game_state()
{
    score = 0;
    health = 4;
    num_health_bars = 3;
    current_level = 0;
    num_bombs = 0;
    num_stars_collected = 0;
    cheats_used_flag = 0;
    has_had_bomb_flag = 0;
    knows_about_powerups_flag = 0;
    return;
}

U0 reset_game_state()
{
    finished_game_flag_maybe = 0;
    player_hanging_on_wall_direction = 0;
    byte_2E2E4 = 1;
    player_input_jump_related_flag = 1;
    byte_2E182 = 0;
    word_2E180 = 1;
    player_bounce_flag_maybe = 0;
    player_bounce_height_counter = 0;
    player_direction_related_32E98 = 3;
    player_sprite_dir_frame_offset = 0;
    player_direction = 0x17;
    player_death_counter = 0;
    finished_level_flag_maybe = 0;
    player_invincibility_counter = 0x28;
    teleporter_counter = 0;
    teleporter_state_maybe = 0;
    player_in_pneumatic_tube_flag = 0;
    player_hoverboard_counter = 0;
    player_is_teleporting_flag = 0;
    word_32EAC = 0;
    energy_beam_enabled_flag = 1;
    byte_2E17C = 0;
    health = num_health_bars + 1;

    sub_11062();

    hide_player_sprite = 0;
    move_platform_flag = 1;
    byte_32EB8 = 0;
    palette_2E1EE = 0;
    palette_index = 0;
    word_32EC2 = 0;
    player_fall_off_map_bottom_counter = 0;
    word_28BEA = 0;
    byte_2E21C = 0;
    word_2E1E4 = 0;
    word_2E1E2 = 0;
    num_hits_since_touching_ground = 0;

    //Actor values
    word_2E22A = 0;
    word_2E236 = 0;
    word_2E228 = 0;
    word_2E220 = 0;
    word_2E238 = 0;
    word_2E21E = 0;
    word_2E24C = 0;
    word_2E23C = 0;
    word_2E232 = 0;
    word_2E234 = 0;
    word_2E246 = 0;
    return;
}

U0 game_init()
{
    if(!is_quick_start())
    {
        display_fullscreen_image(0);
        wait_for_time_or_key(0xc8);
    }

    //load_config_file();

    status_load_tiles();
    tile_attr_load();
    player_load_tiles();
    actor_load_tiles();
    map_load_tiles();
    load_cartoon_images();
    font_load_tiles();
    //load_sfx();
}

U8 *get_game_vol_filename()
{
    switch(get_episode_number())
    {
        case 1 : return "COSMO1.VOL";
        case 2 : return "COSMO2.VOL";
        case 3 : return "COSMO3.VOL";
        default : break;
    }

    return NULL;
}

U8 *get_game_stn_filename()
{
    switch(get_episode_number())
    {
        case 1 : return "COSMO1.STN";
        case 2 : return "COSMO2.STN";
        case 3 : return "COSMO3.STN";
        default : break;
    }

    return NULL;
}

Bool open_file(U8 *filename, File *file)
{
    if(vol_file_open(get_game_vol_filename(), filename, file))
    {
        return TRUE;
    }

    return vol_file_open(get_game_stn_filename(), filename, file);
}

U8 *load_file(U8 *filename, U8 *buf, U32 buf_size)
{
    U32 bytes_read;
    if(vol_file_load(get_game_vol_filename(), filename, buf, buf_size, &bytes_read))
    {
        return buf;
    }

    return vol_file_load(get_game_stn_filename(), filename, buf, buf_size, &bytes_read);
}

U0 select_next_level()
{
    U32 tmp_num_stars_collected = num_stars_collected;
    if (game_play_mode == PLAY_GAME)
    {
        switch (current_level)
        {
            case 2:
            case 6:
            case 10:
            case 14:
            case 18:
            case 22:
            case 26:
                display_end_of_level_score_dialog("Bonus Level Completed!!", "Press ANY key.");
                current_level += 2;
                break;

            case 3:
            case 7:
            case 11:
            case 15:
            case 19:
            case 23:
            case 27:
                display_end_of_level_score_dialog("Bonus Level Completed!!", "Press ANY key.");
                current_level++;
                break;

            case 0:
            case 4:
            case 8:
            case 12:
            case 16:
            case 20:
            case 24:
                current_level++;
                break;

            case 1:
            case 5:
            case 9:
            case 13:
            case 17:
            case 21:
            case 25:
                display_end_of_level_score_dialog("Section Completed!", "Press ANY key.");
                if(tmp_num_stars_collected <= 24)
                {
                    current_level += 3;
                }
                else
                {
                    fade_to_black(0);
                    display_fullscreen_image(3);
                    play_sfx(0x2d);
                    if(tmp_num_stars_collected > 49)
                    {
                        current_level++;
                    }
                    current_level++;
                    cosmo_wait(0x96);
                }
                break;

            default: break;
        }
    }
    else //DEMO Mode
    {
        switch (current_level)
        {
            case 0:
                current_level = 13;
                break;

            case 13:
                current_level = 5;
                break;

            case 5:
                current_level = 9;
                break;

            case 9:
                current_level = 0x10;
                break;
        }
    }
}


Bool executeTick() {
    I64 input_state = 0;

    update_palette_anim();

    input_state = read_input();
    if (input_state == QUIT) {
        return FALSE;
    }

    if (input_state == PAUSED) {
        return TRUE;
    }

    handle_player_input_maybe();
    if (player_hoverboard_counter != 0)
    {
        player_hoverboard_update();
    }

    if (word_32EB2 != 0 || player_walk_anim_index != 0)
    {
        player_update_walk_anim(); //TODO check name I think this might be fall anim
    }

    update_moving_platforms();

    update_mud_fountains();

    map_display();

    if (player_update_sprite() != 0) {
        return TRUE;
    }

    display_mud_fountains();

    actor_update_all();

    explode_effect_update_sprites();

    actor_toss_update();

    update_rain_effect();

    struct6_update_sprites();

    effect_update_sprites();

    update_brightness_objs();

    if (game_play_mode != PLAY_GAME)
    {
        display_actor_sprite_maybe(0x10a, 0, 17, 4, 6); //DEMO sign.
    }

    if (show_monster_attack_hint == 1)
    {
        show_monster_attack_hint = 2;
        monster_attack_hint_dialog();
    }

    video_update();

    if (finished_level_flag_maybe)
    {
        finished_level_flag_maybe = 0;
        play_sfx(11);
        select_next_level();
        load_level(current_level);
    }

    if (finished_game_flag_maybe)
    {
        //end_sequence();
        return FALSE;
    }

    return TRUE;
}

U0 game_wait()
{
    while (last_wait + 100 > cnts.jiffies)
    {
        Sleep(1);
    }
    last_wait = cnts.jiffies;
}

U0 game_loop()
{
    while (executeTick())
    {
        game_wait();
    }
}

U8 *load_file_in_new_buf(U8 *filename, U32 *file_size)
{
    U8 *buf;
    buf = vol_file_load(get_game_vol_filename(), filename, NULL, 0, file_size);
    if(buf)
    {
        return buf;
    }

    return vol_file_load(get_game_stn_filename(), filename, NULL, 0, file_size);
}


U0 set_episode_number(U8 episode)
{
    episode_number = episode;
}

U0 enable_quick_start_mode()
{
    quick_start_mode = TRUE;
}

extern U0 video_update();
extern Tile *map_get_bg_tile(U16 tile_num);
extern U8 get_episode_number();
extern U0 set_initial_game_state();
extern U0 display_fullscreen_image(U8 image_number);
extern U0 fade_to_black_speed_3();
extern U0 video_fill_screen_with_black();
extern U0 fade_in_from_black_with_delay_3();
extern U0 fade_to_white(U16 wait_time);
extern U0 fade_in_from_black(U16 wait_time);

#define SDLK_UP      1
#define SDLK_DOWN    2
#define SDLK_LEFT    3
#define SDLK_RIGHT   4

class MenuItem {
    U16 x_pos;
    U16 y_pos;
    U8 *text;
    I64 action_key;
};


//Data
U8 show_one_moment_screen_flag = 0;
U8 byte_28BE3 = 0;
U8 byte_2E21C = 0;
I64 cur_selected_item = 0;

//HintDialogInput
#define FAST_FORWARD    0
#define EXIT            1
#define NO_INPUT        2

I64 hint_dialog_get_input(I64 input)
{
    if (Bt(kbd.down_bitmap, Char2ScanCode(' ')))
    {
        return FAST_FORWARD;
    }
    if (Bt(kbd.down_bitmap, SC_ESC))
    {
        return EXIT;
    }
    return NO_INPUT;
    //return input;
}

U8 score_text_tbl[13][17] = {
        "    Not Bad!    ",
        "    Way Cool    ",
        "     Groovy     ",
        "    Radical!    ",
        "     Insane     ",
        "     Gnarly     ",
        "   Outrageous   ",
        "   Incredible   ",
        "    Awesome!    ",
        "   Brilliant!   ",
        "    Profound    ",
        "    Towering    ",
        "Rocket Scientist"
};


U16 dialog_text_extract_num(U8 *text)
{
    U8 buf[4];

    buf[0] = text[0];
    buf[1] = text[1];
    buf[2] = text[2];
    buf[3] = 0;

    return Str2I64(&buf) & 0xFFFF;
}

U0 display_dialog_text_with_color(U16 x_pos, U16 y_pos, U8 *text, U8 text_color)
{
    I64 input = NO_INPUT;
    U16 typewriter_keys_count = 0;
    U16 typewriter_delay_counter = 0;
    I64 len = StrLen(text);
    I64 x=0;
    I64 i;
    for(i=0; i < len; i++)
    {
        U8 c = text[i];
        if(c == '\n')
        {
            x = 0;
            y_pos++;
            goto display_dialog_text_with_color_cont;
        }

        if(c < 123)
        {
            if (typewriter_delay_counter > 0)
            {
                input = hint_dialog_get_input(input);

                if(input == FAST_FORWARD)
                {
                    cosmo_wait(1);
                }
                else
                {
                    if(input == NO_INPUT)
                    {
                        for(; typewriter_keys_count > 0; typewriter_keys_count--)
                        {
                            cosmo_wait(3);
                        }
                    }
                }

                typewriter_keys_count = typewriter_delay_counter;
                if (c != 0x20)
                {
                    play_sfx(0x2c);
                }
                video_update();
                display_char(x_pos + x, y_pos, c, text_color);
            }
            else
            {
                display_char(x_pos + x, y_pos, c, text_color);
            }
            x++;
        }
        if(c >= 0xfb && c < 0xff)
        {
            U16 frame_num = dialog_text_extract_num(&text[i+1]);
            switch(c)
            {
                case 0xfb : display_cartoon_sequence(frame_num, x_pos + x, y_pos); break;
                case 0xfc :
                    typewriter_keys_count = frame_num;
                    typewriter_delay_counter = frame_num;
                    break;
                case 0xfd : display_player_sprite(frame_num, x_pos + x, y_pos, 6); break;
                case 0xfe :
                    display_actor_sprite_maybe(frame_num, dialog_text_extract_num(&text[i+4]), x_pos + x - 1, y_pos, 6);
                    i += 3;
                    break;
            }
            i += 3;
        }
display_dialog_text_with_color_cont:        
    }
    video_update();
}

U0 display_dialog_text(U16 x_pos, U16 y_pos, U8 *text)
{
    display_dialog_text_with_color(x_pos, y_pos, text, FONT_WHITE);
}

U16 draw_dialog_frame(U16 x_pos, U16 y_pos, U16 height, U16 width, U8 *top_text, U8 *bottom_text, U8 display_text)
{
    video_draw_tile(map_get_bg_tile(1991), x_pos * TILE_WIDTH, y_pos * TILE_HEIGHT);
    video_draw_tile(map_get_bg_tile(1992), (x_pos + width-1) * TILE_WIDTH, y_pos * TILE_HEIGHT);
    I64 x, y, x1;

    for(x=1;x < width-1;x++)
    {
        video_draw_tile(map_get_bg_tile(1995), (x_pos + x) * TILE_WIDTH, y_pos * TILE_HEIGHT);
        video_draw_tile(map_get_bg_tile(1996), (x_pos + x) * TILE_WIDTH, (y_pos + height-1) * TILE_HEIGHT);

        for(y=1;y < height-1;y++)
        {
            video_draw_tile(map_get_bg_tile(1997), x_pos * TILE_WIDTH, (y_pos + y) * TILE_HEIGHT);
            video_draw_tile(map_get_bg_tile(1998), (x_pos + width-1) * TILE_WIDTH, (y_pos + y) * TILE_HEIGHT);

            for(x1=1;x1 < width-1;x1++)
            {
                video_draw_tile(map_get_bg_tile(1999), (x_pos + x1) * TILE_WIDTH, (y_pos + y) * TILE_HEIGHT);
            }
        }
    }

    video_draw_tile(map_get_bg_tile(1993), x_pos * TILE_WIDTH, (y_pos + height-1) * TILE_HEIGHT);
    video_draw_tile(map_get_bg_tile(1994), (x_pos + width-1) * TILE_WIDTH, (y_pos + height-1) * TILE_HEIGHT);

    if(display_text)
    {
        display_dialog_text(0x14 - (StrLen(top_text)/2), y_pos + 1, top_text);
        display_dialog_text(0x14 - (StrLen(bottom_text)/2), y_pos + height - 2, bottom_text);
    }

    video_update();
    return x_pos + 1;
}

U16 create_text_dialog_box(U16 y_offset, U16 height, U16 width, U8 *top_message, U8 *bottom_message)
{
    I64 dialog_x = 0x14 - (width / 2);
    I64 var_4 = (height / 2) + y_offset;
    I64 cur_width = 1;
    I64 cur_x, cur_y;
    for(cur_x = 0x13; cur_x > dialog_x; cur_x--)
    {
        cur_width = cur_width + 2;
        draw_dialog_frame(cur_x, var_4, 2, cur_width, "", "", 0);
        cosmo_wait(1);
    }

    I64 cur_height = 0;
    for(cur_y = var_4;cur_y >= Cond((height & 1), 1, 2) + y_offset; cur_y--)
    {
        cur_height += 2;
        draw_dialog_frame(dialog_x, cur_y, cur_height, width, "", "", 0);
        cosmo_wait(1);
    }

    return draw_dialog_frame(dialog_x, y_offset, height, width, top_message, bottom_message, 1);
}

U0 display_clear_tile_to_gray(U16 x, U16 y)
{
    video_draw_tile(map_get_bg_tile(1999), x * TILE_WIDTH, y * TILE_HEIGHT);
}

I64 wait_for_input_with_repeat(I64 spinner_x, I64 spinner_y, Bool allow_key_repeat)
{
    video_update();
    reset_player_control_inputs();
    flush_input();

    U16 spinner_idx = 0;
    I64 keycode = poll_for_key_press(allow_key_repeat);
    while(keycode == SDLK_UNKNOWN && !keys_down())
    {
        //Draw spinning cursor
        video_draw_tile(map_get_bg_tile(1987+spinner_idx), spinner_x * TILE_WIDTH, spinner_y * TILE_HEIGHT);
        video_update();
        if(spinner_idx == 3)
            spinner_idx = 0;
        else
            spinner_idx++;
        cosmo_wait(5);
        keycode = poll_for_key_press(allow_key_repeat);
    }
    display_clear_tile_to_gray(spinner_x, spinner_y);
    return keycode;
}

I64 wait_for_input(I64 spinner_x, I64 spinner_y)
{
    return wait_for_input_with_repeat(spinner_x, spinner_y, FALSE);
}


MenuItem main_menu_items[14] = {
        {0, 5, " B)egin New Game", Char2ScanCode('b')},
        {0, 6, " R)estore A Game", Char2ScanCode('r')},
        {0, 7, " S)tory", Char2ScanCode('s')},
        {0, 8, " I)nstructions", Char2ScanCode('i')},
        {0, 9, " H)igh Scores", Char2ScanCode('h')},
        {0, 10, " G)ame Redefine", Char2ScanCode('g')},
        {0, 12, " O)rdering Info.", Char2ScanCode('o')},
        {0, 14, " F)oreign Orders", Char2ScanCode('f')},
        {0, 15, " A)pogee's BBS", Char2ScanCode('a')},
        {0, 0x10, " D)emo", Char2ScanCode('d')},
        {0, 0x11, " C)redits", Char2ScanCode('c')},
        {0, 0x12, " T)itle Screen", Char2ScanCode('t')},
        {0, 0x14, " Q)uit Game", Char2ScanCode('q')},
        {0, 0, NULL, 0}
};


U0 ingame_hint_dialogs(U16 hint_number) {
    cosmo_wait(0x1e);
    flush_input();
    U16 x;
    if(hint_number != 0 && hint_number < 15)
    {
        x = create_text_dialog_box(2, 9, 0x1c, "COSMIC HINT!", "Press any key to exit.");
        display_dialog_text(x, 8, " Press SPACE to hurry or");
    }

    switch (hint_number)
    {
        case 0:
            x = create_text_dialog_box(2, 11, 0x1c, "COSMIC HINT!", "Press any key to exit.");
            display_dialog_text(x, 10, " Press SPACE to hurry or");
            display_dialog_text(x, 5, " These hint globes will\n"
                                               " help you along your\n"
                                               " journey.  Press the up\n"
                                               " key to reread them");

            wait_for_input(x + 0x19, 11);
            break;

        case 1:
            display_dialog_text(x, 5, " Bump head into switch\n above!");
            break;

        case 2:
            display_dialog_text(x, 5, " The ice in this cave is\n very, very slippery.");
            break;

        case 3:
            display_dialog_text(x, 5, " Use this shield for\n temporary invincibility.");
            break;

        case 4:
            display_dialog_text(x, 5, " You found a secret\n area!!!  Good job!");
            break;

        case 5:
            display_dialog_text(x, 5, " In high places look up\n to find bonus objects.");
            break;

        case 6:
            display_dialog_text(x, 5, "      Out of Order...");
            break;

        case 7:
            display_dialog_text(x, 5, " This might be a good\n time to save your game!");
            break;

        case 8:
            display_dialog_text(x, 5, " Press your up key to\n use the transporter.");
            break;

        case 9:
            display_dialog_text(x, 5, "  (1) FOR...");
            break;

        case 10:
            display_dialog_text(x, 5, "  (2) EXTRA...");
            break;

        case 11:
            display_dialog_text(x, 5, "  (3) POINTS,...");
            break;

        case 12:
            display_dialog_text(x, 5, "  (4) DESTROY...");
            break;

        case 13:
            display_dialog_text(x, 5, "  (5) HINT...");
            break;

        case 14:
            display_dialog_text(x, 5, "  (6) GLOBES!!!");
            break;

        case 15:
            x = create_text_dialog_box(2, 11, 0x1c, "COSMIC HINT!", "Press any key to exit.");
            display_dialog_text(x + 0x16, 8, "");
            display_dialog_text(x, 10, " Press SPACE to hurry or");
            display_dialog_text(x, 5, "  The Clam Plants won't\n  hurt you if their\n  mouths are closed.");
            wait_for_input(x + 0x19, 11);
            break;

        case 16:
            x = create_text_dialog_box(2, 10, 0x1c, "COSMIC HINT!", "Press any key to exit.");
            display_dialog_text(x, 9, " Press SPACE to hurry or");
            display_dialog_text(x + 0x17, 7, "\n  Collect the STARS to\n  advance to BONUS\n  STAGES.");
            wait_for_input(x + 0x19, 10);
            break;

        case 17:
            x = create_text_dialog_box(2, 10, 0x1c, "COSMIC HINT!", "Press any key to exit.");
            display_dialog_text(x, 9, " Press SPACE to hurry or");
            display_dialog_text(x, 5, "  Some creatures require\n  more than one pounce\n  to defeat!");
            wait_for_input(x + 0x19, 10);
            break;

        case 18:
            x = create_text_dialog_box(2, 9, 0x1e, "COSMIC HINT!", "Press any key to exit.");
            display_dialog_text(x + 0x19, 8, "\xfd""032");
            display_dialog_text(x, 8, "  Press SPACE to hurry or");
            display_dialog_text(x, 5, " Cosmo can climb wall's\n with his suction hands.");
            wait_for_input(x + 0x1b, 9);
            break;
    }

    if(hint_number != 0 && hint_number < 15)
    {
        wait_for_input(x + 0x19, 9);
    }
}

/*
    U16 x = create_text_dialog_box(4, 13, 0x1a, "A game by", "Copyright (c) 1992");
    display_dialog_text(x, 7, "     Todd J Replogle");
    display_dialog_text(x + 11, 9, "and");
    display_dialog_text(x, 11, "\xfd""027   Stephen A Hornback""\xfd""004");
    display_dialog_text(x, 13, "      Version 1.20");
    wait_for_time_or_key(0x2bc);
    fade_to_black_speed_3();
}
*/


U0 end_game_dialog(U16 dialog_number) {
    if(get_episode_number() != 1)
    {
        return;
    }

    flush_input();
    reset_player_control_inputs();
    if(dialog_number == 0xa6)
    {
        finished_game_flag_maybe = 1;
        return;
    }
    if(dialog_number == 0xa4 || dialog_number == 0xa5)
    {
        U16 x = create_text_dialog_box(2, 8, 0x1c, "", "Press any key to exit.");
        if(dialog_number == 0xa4)
        {
            display_dialog_text(x, 4, "\xfc003 What's happening?  Is\n Cosmo falling to his\n Doom?");
        }
        else
        {
            display_dialog_text(x, 4, "\xfc003 Is there no end to this\n pit?  And what danger\n awaits below?!");
        }
        wait_for_input(x + 0x19, 8);
    }
}

U0 display_menu_items(I64 x_offset, MenuItem *menu_items)
{
    MenuItem *item = menu_items;
    I64 i;
    for(i=0; item->text != NULL; item++, i++)
    {
        display_dialog_text_with_color(x_offset + item->x_pos, item->y_pos, item->text, Cond(i == cur_selected_item, 2, FONT_WHITE));
    }
}

U0 menu_handle_arrow_key(I64 key, MenuItem *items) {
    I64 num_items = 0;
    MenuItem *item;
    for(item = items; item->text != NULL; item++)
    {
        num_items++;
    }

    if(key == SDLK_DOWN)
    {
        cur_selected_item = (cur_selected_item + 1) % num_items;
    }
    if(key == SDLK_UP)
    {
        cur_selected_item = cur_selected_item - 1;
        if(cur_selected_item < 0)
            cur_selected_item = num_items - 1;
    }

}

I64 display_menu_items_in_dialog(I64 x_offset,
                         MenuItem *menu_items,
                         I64 spinner_x, I64 spinner_y)
{
    cur_selected_item = 0;
    I64 key = 0;
    do {
        display_menu_items(x_offset, menu_items);
        key = wait_for_input_with_repeat(spinner_x, spinner_y, TRUE);
        if (Bt(kbd.down_bitmap, SC_CURSOR_UP))
            key = SDLK_UP;
        if (Bt(kbd.down_bitmap, SC_CURSOR_DOWN))
            key = SDLK_DOWN;
        if(key == SDLK_UP || key == SDLK_DOWN)
        {
            menu_handle_arrow_key(key, menu_items);
        }
    } while(key == SDLK_UP || key == SDLK_DOWN);

    //if(is_return_key(key))
    if (Bt(kbd.down_bitmap, SC_ENTER))
    {
        key = menu_items[cur_selected_item].action_key;
    }

    return key;
}

I64 quit_game_dialog()
{
    U16 x = create_text_dialog_box(11, 4, 0x12, "Are you sure you", "want to quit? ");
    I64 key = wait_for_input(x + 14, 13);
    //if (key == SDLK_y || is_return_key(key))
    if (Bt(kbd.down_bitmap, Char2ScanCode('y')) || Bt(kbd.down_bitmap, SC_ENTER))
    {
        return 1;
    }

    return 0;
}

U0 main_menu_dialog()
{
    cur_selected_item = 0;
    I64 x = create_text_dialog_box(2, 0x15, 0x14, "MAIN MENU", "");
    display_menu_items(x, main_menu_items);
}

U8 level_numbers_tbl[18] ={ 1, 2, 0, 0, 3, 4, 0, 0, 5, 6, 0, 0, 7, 8, 0, 0, 9, 10 };
U0 now_entering_level_n_dialog(U16 level_number)
{
    if(game_play_mode == 0)
    {
        U16 x = create_text_dialog_box(7, 3, 0x18, "  Now entering level    ", "");
        cosmo_wait(0x14);
        play_sfx(0x40);
        if(level_numbers_tbl[level_number] != 10)
        {
            display_number(x + 0x14, 8, level_numbers_tbl[level_number]);
        }
        else
        {
            display_number(x + 0x15, 8, level_numbers_tbl[level_number]);
        }
        video_update();
    }
}

I64 main_menu() {
    set_initial_game_state();
    show_one_moment_screen_flag = 0;
    load_music(0x12);
    display_fullscreen_image(1);
    flush_input();
    I64 i, return_to_title;
    Bool key_handled = FALSE;
    I64 key;

    for(i=0;i==i;i+=3)
    {
            if (Bt(kbd.down_bitmap, Char2ScanCode('q')) || Bt(kbd.down_bitmap, SC_ESC))
            {
                if (quit_game_dialog())
                {
                    return QUIT_GAME;
                }
            }
            U16 restore_status = 0;
            if (keys_down)
            {
            for(return_to_title=0;!return_to_title;)
            {
                main_menu_dialog();
                //key_handled = TRUE;
                while(!key_handled && !return_to_title)
                {
                    key = display_menu_items_in_dialog(11, main_menu_items, 0x1c, 0x15);
                    //switch(key)
                    //{
                        //case SDLK_ESCAPE :
                        //case SDLK_q :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('q')) || 
                            Bt(kbd.down_bitmap, SC_ESC))
                        {
                            if(quit_game_dialog())
                            {
                                return QUIT_GAME;
                            }
                            return_to_title = 1;
                            i = 0;
                        }

                        //case SDLK_b :
                        //case SDLK_SPACE :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('b')) || 
                            Bt(kbd.down_bitmap, Char2ScanCode(' ')))
                        {

                            stop_music();
                            show_one_moment_screen_flag = 1;
                            show_monster_attack_hint = 0;
                            play_sfx(0x30);
                            return PLAY_GAME;
                        }

                        //case SDLK_r :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('r')))
                        {
                            //restore_status = restore_savegame_dialog();
                            if(restore_status == 1)
                            {
                                stop_music();
                                return PLAY_GAME;
                            }

                            if(restore_status == 0)
                            {
                                //missing_savegame_dialog();
                            }
                            //break;
                        }

                        //case SDLK_i :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('i')))
                        {
                            //instructions_dialog();
                        }                            
                            //break;

                        //case SDLK_s :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('s')))
                        {
                            //story_dialog();
                        }
                            //break;

                        //case SDLK_g :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('g')))
                        {
                            //game_redefine();
                        }                            
                            //break;

                        //case SDLK_F11 :
                        if (Bt(kbd.down_bitmap, SC_F11))
                        {
                            //if (cheat_mode_flag)
                            //{
                            //    return RECORD_DEMO;
                            //}
                        }
                            //break;

                        //case SDLK_o :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('o')))
                        {
                            //ordering_info_dialog();
                        }
                            //break;

                        //case SDLK_f :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('f')))
                        {
                            //foreign_orders_dialog();
                        }
                            //break;

                        //case SDLK_a :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('a')))
                        {
                            //apogee_bbs_dialog();
                        }
                            //break;

                        //case SDLK_d :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('d')))
                        {
                            return PLAY_DEMO;
                        }
                            
                        //case SDLK_h :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('h')))
                        {
                            fade_to_black_speed_3();
                            video_fill_screen_with_black();
                            //display_high_score_dialog(TRUE);
                        }
                            //break;

                        //case SDLK_c :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('c')))
                        {
                            display_fullscreen_image(2);
                            while (!keys_down()) Sleep(1);
                            return_to_title = 1;
                            i = 0;
                        }
                            //break;

                        //case SDLK_t :
                        if (Bt(kbd.down_bitmap, Char2ScanCode('t')))
                        {
                            return_to_title = 1;
                            i = 0;
                        }
                            //break;

                        //default :
                        //    key_handled = FALSE;
                        //    break;
                }

                if (i<600) display_fullscreen_image(1);
            
            }
            }
            if(i==600)
            {
                display_fullscreen_image(2);
            }
            if(i == 1200)
            {
                return PLAY_DEMO;
            }
        cosmo_wait(3);
    }
}

U0 no_bombs_dialog() {
    if(game_play_mode == PLAY_GAME)
    {
        play_sfx(0x1e);
        U16 x = create_text_dialog_box(2, 4, 0x1c, "", "");
        x++;
        display_dialog_text(x, 3, "You haven't found any");
        display_dialog_text(x, 4, "bombs to use yet!    ");
        cosmo_wait(0x3c);
        wait_for_input(x-1 + 0x19, 4);
    }
}

U0 power_up_module_dialog()
{
    if(game_play_mode == PLAY_GAME)
    {
        play_sfx(0x1e);
        I64 si = create_text_dialog_box(2, 5, 0x16, "", "");
        display_dialog_text(si, 3, " Power Up modules");
        display_dialog_text(si, 4, " increase Cosmo's");
        display_dialog_text(si, 5, " health.         ");
        cosmo_wait(0x3c);
        flush_input();
        wait_for_input(si + 8, 5);
    }
}

U0 monster_attack_hint_dialog()
{
    if(game_play_mode == PLAY_GAME)
    {
        play_sfx(0x1e);
        U16 si = create_text_dialog_box(2, 5, 0x16, "REMINDER:  Jump on", "defend yourself.  ");
        display_dialog_text(si, 4, " top of creatures to");
        cosmo_wait(0x3c);
        wait_for_input(si + 0x13, 5);
        si = create_text_dialog_box(2, 13, 0x14, "Like this...", "Press ANY key.");
        display_dialog_text(si + 5, 9, "   ");
        display_dialog_text(si + 5, 11, "   ");
        cosmo_wait(0x3c);
        wait_for_input(si + 0x11, 13);
    }
}

U0 display_score_from_level()
{
    stop_music();

    if(num_stars_collected == 0)
    {
        fade_in_from_black_with_delay_3();
        return;
    }

    fade_to_white(3);
    video_fill_screen_with_black();
    create_text_dialog_box(2, 0xe, 0x1e, "Super Star Bonus!!!!", "");

    display_actor_sprite_maybe(1, 2, 8, 8, 6);

    display_dialog_text(0xe, 7, "X 1000 =");

    display_number(0x1b, 7, num_stars_collected * 1000);

    cosmo_wait(0x32);
    display_dialog_text(0xa, 0xc, "YOUR SCORE =  ");
    display_number(0x1d, 0xc, score);

    fade_in_from_black_with_delay_3();

    cosmo_wait(0x64);

    I64 star_counter = 0;
    I64 i, j;
    for(i=num_stars_collected; i > 0; i--)
    {
        score += 1000;
        cosmo_wait(0xf);

        for(j=0; j < 7; j++)
        {
            display_clear_tile_to_gray(0x17 + j, 0xc);
        }
        play_sfx(1);
        display_number(0x1d, 0xc, score);

        if (star_counter / 6 < 13)
        {
            star_counter++;
        }

        for(j=0; j < 16; j++)
        {
            if(j < 7)
            {
                display_clear_tile_to_gray(0x16 + j, 7);
            }

            if((star_counter & 7) == 1)
            {
                display_clear_tile_to_gray(0xd + j, 0xe);

            }
        }

        display_number(0x1b, 7, i * 1000);

        video_update();

        if((star_counter & 7) == 1)
        {
            U8 score_text_idx = (star_counter/6);
            if(score_text_idx > 12)
            {
                score_text_idx = 12;
            }

            display_dialog_text(0xd, 0xe, score_text_tbl[score_text_idx]);
        }

        video_update();
    }

    cosmo_wait(0x190);
    num_stars_collected = 0;
}

U0 display_end_of_level_score_dialog(U8 *header_text, U8 *footer_text)
{
    fade_to_black_speed_3();
    video_fill_screen_with_black();
    U16 x = create_text_dialog_box(6, 4, 0x1e, header_text, footer_text);
    fade_in_from_black_with_delay_3();
    wait_for_input(x + 0x1b, 8);
    display_score_from_level();
    fade_to_black_speed_3();
    video_fill_screen_with_black();
}


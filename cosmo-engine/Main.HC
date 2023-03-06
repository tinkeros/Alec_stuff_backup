I64 cleanup_and_exit()
{
    //write_config_file();
    //video_shutdown();
    //audio_shutdown();
    //SDL_Quit();

    Fs->draw_it = NULL;
    DCFill(gr.dc, TRANSPARENT);
    return 0;
}

I64 main(...)
{
    //load_config_from_command_line(argc, argv);
    video_init();
    Fs->draw_it = &video_draw_it;
    game_init();
    //audio_init();
    music_init();
    load_sfx();

    video_fill_screen_with_black();

    //a_game_by_dialog();
    U16 x = create_text_dialog_box(4, 13, 0x1a, "A game by", "Copyright (c) 1992");
    display_dialog_text(x, 7, "     Todd J Replogle");
    display_dialog_text(x + 11, 9, "and");
    display_dialog_text(x, 11, "\xfd027   Stephen A Hornback\xfd004");
    display_dialog_text(x, 13, "      Version 1.20");
    wait_for_time_or_key(0x2bc);
      
    game_play_mode = main_menu();
    video_update;

    while(game_play_mode != QUIT_GAME)
    {
        load_level(current_level);
        if(game_play_mode == PLAY_DEMO)
        {
            load_demo();
        }

        game_loop();
        stop_music();
        /*
        if(game_play_mode == PLAY_GAME)
        {
            //show_high_scores();
        }
        */
        game_play_mode = main_menu();
    }

    stop_music();
    //display_exit_text();

    return cleanup_and_exit();

}

main;
extern U8 read_input_from_demo();
extern I64 game_play_mode;

#define PLAY_GAME   0
#define PLAY_DEMO   1
#define RECORD_DEMO 2
#define QUIT_GAME   3

//input_state_enum
#define QUIT        0
#define PAUSED      1
#define CONTINUE    2

//InputCommand
#define CMD_KEY_UP      0
#define CMD_KEY_DOWN    1
#define CMD_KEY_LEFT    2
#define CMD_KEY_RIGHT   3
#define CMD_KEY_JUMP    4
#define CMD_KEY_BOMB    5
#define CMD_KEY_OTHER   6

#define SDLK_UNKNOWN    0

U8 bomb_key_pressed = 0;
U8 jump_key_pressed = 0;
U8 up_key_pressed = 0;
U8 down_key_pressed = 0;
U8 left_key_pressed = 0;
U8 right_key_pressed = 0;

//This is needed because the game manipulates up_key_pressed as part of the hover board logic. This is the actual
//key pressed state.
U8 input_up_key_pressed = 0;

U8 byte_2E17C; //modifies the left, right and jump key presses

U0 cosmo_wait(I64 delay)
{
    Sleep(8 * delay);
}

U0 flush_input()
{
    FifoI64Flush(kbd.scan_code_fifo);
}

Bool keys_down()
{
    I64 i;
    for (i=0; i<8; i++)
    {
        if (kbd.down_bitmap[i]) return TRUE;
    }
    return FALSE;
}

I64 handle_demo_input()
{
    if (keys_down) return QUIT;
    if(read_input_from_demo())
    {
        return QUIT;
    }
    return CONTINUE;
}

U0 reset_player_control_inputs()
{
    up_key_pressed = 0;
    input_up_key_pressed = 0;
    down_key_pressed = 0;
    left_key_pressed = 0;
    right_key_pressed = 0;
    bomb_key_pressed = 0;
    jump_key_pressed = 0;
}

I64 poll_for_key_press(I64 keycode)
{
    //FIXME: implementation
    return SDLK_UNKNOWN;
}

U0 wait_for_time_or_key(I64 delay_in_game_cycles)
{
    //FIXME: implementation wait for key
    cosmo_wait(delay_in_game_cycles);
}

I64 read_input()
{
    if (game_play_mode == PLAY_DEMO)
    {
        return handle_demo_input();
    }
    if (Bt(kbd.down_bitmap, SC_CURSOR_UP))
    {
        up_key_pressed = 1;
    }
    else
    {
        up_key_pressed = 0;
    }
    if (Bt(kbd.down_bitmap, SC_CURSOR_DOWN))
    {
        down_key_pressed = 1;
    }
    else
    {
        down_key_pressed = 0;
    }
    if (Bt(kbd.down_bitmap, SC_CURSOR_LEFT))
    {
        left_key_pressed = 1;
    }
    else
    {
        left_key_pressed = 0;
    }
    if (Bt(kbd.down_bitmap, SC_CURSOR_RIGHT))
    {
        right_key_pressed = 1;
    }
    else
    {
        right_key_pressed = 0;
    }
    if (Bt(kbd.down_bitmap, SC_CTRL))
    {
        jump_key_pressed = 1;
    }
    else
    {
        jump_key_pressed = 0;
    }
    if (Bt(kbd.down_bitmap, SC_ALT))
    {
        bomb_key_pressed = 1;
    }
    else
    {
        bomb_key_pressed = 0;
    }

    return CONTINUE;
}
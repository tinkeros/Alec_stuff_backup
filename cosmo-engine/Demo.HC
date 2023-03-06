U16 demo_input_index = 0;
U16 demo_input_length = 0;

U8 *demo_data = NULL;

U0 load_demo()
{
    demo_input_index = 0;
    demo_input_length = 0;

    if(demo_data)
    {
        Free(demo_data);
    }

    U32 file_size;
    demo_data = load_file_in_new_buf("PREVDEMO.MNI", &file_size);
    if(!demo_data)
    {
        "Error: Loading demo data.\n";
        return;
    }

    demo_input_length = (file_size - 2);
}

U8 read_input_from_demo()
{
    if(demo_input_index >= demo_input_length)
    {
        return 1;
    }

    U8 input = demo_data[demo_input_index + 2];
    demo_input_index++;

    left_key_pressed = (input & 1);
    right_key_pressed = ((input >> 1) & 1);
    up_key_pressed = ((input >> 2) & 1);
    down_key_pressed = ((input >> 3) & 1);
    jump_key_pressed = ((input >> 4) & 1);
    bomb_key_pressed = ((input >> 5) & 1);
    finished_level_flag_maybe = ((input >> 6) & 1);

    return 0;
}

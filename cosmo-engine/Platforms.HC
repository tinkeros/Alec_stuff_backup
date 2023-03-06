extern U0 map_write_tile_cell(U16 map_tile_cell, I64 x, I64 y);
extern U0 display_actor_sprite_maybe(I64 actorInfoIndex, I64 frame_num, I64 x_pos, I64 y_pos, I64 tile_display_func_index);
extern U16 num_moving_platforms;
extern U8 move_platform_flag;

class MovingPlatform
{
    U16 x;
    U16 y;
    U16 map_tiles[5];
};

class MudFountain
{
    U16 x;
    U16 y;
    U16 direction;
    U16 length_counter;
    U16 current_height;
    U16 max_height;
    U16 pause_counter;
};

U16 num_mud_fountains = 0;
MovingPlatform moving_platform_tbl[10];
MudFountain mud_fountain_tbl[10];

U0 update_mud_fountains()
{
    I64 si;
    for(si=0;si < num_mud_fountains; si++)
    {
        MudFountain *mud_fountain = &mud_fountain_tbl[si];
        if(mud_fountain->pause_counter == 0)
        {
            mud_fountain->length_counter++;
            if(mud_fountain->length_counter != mud_fountain->max_height)
            {
                map_write_tile_cell(0, mud_fountain->x, mud_fountain->y);
                map_write_tile_cell(0, mud_fountain->x + 1 + 1, mud_fountain->y);
                if(player_death_counter == 0)
                {
                    if(mud_fountain->y - 1 == player_y_pos)
                    {
                        if(mud_fountain->direction == 0)
                        {
                            player_move_on_platform(mud_fountain->x, mud_fountain->x + 2, 0, 1);
                        }
                        else
                        {
                            player_move_on_platform(mud_fountain->x, mud_fountain->x + 2, 0, 5);
                        }
                    }
                }
                
                if(mud_fountain->direction == 0)
                {
                    mud_fountain->y--;
                    mud_fountain->current_height++;
                }
                else
                {
                    mud_fountain->y++;
                    mud_fountain->current_height--;
                }
                
                map_write_tile_cell(0x48, mud_fountain->x, mud_fountain->y);
                map_write_tile_cell(0x48, mud_fountain->x + 2, mud_fountain->y);
            }
            else
            {
                mud_fountain->length_counter = 0;
                mud_fountain->direction = (Cond(mud_fountain->direction, -1, 0) + 1);
                mud_fountain->pause_counter = 10;
            }
        }
        else
        {
            mud_fountain->pause_counter--;
        }
    }


    return;
}

U0 display_mud_fountains()
{
    U16 frame_counter = 0;
    U16 frame_num = 0;
    I64 i, j;
    frame_counter++;
    if ((frame_counter & 1) != 0)
    {
        frame_num++;
    }
    for (i = 0; i < num_mud_fountains; i++)
    {
        MudFountain *mud_fountain = &mud_fountain_tbl[i];
        display_actor_sprite_maybe(0x4f, frame_num & 1, mud_fountain->x, mud_fountain->y + 1, 0);

        for (j = 0; j < mud_fountain->current_height + 1; j++)
        {
            display_actor_sprite_maybe(0x4f, (frame_num & 1) + 1 + 1, mud_fountain->x + 1, mud_fountain->y + j + 1, 0);

            if (player_check_collision_with_actor(0x4f, 2, mud_fountain->x + 1, mud_fountain->y + j + 1) != 0)
            {
                player_decrease_health();
            }
        }
    }

    return;
}

U0 update_moving_platforms() {
    I64 i, si;
    for(i =0;i < num_moving_platforms; i++) {
        MovingPlatform *platform = &moving_platform_tbl[i];
        for (si = 2; si < 7; si++) {
            map_write_tile_cell(platform->map_tiles[si - 2], platform->x + si - 4, platform->y);
        }

        U16 map_tile_num = (map_get_tile_cell(platform->x, platform->y) / 8);
        if (player_death_counter == 0) {
            if (platform->y - 1 == player_y_pos && move_platform_flag != 0) {
                player_move_on_platform(platform->x - 2, platform->x + 2, map_tile_num, map_tile_num);
            }
        }
        if (move_platform_flag != 0) {
            platform->x += player_x_offset_tbl[map_tile_num];
            platform->y += player_y_offset_tbl[map_tile_num];
        }

        for (si = 2; si < 7; si++) {
            platform->map_tiles[si - 2] = map_get_tile_cell(platform->x + si - 4, platform->y);
        }

        for (si = 2; si < 7; si++) {
            map_write_tile_cell(((si - 2) / 8) + 0x3dd0, platform->x + si - 4, platform->y);
        }
    }
    return;
}

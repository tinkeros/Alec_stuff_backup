extern U8 rain_flag;
extern U0 actor_add_new(I64 image_index, I64 x_pos, I64 y_pos);
extern U0 actor_toss_add_new(I64 actorInfoIndex, I64 x_pos, I64 y_pos);
extern U16 word_2E1E2;
extern TileInfo *actor_get_tile_info(I64 actorInfoIndex, I64 frame_num);
extern I64 sprite_blocking_check(I64 blocking_dir, I64 actorInfoIndex, I64 frame_num, I64 x_pos, I64 y_pos);
extern I64 is_sprite_on_screen(I64 actorInfoIndex, I64 frame_num, I64 x_pos, I64 y_pos);
extern U16 brightness_effect_enabled_flag;
extern U0 video_draw_highlight_effect(U16 x, U16 y, U8 type);

#define MAX_EFFECT_SPRITES 10
#define MAX_EXPLODE_EFFECT_SPRITES 16
#define MAX_STRUCT6_SPRITES 7
#define MAX_BRIGHTNESS_OBJS 0xc7

class effect_sprite
{
    I64 is_active_flag;
    I64 actorInfoIndex;
    I64 frame_num;
    I64 x;
    I64 y;
    I64 field_A;
    I64 counter;
};

class explode_effect_sprite
{
    I64 actorInfoIndex;
    I64 x;
    I64 y;
    I64 frame_num;
    I64 counter;
    I64 direction;
    I64 fall_through_floor;
};

class struc_6
{
    I64 counter;
    I64 x;
    I64 y;
};

class Brightness
{
    I64 type;
    I64 x;
    I64 y;
};

U16 num_brightness_objs = 0;
Brightness brightness_tbl[MAX_BRIGHTNESS_OBJS + 1];

effect_sprite static_effect_sprites[MAX_EFFECT_SPRITES];
U16 effect_frame_num_tbl[MAX_EFFECT_SPRITES];

explode_effect_sprite explode_effect_sprites[MAX_EXPLODE_EFFECT_SPRITES];

struc_6 struc6_sprites[MAX_STRUCT6_SPRITES];

U0 effect_add_sprite(I64 actorInfoIndex, I64 frame_num, I64 x_pos, I64 y_pos, I64 arg_8, I64 counter)
{
    I64 i;
    for(i=0;i<MAX_EFFECT_SPRITES;i++)
    {
        effect_sprite *sprite = &static_effect_sprites[i];
        if(!sprite->is_active_flag)
        {
            sprite->is_active_flag = 1;
            sprite->actorInfoIndex = actorInfoIndex;
            sprite->frame_num = frame_num;
            sprite->x = x_pos;
            sprite->y = y_pos;
            sprite->field_A = arg_8;
            sprite->counter = counter;
            effect_frame_num_tbl[i] = 0;
            return;
        }
    }
}

U0 effect_clear_sprites()
{
    I64 i;
    for(i=0; i < MAX_EFFECT_SPRITES; i++)
    {
        static_effect_sprites[i].is_active_flag = 0;
    }
}

U0 explode_effect_add_sprite(I64 actorInfoIndex, I64 frame_num, I64 x_pos, I64 y_pos)
{
    U8 explode_direction = 0;
    I64 i;

    explode_direction++;
    if(explode_direction == 5)
    {
        explode_direction = 0;
    }

    for(i=0;i < MAX_EXPLODE_EFFECT_SPRITES; i++)
    {
        explode_effect_sprite *sprite = &explode_effect_sprites[i];
        
        if(sprite->counter == 0)
        {
            sprite->actorInfoIndex = actorInfoIndex;
            sprite->x = x_pos;
            sprite->y = y_pos;
            sprite->frame_num = frame_num;
            sprite->counter = 1;
            sprite->direction = explode_direction;
            sprite->fall_through_floor = 0;
            return;
        }
    }

    return ;
}

U0 explode_effect_clear_sprites()
{
    I64 i;
    for(i=0;i < MAX_EXPLODE_EFFECT_SPRITES; i++)
    {
        explode_effect_sprites[i].counter = 0;
    }
}

U0 update_rain_effect() //FIXME this rain doesn't look quite right. The lightning palette anim might need tweaking.
{

    I64 x = (cosmo_rand % 38) + mapwindow_x_offset;
    I64 y = (cosmo_rand % 18) + mapwindow_y_offset;
    I64 map_tile_cell = map_get_tile_cell(x, y);

    if((cosmo_rand & 1) != 0)
    {
        if((tileattr_mni_data[map_tile_cell / 8] & TILE_ATTR_SLIPPERY) != 0)
        {
            effect_add_sprite(0x63, 5, x, y, 0, 1);
        }
    }
    if(rain_flag != 0)
    {
        y = mapwindow_y_offset + 1;

        if(map_get_tile_cell(x, y) == 0)
        {
            effect_add_sprite(0x1b, 1, x, y, 6, 0x14);
        }
    }
    return;
}

U0 exploding_balls_effect(I64 x_pos, I64 y_pos)
{
    effect_add_sprite(0x15, 6, x_pos + 1, y_pos, 6, 2);
    effect_add_sprite(0x15, 6, x_pos + 3, y_pos, 4, 2);
    effect_add_sprite(0x15, 6, x_pos + 4, y_pos - 2, 3, 2);
    effect_add_sprite(0x15, 6, x_pos + 3, y_pos - 4, 2, 2);
    effect_add_sprite(0x15, 6, x_pos + 1, y_pos - 4, 8, 2);
    effect_add_sprite(0x15, 6, x_pos, y_pos - 2, 7, 2);
}



I64 blow_up_actor_with_bomb(I64 actorInfoIndex, I64 frame_num, I64 x_pos, I64 y_pos)
{
    switch (actorInfoIndex)
    {
        case 3:
        case 4:
        case 17:
        case 18:
        case 20:
        case 25:
        case 41:
        case 46:
        case 47:
        case 51:
        case 54:
        case 55:
        case 65:
        case 69:
        case 74:
        case 75:
        case 78:
        case 80:
        case 83:
        case 84:
        case 86:
        case 87:
        case 88:
        case 89:
        case 92:
        case 95:
        case 96:
        case 101:
        case 106:
        case 111:
        case 112:
        case 113:
        case 118:
        case 124:
        case 125:
        case 126:
        case 127:
        case 128:
        case 129:
        case 187:
        case 188:
            if(actorInfoIndex == 0x7d)
            {
                actor_add_new(0xb8, x_pos, y_pos);
            }
            if((actorInfoIndex == 0x12 || actorInfoIndex == 0x58) && frame_num == 2)
            {
                return 0;
            }
            else
            {
                explode_effect_add_sprite(actorInfoIndex, frame_num, x_pos, y_pos);
                player_add_score_for_actor(actorInfoIndex);
                if(actorInfoIndex == 0x5f)
                {
                    if(word_2E1E2 == 1)
                    {
                        actor_add_new(0xf6, player_x_pos - 1, player_y_pos - 5);
                    }
                    effect_add_sprite(0x17, 8, x_pos, y_pos, 0, 1);
                    actor_toss_add_new(0x39, x_pos, y_pos);
                    word_2E1E2--;
                }
            }
            return 1;

        default : break;
    }

    return 0;
}

Bool struct6_collision_check_maybe(I64 actorInfoIndex1, I64 actor_frame_num1, I64 actor1_x, I64 actor1_y, I64 actorInfoIndex2, I64 actor_frame_num2, I64 actor2_x, I64 actor2_y)
{
    TileInfo *actor1_info = actor_get_tile_info(actorInfoIndex1, actor_frame_num1);
    U16 sprite1_width = actor1_info->width;
    U16 si = actor1_info->height;

    TileInfo *actor2_info = actor_get_tile_info(actorInfoIndex2, actor_frame_num2);
    U16 sprite2_width = actor2_info->width;
    U16 di = actor2_info->height;

    if(actor1_x > map_width_in_tiles && actor1_x <= -1)
    {
        sprite1_width = actor1_x + sprite1_width;
        actor1_x = 0;
    }

    if(((actor2_x > actor1_x || actor2_x + sprite2_width <= actor1_x) && (actor2_x < actor1_x || actor1_x + sprite1_width <= actor2_x)) ||
            ((actor1_y - si >= actor2_y || actor2_y > actor1_y) && (actor2_y - di >= actor1_y || actor1_y > actor2_y)))
    {
        return 0;
    }

    return 1;
}

I64 struct6_1B4FC(I64 actorInfoIndex, I64 frame_num, I64 x_pos, I64 y_pos)
{
    I64 i;
    for(i=0; i < MAX_STRUCT6_SPRITES; i++)
    {
        struc_6 *sprite = &struc6_sprites[i];

        if(sprite->counter != 0)
        {
            if(struct6_collision_check_maybe(0x1a, 0, sprite->x, sprite->y, actorInfoIndex, frame_num, x_pos, y_pos) != 0)
            {
                return 1;
            }
        }
    }

    return 0;
}

U0 struct6_clear_sprites()
{
    I64 i;
    for(i=0; i < MAX_STRUCT6_SPRITES; i++)
    {
        struc6_sprites[i].counter = 0;
    }
}

U0 struct6_add_sprite(I64 x_pos, I64 y_pos)
{
    I64 i;
    for(i=0; i < MAX_STRUCT6_SPRITES; i++)
    {
        struc_6 *sprite = &struc6_sprites[i];
        if (sprite->counter == 0)
        {
            sprite->counter = 1;
            sprite->x = x_pos;
            sprite->y = y_pos + 2;
            play_sfx(0xa);
            return;
        }
    }
}

U0 add_brightness_obj(U8 type, I64 x_pos, I64 y_pos)
{
    if (num_brightness_objs != MAX_BRIGHTNESS_OBJS)
    {
        brightness_tbl[num_brightness_objs].type = type;
        brightness_tbl[num_brightness_objs].x = x_pos;
        brightness_tbl[num_brightness_objs].y = y_pos;
        num_brightness_objs++;
    }
}

U0 clear_brightness_objs()
{
    num_brightness_objs = 0;
}

U0 explode_effect_update_sprites()
{
    I64 i;
    for(i=0;i < MAX_EXPLODE_EFFECT_SPRITES; i++)
    {
        explode_effect_sprite *sprite = &explode_effect_sprites[i];
        if (sprite->counter == 0)
        {
            goto explode_while_cont2;
        }

        if(sprite->direction == 0 || sprite->direction == 3)
        {
            if(sprite_blocking_check(RIGHT, sprite->actorInfoIndex, sprite->frame_num, sprite->x + 1, sprite->y + 1) == NOT_BLOCKED)
            {
                sprite->x++;
                if(sprite->direction == 3)
                {
                    sprite->x++;
                }
            }
        }
        else
        {
            if(sprite->direction == 1 || sprite->direction == 4)
            {
                if(sprite_blocking_check(LEFT, sprite->actorInfoIndex, sprite->frame_num, sprite->x - 1, sprite->y + 1) == NOT_BLOCKED)
                {
                    sprite->x--;
                    if(sprite->direction == 4)
                    {
                        sprite->x--;
                    }
                }
            }
        }

        //for(;;)
        while(1)
        {
            if(sprite->counter < 5)
            {
                sprite->y -= 2;
            }

            if(sprite->counter == 5)
            {
                sprite->y--;
            }
            else if(sprite->counter == 8)
            {
                if (sprite_blocking_check(DOWN, sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y + 1) ==
                    NOT_BLOCKED)
                {
                    sprite->y++;
                }
                else
                {
                    sprite->counter = 3;
                    sprite->y += 2;
                    goto explode_while_cont1;
                }
            }

            if(sprite->counter < 9)
            {
                if(sprite->counter == 1)
                {
                    display_actor_sprite_maybe(sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y, 2);
                }
                else
                {
                    display_actor_sprite_maybe(sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y, 4);
                }
                sprite->counter++;
                if(sprite->counter > 40)
                {
                    sprite->counter = 0;
                }
                break;
            }

            if(sprite->counter > 16 && is_sprite_on_screen(sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y) == 0)
            {
                sprite->counter = 0;
                break;
            }

            if(sprite->fall_through_floor != 0 || sprite_blocking_check(DOWN, sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y + 1) == NOT_BLOCKED)
            {
                sprite->y++;
                if(sprite->fall_through_floor != 0 || sprite_blocking_check(DOWN, sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y + 1) == NOT_BLOCKED)
                {
                    if(sprite->counter == 1)
                    {
                        display_actor_sprite_maybe(sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y, 2);
                    }
                    else
                    {
                        display_actor_sprite_maybe(sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y, 4);
                    }
                    sprite->counter++;
                    if(sprite->counter > 40)
                    {
                        sprite->counter = 0;
                    }
                    break;
                }
            }
            sprite->counter = 3;
            sprite->fall_through_floor = 1;
            play_sfx(0x2e);
explode_while_cont1:
        }
explode_while_cont2:        
    }
}

U0 struct6_update_sprites()
{
    I64 i;
    for(i=0; i < MAX_STRUCT6_SPRITES; i++)
    {
        struc_6 *sprite = &struc6_sprites[i];
        if(sprite->counter != 0)
        {
            if(sprite->counter == 1)
            {
                effect_add_sprite(0x17, 8, sprite->x + 1 + 1, sprite->y - 2, 0, 1);
            }

            display_actor_sprite_maybe(0x1a, sprite->counter - 1 & 3, sprite->x, sprite->y, 0);

            if(player_check_collision_with_actor(0x1a, sprite->counter - 1 & 3, sprite->x, sprite->y) != 0)
            {
                player_decrease_health();
            }

            sprite->counter++;
            if(sprite->counter == 9)
            {
                sprite->counter = 0;
                effect_add_sprite(0x62, 6, sprite->x + 1, sprite->y - 1, 1, 1);
            }
        }
    }
}

U0 effect_update_sprites()
{
    I64 i;
    for(i=0; i < MAX_EFFECT_SPRITES; i++)
    {
        effect_sprite *sprite = &static_effect_sprites[i];

        if(sprite->is_active_flag)
        {
            if(is_sprite_on_screen(sprite->actorInfoIndex, sprite->frame_num, sprite->x, sprite->y))
            {

                if(sprite->actorInfoIndex == 0x63)
                {
                    
                    display_actor_sprite_maybe(sprite->actorInfoIndex, effect_frame_num_tbl[i], sprite->x, sprite->y, 5);
                }
                else
                {
                    display_actor_sprite_maybe(sprite->actorInfoIndex, effect_frame_num_tbl[i], sprite->x, sprite->y, 0);
                }
                
                if(sprite->actorInfoIndex == 0x1b)
                {
                    sprite->x--;
                    sprite->y = sprite->y + (cosmo_rand() % 3);
                }
                sprite->x = sprite->x + player_x_offset_tbl[sprite->field_A];
                sprite->y = sprite->y + player_y_offset_tbl[sprite->field_A];
                effect_frame_num_tbl[i]++;
                if(effect_frame_num_tbl[i] == sprite->frame_num)
                {
                    effect_frame_num_tbl[i] = 0;
                    if(sprite->counter != 0)
                    {
                        sprite->counter--;
                        if(sprite->counter == 0)
                        {
                            sprite->is_active_flag = 0;
                        }
                    }
                }
            }
            else
            {
                sprite->is_active_flag = 0;
            }
        }
    }
 
    return;
}

U0 update_brightness_objs()
{
    if(brightness_effect_enabled_flag == 0)
        return;

    I64 i, j;
    for(i=0;i<num_brightness_objs;i++)
    {
        Brightness *brightness = &brightness_tbl[i];
        if(brightness->x >= mapwindow_x_offset && brightness->x < mapwindow_x_offset + MAP_WINDOW_WIDTH &&
           brightness->y >= mapwindow_y_offset && brightness->y < mapwindow_y_offset + MAP_WINDOW_HEIGHT)
        {
            video_draw_highlight_effect((brightness->x - mapwindow_x_offset + 1) * TILE_WIDTH, (brightness->y - mapwindow_y_offset + 1) * TILE_HEIGHT, brightness->type);

            U16 tile_attr = tileattr_mni_data[map_get_tile_cell(brightness->x,brightness->y + 1)/8];
            for(j = 1; !(tile_attr & TILE_ATTR_BLOCK_DOWN);)
            {
                if(brightness->x >= mapwindow_x_offset && brightness->x < mapwindow_x_offset + MAP_WINDOW_WIDTH &&
                   brightness->y + j >= mapwindow_y_offset && brightness->y + j < mapwindow_y_offset + MAP_WINDOW_HEIGHT)
                {
                    video_draw_highlight_effect((brightness->x - mapwindow_x_offset + 1) * TILE_WIDTH,
                                                (brightness->y + j - mapwindow_y_offset + 1) * TILE_HEIGHT, 1);
                }
                j++;
                tile_attr = tileattr_mni_data[map_get_tile_cell(brightness->x,brightness->y + j)/8];
            }
        }
    }
}


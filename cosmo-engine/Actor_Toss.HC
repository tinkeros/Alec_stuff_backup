#define MAX_TOSSED_ACTORS 6

class ActorToss
{
I64 actorInfoIndex;
I64 x;
I64 y;
I64 counter;
};

ActorToss actorToss[MAX_TOSSED_ACTORS];

U0 actor_toss_add_new(I64 actorInfoIndex, I64 x_pos, I64 y_pos) {
    I64 i;
    for(i=0;i<MAX_TOSSED_ACTORS;i++)
    {
        if(actorToss[i].actorInfoIndex == 0)
        {
            actorToss[i].actorInfoIndex = actorInfoIndex;
            actorToss[i].x = x_pos;
            actorToss[i].y = y_pos;
            actorToss[i].counter = 0;
            return;
        }
    }
}

U0 actor_toss_update() {
    I64 i;
    for(i=0;i<MAX_TOSSED_ACTORS;i++)
    {
        ActorToss *at = &actorToss[i];
        if (at->actorInfoIndex == 0)
            goto actor_toss_update_cont;
        
        at->counter = at->counter + 1;
        at->y--;
        if (sprite_blocking_check(0, at->actorInfoIndex, 0, at->x, at->y) == NOT_BLOCKED)
        {
            if (at->counter >= 9 || sprite_blocking_check(0, at->actorInfoIndex, 0, at->x, --at->y) == NOT_BLOCKED)
            {
                if(at->counter != 11)
                {
                    display_actor_sprite_maybe(at->actorInfoIndex, 0, at->x, at->y, 4);
                }
                else
                {
                    actor_add_new(at->actorInfoIndex, at->x, at->y);
                    display_actor_sprite_maybe(at->actorInfoIndex, 0, at->x, at->y, 4);
                    at->actorInfoIndex = 0;
                }
            }
            else
            {
                actor_add_new(at->actorInfoIndex, at->x, at->y + 1);
                display_actor_sprite_maybe(at->actorInfoIndex, 0, at->x, at->y + 1, 0);
                at->actorInfoIndex = 0;
            }
        }
        else
        {
            actor_add_new(at->actorInfoIndex, at->x, at->y + 1);
            display_actor_sprite_maybe(at->actorInfoIndex, 0, at->x, at->y + 1, 0);
            at->actorInfoIndex = 0;
        }
actor_toss_update_cont:        
    }
}

U0 actor_toss_clear_all() {
    I64 i;
    for(i=0;i<MAX_TOSSED_ACTORS;i++)
    {
        actorToss[i].actorInfoIndex = 0;
    }
}

#define ST_GRG_DOOR    1
#define ST_KTC_DOOR    3

U0 AddSceneTarget(GameState *gs, I64 uid, I64 sid, I64 x, I64 y)
{
  I64 ctr=0;
  while (ctr<S_MAX_OBJ)
  {
    if (gs->s_tgt_uid[ctr]==0)
    {
      break;
    };
    ctr++;
  };  
  gs->s_tgt_uid[ctr]=uid;
  gs->s_tgt_sid[ctr]=sid;
  gs->s_tgt_x[ctr]=x;
  gs->s_tgt_y[ctr]=y;
}

U0 InitSceneTgts(GameState *gs)
{
  AddSceneTarget(gs,ST_GRG_DOOR,0,454,294);
  AddSceneTarget(gs,ST_KTC_DOOR,3,544,80);
}

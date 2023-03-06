#define SO_SHASTA      1
#define SO_BOYARDEE    2
#define SO_GOLD_KEY    4
#define SO_NUGGIES     5

U0 AddSceneObject(GameState *gs, I64 uid, I64 sid, I64 x, I64 y)
{
  I64 ctr=0;
  while (ctr<S_MAX_OBJ)
  {
    if (gs->s_obj_uid[ctr]==0)
    {
      break;
    };
    ctr++;
  };  
  gs->s_obj_uid[ctr]=uid;
  gs->s_obj_sid[ctr]=sid;
  gs->s_obj_x[ctr]=x;
  gs->s_obj_y[ctr]=y;
}

U0 InitSceneObjs(GameState *gs)
{
  AddSceneObject(gs,SO_GOLD_KEY,0,311,412);
  AddSceneObject(gs,SO_SHASTA,1,640,310);
  AddSceneObject(gs,SO_BOYARDEE,2,902,370);
  AddSceneObject(gs,SO_NUGGIES,2,1032,210);
}

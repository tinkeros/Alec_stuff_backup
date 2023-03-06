// Scene Scripts
//  placeholder: Scene Script is triggered when
//  use SceneObject with SceneTarget

  /*
     gs->st_so_uid   uid of scene object to trigger SceneScript
     gs->st_scr_id   id of SceneScript
     st_scr_msg  msg displayed when object used on target,
                 prior to trigger SceneScript
  */


U0 TargetOverlay(Bool bg_layer, CDC *dc, CDC *s_mask, I64 bgs_x, I64 uid)
{
  switch (uid)
  {

      // individual device contexts for now, but ugly,
      // need to merge into one, blah.
      //   test adding destination mask, teleport to store

    case 0x02:
      // garage door opened   
      s_mask->color=6;
      GrRect(s_mask,454,284,154,80);
      if (bg_layer)
      {    
        GrBlot(dc,bgs_x+454,284,to_01);
      }
      else {
        dc->color=6;
        GrRect(dc,bgs_x+454,284,154,80);
      };
      break;

    case 0x04:
      // kitchen door opened
      s_mask->color=6;
      GrRect(s_mask,544,80,to_02->width,to_02->height);
      if (bg_layer)
      {    
        GrBlot(dc,bgs_x+544,80,to_02);
      }
      else {
        dc->color=6;
        GrRect(dc,bgs_x+544,80,to_02->width,to_02->height);
      };
      break;

    default:
      break;
  };
}

U0 SceneScript(I64 script, GameState *gs, I64 target)
{
  switch (script)
  {

    case ACT_OPEN:
      gs->s_tgt_uid[target]++;
      gs->st_so_uid[gs->s_tgt_uid[target]]=ACT_CLOSE;
      gs->st_scr_id[gs->s_tgt_uid[target]]=ACT_CLOSE;
      break;

    case ACT_CLOSE:
      gs->s_tgt_uid[target]--;
      gs->st_so_uid[gs->s_tgt_uid[target]]=ACT_OPEN;
      gs->st_scr_id[gs->s_tgt_uid[target]]=ACT_OPEN;
      break;

    case 0x10:
      // Unlock Garage Door /w Gold Key
      gs->st_so_uid[gs->s_tgt_uid[target]]=ACT_OPEN;
      gs->st_scr_id[gs->s_tgt_uid[target]]=ACT_OPEN;
      break;

    default:
      break;
  };
};

// Terrys Temple Quest

// scene_objects
//   unique_id (if 0, next free)
//   scene_id (if -1, inventory)
//   obj_x
//   obj_y

#define I_MAX_ITEMS    8
#define S_MAX_OBJ      512
#define SO_MAX_DESC    48
#define SO_MAX_SMSG    256

#define ACT_WALK_TO    -10
#define ACT_PICK_UP    -11
#define ACT_TALK_TO    -12
#define ACT_INVENTORY  -13
#define ACT_OPEN       -14
#define ACT_CLOSE      -15
#define ACT_PUSH       -16
#define ACT_PULL       -17
#define ACT_USE        -18

#define INV_DROP       -10
#define INV_USE        -11

#define ST_Y_OFS       -48

#define WALK_SPEED     2

class GameState {
  I64 scene_id;
  I64 player_x;
  I64 player_y;
  I64 walkto_x;
  I64 walkto_y;
  I64 walk_fdir;
  I64 walk_fseq;
  I64 bgscroll_x;
  I64 walk_dir;
  I64 s_obj_uid[S_MAX_OBJ];
  I64 s_obj_sid[S_MAX_OBJ];
  I64 s_obj_x[S_MAX_OBJ];
  I64 s_obj_y[S_MAX_OBJ];
  I64 s_tgt_uid[S_MAX_OBJ];
  I64 s_tgt_sid[S_MAX_OBJ];
  I64 s_tgt_x[S_MAX_OBJ];
  I64 s_tgt_y[S_MAX_OBJ];
  I64 st_so_uid[S_MAX_OBJ];
  I64 st_scr_id[S_MAX_OBJ];
};

class Scene {
  Scene *next;
  I64 init_x;
  I64 t_x;
  I64 t_y;
  U8 loc[32];
  I64 st_id[16];
  I64 st_bx[16];
  I64 st_nx[16];
  I64 st_ny[16];
  CDC *bg;
  CDC *mask;
  CDC*path;
  U8 song[512];
};

// for now. :/
CDC *to_01=GRRead("Chars/GarageOpen.TGT.GR");
CDC *to_02=GRRead("Chars/KtchDoorOpen.TGT.GR");

#include "InitSceneObjs"
#include "InitSceneTgts"
#include "SceneScripts"

CDC *dc=DCNew(640,480);

Scene *SceneAdd(I64 init_x, I64 t_x, I64 t_y, U8 *loc, U8 *bg_file, U8 *path_file, Scene *sc_head)
{
  I64 scx=0;
  Scene *sc_new = CAlloc(sizeof(Scene));
  sc_new->init_x=init_x;
  sc_new->t_x=t_x;
  sc_new->t_y=t_y;
  while (scx<16)
  {
    sc_new->st_id[scx]=0;
    sc_new->st_bx[scx]=0;
    sc_new->st_nx[scx]=0;
    sc_new->st_ny[scx]=0;
    scx++;
  };
  StrCpy(sc_new->loc,loc);
  StrCpy(sc_new->song,"R");
  sc_new->bg=GRRead(bg_file);
  sc_new->mask=DCNew(sc_new->bg->width,sc_new->bg->height);
  if (StrCmp(path_file,"")==0)
  {
    sc_new->path=DCNew(sc_new->bg->width,sc_new->bg->height);
    DCFill(sc_new->path,0);
  }
  else
  {
    sc_new->path=GRRead(path_file);
  };
  DCFill(sc_new->mask,0);
  sc_new->next=0;
  if (sc_head->next==0)
  { 
    sc_head->next=sc_new;
  } else
  {
    Scene *sc_cur=sc_head;
    while (TRUE) {
      if (sc_cur->next==0)
      {
        sc_cur->next=sc_new;
        break;
      };
      sc_cur=sc_cur->next;
    };
  };
  return sc_new;
}

U0 ScenesDel(Scene *_lst)
{
  Scene *tmps;
  while(_lst->next)
  {
    tmps=_lst;
    DCDel(_lst->mask);
    DCDel(_lst->path);
    DCDel(_lst->bg);
    Free(_lst);
    _lst=tmps->next;
  };
  DCDel(_lst->mask);
  DCDel(_lst->path);
  DCDel(_lst->bg);
  Free(_lst);
}

U0 PlaySceneSong(U8 *song)
{
  while (TRUE)
  {
    Play(song);
  };
}

U0 LoadGameState(GameState *gs, U8 *state_file)
{
  // Load game state from GAME.STATE.Z
  I64 *state_load=FileRead(state_file);
  I64 so_ctr=0;
  I64 so_idx=9;
  gs->scene_id = state_load[0];
  gs->player_x = state_load[1];
  gs->player_y = state_load[2];
  gs->walkto_x = state_load[3];
  gs->walkto_y = state_load[4];
  gs->walk_fdir = state_load[5];
  gs->walk_fseq = state_load[6];
  gs->bgscroll_x = state_load[7];
  gs->walk_dir = state_load[8];
  while (so_ctr<S_MAX_OBJ)
  {
    gs->s_obj_uid[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->s_obj_sid[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->s_obj_x[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->s_obj_y[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->s_tgt_uid[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->s_tgt_sid[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->s_tgt_x[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->s_tgt_y[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->st_so_uid[so_ctr] = state_load[so_idx];
    so_idx++; 
    gs->st_scr_id[so_ctr] = state_load[so_idx];
    so_idx++; 
    so_ctr++;
  };
  Free(state_load);
}

U0 SaveGameState(U8 *state_file, GameState *gs)
{
  // Save game state to GAME.STATE.Z
  I64 *save_state=CAlloc(sizeof(GameState));
  I64 so_ctr=0;
  I64 so_idx=9;
  save_state[0]= gs->scene_id;
  save_state[1]= gs->player_x;
  save_state[2]= gs->player_y;
  save_state[3]= gs->walkto_x;
  save_state[4]= gs->walkto_y;
  save_state[5]= gs->walk_fdir;
  save_state[6]= gs->walk_fseq;
  save_state[7]= gs->bgscroll_x;
  save_state[8]= gs->walk_dir;
  while (so_ctr<S_MAX_OBJ)
  {
    save_state[so_idx]= gs->s_obj_uid[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->s_obj_sid[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->s_obj_x[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->s_obj_y[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->s_tgt_uid[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->s_tgt_sid[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->s_tgt_x[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->s_tgt_y[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->st_so_uid[so_ctr];
    so_idx++; 
    save_state[so_idx]= gs->st_scr_id[so_ctr];
    so_idx++; 
    so_ctr++;
  };
  FileWrite(state_file,save_state,sizeof(GameState));
  Free(save_state);
}

U0 DrawIt(CTask *task,CDC *tdc)
{
  task=task; //Suppress unused var warning
  GrBlot(tdc,0,0,dc);
}

I64 InventoryView(CDC *dc, GameState *gs, GameFont *font_berk, U8 *so_desc, I64 *so_col, I64 *so_row)
{

  Bool i_exit=FALSE;
  I64 i_act=INV_DROP;
  I64 i_ctr=0;
  I64 i_item_x=0;
  I64 i_item_y=0;
  I64 i_tc=0;
  I64 i_use=-1;
  I64 ms_sel_x=0;
  I64 ms_sel_y=0;
  I64 msg_code=0;
  I64 scan_code=0;
  U8 i_desc[SO_MAX_DESC];

  while (!i_exit&&scan_code!=1&&msg_code!=MSG_MS_R_UP)
  {
    // Polling IN 0x60 screws up mouse msg handling?.. will fix
    //scan_code=InU8(0x60);
    msg_code=ScanMsg(,,1<<MSG_MS_L_UP+1<<MSG_MS_R_UP);

    dc->color=BLUE;
    GrRect(dc,0,96,640,272);

    dc->color=WHITE;
    GrLine(dc,0,96,0,368);
    GrLine(dc,639,96,639,368);

    GrLine(dc,0,96,639,96);
    GrLine(dc,0,368,639,368);
    
    FontText(dc,font_berk,"Inventory",12,108,LTCYAN);

    if (i_act==INV_DROP)
    {
      i_tc=YELLOW;
    }
    else
    {
      i_tc=WHITE;
      if (ms.pos.y>132 && ms.pos.y<154)
      {
        if (ms.pos.x>12 && ms.pos.x<68)
        {
          if (msg_code==MSG_MS_L_UP)
          {
            i_act=INV_DROP;
            i_tc=YELLOW;
          }
          else
          {
            i_tc=LTGREEN;
          };
        };
      };
    };
    FontText(dc,font_berk,"Drop",12,132,i_tc);

    if (i_act==INV_USE)
    {
      i_tc=YELLOW;
    }
    else
    {
      i_tc=WHITE;
      if (ms.pos.y>156 && ms.pos.y<178)
      {
        if (ms.pos.x>12 && ms.pos.x<55)
        {
          if (msg_code==MSG_MS_L_UP)
          {
            i_act=INV_USE;
            i_tc=YELLOW;
          }
          else
          {
            i_tc=LTGREEN;
          };
        };
      };
    };
    FontText(dc,font_berk,"Use",12,156,i_tc);

    FontText(dc,font_berk,"Right click",12,300,LTGRAY);
    FontText(dc,font_berk,"to close",12,324,LTGRAY);

    i_ctr=0;
    i_item_x=0;
    i_item_y=0;
    while (i_ctr<S_MAX_OBJ)
    {
      i_desc[0]=0;
      if (gs->s_obj_uid[i_ctr]>0 && gs->s_obj_sid[i_ctr]==-1)
      {
        StrCpy(i_desc,so_desc+(gs->s_obj_uid[i_ctr]*SO_MAX_DESC));

        dc->color=WHITE;
        GrPrint(dc,192+(224*i_item_x),136+(64*i_item_y),i_desc);
        SceneObjBlot(dc,144+(224*i_item_x),104+(64*i_item_y),so_col[gs->s_obj_uid[i_ctr]],so_row[gs->s_obj_uid[i_ctr]]);

        if (ms.pos.y> 104+(64*i_item_y) && ms.pos.y<104+(64*i_item_y)+64)
        {
          if (ms.pos.x>144+(224*i_item_x) && ms.pos.x<144+(224*i_item_x)+224)
          {
            ms_sel_y=104+(64*i_item_y);
            while (ms_sel_y<104+(64*i_item_y)+64)
            {
              ms_sel_x=144+(224*i_item_x);
              while (ms_sel_x<144+(224*i_item_x)+224)
              {
                if (GrPeek(dc,ms_sel_x,ms_sel_y)!=BLUE)
                {
                  if (msg_code==MSG_MS_L_UP)
                  {
                    if (i_act==INV_DROP)
                    {
                      gs->s_obj_sid[i_ctr]=gs->scene_id;
                      gs->s_obj_x[i_ctr]=-gs->bgscroll_x+gs->player_x;
                      gs->s_obj_y[i_ctr]=gs->player_y+96;
                      i_exit=TRUE;
                    };
                    if (i_act==INV_USE)
                    {
                      i_use=i_ctr;
                      i_exit=TRUE;
                    };
                  };
                  dc->color=YELLOW;
                  GrPrint(dc,192+(224*i_item_x),136+(64*i_item_y),i_desc);
                  break;
                };
                ms_sel_x++;
              };
              ms_sel_y++;
            };
          };
        };


        i_item_x++;
        if (i_item_x>1) { i_item_x=0; i_item_y++; };
      };
 
      i_ctr++;
    };


    Sleep(1);
  };
  return i_use;
}

U0 Run(I64 sfx_cpu=0,Bool load_state=FALSE)
{
  sfx_cpu=sfx_cpu; // Suppress unused var warning
  SettingsPush;
  U8 *doc=DocSave(DocPut);
  DocClear;
  WinBorder;
  WinMax;
  U8 i_desc[SO_MAX_DESC];
  U8 i_with[SO_MAX_DESC];
  I64 pop_up;
  I64 so_ctr=0;

  GameState *gs=CAlloc(sizeof(GameState));

  if (load_state)
  {
    LoadGameState(gs,"GAME.STATE.Z");
  }
  else
  {
    gs->scene_id=0;
    gs->player_x=320;
    gs->player_y=240;
    gs->walkto_x=gs->player_x;
    gs->walkto_y=gs->player_y;
    gs->walk_dir=0;
    so_ctr=0;
    while (so_ctr<S_MAX_OBJ)
    {
      gs->s_obj_uid[so_ctr]=0;
      gs->s_obj_sid[so_ctr]=0;
      gs->s_obj_x[so_ctr]=0;
      gs->s_obj_y[so_ctr]=0;
      //gs->s_obj_y[so_ctr]=0;
      //gs->s_obj_y[so_ctr]=0;
      so_ctr++;
    };
    InitSceneObjs(gs);
    InitSceneTgts(gs);
  };

  Bool bg_layer=TRUE;

  I64 bnd_x1y1=0;
  I64 bnd_x2y2=0;
  I64 get_obj=FALSE;
  I64 get_oid=-1;
  I64 h_tc=0;
  I64 i_use=-1;
  I64 left_action=ACT_WALK_TO;
  I64 msg_code;
  I64 prev_bgx=0;
  I64 prev_px=0;
  I64 prev_py=0;
  I64 prev_timer=0;
  I64 scan_code=0;
  I64 scene_ctr=0;
  I64 snd_toggle=TRUE;
  I64 success=FALSE;
  I64 tr_c=BLUE;
  I64 tr_x1=-1;
  I64 tr_x2=-1;
  I64 tr_y1=-1;
  I64 tr_y2=-1;
  I64 use_obj=FALSE;
  I64 use_tid=-1;

  CTask *SongTask=0;
  
  #include "Scenes";

  I64 *so_col=CAlloc(sizeof(I64)*S_MAX_OBJ);
  I64 *so_row=CAlloc(sizeof(I64)*S_MAX_OBJ);
  U8 *so_desc=CAlloc(SO_MAX_DESC*S_MAX_OBJ);

  I64 *st_width=CAlloc(sizeof(I64)*S_MAX_OBJ);
  I64 *st_height=CAlloc(sizeof(I64)*S_MAX_OBJ);
  I64 *st_charx=CAlloc(sizeof(I64)*S_MAX_OBJ);
  I64 *st_chary=CAlloc(sizeof(I64)*S_MAX_OBJ);

  /*
     gs->st_so_uid   uid of scene object to trigger SceneScript
     gs->st_scr_id   id of SceneScript
     st_scr_msg  msg displayed when object used on target,
                 prior to trigger SceneScript
  */
 
  U8 *st_desc=CAlloc(SO_MAX_DESC*S_MAX_OBJ);
  U8 *st_scr_msg=CAlloc(SO_MAX_SMSG*S_MAX_OBJ);

  so_ctr=0;
  while (so_ctr<S_MAX_OBJ)
  {
    so_col[so_ctr]=0;
    so_row[so_ctr]=0;
    so_ctr++;
  };
  so_ctr=0;
  while (so_ctr<S_MAX_OBJ)
  {
    st_width[so_ctr]=0;
    st_height[so_ctr]=0;
    st_charx[so_ctr]=0;
    st_chary[so_ctr]=0;
    so_ctr++;
  };

  #include "SceneObjects";
  #include "SceneTargets";
    
  U8 f_charset[0x7F];

  StrCpy(f_charset," !\"#$$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~");
  GameFont *font_swash=LoadFont("Fonts/Swash.FONT.GR",12,9,52,83,19,f_charset);

  StrCpy(f_charset,"ABCDEFGHIJKLMNOPQRSTUVWXYZ    abcdefghijklmnopqrstuvwxyz '  0123456789  $$ !?#%&()\"*@");
  GameFont *font_berk=LoadFont("Fonts/Berkelium.FONT.GR",6,13,25,26,12,f_charset);

  s_ptr=*scenes;
  scene_ctr=0;
  while(scene_ctr<gs->scene_id)
  {
    s_ptr=s_ptr->next;
    scene_ctr++;
  };
  if (SongTask) { Kill(SongTask); };
  SndRst;
  if (snd_toggle) { SongTask=Spawn(&PlaySceneSong,s_ptr->song); }

  if (!load_state)
  {
    gs->bgscroll_x=s_ptr->init_x;
  };

  Fs->draw_it=&DrawIt;

  while (scan_code!=1)
  {
    scan_code=InU8(0x60);

    // clear target overlay paths
    GrBlot(s_ptr->mask,0,0,s_ptr->path);

    if (scan_code==0x26)
    { 
      LoadGameState(gs,"GAME.STATE.Z");
      s_ptr=*scenes;
      scene_ctr=0;
      while(scene_ctr<gs->scene_id)
      {
        s_ptr=s_ptr->next;
        scene_ctr++;
      };
      if (SongTask) { Kill(SongTask); };
      SndRst;
      if (snd_toggle) { SongTask=Spawn(&PlaySceneSong,s_ptr->song); }
    };

    // Debug: ENTER=toggle bg_layer
    if (scan_code==0x23) { bg_layer=!bg_layer; };


    // Toggle music and sound effects
    if (scan_code==0x32)
    { 
      snd_toggle=!snd_toggle;
      if (SongTask) { Kill(SongTask); };
      SndRst;
      if (snd_toggle) { SongTask=Spawn(&PlaySceneSong,s_ptr->song); }
    };

    // Arrow keys move player
    if (scan_code==0x4B) { get_oid=-1; use_tid=-1; gs->walkto_x= gs->player_x-WALK_SPEED*2; };
    if (scan_code==0x4D) { get_oid=-1; use_tid=-1; gs->walkto_x= gs->player_x+WALK_SPEED*2; };
    if (scan_code==0x48) { get_oid=-1; use_tid=-1; gs->walkto_y= gs->player_y-WALK_SPEED*2; };
    if (scan_code==0x50) { get_oid=-1; use_tid=-1; gs->walkto_y= gs->player_y+WALK_SPEED*2; };

    msg_code=ScanMsg(,,1<<MSG_MS_L_UP+1<<MSG_MS_R_UP);

    // Path Trace Mode

    if (!bg_layer)
    {

      if (scan_code==0x0C)
      {
        tr_c--;
      };
      if (scan_code==0x0D)
      {
        tr_c++;
      };
      if (scan_code==0x1F)
      {
        GRWrite("PATH.GR.Z",s_ptr->path);
        pop_up=PopUpOk("Scene Path saved to PATH.GR.Z");
      };

      if (tr_c>15) { tr_c=0;  };
      if (tr_c<0)  { tr_c=15; };

      if (tr_x1 != -1 && tr_x2 == -1)
      {
        s_ptr->mask->color=tr_c;
        GrLine(s_ptr->mask, tr_x1, tr_y1, -gs->bgscroll_x+ms.pos.x, ms.pos.y);
      };
    };

    if (msg_code==MSG_MS_L_UP && !bg_layer)
    {
      s_ptr->path->color=tr_c;
      if (tr_x1==-1)
      {
        tr_x1= -gs->bgscroll_x+ms.pos.x;
        tr_y1= ms.pos.y;
      }
      else
      {
        tr_x2= -gs->bgscroll_x+ms.pos.x;
        tr_y2= ms.pos.y;
        GrLine(s_ptr->path, tr_x1, tr_y1, tr_x2, tr_y2);
        tr_x1=-1;
        tr_x2=-1;
      }; 
    };

    if (msg_code==MSG_MS_R_UP && !bg_layer)
    {
      s_ptr->mask->color=tr_c;
      if (tr_x1==-1)
      {
        GrFloodFill(s_ptr->path, -gs->bgscroll_x+ms.pos.x, ms.pos.y, TRUE);
      }
      else
      {
        tr_x1=-1;
        tr_x2=-1;
      };
    };

    if (msg_code==MSG_MS_R_UP && bg_layer)
    {
      left_action=ACT_WALK_TO;
    };
    if (msg_code==MSG_MS_L_UP && bg_layer)
    {
      if (ms.pos.y>103)
      {
        if (left_action==ACT_WALK_TO)
        { 
          gs->walkto_x=(ms.pos.x-24)/WALK_SPEED*WALK_SPEED;
          gs->walkto_y=(ms.pos.y-24)/WALK_SPEED*WALK_SPEED;      
        };


        if (left_action==ACT_PICK_UP)
        {

          so_ctr=0;
          while (so_ctr<S_MAX_OBJ)
          {
            if (gs->s_obj_uid[so_ctr]>0)
            {
              if (gs->s_obj_sid[so_ctr]==gs->scene_id)
              {
                if (ms.pos.y>gs->s_obj_y[so_ctr] && ms.pos.y<(gs->s_obj_y[so_ctr]+48))
                {
                  if ((-gs->bgscroll_x+ms.pos.x)>gs->s_obj_x[so_ctr] && (-gs->bgscroll_x+ms.pos.x)<gs->s_obj_x[so_ctr]+48)
                  {
                    get_obj=TRUE;
                    get_oid=-1;
                    if (gs->player_y+48<gs->s_obj_y[so_ctr] || gs->player_y+48>(gs->s_obj_y[so_ctr]+48))
                    {
                      get_obj=FALSE;
                    };
                    if ((-gs->bgscroll_x+gs->player_x)<gs->s_obj_x[so_ctr] || (-gs->bgscroll_x+gs->player_x)>gs->s_obj_x[so_ctr]+48)
                    {
                      get_obj=FALSE;
                    };
                    if (!get_obj)
                    {
                      gs->walkto_x=(ms.pos.x-24)/WALK_SPEED*WALK_SPEED;
                      gs->walkto_y=(ms.pos.y-24)/WALK_SPEED*WALK_SPEED;
                      get_oid=so_ctr;
                    }
                    else { gs->s_obj_sid[so_ctr]=-1; };
                  };
                };
              };
            };
            so_ctr++;
          };

        };

        if (left_action!=ACT_WALK_TO && left_action!=ACT_PICK_UP)
        {

          so_ctr=0;
          while (so_ctr<S_MAX_OBJ)
          {
            if (gs->s_tgt_uid[so_ctr]>0)
            {
              if (gs->s_tgt_sid[so_ctr]==gs->scene_id)
              {
                if (ms.pos.y>gs->s_tgt_y[so_ctr] && ms.pos.y<gs->s_tgt_y[so_ctr]+st_height[gs->s_tgt_uid[so_ctr]])
                {
                  if ((-gs->bgscroll_x+ms.pos.x)>gs->s_tgt_x[so_ctr] && (-gs->bgscroll_x+ms.pos.x)<gs->s_tgt_x[so_ctr]+st_width[gs->s_tgt_uid[so_ctr]])
                  {

                    // walk to SceneTarget if needed, or Use SceneObject

                    use_obj=TRUE;
                    use_tid=-1;
                    if (gs->player_y+st_height[gs->s_tgt_uid[so_ctr]]<gs->s_tgt_y[so_ctr] || ST_Y_OFS+gs->player_y+st_height[gs->s_tgt_uid[so_ctr]]>(gs->s_tgt_y[so_ctr]+st_height[gs->s_tgt_uid[so_ctr]]))
                    {
                      use_obj=FALSE;
                    };
                    if ((-gs->bgscroll_x+gs->player_x)<gs->s_tgt_x[so_ctr] || (-gs->bgscroll_x+gs->player_x)>gs->s_tgt_x[so_ctr]+st_width[gs->s_tgt_uid[so_ctr]])
                    {
                      use_obj=FALSE;
                    };
                    if (!use_obj)
                    {
                      gs->walkto_x=(ms.pos.x-24)/WALK_SPEED*WALK_SPEED;
                      gs->walkto_y=(ms.pos.y-24)/WALK_SPEED*WALK_SPEED;
                      if (left_action==ACT_USE)
                      {
                        use_tid=so_ctr;
                      }
                      else {
                        use_tid=left_action;
                      };
                    }
                    else {                      
                      GrPrint(dc,40,40,"top %d",gs->st_so_uid[gs->s_tgt_uid[so_ctr]]);

                      success=FALSE;
                      if (left_action==ACT_USE && gs->s_obj_uid[i_use]==gs->st_so_uid[gs->s_tgt_uid[so_ctr]])
                      {
                        pop_up=PopUpOk(st_scr_msg+(gs->s_tgt_uid[so_ctr]*SO_MAX_SMSG));
                        gs->s_obj_sid[i_use]=-2;
                        SceneScript(gs->st_scr_id[gs->s_tgt_uid[so_ctr]],gs,so_ctr);  
                        success=TRUE;
                      }
                      else {
                        if (left_action==gs->st_so_uid[gs->s_tgt_uid[so_ctr]])
                        {
                          SceneScript(gs->st_scr_id[gs->s_tgt_uid[so_ctr]],gs,so_ctr);  
                          success=TRUE;
                        };
                      };
                      if (!success)
                      {
                        pop_up=PopUpOk("You can't do that here.");
                      };
                      left_action=ACT_WALK_TO;
                      use_tid=-1;
                    };

                  };
                };
              };
            };
            so_ctr++;
          };

        };

      }
      else
      {
        if (ms.pos.y>57 && ms.pos.y<71)
        {
          if (ms.pos.x>237 && ms.pos.x<321)
          {
            left_action=ACT_WALK_TO;
          };
          if (ms.pos.x>346 && ms.pos.x<431)
          {
            left_action=ACT_TALK_TO;
          };
          if (ms.pos.x>479 && ms.pos.x<526)
          {
            left_action=ACT_OPEN;
          };
          if (ms.pos.x>563 && ms.pos.x<611)
          {
            left_action=ACT_PUSH;
          };
        };
        if (ms.pos.y>80 && ms.pos.y<95)
        {
          if (ms.pos.x>238 && ms.pos.x<321)
          {
            left_action=ACT_PICK_UP;
          };
          if (ms.pos.x>347 && ms.pos.x<454)
          {
            left_action=ACT_INVENTORY;
          };
          if (ms.pos.x>480 && ms.pos.x<538)
          {
            left_action=ACT_CLOSE;
          };
          if (ms.pos.x>561 && ms.pos.x<606)
          {
            left_action=ACT_PULL;
          };
        };
      }
    };

    prev_timer=SysTimerRead;    

    if (bg_layer)
    {
      GrBlot(dc,gs->bgscroll_x,0,s_ptr->bg);
    }
    else
    {
      GrBlot(dc,gs->bgscroll_x,0,s_ptr->mask);
      // Draw Walking BoundingBox
      dc->color=GREEN;
      GrRect(dc,gs->player_x+16,gs->player_y+132,40,16);
    };

    // Draw Scene Targets
    i_with[0]=0;
    so_ctr=0;
    while (so_ctr<S_MAX_OBJ)
    {
      if (gs->s_tgt_uid[so_ctr]>0)
      {
        if (gs->s_tgt_sid[so_ctr]==gs->scene_id)
        {
          TargetOverlay(bg_layer,dc,s_ptr->mask,gs->bgscroll_x,gs->s_tgt_uid[so_ctr]);
          if (left_action!=ACT_WALK_TO && left_action!=ACT_PICK_UP)
          {
            if (ms.pos.y>gs->s_tgt_y[so_ctr] && ms.pos.y<gs->s_tgt_y[so_ctr]+st_height[gs->s_tgt_uid[so_ctr]])
            {
              if ((-gs->bgscroll_x+ms.pos.x)>gs->s_tgt_x[so_ctr] && (-gs->bgscroll_x+ms.pos.x)<gs->s_tgt_x[so_ctr]+st_width[gs->s_tgt_uid[so_ctr]])
              {
                if (left_action==ACT_USE)
                {
                  StrCpy(i_with,"With ");
                  StrCpy(i_with+5,st_desc+(gs->s_tgt_uid[so_ctr]*SO_MAX_DESC));
                }
                else {
                  StrCpy(i_with,st_desc+(gs->s_tgt_uid[so_ctr]*SO_MAX_DESC));         
                };
              };
            };
          };
        };
      };
      so_ctr++;
    };

    i_desc[0]=0;
    // Draw Scene Objects
    so_ctr=0;
    while (so_ctr<S_MAX_OBJ)
    {
      if (gs->s_obj_uid[so_ctr]>0)
      {
        if (gs->s_obj_sid[so_ctr]==gs->scene_id)
        {
          SceneObjBlot(dc,gs->bgscroll_x+gs->s_obj_x[so_ctr],gs->s_obj_y[so_ctr],so_col[gs->s_obj_uid[so_ctr]],so_row[gs->s_obj_uid[so_ctr]]);
          if (left_action==ACT_PICK_UP)
          {
            if (ms.pos.y>gs->s_obj_y[so_ctr] && ms.pos.y<(gs->s_obj_y[so_ctr]+48))
            {
              if ((-gs->bgscroll_x+ms.pos.x)>gs->s_obj_x[so_ctr] && (-gs->bgscroll_x+ms.pos.x)<gs->s_obj_x[so_ctr]+48)
              {
                //StrCpy(i_desc,"Pick Up ");
                //StrCpy(i_desc+8,so_desc+(gs->s_obj_uid[so_ctr]*SO_MAX_DESC));
                StrCpy(i_with,so_desc+(gs->s_obj_uid[so_ctr]*SO_MAX_DESC));
              };
            };
          };
        };
      };
      so_ctr++;
    };
  
    // HUD
    dc->color=BLUE;
    GrRect(dc,0,0,640,96);
    FontText(dc,font_swash,"Terry's Temple Quest",220,-24,LTCYAN,BLACK);

    if (left_action==ACT_WALK_TO)
    {
      h_tc=YELLOW;
    }
    else
    {
      h_tc=WHITE;
      if (ms.pos.y>57 && ms.pos.y<71)
      {
        if (ms.pos.x>237 && ms.pos.x<321)
        {
          h_tc=LTGREEN;
        };
      };
    };
    FontText(dc,font_berk,"Walk To",224+8,48,h_tc);

    if (left_action==ACT_USE)
    {
      StrCpy(i_desc,"Use ");
      StrCpy(i_desc+4,so_desc+(gs->s_obj_uid[i_use]*SO_MAX_DESC));

      h_tc=YELLOW;
      FontText(dc,font_berk,"Use",224+8,70,h_tc);
    }
    else
    {
      if (left_action==ACT_PICK_UP)
      {
        StrCpy(i_desc,"Pick Up ");
        h_tc=YELLOW;
      }
      else
      {
        h_tc=WHITE;
        if (ms.pos.y>80 && ms.pos.y<95)
        {
          if (ms.pos.x>238 && ms.pos.x<321)
          {
            h_tc=LTGREEN;
          };
        };
      };
      FontText(dc,font_berk,"Pick Up",224+8,70,h_tc);
    };

    if (left_action==ACT_TALK_TO)
    {
      StrCpy(i_desc,"Talk To ");

      h_tc=YELLOW;
    }
    else
    {
      h_tc=WHITE;
      if (ms.pos.y>57 && ms.pos.y<71)
      {
        if (ms.pos.x>346 && ms.pos.x<431)
        {
          h_tc=LTGREEN;
        };
      };
    };
    FontText(dc,font_berk,"Talk To",332+8,48,h_tc);


    if (left_action==ACT_INVENTORY)
    {

      h_tc=YELLOW;
    }
    else
    {
      h_tc=WHITE;
      if (ms.pos.y>80 && ms.pos.y<95)
      {
        if (ms.pos.x>347 && ms.pos.x<454)
        {
          h_tc=LTGREEN;
        };
      };
    };
    FontText(dc,font_berk,"Inventory",332+8,70,h_tc);


    if (left_action==ACT_OPEN)
    {
      StrCpy(i_desc,"Open ");

      h_tc=YELLOW;
    }
    else
    {
      h_tc=WHITE;
      if (ms.pos.y>57 && ms.pos.y<71)
      {
        if (ms.pos.x>479 && ms.pos.x<526)
        {
          h_tc=LTGREEN;
        };
      };
    };
    FontText(dc,font_berk,"Open",464+8,48,h_tc);

    if (left_action==ACT_CLOSE)
    {
      StrCpy(i_desc,"Close ");

      h_tc=YELLOW;
    }
    else
    {
      h_tc=WHITE;
      if (ms.pos.y>80 && ms.pos.y<95)
      {
        if (ms.pos.x>480 && ms.pos.x<538)
        {
          h_tc=LTGREEN;
        };
      };
    };
    FontText(dc,font_berk,"Close",464+8,70,h_tc);

    if (left_action==ACT_PUSH)
    {
      StrCpy(i_desc,"Push ");

      h_tc=YELLOW;
    }
    else
    {
      h_tc=WHITE;
      if (ms.pos.y>57 && ms.pos.y<71)
      {
        if (ms.pos.x>563 && ms.pos.x<611)
        {
          h_tc=LTGREEN;
        };
      };
    };
    FontText(dc,font_berk,"Push",548+8,48,h_tc);

    if (left_action==ACT_PULL)
    {
      StrCpy(i_desc,"Pull ");

      h_tc=YELLOW;
    }
    else
    {
      h_tc=WHITE;
      if (ms.pos.y>80 && ms.pos.y<95)
      {
        if (ms.pos.x>561 && ms.pos.x<606)
        {
          h_tc=LTGREEN;
        };
      };
    };
    FontText(dc,font_berk,"Pull",548+8,70,h_tc);

    dc->color=YELLOW;
    GrPrint(dc,8,16+(8*7),i_desc);    
    GrPrint(dc,8,16+(8*8),i_with);    

    dc->color=WHITE;
    //GrPrint(dc,8,16+(8*1)-4, "S");
    //GrPrint(dc,8,16+(8*2)-4, "h");
    //GrPrint(dc,8,16+(8*3)-4, "a");
    //GrPrint(dc,8,16+(8*4)-4, "s");
    //GrPrint(dc,8,16+(8*5)-4, "t");
    //GrPrint(dc,8,16+(8*6)-4, "a");
    GR96Blot(dc,-20,-28,s_Terry,3,1,0);

    StrCpy(Fs->task_title,s_ptr->loc);
    dc->color=LTCYAN;
    GrPrint(dc,8,8,s_ptr->loc);
    dc->color=WHITE;

    GrLine(dc,0,0,0,96);
    GrLine(dc,639,0,639,96);

    GrLine(dc,0,0,639,0);
    GrLine(dc,0,96,639,96);


    //Debug
    if (!bg_layer)
    {
      dc->color=tr_c;
      GrPrint(dc,24+(8*3),32-(8*1),"%d",tr_c);
      dc->color=WHITE;
      GrPrint(dc,24+(8*3),32+(8*1),"Mouse  X1 Y1: %d %d", -gs->bgscroll_x+ms.pos.x, ms.pos.y);

      GrPrint(dc,24+(8*3),32+(8*2),"BgrScrollPos: %d", gs->bgscroll_x);
      GrPrint(dc,24+(8*3),32+(8*3),"Player X1 Y1: %d %d", -gs->bgscroll_x+gs->player_x+16, gs->player_y+132);
      GrPrint(dc,24+(8*3),32+(8*4),"Player X2 Y2: %d %d", -gs->bgscroll_x+gs->player_x+16+39, gs->player_y+132+15);
    };

    // Terry 
    GR96Blot(dc,gs->player_x,gs->player_y+52,s_Terry,gs->walk_fseq,0,gs->walk_dir);
    GR96Blot(dc,gs->player_x,gs->player_y,s_Terry,2,2,!gs->walk_dir);

    // Test Dianna Thumbnail Overlay
    GrBlot(dc,0,360,th_Dianna);

    bnd_x1y1 = GrPeek(s_ptr->mask, -gs->bgscroll_x+gs->player_x+16, gs->player_y+132);
    bnd_x2y2 = GrPeek(s_ptr->mask, -gs->bgscroll_x+gs->player_x+16+39, gs->player_y+132+15);

    if (gs->walkto_x != gs->player_x || gs->walkto_y != gs->player_y)
    {

      if (bnd_x1y1>0 && bnd_x2y2>0) 
      {
        if (bnd_x1y1>1 && bnd_x2y2>1)
        {
          gs->bgscroll_x=s_ptr->st_bx[bnd_x1y1];
          gs->player_x=s_ptr->st_nx[bnd_x1y1];
          gs->player_y=s_ptr->st_ny[bnd_x1y1];
          gs->scene_id=s_ptr->st_id[bnd_x1y1];
          gs->walkto_x=gs->player_x;
          gs->walkto_y=gs->player_y;
          prev_px=gs->player_x;
          prev_py=gs->player_y;
          prev_bgx=gs->bgscroll_x;
          s_ptr=*scenes;
          scene_ctr=0;
          while(scene_ctr<gs->scene_id)
          {
            s_ptr=s_ptr->next;
            scene_ctr++;
          };
          if (SongTask) { Kill(SongTask); };
          SndRst;
          if (snd_toggle) { SongTask=Spawn(&PlaySceneSong,s_ptr->song); }
        }
        else
        {
          prev_px=gs->player_x;
          prev_py=gs->player_y;
          prev_bgx=gs->bgscroll_x;

          if (gs->walkto_x < gs->player_x) { gs->walk_dir=1; gs->bgscroll_x+=2; gs->walkto_x+=2; };
          if (gs->walkto_x > gs->player_x) { gs->walk_dir=0; gs->bgscroll_x-=2; gs->walkto_x-=2; };

          if (gs->bgscroll_x>0) { gs->bgscroll_x=0; };
          if (640-gs->bgscroll_x>s_ptr->bg->width) { gs->bgscroll_x= (640-s_ptr->bg->width); };

          if (gs->walkto_x < gs->player_x) { gs->player_x -= WALK_SPEED; };
          if (gs->walkto_x > gs->player_x) { gs->player_x += WALK_SPEED; };
          if (gs->walkto_y < gs->player_y) { gs->player_y -= WALK_SPEED; };
          if (gs->walkto_y > gs->player_y) { gs->player_y += WALK_SPEED; };

          if (gs->walk_fdir==0) { gs->walk_fseq++; };
          if (gs->walk_fdir==1) { gs->walk_fseq--; };
        };
      } 
      else {
        gs->player_x=prev_px;
        gs->player_y=prev_py;
        gs->bgscroll_x=prev_bgx;
 
        gs->walkto_x=gs->player_x;
        gs->walkto_y=gs->player_y;  
      };
    }
    else
    {
      if (left_action==ACT_PICK_UP && get_oid!=-1)
      {
        get_obj=TRUE;
        if (gs->player_y+48<gs->s_obj_y[get_oid] || gs->player_y+48>(gs->s_obj_y[get_oid]+48))
        {
          if ((-gs->bgscroll_x+gs->player_x)<gs->s_obj_x[get_oid] || (-gs->bgscroll_x+gs->player_x)>gs->s_obj_x[get_oid]+48)
          {
            get_obj=FALSE;
          };
        };
        if (get_obj) { gs->s_obj_sid[get_oid]=-1; get_oid=-1; };
      };

      //ACT_USE
      if (left_action!=ACT_WALK_TO && use_tid!=-1)
      {

        use_obj=TRUE;
        if (gs->player_y+st_height[gs->s_tgt_uid[use_tid]]<gs->s_obj_y[use_tid] || gs->player_y+st_height[gs->s_tgt_uid[use_tid]]>(gs->s_obj_y[use_tid]+st_height[gs->s_tgt_uid[use_tid]]))
        {
          if ((-gs->bgscroll_x+gs->player_x)<gs->s_obj_x[use_tid] || (-gs->bgscroll_x+gs->player_x)>gs->s_obj_x[use_tid]+st_height[gs->s_tgt_uid[use_tid]])
          {
            use_obj=FALSE;
          };
        };

        if (use_obj) {

          GrPrint(dc,40,40,"bot %d",gs->st_so_uid[gs->s_tgt_uid[use_tid]]);

          if (gs->s_obj_uid[i_use]==gs->st_so_uid[gs->s_tgt_uid[use_tid]])
          {
            if (left_action==ACT_USE)
            {
              pop_up=PopUpOk(st_scr_msg+(gs->s_tgt_uid[use_tid]*SO_MAX_SMSG));
            };
            gs->s_obj_sid[i_use]=-2;
            SceneScript(gs->st_scr_id[gs->s_tgt_uid[use_tid]],gs,use_tid);
          }
          else {
            pop_up=PopUpOk("You can't do that here.");
          };
        };
        left_action=ACT_WALK_TO;
        use_tid=-1;
     };

    };

    if (left_action==ACT_INVENTORY)
    {
      i_use=InventoryView(dc,gs,font_berk,so_desc,so_col,so_row);
      if (i_use>-1)
      {
        left_action=ACT_USE;
      }
      else
      {
        left_action=ACT_WALK_TO;
      };
    };

    if (gs->walk_fseq>3) { gs->walk_fdir=1; };
    if (gs->walk_fseq<1) { gs->walk_fdir=0; };    

    while (SysTimerRead<prev_timer+(30000)) { Sleep(1); };
  };

  if (SongTask) { Kill(SongTask); };
  SndRst;

  SaveGameState("GAME.STATE.Z",gs);
  Free(gs);

  // ugly, get rid of this
  DCDel(to_02);
  DCDel(to_01);

  Free(st_scr_msg);
  Free(st_chary);
  Free(st_charx);
  Free(st_height);
  Free(st_width);
  Free(st_desc);
  Free(so_col);
  Free(so_row);
  Free(so_desc);
  ScenesDel(scenes);
  Fs->draw_it=0;
  FreeFont(font_berk);
  FreeFont(font_swash);
  FreeChars;
  DCDel(dc);
  DocLoad(DocPut,doc,sizeof(doc));
  Free(doc);
  SettingsPop;
}

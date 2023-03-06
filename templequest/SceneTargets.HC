// Scene Targets
//  placeholder: use SceneObject with SceneTarget


st_width[1]=142; st_height[1]=58;
st_charx[1]=0; st_chary[1]=0;
if (gs->st_so_uid[1]==0)
{
  gs->st_so_uid[1]=4; gs->st_scr_id[1]=0x10;
};
// garage door closed
StrCpy(st_desc+(1*SO_MAX_DESC), "Garage Door");
StrCpy(st_scr_msg+(1*SO_MAX_SMSG),"You use the Gold Key on the\nGarage Door, and it unlocks.");

st_width[2]=142; st_height[2]=58;
st_charx[2]=0; st_chary[2]=0;
if (gs->st_so_uid[2]==0)
{
  gs->st_so_uid[2]=0; gs->st_scr_id[2]=0;
};
// garage door opened
StrCpy(st_desc+(2*SO_MAX_DESC), "Garage Door");
StrCpy(st_scr_msg+(2*SO_MAX_SMSG),"");


st_width[3]=90; st_height[3]=182;
st_charx[3]=0; st_chary[3]=0;
if (gs->st_so_uid[3]==0)
{
  gs->st_so_uid[3]=ACT_OPEN; gs->st_scr_id[3]=ACT_OPEN;
};
// kitchen door closed
StrCpy(st_desc+(3*SO_MAX_DESC), "Kitchen Door");
StrCpy(st_scr_msg+(3*SO_MAX_SMSG),"");

st_width[4]=90; st_height[4]=182;
st_charx[4]=0; st_chary[4]=0;
if (gs->st_so_uid[4]==0)
{
  gs->st_so_uid[4]=ACT_CLOSE; gs->st_scr_id[4]=ACT_CLOSE;
};
// kitchen door open
StrCpy(st_desc+(4*SO_MAX_DESC), "Kitchen Door");
StrCpy(st_scr_msg+(4*SO_MAX_SMSG),"");


class CSound {
  U8 signature[8];
  U32 *data;
  I64 len;
};

class @sound {
  CSound *(*Load)(U8 * filename);
  U64 func_addr[16];
};

@sound Sound;

CSound *@sound_load(U8 *filename) {
  if (!filename || !FileFind(filename)) {
    PrintErr("Sound file not found.\n");
    return NULL;
  }
  CSound *sound = CAlloc(sizeof(CSound));
  StrCpy(&sound->signature, "CSound");
  return sound;
}

Sound.Load = &@sound_load;
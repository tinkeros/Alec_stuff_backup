#define FS_TYPE_UNSUPPORTED -1
#define FS_TYPE_SYSTEM 0
#define FS_TYPE_REDSEA 1
#define FS_TYPE_9P 2

#define DE_TYPE_FILE 0
#define DE_TYPE_DIR 1

class @dir_entry {
  U8 mode;
  U8 type;
  U32 atime;
  U32 mtime;
  U64 size;
  U8 name[255];
  U8 uid[255];
  U8 gid[255];
  @dir_entry *next;
};

extern Bool @plan9fs_file_find(U8 *path);
extern @dir_entry *@plan9fs_get_files(U8 *path);
extern U8 *@plan9fs_read_file(U8 *path, I64 *size);
extern I64 @plan9fs_write_file(U8 *path, U64 buffer, I64 size);

class @filesystem {
  I64 root_fs_type;
  @dir_entry (*GetFiles)(U8 * path);
  U8 *(*GetFileExtension)(U8 * path);
  U0 (*Init)();
  Bool (*PathExists)(U8 * path);
  U8 *(*ReadFile)(U8 * path, I64 * size);
  I64 *(*WriteFile)(U8 * path, U64 buffer, I64 size);
};

@filesystem FileSystem;

U8 *@filesystem_resolve_path(U8 *path) {
  U8 *abs_path = CAlloc(StrLen(path));
  I64 argc;
  I64 i;
  I64 pos = 0;
  U8 **argv;
  U8 **outv;
  U8 *path_cpy = StrNew(path);
  argv = String.Split(path_cpy, '/', &argc);
  outv = CAlloc(sizeof(U64) * argc);

  for (i = 0; i < argc; i++) {
    if (!(!StrCmp(argv[i], ".") || !StrCmp(argv[i], "") ||
          !StrCmp(argv[i], ".."))) {
      outv[pos] = argv[i];
      pos++;
    }
    if (!StrCmp(argv[i], "..")) {
      pos = Max(0, pos - 1);
    }
  }
  for (i = 0; i < pos; i++)
    String.Append(abs_path, "/%s", outv[i]);
  Free(path_cpy);
  Free(outv);
  if (abs_path[StrLen(abs_path) - 1] == '/')
    abs_path[StrLen(abs_path) - 1] = NULL;
  if (!StrLen(abs_path))
    StrCpy(abs_path, "/");
  return abs_path;
}

I64 @filesystem_get_type(U8 *path) {
  if (!MemCmp(path, "/mnt/redsea/", 12) && StrLen(path) > 12)
    return FS_TYPE_REDSEA;
  if (!MemCmp(path, "/sys/", 5))
    return FS_TYPE_SYSTEM;
  return FileSystem.root_fs_type;
}

@dir_entry *@filesystem_get_files_9p(U8 *path) {
  return @plan9fs_get_files(path);
}

@dir_entry *@filesystem_get_files_redsea(U8 *path) {
  CDirEntry *de = FilesFind(path);
  CDirEntry *tmpde = NULL;
  @dir_entry *entries = NULL;
  @dir_entry *entry = NULL;
  @dir_entry *new = NULL;
  if (de) {
    entries = CAlloc(sizeof(@dir_entry));
    entry = entries;
    tmpde = de;
    while (tmpde) {
      new = CAlloc(sizeof(@dir_entry));
      entry->next = new;

      StrCpy(&new->name, &tmpde->name);
      StrCpy(&new->uid,
             "templeos"); // No file ownership in TempleOS
      StrCpy(&new->gid,
             "templeos"); // No file ownership in TempleOS
      new->size = tmpde->size;
      new->type = T(IsDir(tmpde->full_name), 1, 0);

      entry = new;
      tmpde = tmpde->next;
    }
    DirTreeDel(de);
    return entries;
  }
  return NULL;
}

@dir_entry *@filesystem_get_files(U8 *path) {
  if (!path)
    return NULL;
  U8 buf[512];
  I64 type = @filesystem_get_type(path);
  switch (type) {
  case FS_TYPE_SYSTEM:
    SysHlt;
    break;
  case FS_TYPE_REDSEA:
    StrPrint(&buf, "%c:%s", ToUpper(path[12]), path + 13);
    if (buf[StrLen(&buf) - 1] == ':')
      buf[StrLen(&buf)] = '/';
    if (buf[StrLen(&buf) - 1] == '/')
      buf[StrLen(&buf)] = '.';
    return @filesystem_get_files_redsea(&buf);
    break;
  case FS_TYPE_9P:
    return @filesystem_get_files_9p(path);
    break;
  default:
    break;
  }
  return NULL;
}

U8 *@filesystem_get_file_extension(U8 *path) {
  return (StrLastOcc(path, ".") + 1);
}

Bool @filesystem_path_exists(U8 *opath) {
  if (!opath)
    return FALSE;
  U8 buf[512];
  U8 *path = @filesystem_resolve_path(opath);
  I64 type = @filesystem_get_type(path);
  switch (type) {
  case FS_TYPE_SYSTEM:
    SysHlt;
    break;
  case FS_TYPE_REDSEA:
    StrPrint(&buf, "%c:%s", ToUpper(path[12]), path + 13);
    if (buf[StrLen(&buf) - 1] == ':')
      buf[StrLen(&buf)] = '/';
    if (buf[StrLen(&buf) - 1] == '/')
      buf[StrLen(&buf)] = '.';
    Free(path);
    return FileFind(&buf);
    break;
  case FS_TYPE_9P:
    Free(path);
    return @plan9fs_file_find(path);
    break;
  default:
    break;
  }
  return NULL;
}

U8 *@filesystem_read_file(U8 *path, I64 *size) {
  if (!path)
    return FALSE;
  U8 buf[512];
  I64 type = @filesystem_get_type(path);
  switch (type) {
  case FS_TYPE_SYSTEM:
    SysHlt;
    break;
  case FS_TYPE_REDSEA:
    StrPrint(&buf, "%c:%s", ToUpper(path[12]), path + 13);
    return FileRead(&buf, size);
    break;
  case FS_TYPE_9P:
    return @plan9fs_read_file(path, size);
    break;
  default:
    break;
  }
  return NULL;
}

I64 @filesystem_write_file(U8 *path, U8 *buffer, I64 size) {
  if (!path || !buffer || !size)
    return FALSE;
  U8 buf[512];
  I64 type = @filesystem_get_type(path);
  switch (type) {
  case FS_TYPE_SYSTEM:
    SysHlt;
    break;
  case FS_TYPE_REDSEA:
    StrPrint(&buf, "%c:%s", ToUpper(path[12]), path + 13);
    return FileWrite(&buf, buffer, size);
    break;
  case FS_TYPE_9P:
    return @plan9fs_write_file(path, buffer, size);
    break;
  default:
    break;
  }
  return NULL;
}

FileSystem.GetFiles = &@filesystem_get_files;
FileSystem.GetFileExtension = &@filesystem_get_file_extension;
FileSystem.PathExists = &@filesystem_path_exists;
FileSystem.ReadFile = &@filesystem_read_file;
FileSystem.WriteFile = &@filesystem_write_file;

"filesystem ";
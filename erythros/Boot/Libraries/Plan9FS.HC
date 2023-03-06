#define P9_TLERROR 6
#define P9_RLERROR 7
#define P9_TSTATFS 8
#define P9_RSTATFS 9

#define P9_TLOPEN 12
#define P9_RLOPEN 13
#define P9_TLCREATE 14
#define P9_RLCREATE 15
#define P9_TSYMLINK 16
#define P9_RSYMLINK 17
#define P9_TMKNOD 18
#define P9_RMKNOD 19
#define P9_TRENAME 20
#define P9_RRENAME 21
#define P9_TREADLINK 22
#define P9_RREADLINK 23
#define P9_TGETATTR 24
#define P9_RGETATTR 25
#define P9_TSETATTR 26
#define P9_RSETATTR 27

#define P9_TXATTRWALK 30
#define P9_RXATTRWALK 31
#define P9_TXATTRCREATE 32
#define P9_RXATTRCREATE 33

#define P9_TREADDIR 40
#define P9_RREADDIR 41

#define P9_TFSYNC 50
#define P9_RFSYNC 51
#define P9_TLOCK 52
#define P9_RLOCK 53
#define P9_TGETLOCK 54
#define P9_RGETLOCK 55

#define P9_TLINK 70
#define P9_RLINK 71
#define P9_TMKDIR 72
#define P9_RMKDIR 73
#define P9_TRENAMEAT 74
#define P9_RRENAMEAT 75
#define P9_TUNLINKAT 76
#define P9_RUNLINKAT 77

#define P9_TVERSION 100
#define P9_RVERSION 101
#define P9_TAUTH 102
#define P9_RAUTH 103
#define P9_TATTACH 104
#define P9_RATTACH 105
#define P9_TERROR 106
#define P9_RERROR 107
#define P9_TFLUSH 108
#define P9_RFLUSH 109
#define P9_TWALK 110
#define P9_RWALK 111
#define P9_TOPEN 112
#define P9_ROPEN 113
#define P9_TCREATE 114
#define P9_RCREATE 115
#define P9_TREAD 116
#define P9_RREAD 117
#define P9_TWRITE 118
#define P9_RWRITE 119
#define P9_TCLUNK 120
#define P9_RCLUNK 121
#define P9_TREMOVE 122
#define P9_RREMOVE 123
#define P9_TSTAT 124
#define P9_RSTAT 125
#define P9_TWSTAT 126
#define P9_RWSTAT 127

#define P9_NOTAG 0xFFFF
#define P9_NOFID 0xFFFF
#define P9_NONUNAME 0xFFFF

#define P9_MAXWELEM 16
#define P9_MSIZE_DEFAULT 8216
#define P9_IOHDRSZ 24
#define P9_READDIRHDRSZ 24
#define P9_READDIRMAXSIZE 8168
#define P9_RBUF_SIZE 16384

#define P9_CHUNK_SIZE 1024

#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR 2
#define O_TRUNC 0x10

#define P9_ISDIR 0x80000000

class @plan9fs_header {
  U32 size;
  U8 type;
  U16 tag;
};

class @plan9fs_qid {
  U8 type;
  U32 version;
  U64 path;
};

class @plan9fs_str {
  U16 len;
  U8 *str;
}

class @plan9fs_tversion : @plan9fs_header {
  U32 msize;
  @plan9fs_str version;
}

class @plan9fs_rversion : @plan9fs_header {
  U32 msize;
  @plan9fs_str version;
}

class @plan9fs_tattach : @plan9fs_header {
  U32 fid;
  U32 afid;
  @plan9fs_str uname;
  @plan9fs_str aname;
};

class @plan9fs_rattach : @plan9fs_header {
  @plan9fs_qid qid;
};

class @plan9fs_tclunk : @plan9fs_header {
  U32 fid;
};

class @plan9fs_rclunk : @plan9fs_header{};

class @plan9fs_tcreate : @plan9fs_header {
  U32 fid;
  @plan9fs_str name;
  U32 perm;
  U8 mode;
};

class @plan9fs_rcreate : @plan9fs_header {
  @plan9fs_qid qid;
  U32 iounit;
};

class @plan9fs_topen : @plan9fs_header {
  U32 fid;
  U8 mode;
};

class @plan9fs_ropen : @plan9fs_header {
  @plan9fs_qid qid;
  U32 iounit;
};

class @plan9fs_tread : @plan9fs_header {
  U32 fid;
  U64 offset;
  U32 count;
};

class @plan9fs_rread : @plan9fs_header {
  U32 count;
  U8 *data;
};

class @plan9fs_twrite : @plan9fs_header {
  U32 fid;
  U64 offset;
  U32 count;
  U8 *data;
};

class @plan9fs_rwrite : @plan9fs_header {
  U32 count;
};

class @plan9fs_tstat : @plan9fs_header {
  U32 fid;
};

class @plan9fs_rstat : @plan9fs_header {
  U16 paramsz;
  U16 sdlen;
  U16 stattype;
  U32 dev;
  @plan9fs_qid qid;
  U32 mode;
  U32 atime;
  U32 mtime;
  U64 len;
  @plan9fs_str name;
  @plan9fs_str uid;
  @plan9fs_str gid;
  @plan9fs_str muid;
};

class @plan9fs_rdir_entry {
  U16 size;
  U16 type;
  U32 dev;
  @plan9fs_qid qid;
  U32 mode;
  U32 atime;
  U32 mtime;
  U64 len;
  U16 fnchars;
};

class @plan9fs_tstatfs : @plan9fs_header {
  U32 fid;
};

class @plan9fs_rstatfs : @plan9fs_header {
  U32 fstype;
  U32 bsize;
  U64 blocks;
  U64 bfree;
  U64 bavail;
  U64 files;
  U64 ffree;
  U64 fsid;
  U32 namelen;
};

class @plan9fs_twalk : @plan9fs_header {
  U32 fid;
  U32 newfid;
  U16 nwname;
  @plan9fs_str wnames[P9_MAXWELEM];
};

class @plan9fs_rwalk : @plan9fs_header {
  U16 nwqid;
  @plan9fs_qid wqids[P9_MAXWELEM];
};

I64 @plan9fs_marshall_and_incr_str(U64 buf, @plan9fs_str *str) {
  I64 res = 0;
  *buf(U16 *) = str->len;
  buf += sizeof(U16);
  res += sizeof(U16);
  MemCpy(buf, str->str, StrLen(str->str));
  buf += StrLen(str->str);
  res += StrLen(str->str);
  return res;
}

U0 @plan9fs_marshall_payload(U64 buf, @plan9fs_header *msg) {
  MemSet(buf, 0, 16384);
  I64 i;
  switch (msg->type) {
  case P9_TATTACH:
    msg(@plan9fs_tattach *)->uname.len =
        StrLen(msg(@plan9fs_tattach *)->uname.str);
    msg(@plan9fs_tattach *)->aname.len =
        StrLen(msg(@plan9fs_tattach *)->aname.str);

    msg->tag = 0;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 fid;
    msg->size += sizeof(U32); // U32 afid;
    msg->size +=
        sizeof(U16) +
        StrLen(msg(@plan9fs_tattach *)->uname.str); // @plan9fs_str uname;
    msg->size +=
        sizeof(U16) +
        StrLen(msg(@plan9fs_tattach *)->aname.str); // @plan9fs_str aname;

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_tattach *)->fid; // U32 fid;
    buf += sizeof(U32);

    *buf(U32 *) = msg(@plan9fs_tattach *)->afid; // U32 afid;
    buf += sizeof(U32);

    buf += @plan9fs_marshall_and_incr_str(buf, &msg(@plan9fs_tattach *)->uname);
    buf += @plan9fs_marshall_and_incr_str(buf, &msg(@plan9fs_tattach *)->aname);

    break;
  case P9_TCLUNK:
    msg->tag = 0;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 fid;

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_tclunk *)->fid; // U32 fid;
    buf += sizeof(U32);
    break;
  case P9_TCREATE:
    msg(@plan9fs_tcreate *)->name.len =
        StrLen(msg(@plan9fs_tcreate *)->name.str);

    msg->tag = 0;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 fid;
    msg->size +=
        sizeof(U16) +
        StrLen(msg(@plan9fs_tcreate *)->name.str); // @plan9fs_str name;
    msg->size += sizeof(U32);                      // U32 perm;
    msg->size += sizeof(U8);                       // U8 mode;

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_tcreate *)->fid; // U32 fid;
    buf += sizeof(U32);

    buf += @plan9fs_marshall_and_incr_str(buf, &msg(@plan9fs_tcreate *)->name);

    *buf(U32 *) = msg(@plan9fs_tcreate *)->perm; // U32 perm;
    buf += sizeof(U32);

    *buf(U8 *) = msg(@plan9fs_tcreate *)->mode; // U8 mode;
    buf += sizeof(U8);
    break;
  case P9_TOPEN:
    msg->tag = 0;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 fid;
    msg->size += sizeof(U8);  // U8 mode;

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_topen *)->fid; // U32 fid;
    buf += sizeof(U32);

    *buf(U8 *) = msg(@plan9fs_topen *)->mode; // U8 mode;
    buf += sizeof(U8);
    break;
  case P9_TREAD:
    msg->tag = 0;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 fid;
    msg->size += sizeof(U64); // U64 offset;
    msg->size += sizeof(U32); // U32 count;

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_tread *)->fid; // U32 fid;
    buf += sizeof(U32);

    *buf(U64 *) = msg(@plan9fs_tread *)->offset; // U8 mode;
    buf += sizeof(U64);

    *buf(U32 *) = msg(@plan9fs_tread *)->count; // U32 fid;
    buf += sizeof(U32);
    break;
  case P9_TWRITE:
    msg->tag = 0;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32);                   // U32 fid;
    msg->size += sizeof(U64);                   // U64 offset;
    msg->size += sizeof(U32);                   // U32 count;
    msg->size += msg(@plan9fs_twrite *)->count; // length of data

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_twrite *)->fid; // U32 fid;
    buf += sizeof(U32);

    *buf(U64 *) = msg(@plan9fs_twrite *)->offset; // U8 mode;
    buf += sizeof(U64);

    *buf(U32 *) = msg(@plan9fs_twrite *)->count; // U32 fid;
    buf += sizeof(U32);

    MemCpy(buf, msg(@plan9fs_twrite *)->data, msg(@plan9fs_twrite *)->count);
    break;
  case P9_TSTAT:
    msg->tag = 0;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 fid;

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_tattach *)->fid; // U32 fid;
    buf += sizeof(U32);
    break;
  case P9_TVERSION:
    msg(@plan9fs_tversion *)->msize = P9_MSIZE_DEFAULT;
    msg(@plan9fs_tversion *)->version.str = "9P2000";
    msg(@plan9fs_tversion *)->version.len =
        StrLen(msg(@plan9fs_tversion *)->version.str);
    msg->tag = P9_NOTAG;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 msize;
    msg->size +=
        sizeof(U16) +
        StrLen(msg(@plan9fs_tversion *)->version.str); // @plan9fs_str version;

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_tversion *)->msize; // U32 msize;
    buf += sizeof(U32);

    buf +=
        @plan9fs_marshall_and_incr_str(buf, &msg(@plan9fs_tversion *)->version);

    break;
  case P9_TWALK:
    for (i = 0; i < msg(@plan9fs_twalk *)->nwname; i++)
      msg(@plan9fs_twalk *)->wnames[i].len =
          StrLen(msg(@plan9fs_twalk *)->wnames[i].str);
    msg->tag = P9_NOTAG;
    msg->size = sizeof(@plan9fs_header);

    msg->size += sizeof(U32); // U32 fid;
    msg->size += sizeof(U32); // U32 newfid;
    msg->size += sizeof(U16); // U32 nwname;
    for (i = 0; i < msg(@plan9fs_twalk *)->nwname; i++)
      msg->size += sizeof(U16) + StrLen(msg(@plan9fs_twalk *)->wnames[i].str);

    MemCpy(buf, msg, sizeof(@plan9fs_header));
    buf += sizeof(@plan9fs_header);

    *buf(U32 *) = msg(@plan9fs_twalk *)->fid; // U32 fid;
    buf += sizeof(U32);

    *buf(U32 *) = msg(@plan9fs_twalk *)->newfid; // U32 newfid;
    buf += sizeof(U32);

    *buf(U16 *) = msg(@plan9fs_twalk *)->nwname; // U32 nwname;
    buf += sizeof(U16);

    for (i = 0; i < msg(@plan9fs_twalk *)->nwname; i++)
      buf += @plan9fs_marshall_and_incr_str(buf,
                                            &msg(@plan9fs_twalk *)->wnames[i]);

    break;
  default:
    System.Log(
        Fs, "Plan9FS: Unsupported message type in @plan9fs_marshall_payload\n");
    break;
  }
  Free(msg);
}

U0 @plan9fs_unmarshall_payload(U8 *buf, @plan9fs_header *msg) {
  I64 pos = 0;
  switch (msg->type) {
  case 0:
  default:
    System.Log(
        Fs,
        "Plan9FS: Unsupported message type in @plan9fs_unmarshall_payload\n");
    break;
  }
}

class @plan9fs {
  I64 sock;
  I64 last_fd;
  U8 host[255];
  I64 port;
  Bool attached;
  U0 (*Init)();
};

@plan9fs Plan9FS;

Bool @plan9fs_send_tclunk(I64 fd) {
  I64 err;
  I64 rval = 0;
  @plan9fs_header *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_tclunk *tclunk = CAlloc(sizeof(@plan9fs_tclunk));
  tclunk->type = P9_TCLUNK;
  tclunk->fid = fd;

  @plan9fs_marshall_payload(msg, tclunk);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RCLUNK)
      rval = 0;
    else
      rval = -1;
  } else
    rval = -1;
  Free(resp);
  return rval;
}

I64 @plan9fs_send_twalk(U8 *path) {
  I64 err;
  I64 rval = 0;
  @plan9fs_header *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  U8 *str = StrNew(path);
  U8 *str2 = str;
  I64 i;
  I64 cnt;
  U8 **s = String.Split(str2, '/', &cnt);

  if (!cnt) {
    Free(resp);
    Free(msg);
    Free(str);
    return -1;
  }

  Plan9FS.last_fd++;

  @plan9fs_twalk *twalk = CAlloc(sizeof(@plan9fs_twalk));
  twalk->type = P9_TWALK;
  twalk->fid = 3;
  twalk->newfid = Plan9FS.last_fd;
  twalk->nwname = cnt - 1;
  for (i = 0; i < cnt - 1; i++)
    twalk->wnames[i].str = s[i];

  @plan9fs_marshall_payload(msg, twalk);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RWALK)
      rval = Plan9FS.last_fd;
    else
      rval = -1;
  } else
    rval = -1;
  Free(str);
  Free(resp);
  return rval;
}

Bool @plan9fs_send_tstat(I64 fd, I64 *size = NULL) {
  I64 err;
  I64 rval = 0;
  @plan9fs_rstat *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_tstat *tstat = CAlloc(sizeof(@plan9fs_tstat));
  tstat->type = P9_TSTAT;
  tstat->fid = fd;

  @plan9fs_marshall_payload(msg, tstat);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RSTAT) {
      if (size)
        size[0] = resp->len;
      rval = 0;
    } else
      rval = -1;
  } else
    rval = -1;
  Free(resp);
  return rval;
}

Bool @plan9fs_send_tcreate(I64 fd, U8 mode, U8 *name) {
  I64 err;
  I64 rval = 0;
  @plan9fs_header *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_tcreate *tcreate = CAlloc(sizeof(@plan9fs_tcreate));
  tcreate->type = P9_TCREATE;
  tcreate->fid = fd;
  tcreate->perm = 0x6 + 0x6 << 3 + 0x6 << 6;
  tcreate->mode = mode;
  tcreate->name.str = name;

  @plan9fs_marshall_payload(msg, tcreate);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RCREATE)
      rval = 0;
    else
      rval = -1;
  } else
    rval = -1;
  Free(resp);
  return rval;
}

Bool @plan9fs_send_topen(I64 fd, U8 mode) {
  I64 err;
  I64 rval = 0;
  @plan9fs_header *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_topen *topen = CAlloc(sizeof(@plan9fs_topen));
  topen->type = P9_TOPEN;
  topen->fid = fd;
  topen->mode = mode;

  @plan9fs_marshall_payload(msg, topen);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_ROPEN)
      rval = 0;
    else
      rval = -1;
  } else
    rval = -1;
  Free(resp);
  return rval;
}

U8 *@plan9fs_send_tread(I64 fd, I64 offset, I64 count) {
  I64 err;
  @plan9fs_rread *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_tread *tread = CAlloc(sizeof(@plan9fs_tread));
  tread->type = P9_TREAD;
  tread->fid = fd;
  tread->offset = offset;
  tread->count = count;

  @plan9fs_marshall_payload(msg, tread);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RREAD)
      return resp;
    else
      return 0;
  } else
    return 0;
}

U8 *@plan9fs_send_twrite(I64 fd, I64 offset, I64 count, U8 *data) {
  I64 err;
  I64 rval = 0;
  @plan9fs_header *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_twrite *twrite = CAlloc(sizeof(@plan9fs_twrite));
  twrite->type = P9_TWRITE;
  twrite->fid = fd;
  twrite->offset = offset;
  twrite->count = count;
  twrite->data = data;

  @plan9fs_marshall_payload(msg, twrite);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RWRITE)
      rval = 0;
    else
      rval = -1;
  } else
    rval = -1;
  Free(resp);
  return rval;
}

Bool @plan9fs_file_find(U8 *path) {
  I64 fd;
  I64 err;
  fd = @plan9fs_send_twalk(path);
  if (fd < 3)
    return FALSE; // bad fd
  err = @plan9fs_send_tstat(fd);
  if (err)
    return FALSE; // bad fd
  @plan9fs_send_tclunk(fd);
  return TRUE;
}

@dir_entry *@plan9fs_get_files(U8 *path) {
  I64 fd;
  I64 err;
  U64 buf = NULL;
  U64 obuf = NULL;
  @plan9fs_rdir_entry *plan9fs_entry;
  fd = @plan9fs_send_twalk(path);
  if (fd < 3)
    return NULL; // bad fd
  err = @plan9fs_send_tstat(fd);
  if (err)
    return NULL; // bad fd
  err = @plan9fs_send_topen(fd, O_RDONLY);
  if (err)
    return NULL; // bad fd
  buf = @plan9fs_send_tread(fd, 0, P9_READDIRMAXSIZE);
  if (!buf)
    return NULL; // bad read response

  obuf = buf;
  buf += sizeof(@plan9fs_header);
  buf += sizeof(U32);

  @dir_entry *entries = NULL;
  @dir_entry *entry = NULL;
  @dir_entry *new = NULL;
  entries = CAlloc(sizeof(@dir_entry));
  entry = entries;
  U16 name_len;
  U16 uid_len;
  U16 gid_len;
  U16 lmid_len;

  plan9fs_entry = buf;
  while (plan9fs_entry->fnchars) {
    new = CAlloc(sizeof(@dir_entry));
    entry->next = new;
    new->type = T(plan9fs_entry->mode & P9_ISDIR == P9_ISDIR, 1, 0);

    buf = &plan9fs_entry->fnchars;
    MemCpy(&name_len, buf, 2);
    buf += sizeof(U16);

    MemCpy(&new->name, buf, name_len);
    buf += name_len;
    MemCpy(&uid_len, buf, 2);
    buf += sizeof(U16);

    MemCpy(&new->uid, buf, uid_len);
    buf += uid_len;
    MemCpy(&gid_len, buf, 2);
    buf += sizeof(U16);

    MemCpy(&new->gid, buf, gid_len);
    buf += gid_len;
    lmid_len = *buf(U16 *);
    buf += sizeof(U16);

    new->size = plan9fs_entry->len;

    entry = new;
    plan9fs_entry = buf;
  }
  Free(obuf);
  @plan9fs_send_tclunk(fd);
  return entries;
}

U8 *@plan9fs_read_file(U8 *path, I64 *size) {
  if (!path || !size)
    return NULL;
  I64 fd;
  I64 cnt = 0;
  I64 chunk_size;
  I64 err;
  @plan9fs_rread *rbuf = NULL;
  fd = @plan9fs_send_twalk(path);
  if (fd < 3)
    return NULL; // bad fd
  err = @plan9fs_send_tstat(fd, size);
  if (err)
    return NULL; // bad fd
  err = @plan9fs_send_topen(fd, O_RDONLY);
  if (err)
    return NULL; // bad fd
  U64 buf = CAlloc(size[0]);
  while (cnt < size[0]) {
    chunk_size =
        T((size[0] - cnt < P9_CHUNK_SIZE), size[0] - cnt, P9_CHUNK_SIZE);
    rbuf = @plan9fs_send_tread(fd, cnt, chunk_size);
    MemCpy(buf + cnt, &rbuf->data, chunk_size);
    cnt += chunk_size;
    Busy(50);
  }
  @plan9fs_send_tclunk(fd);
  return buf;
}

I64 @plan9fs_write_file(U8 *path, U64 buffer, I64 size) {
  if (!path || !size)
    return NULL;
  I64 fd;
  I64 cnt = 0;
  I64 chunk_size;
  I64 err;
  U8 *cpath = StrNew(path);
  StrLastOcc(cpath, "/")[0] = NULL;
  fd = @plan9fs_send_twalk(path);
  if (fd < 3) {
    Free(cpath);
    return NULL; // bad fd
  }
  err = @plan9fs_send_tstat(fd);
  if (err) // File does not exist, create it
  {
    fd = @plan9fs_send_twalk(cpath);
    if (fd < 3) {
      Free(cpath);
      return NULL; // bad fd
    }
    err = @plan9fs_send_tcreate(fd, O_WRONLY, StrLastOcc(path, "/") + 1);
    if (err) {
      Free(cpath);
      return NULL;
    }
  } else // File exists, open it
  {
    err = @plan9fs_send_topen(fd, O_WRONLY | O_TRUNC);
    if (err) {
      Free(cpath);
      return NULL;
    }
  }
  Free(cpath);
  while (cnt < size) {
    chunk_size = T((size - cnt > P9_CHUNK_SIZE), P9_CHUNK_SIZE, size - cnt);
    @plan9fs_send_twrite(fd, cnt, chunk_size, buffer + cnt);
    cnt += chunk_size;
  }
  @plan9fs_send_tclunk(fd);
  return cnt;
};

I64 @plan9fs_send_tattach() {
  I64 err;
  I64 rval = 0;
  @plan9fs_header *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_tattach *tatt = CAlloc(sizeof(@plan9fs_tattach));
  tatt->type = P9_TATTACH;
  tatt->fid = 3;
  tatt->afid = NULL; // who needs authentication, anyway :P
  tatt->uname.str = "root";
  tatt->aname.str = "";
  @plan9fs_marshall_payload(msg, tatt);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);

  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RATTACH)
      rval = 0;
    else
      rval = -1;
  } else
    rval = -1;
  Free(resp);
  return rval;
}

I64 @plan9fs_send_tversion() {
  I64 err;
  I64 rval = 0;
  @plan9fs_header *resp = CAlloc(P9_RBUF_SIZE);
  @plan9fs_header *msg = CAlloc(P9_RBUF_SIZE);

  @plan9fs_tversion *tver = CAlloc(sizeof(@plan9fs_tversion));
  tver->type = P9_TVERSION;
  @plan9fs_marshall_payload(msg, tver);
  send(Plan9FS.sock, msg, msg->size, 0);
  Free(msg);
  err = recv(Plan9FS.sock, resp, P9_RBUF_SIZE, 0);
  if (err > 0) {
    if (resp->type == P9_RVERSION)
      rval = 0;
    else
      rval = -1;
  } else
    rval = -1;
  Free(resp);
  return rval;
}

I64 @plan9fs_attach() {
  Plan9FS.sock = socket(AF_INET, SOCK_STREAM);
  sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons(Plan9FS.port);
  I64 err = Net.ResolveIPv4Address(Plan9FS.host, &addr.sin_addr);
  if (!err) {
    err = connect(Plan9FS.sock, &addr, sizeof(addr));
    if (!err) {
      if (@plan9fs_send_tversion)
        return -3; // Error instead of rversion
      if (@plan9fs_send_tattach)
        return -4; // Error instead of rattach
      Plan9FS.attached = TRUE;
      Plan9FS.last_fd = 3;
      return 0;
    } else
      return -2; // Error in connect
  } else
    return -1; // Error in Net.ResolveIPv4Address
}

U0 @plan9fs_init() {
  I64 err;
  StrPrint(&Plan9FS.host, "%d.%d.%d.%d", ipv4_router_addr.u8[3],
           ipv4_router_addr.u8[2], ipv4_router_addr.u8[1],
           ipv4_router_addr.u8[0]);
  Plan9FS.port = 5640;
  err = @plan9fs_attach;
  System.text_mode = TRUE;
  "Mounting remote filesystem on /\n";
  if (err) {
    System.Log(Fs, "ERROR: Cannot attach remote filesystem: %d", err);
    "PANIC! Cannot attach remote filesystem.\n";
    SysHlt;
    return;
  } else {
    System.Log(Fs, "Mounted remote filesystem on / - %s", &Plan9FS.host);
    System.text_mode = FALSE;
  }
}

Plan9FS.Init = &@plan9fs_init;

U0 @filesystem_init() {
  FileSystem.root_fs_type = FS_TYPE_9P;
  while (!my_ip)
    Sleep(1);
  Plan9FS.Init();
}

FileSystem.Init = &@filesystem_init;

"plan9fs ";
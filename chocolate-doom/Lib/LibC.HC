#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

U8 *f_whence[3];
f_whence[0] = "SEEK_SET";
f_whence[1] = "SEEK_CUR";
f_whence[2] = "SEEK_END";

class FILE {
  U8 *filename;
  U8 *data;
  U8 *mode;
  I64 descriptor;
  I64 size;
  I64 offset;
  I64 pos;
};

class va_list {
  U32 gp_offset;
  U32 fp_offset;
  U8 *overflow_arg_area;
  U8 *reg_save_area;
};

FILE *iwad_fp = NULL;

#define PUSH_SYSV_REGS                                                         \
  asm {PUSH RCX PUSH RDX PUSH RBX PUSH RBP PUSH RSI PUSH RDI PUSH R8 PUSH R9 PUSH   \
      R10 PUSH R11 PUSH R12 PUSH R13 PUSH R14 PUSH R15}
#define POP_SYSV_REGS                                                          \
  asm {POP R15 POP R14 POP R13 POP R12 POP R11 POP R10 POP R9 POP R8 POP RDI POP    \
      RSI POP RBP POP RBX POP RDX POP RCX}
#define MOV_ANS_RAX asm {MOV [&ans], RAX}
#define MOV_P0_RDI asm {MOV [&p0], RDI}
#define MOV_P1_RSI asm {MOV [&p1], RSI}
#define MOV_P2_RDX asm {MOV [&p2], RDX}
#define MOV_P3_RCX asm {MOV [&p3], RCX}
#define MOV_P4_R8 asm {MOV [&p4], R8}
#define MOV_P5_R9 asm {MOV [&p5], R9}
#define GET_SYSV_ARGS                                                          \
  MOV_P0_RDI MOV_P1_RSI MOV_P2_RDX MOV_P3_RCX MOV_P4_R8 MOV_P5_R9

I64 new_fd = 3;
I64 p0, p1, p2, p3, p4, p5;
I64 elf_argc;
U8 **elf_argv;

#define stdin 0
#define stdout 1
#define stderr 2

asm {
_ELF_CALL::
        PUSH    RBP
        MOV     RBP,RSP
        MOV     RAX,U64 SF_ARG1[RBP]
        MOV     RDI,U64 SF_ARG2[RBP]
        MOV     RSI,U64 SF_ARG3[RBP]
        TEST    RAX,RAX
        JZ      @@05
        CALL    RAX
@@05:   POP     RBP
        RET1    8
}

U0 _main() {
  MOV_P0_RDI
  CallInd(_ELF_CALL, p0, elf_argc, elf_argv);
  MOV_ANS_RAX
  throw('end', TRUE);
}

U0 _exit() {
  MOV_ANS_RAX
  throw('end', TRUE);
}

U0 convert_format_string(U8 *s) {
  while (*s) {
    switch (*s) {
    case '%':
      if (s[1] == 'i')
        s[1] = 'd';
      if (s[1] == 'p')
        s[1] = 'x';
      break;
    }
    s++;
  }
}

U0 putc() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: putc('%c', %d)\n", p0, p1);
  switch (p1) {
  case stdout:
  case stderr:
    PutChars(p0);
    break;
  default:
    PrintErr("putc: not yet implemented\n");
    break;
  }
  POP_SYSV_REGS
}

U8 *@calloc(I64 nitems, I64 size) {
  return CAlloc(nitems * size, Fs->code_heap);
}

U0 calloc() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: calloc(%d, %d)\n", p0, p1);
  @calloc(p0, p1);
  POP_SYSV_REGS
}

U8 *@getenv(U8 *str) {
  if (!StrCmp(str, "HOME"))
    return "B:";
  return NULL;
}

U0 getenv() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: getenv(\"%s\")\n", p0);
  @getenv(p0);
  POP_SYSV_REGS
}

I64 @fileno(FILE *f) {
  debug_print("fileno: 0x%08x has fd %d\n", f, f->descriptor);
  return f->descriptor;
}

U0 fileno() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: fileno(0x%08x)\n", p0);
  @fileno(p0);
  POP_SYSV_REGS
}

I64 @fflush(FILE *f) {
  no_warn f;
  return NULL;
}

U0 fflush() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: fflush(0x%08x)\n", p0);
  @fflush(p0);
  POP_SYSV_REGS
}

I64 @fclose(FILE *f) {
  if (!f)
    return NULL;
  if (f->data)
    Free(f->data);
  if (f->filename)
    Free(f->filename);
  if (f->mode)
    Free(f->mode);
  Free(f);
  return NULL;
}

U0 fclose() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: fclose(%d)\n", p0(FILE *)->descriptor);
  @fclose(p0);
  POP_SYSV_REGS
}

FILE *@fopen(U8 *filename, U8 *mode) {
  U64 file_data;
  FILE *f;
  if (!StrCmp(mode, "r") || !StrCmp(mode, "r+") || !StrCmp(mode, "rb")) {
    if (!FileFind(filename))
      return NULL;
    f = MAlloc(sizeof(FILE), Fs->code_heap);
    f->filename = StrNew(filename);
    file_data = FileRead(filename, &f->size);
    f->data = CAlloc(f->size, Fs->code_heap);
    // MemCpy(f->data, file_data, f->size);
    MemCpy(f->data, file_data, f->size);
    f->descriptor = new_fd++;
    f->mode = StrNew(mode);
    debug_print("fopen: got file descriptor %d\n", f->descriptor);
    return f;
  }
}

U0 fopen() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: fopen(\"%s\",\"%s\")\n", p0, p1);
  @fopen(p0, p1);
  POP_SYSV_REGS
}

I64 @fread(U8 *ptr, I64 size, I64 nmemb, FILE *f) {
  MemCpy(ptr, f->data + f->pos, (size * nmemb));

  //"fread @ pos, size: %d, %d\n", f->pos, (size * nmemb);
  // D(ptr, Min(256, size * nmemb));

  f->pos += (size * nmemb);
  // if (debug.enabled)
  // debug_print("fread: pos: %d\n", f->pos);
  return (size * nmemb);
}

U0 efread() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called fread(0x%08x, %d, %d, %d)\n", p0, p1, p2,
              p3(FILE *)->descriptor);
  @fread(p0, p1, p2, p3);
  POP_SYSV_REGS
}

U0 free() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called free(0x%08x)\n", p0);
  Free(p0);
  POP_SYSV_REGS
}

I64 @fseek(FILE *f, I64 off, I64 whence) {
  switch (whence) {
  case SEEK_SET:
    f->pos = off;
    break;
  case SEEK_CUR:
    f->pos += off;
    break;
  case SEEK_END:
    f->pos = f->size + off;
    break;
  }
  return NULL;
}

U0 fseek() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: fseek(%d, %d, %s)\n", p0(FILE *)->descriptor, p1,
              f_whence[p2]);
  @fseek(p0, p1, p2);
  POP_SYSV_REGS
}

I64 @ftell(FILE *f) {
  debug_print("ftell: %d\n", f->pos);
  return f->pos;
}

U0 ftell() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: ftell(%d)\n", p0(FILE *)->descriptor);
  @ftell(p0);
  POP_SYSV_REGS
}

I64 @fwrite(U8 *ptr, I64 size, I64 nmemb, FILE *f) {
  return (size * nmemb);
  MemCpy(f->data + f->pos, ptr, (size * nmemb));
  if (debug.enabled)
    D(f->data + f->pos, Min(256, size * nmemb));
  f->pos += (size * nmemb);
  debug_print("fwrite: pos: %d\n", f->pos);
  return (size * nmemb);
}

U0 fwrite() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called fwrite(0x%08x, %d, %d, 0x%08x)\n", p0, p1, p2,
              p3(FILE *)->descriptor);
  if (p3(FILE *)->descriptor(U64) >= 0x100000000) {
    // mock for stderr problem
    PutS(p0);
    "\n";
  }
  if (p3(FILE *)->descriptor(U64) < 0x100000000)
    @fwrite(p0, p1, p2, p3);
  POP_SYSV_REGS
}

Bool @isatty(I64 fd) {
  no_warn fd;
  return FALSE;
}

U0 isatty() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: isatty(%d)\n", p0);
  @isatty(p0);
  POP_SYSV_REGS
}

U64 @malloc(I64 size) {
  U64 ptr = NULL;
  ptr = MAlloc(p0, Fs->code_heap);
  debug_print("malloc(%d), result: 0x%08x\n", size, ptr);
  return ptr;
}

U0 malloc() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: malloc(%d)\n", p0);
  @malloc(p0);
  POP_SYSV_REGS
}

U0 memcpy() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: memcpy(0x%08x, 0x%08x, %d)\n", p0, p1, p2);
  MemCpy(p0, p1, p2);
  POP_SYSV_REGS
}

U0 memcmp() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: memcmp(0x%08x, 0x%08x, %d)\n", p0, p1, p2);
  MemCmp(p0, p1, p2);
  POP_SYSV_REGS
}

U0 memset() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: memset(0x%08x, %d, %d)\n", p0, p1, p2);
  // if (debug.counter > 1845140)
  //  PressAKey;
  MemSet(p0, p1, p2);
  POP_SYSV_REGS
}

I64 @mkdir(U8 *path) {
  path = StrNew(path);
  while (path[StrLen(path) - 1] == '/')
    path[StrLen(path) - 1] = NULL;
  CDoc *olddoc = Fs->put_doc;
  CDoc *tmpdoc = DocNew;
  Fs->put_doc = tmpdoc;
  DirMk(path);
  Fs->put_doc = olddoc;
  DocDel(tmpdoc);
  return 0;
}

U0 mkdir() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: mkdir(\"%s\")\n", p0);
  @mkdir(p0);
  POP_SYSV_REGS
}

I64 @open(U8 *path) {
  iwad_fp = @fopen(path, "rb");
  return iwad_fp->descriptor;
}

U0 open() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: open(\"%s\", %d, %d)\n", p0, p1, p2);
  @open(p0);
  POP_SYSV_REGS
}

U0 lseek() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: lseek(%d, %d, %d)\n", p0, p1, p2);
  @fseek(iwad_fp, p1, p2);
  POP_SYSV_REGS
}

U8 *@mmap(I64 fd) {
  no_warn fd;
  MemSetU32(0x4136ae, iwad_fp->data, 1);
  return iwad_fp->data;
}

U0 mmap() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: mmap(0x%08x, %d, %d, %d, %d, %d)\n", p0, p1, p2, p3, p4,
              p5);
  @mmap(p4);
  POP_SYSV_REGS
}

U0 read() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called read(%d, 0x%08x, %d)\n", p0, p1, p2);
  @fread(p1, 1, p2, iwad_fp);
  POP_SYSV_REGS
}

I64 @putchar(I64 ch) {
  if (ch != 0x8)
    PutChars(ch);
  if (ch == 0x8)
    Fs->put_doc->cur_col--;
  return 0;
}

U0 putchar() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: putchar(%d)\n", p0);
  @putchar(p0);
  POP_SYSV_REGS
}

U0 puts() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  PutS(p0);
  "\n";
  POP_SYSV_REGS
}

U8 *@realloc(U8 *ptr, I64 size) {
  U8 *new;
  if (!ptr) {
    new = MAlloc(size, Fs->code_heap);
  } else {
    new = MAlloc(size, Fs->code_heap);
    MemCpy(new, ptr, size);
    Free(ptr);
  }
  return new;
}

U0 realloc() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called realloc(0x%08x, %d)\n", p0, p1);
  @realloc(p0, p1);
  POP_SYSV_REGS
}

U0 strcasecmp() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: strcasecmp(\"%s\",\"%s\")\n", p0, p1);
  StrICmp(p0, p1);
  POP_SYSV_REGS
}

U0 strcmp() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: strcmp(\"%s\",\"%s\")\n", p0, p1);
  StrCmp(p0, p1);
  POP_SYSV_REGS
}

U0 strlen() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: strlen(\"%s\")\n", p0);
  StrLen(p0);
  POP_SYSV_REGS
}

I64 @strncmp(U8 *s1, U8 *s2, I64 n) {
  while (n && *s1 && (*s1 == *s2)) {
    ++s1;
    ++s2;
    --n;
  }
  if (n == 0) {
    return 0;
  } else {
    return (*s1 - *s2);
  }
}

U0 strncmp() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: strncmp(\"%s\", \"%s\", %d)\n", p0, p1, p2);
  @strncmp(p0, p1, p2);
  POP_SYSV_REGS
}
/*
 * This array is designed for mapping upper and lower case letter
 * together for a case independent comparison.  The mappings are
 * based upon ascii character sequences.
 */
U8 @strncasecmp_charmap[256] = {
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b,
    0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
    0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23,
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b,
    0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
    0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73,
    0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b,
    0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
    0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83,
    0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b,
    0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
    0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3,
    0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
    0xc0, 0xe1, 0xe2, 0xe3, 0xe4, 0xc5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb,
    0xec, 0xed, 0xee, 0xef, 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7,
    0xf8, 0xf9, 0xfa, 0xdb, 0xdc, 0xdd, 0xde, 0xdf, 0xe0, 0xe1, 0xe2, 0xe3,
    0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
    0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb,
    0xfc, 0xfd, 0xfe, 0xff};

I64 @strncasecmp(U8 *s1, U8 *s2, I64 n) {
  U64 u1 = 0, u2 = 0;
  for (n == n; n != 0; --n) {
    u1 = *s1++;
    u2 = *s2++;
    if (@strncasecmp_charmap[u1] != @strncasecmp_charmap[u2]) {
      return @strncasecmp_charmap[u1] - @strncasecmp_charmap[u2];
    }
    if (u1 == '\0') {
      return 0;
    }
  }
  return 0;
}

U0 strncasecmp() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: strncasecmp(0x%08x, 0x%08x, %d)\n", p0, p1, p2);
  debug_print("strncasecmp: return value is %d\n", @strncasecmp(p0, p1, p2));
  @strncasecmp(p0, p1, p2);
  POP_SYSV_REGS
}

U8 *@strncpy(U8 *destination, U8 *source, I64 num) {
  // return if no memory is allocated to the destination
  if (destination == NULL) {
    return NULL;
  }

  // take a pointer pointing to the beginning of the destination string
  U8 *ptr = destination;

  // copy first `num` characters of C-string pointed by source
  // into the array pointed by destination
  while (*source && num--) {
    *destination = *source;
    destination++;
    source++;
  }

  // null terminate destination string
  *destination = '\0';

  // the destination is returned by standard `strncpy()`
  return ptr;
}

U0 strncpy() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: strncpy(0x%08x, 0x%08x, %d)\n", p0, p1, p2);
  @strncpy(p0, p1, p2);
  POP_SYSV_REGS
}

U8 *@strrchr(U8 *str, I64 ch) {
  U8 str2[2];
  str2[0] = ch;
  str2[1] = NULL;
  return StrLastOcc(str, &str2);
}

U0 strrchr() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called strrchr(\"%s\",'%c')\n", p0, p1);
  @strrchr(p0, p1);
  POP_SYSV_REGS
}

U8 *CTYPE_TOUPPER_LOC = MAlloc(256, Fs->code_heap);
;
I64 @ctype_toupper_i;
for (@ctype_toupper_i = 0; @ctype_toupper_i < 256; @ctype_toupper_i++) {
  switch (@ctype_toupper_i) {
  case 'a' ... 'z':
    CTYPE_TOUPPER_LOC[@ctype_toupper_i] = @ctype_toupper_i - 0x20;
    break;
  default:
    CTYPE_TOUPPER_LOC[@ctype_toupper_i] = @ctype_toupper_i;
    break;
  }
}

U8 *@__ctype_toupper_loc() { return &CTYPE_TOUPPER_LOC; }

U0 __ctype_toupper_loc() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: __ctype_toupper_loc()\n");
  @__ctype_toupper_loc;
  POP_SYSV_REGS
}

U0 printf() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: printf(\"%s\")\n", p0);
  convert_format_string(p0);
  Print(p0, p1, p2, p3, p4, p5);
  POP_SYSV_REGS
}

U0 system() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: system(\"%s\")\n", p0);
  POP_SYSV_REGS
}

U0 toupper() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: toupper(\"%c\")\n", p0);
  ToUpper(p0);
  POP_SYSV_REGS
}

I64 @tolower(I64 ch) {
  switch (ch) {
  case 'A' ... 'Z':
    return ch + 0x20;
    break;
  default:
    return ch;
  }
}

U0 tolower() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: tolower(\"%c\")\n", p0);
  @tolower(p0);
  POP_SYSV_REGS
}

U0 time() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: time(%d)\n", p0);
  SysTimerRead;
  POP_SYSV_REGS
}

U0 vfprintf() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: vfprintf(0x%08x, 0x%08x, 0x%08x)\n", p0, p1, p2);
  switch (p0) {
  case 1:
    // PutS(p2);
    va_list *ap = p2;
    U64 va_ptr = ap->reg_save_area;
    va_ptr += ap->gp_offset;
    Print(p1, *va_ptr(U64 *));
    debug_print("addr is : 0x%08x\n", *va_ptr(U64 *));
    break;
  }
  POP_SYSV_REGS
}

U0 vprintf() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: vprintf()\n");
  va_list *ap = p1;
  U64 va_ptr = ap->reg_save_area;
  va_ptr += ap->gp_offset;
  Print(p0, *va_ptr(U64 *));
  debug_print("addr is : 0x%08x\n", *va_ptr(U64 *));
  POP_SYSV_REGS
}

U0 vsnprintf() {
  PUSH_SYSV_REGS
  GET_SYSV_ARGS
  debug_print("called: vsnprintf()\n");
  va_list *ap = p3;
  U64 va_ptr = ap->reg_save_area;
  U64 va_ptr2;
  U64 va_ptr3;
  va_ptr += ap->gp_offset;
  va_ptr2 = va_ptr + 8;
  va_ptr3 = va_ptr2 + 8;
  if (StrFind("STCFN", p2) || debug.counter > 1646600) {
    //"string: %s\n", p2;
    // PressAKey;
  }
  convert_format_string(p2);

  StrPrint(p0, p2, *va_ptr(U64 *), *va_ptr2(U64 *), *va_ptr3(U64 *));
  POP_SYSV_REGS
}
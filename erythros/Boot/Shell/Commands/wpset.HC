I64 @shell_cmd_wpset(@shell *sh, I64 argc, U8 **argv) {
  U8 buf[512];
  if (argc < 2) {
    return 0;
  }
  I64 size = 0;
  U64 fbuf = FileSystem.ReadFile(argv[1], &size);
  if (!fbuf) {
    StrPrint(&buf, "Error reading file %s\n", argv[1]);
    Stdio.WriteLine(sh, &buf);
    return 1;
  }
  Context2D *new = PNG.BufferToContext2D(fbuf, size);
  Free(fbuf);
  if (!new) {
    StrPrint(&buf, "Error in PNG.BufferToContext2D\n");
    Stdio.WriteLine(sh, &buf);
    return 1;
  }
  Compositor.SetWallpaper(new);
  DelContext2D(new);
  return 0;
}
I64 @shell_cmd_cat(@shell *sh, I64 argc, U8 **argv) {
  if (argc < 2)
    return 0;
  I64 i;
  I64 j;
  I64 size = 0;
  U8 *filename = NULL;
  U8 *buf = NULL;
  for (i = 1; i < argc; i++) {
    filename = @shell_expand_relative_path(sh, argv[i]);
    buf = FileSystem.ReadFile(filename, &size);
    for (j = 0; j < size; j++)
      FifoU8Ins(sh->output, buf[j]);
    Free(buf);
    Free(filename);
  }
  return 0;
}
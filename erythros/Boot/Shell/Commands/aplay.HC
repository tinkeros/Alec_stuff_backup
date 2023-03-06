I64 @shell_cmd_aplay(@shell *sh, I64 argc, U8 **argv) {
  U8 buf[512];
  if (argc < 2) {
    StrPrint(&buf, "Error reading file %s\n", argv[1]);
    Stdio.WriteLine(sh, "Usage: aplay [OPTION]... [FILE]...\n");
    return 1;
  }
  I64 i;
  I64 size;
  Sound *snd;
  U8 *filename = NULL;
  for (i = 1; i < argc; i++) {
    filename = @shell_expand_relative_path(sh, argv[i]);
    System.Log(Fs, "filename: %s", filename);
    if (FileSystem.PathExists(filename)) {
      snd = Audio.SoundFromFile(filename);
      if (!snd) {
        StrPrint(&buf, "%s: Error playing audio file\n", filename);
        Stdio.WriteLine(sh, &buf);
        Free(filename);
        return 1;
      }
      Audio.PlaySound(snd);
      Audio.FreeSound(snd);
      Free(filename);
    } else {
      StrPrint(&buf, "%s: No such file or directory\n", filename);
      Stdio.WriteLine(sh, &buf);
      Free(filename);
      return 1;
    }
  }
  return 0;
}
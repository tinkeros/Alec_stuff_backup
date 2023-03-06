#define @shell_cmd_ls_opt_a 0
#define @shell_cmd_ls_opt_l 1

I64 @shell_cmd_ls_output(@shell *sh, U8 *arg_path, I64 flags) {
  U8 buf[512];
  U8 *path = @shell_expand_relative_path(sh, arg_path);
  if (!FileSystem.PathExists(path)) {
    StrPrint(&buf, "ls: cannot access '%s': No such file or directory\n", path);
    Stdio.WriteLine(sh, &buf);
    Free(path);
    return 2;
  }
  @dir_entry *tmpf = NULL;
  @dir_entry *tmpf2 = NULL;
  tmpf = FileSystem.GetFiles(path);
  if (tmpf)
    while (tmpf) {
      if (tmpf->type == DE_TYPE_DIR) {
        StrCpy(&buf, "\x1b[1;34m");
        Stdio.WriteLine(sh, &buf);
      }
      StrPrint(&buf, "%s\x1b[0m    %u\n", &tmpf->name, tmpf->size);
      Stdio.WriteLine(sh, &buf);
      tmpf2 = tmpf;
      tmpf = tmpf->next;
      Free(tmpf2);
    }
  Free(path);
  return 0;
}

I64 @shell_cmd_ls(@shell *sh, I64 argc, U8 **argv) {
  U8 buf[512];
  U8 *options_list = "al";
  U64 options_err = NULL;
  I64 dir_cnt = 0;
  I64 flags = NULL;
  I64 rval = 0;
  I64 i;
  switch (@shell_parse_opts(sh, options_list, argc, argv, &flags, &options_err,
                            TRUE)) {
  case SHELL_OPTS_ERR_INVALID_OPT:
    StrPrint(&buf, "ls: invalid option -- '%s'\n", options_err);
    Stdio.WriteLine(sh, &buf);
    break;
  default:
    break;
  }
  if (options_err) {
    Free(options_err);
    return 2;
  }

  for (i = 1; i < argc; i++)
    if (argv[i][0] != '-')
      dir_cnt++;

  if (!dir_cnt) {
    return @shell_cmd_ls_output(sh, &sh->cwd, flags);
  } else {
    for (i = 1; i < argc; i++)
      if (argv[i][0] != '-') {
        rval = Max(rval, @shell_cmd_ls_output(sh, argv[i], flags));
      }
  }

  return rval;
}
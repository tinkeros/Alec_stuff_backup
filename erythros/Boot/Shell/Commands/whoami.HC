I64 @shell_cmd_whoami(@shell *sh, I64 argc, U8 **argv) {
  U8 *options_list = "";
  U64 options_err = NULL;
  I64 flags = NULL;
  I64 res = 0;
  U8 buf[512];
  switch (
      @shell_parse_opts(sh, options_list, argc, argv, &flags, &options_err)) {
  case SHELL_OPTS_ERR_INVALID_OPT:
    StrPrint(&buf, "uname: unrecognized option -- '%s'\n", options_err);
    Stdio.WriteLine(sh, &buf);
    res = 1;
    break;
  case SHELL_OPTS_ERR_EXTRA_OPD:
    StrPrint(&buf, "uname: extra operand '%s'\n", options_err);
    Stdio.WriteLine(sh, &buf);
    res = 1;
    break;
  default:
    Stdio.WriteLine(sh, &sh->session->user.name);
    Stdio.WriteLine(sh, "\n");
    break;
  }
  if (options_err)
    Free(options_err);
  return res;
}
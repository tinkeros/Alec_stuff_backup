#define SHELL_OPTS_ERR_INVALID_OPT -1
#define SHELL_OPTS_ERR_EXTRA_OPD -2

U0 @shell_free_args(I64 argc, U8 **argv) {
  I64 i;
  for (i = 0; i < argc; i++)
    Free(argv[i]);
  if (argv)
    Free(argv);
}

U8 **@shell_parse_args(U8 *str, I64 *argc) { // Return argc, argv from str.
  Bool quoted = FALSE;
  I64 _argc = 0;
  U8 **_argv = NULL;
  U8 **_tmp = CAlloc(sizeof(U64) * StrLen(str));
  I64 i = 0;
  I64 s = 0;
  I64 len;
  while (i < StrLen(str) + 1) {
    switch (str[i]) {
    case 0:
    case ' ':
      if (!quoted) {
        len = (str + i) - (str + s - 1);
        if (str[i - 1] == '"')
          len--;
        if (len - 1) {
          _tmp[_argc] = CAlloc(len);
          MemCpy(_tmp[_argc], str + s, len - 1);
          _argc++;
        }
        s = i + 1;
      }
      break;
    case '"':
      quoted = !quoted;
      if (quoted)
        s = i + 1;
      break;
    default:
      break;
    }
    i++;
  }
  *argc = _argc;
  _argv = CAlloc(sizeof(U64) * _argc);
  MemCpy(_argv, _tmp, sizeof(U64) * _argc);
  Free(_tmp);
  return _argv;
}

I64 @shell_parse_opts(U8 *op_lst, I64 argc, U8 **argv, I64 *flags, U64 *op_err,
                      Bool ignore_extra_opd = FALSE) {
  I64 i, j;
  U8 op_chr[2];
  op_chr[1] = 0;
  for (i = 1; i < argc; i++) {
    if (argv[i][0] == '-') {
      for (j = 1; j < StrLen(argv[i]); j++) {
        op_chr[0] = argv[i][j];
        if (StrFind(&op_chr, op_lst))
          *flags |= 1 << (StrFind(&op_chr, op_lst) - op_lst);
        else {
          *op_err = StrNew(&op_chr);
          return SHELL_OPTS_ERR_INVALID_OPT;
        }
      }
    } else {
      if (!ignore_extra_opd) {
        *op_err = StrNew(argv[i]);
        return SHELL_OPTS_ERR_EXTRA_OPD;
      }
    }
  }
  return 0;
}

U0 @shell_update_prompts(@shell *sh) {
  U8 *user = "user";
  U8 *host = "host";
  U8 *path = "~";
  StrPrint(&sh->PS1, "[%s@%s %s]\d ", user, host, path);
}

I64 @shell_input_loop(@shell *sh) {
  CHashFun *cmd;
  I64 argc;
  U8 **argv;
  U8 buf[4096];
  I64 err = NULL;
  Bool exit = FALSE;
  I64 i;
  I64 (*@shell_exec)(@shell * sh, I64 argc, U8 * *argv);

  while (!exit) {

    @shell_update_prompts(sh);
    Stdio.WriteLine(sh, &sh->PS1);
    Stdio.ReadLine(sh, &buf);

    argv = @shell_parse_args(&buf, &argc);

    if (argc) {
      if (!StrCmp(argv[0], "exit")) {
        exit = TRUE;
        goto @shell_exit;
      }
      StrPrint(&buf, "@shell_cmd_%s", argv[0]);
      cmd = HashFind(&buf, adam_task->hash_table, HTT_FUN);
      if (cmd) {
        @shell_exec = cmd->exe_addr;
        err = @shell_exec(sh, argc, argv);
      } else {
        StrPrint(&buf, "%s: command not found\n", argv[0]);
        Stdio.WriteLine(sh, &buf);
        err = 0;
      }
    }

    @shell_exit : @shell_free_args(argc, argv);

    Sleep(1);
  }
  return 0;
}

U0 @shell_instance(@shell *sh) {
  @shell_input_loop(sh);
  sh->exit = TRUE;
}

U0 @shell_init(@shell *sh) {
  sh->input = FifoU8New(SHELL_INPUT_FIFO_SIZE);
  sh->task = Spawn(&@shell_instance, sh);
}

@shell *@shell_new() {
  @shell *sh = CAlloc(sizeof(@shell));
  @shell_init(sh);
  return sh;
}

"shell ";
#define SHELL_OPTS_ERR_INVALID_OPT -1
#define SHELL_OPTS_ERR_EXTRA_OPD -2

U0 @shell_free_args(I64 argc, U8 **argv) {
  I64 i;
  for (i = 0; i < argc; i++)
    Free(argv[i]);
  if (argv)
    Free(argv);
}

U8 **@shell_parse_args(@shell *sh, U8 *str,
                       I64 *argc) { // Return argc, argv from str.
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

I64 @shell_parse_opts(@shell *sh, U8 *op_lst, I64 argc, U8 **argv, I64 *flags,
                      U64 *op_err, Bool ignore_extra_opd = FALSE) {
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
U8 *@shell_expand_relative_path(@shell *sh, U8 *path) {
  if (!path || !sh)
    return NULL;
  if (StrLen(path) < 1)
    return NULL;
  switch (path[0]) {
  case '/':
    return StrNew(path);
    break;
  default:
    U8 *abs_path = CAlloc(StrLen(path) + StrLen(&sh->cwd) + 4);
    StrPrint(abs_path, "%s/%s", &sh->cwd, path);
    return abs_path;
    break;
  }
}

U8 *@shell_get_env_var(@shell *sh, U8 *key) {
  @shell_env_var *var = sh->env->next;
  while (var) {
    if (StrLen(&var->key) && StrLen(&var->value))
      if (!StrCmp(&var->key, key))
        return &var->value;
    var = var->next;
  }
  return "";
}

U0 @shell_set_env_var(@shell *sh, U8 *key, U8 *value) {
  if (!sh || !key || !value)
    return;
  @shell_env_var *var = sh->env->next;
  while (var->next) {
    if (!StrCmp(&var->key, key)) {
      StrCpy(&var->value, value);
      return;
    }
    var = var->next;
  }
  @shell_env_var *new = CAlloc(sizeof(@shell_env_var));
  StrCpy(&new->key, key);
  StrCpy(&new->value, value);
  new->prev = var;
  var->next = new;
}

U0 @shell_unset_env_var(@shell *sh, U8 *key) {
  @shell_env_var *var = sh->env->next;
  @shell_env_var *prev = NULL;
  @shell_env_var *next = NULL;
  while (var) {
    if (!StrCmp(&var->key, key)) {
      prev = var->prev;
      next = var->next;
      if (prev)
        prev->next = next;
      if (next)
        next->prev = prev;
      Free(var);
      return;
    }
    var = var->next;
  }
}

U0 @shell_history_append(@shell *sh, U8 *str) {
  if (!sh || !str)
    return;
  if (!StrCmp(str, ""))
    return;
  I64 i;
  sh->history.entries[sh->history.pos] = StrNew(str);
  sh->history.pos++;
  if (sh->history.pos > SHELL_HISTORY_LIMIT - 1) {
    Free(sh->history.entries[0]);
    for (i = 0; i < SHELL_HISTORY_LIMIT; i++)
      sh->history.entries[i] = sh->history.entries[i + 1];
    sh->history.pos--;
  }
}

U0 @shell_process_args(@shell *sh, I64 argc, U8 **argv) {
  if (argc < 1 || !argv)
    return;
  I64 i;
  U8 buf[256];
  for (i = 0; i < argc; i++) {
    if (argv[i][0] == '\d') {
      switch (argv[i][1]) {
      case '?':
        Free(argv[i]);
        StrPrint(&buf, "%d", sh->answer);
        argv[i] = StrNew(&buf);
        break;
      case '0':
        Free(argv[i]);
        argv[i] = StrNew("esh");
        break;
      default:
        Free(argv[i]);
        argv[i] = StrNew(@shell_get_env_var(sh, argv[i] + 1));
        break;
      }
    }
    if (!StrCmp(argv[i], "~")) {
      Free(argv[i]);
      argv[i] = StrNew(&sh->session->home);
    }
  }
}

U0 @shell_update_prompts(@shell *sh) {
  U8 buf[512];
  U8 buf2[512];
  StrCpy(&buf, &sh->cwd);
  StrPrint(buf2, "/home/%s", &sh->session->user.name);
  if (!StrCmp(&buf, &buf2))
    StrCpy(&buf, "~");
  else
    StrCpy(&buf, StrLastOcc(&buf, "/") + 1);
  StrPrint(&sh->PS1, "[%s@%s %s]\d ", &sh->session->user.name,
           &sh->session->hostname, &buf);
}

I64 @shell_input_loop(@shell *sh) {
  CHashFun *cmd;
  I64 argc;
  U8 **argv;
  U8 buf[4096];
  Bool exit = FALSE;
  I64 i;
  I64 (*@shell_exec)(@shell * sh, I64 argc, U8 * *argv);

  while (!exit) {

    @shell_update_prompts(sh);
    Stdio.WriteLine(sh, &sh->PS1);
    Stdio.ReadLine(sh, &buf);

    @shell_history_append(sh, &buf);
    argv = @shell_parse_args(sh, &buf, &argc);

    if (argc) {
      if (!StrCmp(argv[0], "exit")) {
        exit = TRUE;
        goto @shell_exit;
      }
      @shell_process_args(sh, argc, argv);
      StrPrint(&buf, "@shell_cmd_%s", argv[0]);
      cmd = HashFind(&buf, adam_task->hash_table, HTT_FUN);
      if (cmd) {
        @shell_exec = cmd->exe_addr;
        sh->answer = @shell_exec(sh, argc, argv);
        sh->break = FALSE;
        FifoU8Flush(sh->input);
      } else {
        StrPrint(&buf, "%s: command not found\n", argv[0]);
        Stdio.WriteLine(sh, &buf);
        sh->answer = 0;
      }
    }

    @shell_exit : @shell_free_args(argc, argv);
  }
  return 0;
}

U0 @shell_instance(@shell *sh) {
  @shell_input_loop(sh);
  sh->exit = TRUE;
}

U0 @shell_init(@shell *sh) {
  sh->env = CAlloc(sizeof(@shell_env_var));
  sh->history.limit = SHELL_HISTORY_LIMIT;
  sh->history.pos = 0;
  sh->history.entries = CAlloc(sizeof(U64) * SHELL_HISTORY_LIMIT);
  sh->input = FifoU8New(SHELL_INPUT_FIFO_SIZE);
  sh->task = Spawn(&@shell_instance, sh);
}

@shell *@shell_new(Bool headless = FALSE) {
  @shell *sh = CAlloc(sizeof(@shell));
  if (!headless)
    @shell_init(sh);
  StrCpy(&sh->cwd, &Compositor.session.home);
  return sh;
}

"shell ";
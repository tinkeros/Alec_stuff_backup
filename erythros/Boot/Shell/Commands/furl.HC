#define @shell_cmd_furl_opt_i 0
#define @shell_cmd_furl_opt_I 1

I64 @shell_cmd_furl(@shell *sh, I64 argc, U8 **argv) {
  I64 i = 0;
  I64 ret = 0;
  U8 *options_list = "iI";
  U64 options_err = NULL;
  U64 buf = NULL;
  U8 out_buf[512];
  I64 flags = NULL;
  I64 request_type = HTTP_REQ_GET;
  Bool display_headers = FALSE;
  if (argc < 2) {
    Stdio.WriteLine(sh, "usage: furl [options] [URLs]\n");
    return 1;
  }

  I64 u = 1;
  switch (
      @shell_parse_opts(sh, options_list, argc, argv, &flags, &options_err)) {
  case SHELL_OPTS_ERR_INVALID_OPT:
    StrPrint(&out_buf, "furl: invalid option -- '%s'\n", options_err);
    Stdio.WriteLine(sh, &out_buf);
    return 1;
    break;
  case SHELL_OPTS_ERR_EXTRA_OPD:
    for (i = 1; i < argc; i++)
      if (!StrCmp(argv[i], options_err))
        u = i;
    break;
  default:
    break;
  }

  if (flags & 1 << @shell_cmd_furl_opt_i)
    display_headers = TRUE;

  if (flags & 1 << @shell_cmd_furl_opt_I) {
    display_headers = TRUE;
    request_type = HTTP_REQ_HEAD;
  }

  @http_url *url = @http_parse_url(argv[u]);
  if (!url) {
    Stdio.WriteLine(sh, "furl: error: malformed URL");
    return 1;
  }

  if (!url->scheme) {
    Stdio.WriteLine(sh, "furl: error: unsupported URL scheme");
    ret = 1;
    goto furl_exit;
  }
  if (!url->host) {
  furl_missing_host:
    Stdio.WriteLine(sh, "furl: error: URL missing host");
    ret = 1;
    goto furl_exit;
  }
  if (!url->path) {
  furl_missing_path:
    Stdio.WriteLine(sh, "furl: error: URL missing path");
    ret = 1;
    goto furl_exit;
  }
  if (!StrCmp(url->host, ""))
    goto furl_missing_host;
  if (!StrCmp(url->path, ""))
    goto furl_missing_path;

  buf = MAlloc(262144);
  @http_response *resp = Http.Get(url, buf);

  if (!resp) {
    Stdio.WriteLine(sh, "furl: error: malformed response from host");
    ret = 1;
    goto furl_exit;
  }

  while (resp->state < HTTP_STATE_LOADING) {
    if (sh->break) {
      Stdio.WriteLine(sh, "^C\n");
      goto furl_exit;
    }
    Sleep(1);
  }

  if (display_headers) {
    StrPrint(out_buf, "%s %d\n", resp->status.protocol, resp->status.code);
    Stdio.WriteLine(sh, out_buf);
    for (i = 0; i < resp->headers.count; i++) {
      StrPrint(out_buf, "\x1b[38;5;212m%s:\x1b[0m %s\n",
               resp->headers.header[i]->key, resp->headers.header[i]->value);
      Stdio.WriteLine(sh, out_buf);
    }
    Stdio.WriteLine(sh, "\n");
  }

  if (request_type != HTTP_REQ_HEAD) {
    i = 0;
    while (resp->state < HTTP_STATE_DONE) {
      while (i < resp->body.length) {
        FifoU8Ins(sh->output, resp->body.data[i]);
        while (FifoU8Cnt(sh->output) > 128)
          Sleep(1);
        i++;
        if (sh->break) {
          Stdio.WriteLine(sh, "^C\n");
          goto furl_exit;
        }
      }
      Sleep(1);
    }
    while (i < resp->body.length) {
      FifoU8Ins(sh->output, resp->body.data[i]);
      while (FifoU8Cnt(sh->output) > 128)
        Sleep(1);
      i++;
      if (sh->break) {
        Stdio.WriteLine(sh, "^C\n");
        goto furl_exit;
      }
    }
    Stdio.WriteLine(sh, "\n");
  }

  @http_free_response(resp);

furl_exit:
  @http_free_url(url);
  if (buf)
    Free(buf);
  return ret;
}
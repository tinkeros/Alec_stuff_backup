I64 @shell_cmd_urlinfo(@shell *sh, I64 argc, U8 **argv) {
  if (argc < 2) {
    Stdio.WriteLine(sh, "usage: urlinfo [URL]\n");
    return 1;
  }

  U8 buf[512];
  @http_url *url = @http_parse_url(argv[1]);
  StrPrint(buf, "Scheme: %s\n", url->scheme);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "Host: %s\n", url->host);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "Port: %d\n", url->port);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "Path: %s\n", url->path);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "Params: %s\n", url->params);
  Stdio.WriteLine(sh, buf);
  StrPrint(buf, "Anchor: %s\n", url->anchor);
  Stdio.WriteLine(sh, buf);

  Stdio.WriteLine(sh, "\n");

  return 0;
}
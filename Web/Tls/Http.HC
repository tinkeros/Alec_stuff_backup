#define HTTP_DEBUG

#ifdef HTTP_DEBUG
#define http_debug Print
#else
#define http_debug http_mute_debug
#endif

U0 http_mute_debug(U8 *buf, ...) {
  no_warn buf;
  no_warn argc;
  no_warn argv;
}

class @http_buffer {
  I64 length;
  U8 *data;
};

class @http_header {
  U8 *key;
  U8 *value;
};

class @http_headers {
  I64 count;
  @http_header **header;
};

class @http_status {
  U8 *protocol;
  I64 code;
  U8 *text;
};

class @http_response {
  I64 state;
  @http_status status;
  @http_headers headers;
  @http_buffer body;
};

class @http_url {
  U8 *scheme;
  U8 *host;
  I64 port;
  U8 *path;
  U8 *params;
  U8 *anchor;
};

class @http_request {
  @http_url *url;
  U8 *buf;
  U8 *data;
  I64 type;
  @http_response *response;
};

#define HttpResponse @http_response
#define HttpUrl @http_url

#define HTTP_PARSE_SCHEME 0
#define HTTP_PARSE_SCHEME_FS 1
#define HTTP_PARSE_HOST 2
#define HTTP_PARSE_PORT 3
#define HTTP_PARSE_PATH 4
#define HTTP_PARSE_PARAMS 5
#define HTTP_PARSE_ANCHOR 6

#define HTTP_PARSE_HEADER_KEY 0
#define HTTP_PARSE_HEADER_SPC 1
#define HTTP_PARSE_HEADER_VALUE 2

#define HTTP_MIN_REQUEST_BUFFER_SIZE 16384
#define HTTP_PARSE_URL_FIFO_SIZE 1024
#define HTTP_PARSE_HEADER_FIFO_SIZE 1024

#define HTTP_REQ_GET 0
#define HTTP_REQ_HEAD 1
#define HTTP_REQ_POST 2
#define HTTP_REQ_PUT 3

#define HTTP_STATE_UNSENT 0
#define HTTP_STATE_OPENED 1
#define HTTP_STATE_HEADERS_RECEIVED 2
#define HTTP_STATE_LOADING 3
#define HTTP_STATE_DONE 4

U8 *@http_string_from_fifo(CFifoU8 *f) {
  U8 ch;
  I64 i = 0;
  U8 *str = CAlloc(FifoU8Cnt(f) + 1);
  while (FifoU8Cnt(f)) {
    FifoU8Rem(f, &ch);
    str[i] = ch;
    i++;
  }
  FifoU8Flush(f);
  return str;
}

U0 @http_free_url(@http_url *url) {
  if (!url)
    return;
  if (url->scheme)
    Free(url->scheme);
  if (url->host)
    Free(url->host);
  if (url->path)
    Free(url->path);
  if (url->params)
    Free(url->params);
  if (url->anchor)
    Free(url->anchor);
  Free(url);
}

U0 @http_free_response(@http_response *resp) {
  if (!resp)
    return;
  I64 i;
  if (resp->headers.header) {
    for (i = 0; i < resp->headers.count; i++) {
      if (resp->headers.header[i]) {
        if (resp->headers.header[i]->key)
          Free(resp->headers.header[i]->key);
        if (resp->headers.header[i]->value)
          Free(resp->headers.header[i]->value);
      }
    }
    Free(resp->headers.header);
  }
  Free(resp);
}

@http_url *@http_parse_url(U8 *str) {
  if (!str)
    return NULL;
  U8 *buf = NULL;
  U8 hex[3];
  I64 i = 0;
  I64 state = HTTP_PARSE_SCHEME;
  CFifoU8 *consume_fifo = FifoU8New(HTTP_PARSE_URL_FIFO_SIZE);
  @http_url *url = CAlloc(sizeof(@http_url));
  while (1) {
    switch (str[i]) {
    case 0:
      switch (state) {
      case HTTP_PARSE_HOST:
        url->host = @http_string_from_fifo(consume_fifo);
        url->path = StrNew("/");
        goto done_parsing_url;
        break;
      case HTTP_PARSE_PORT:
        buf = @http_string_from_fifo(consume_fifo);
        url->port = Str2I64(buf);
        Free(buf);
        url->path = StrNew("/");
        goto done_parsing_url;
        break;
      case HTTP_PARSE_PATH:
        url->path = @http_string_from_fifo(consume_fifo);
        goto done_parsing_url;
        break;
      case HTTP_PARSE_PARAMS:
        url->params = @http_string_from_fifo(consume_fifo);
        goto done_parsing_url;
        break;
      case HTTP_PARSE_ANCHOR:
        url->anchor = @http_string_from_fifo(consume_fifo);
        goto done_parsing_url;
        break;
      default:
        goto done_parsing_url;
        break;
      }
      break;
    case '#':
      switch (state) {
      case HTTP_PARSE_PATH:
        url->path = @http_string_from_fifo(consume_fifo);
        FifoU8Ins(consume_fifo, str[i]);
        state = HTTP_PARSE_ANCHOR;
        break;
      case HTTP_PARSE_PARAMS:
        url->params = @http_string_from_fifo(consume_fifo);
        FifoU8Ins(consume_fifo, str[i]);
        state = HTTP_PARSE_ANCHOR;
        break;
      }
      break;
    case '?':
      switch (state) {
      case HTTP_PARSE_PATH:
        url->path = @http_string_from_fifo(consume_fifo);
        FifoU8Ins(consume_fifo, str[i]);
        state = HTTP_PARSE_PARAMS;
        break;
      }
      break;
    case '/':
      switch (state) {
      case HTTP_PARSE_SCHEME:
        state = HTTP_PARSE_SCHEME_FS;
        goto keep_consuming_url_chars;
        break;
      case HTTP_PARSE_SCHEME_FS:
        FifoU8Ins(consume_fifo, str[i]);
        url->scheme = @http_string_from_fifo(consume_fifo);
        if (!StrCmp(url->scheme, "http://"))
          url->port = 80;
        if (!StrCmp(url->scheme, "https://"))
          url->port = 443;
        state = HTTP_PARSE_HOST;
        break;
      case HTTP_PARSE_HOST:
        url->host = @http_string_from_fifo(consume_fifo);
        FifoU8Ins(consume_fifo, str[i]);
        state = HTTP_PARSE_PATH;
        break;
      case HTTP_PARSE_PORT:
        buf = @http_string_from_fifo(consume_fifo);
        url->port = Str2I64(buf);
        Free(buf);
        FifoU8Ins(consume_fifo, str[i]);
        state = HTTP_PARSE_PATH;
        break;
      case HTTP_PARSE_PATH:
        goto keep_consuming_url_chars;
        break;
      }
      break;
    case ':':
      switch (state) {
      case HTTP_PARSE_SCHEME:
      case HTTP_PARSE_PATH:
      case HTTP_PARSE_PARAMS:
      case HTTP_PARSE_ANCHOR:
        goto keep_consuming_url_chars;
        break;
      case HTTP_PARSE_HOST:
        url->host = @http_string_from_fifo(consume_fifo);
        state = HTTP_PARSE_PORT;
        break;
      }
      break;
    default:
    keep_consuming_url_chars:
      switch (state) {
      case HTTP_PARSE_PATH:
      case HTTP_PARSE_PARAMS:
        switch (str[i]) {
        case '0' ... '9':
        case 'A' ... 'Z':
        case 'a' ... 'z':
        case '?':
        case '&':
        case '/':
        case '=':
        // !'()*-._~
        case '!':
        case '\'':
        case '(':
        case ')':
        case '*':
        case '-':
        case '.':
        case '_':
        case '~':
          FifoU8Ins(consume_fifo, str[i]);
          break;
        default:
          FifoU8Ins(consume_fifo, '%');
          StrPrint(hex, "%02X", str[i]);
          FifoU8Ins(consume_fifo, hex[0]);
          FifoU8Ins(consume_fifo, hex[1]);
          break;
        }
        break;
      default:
        FifoU8Ins(consume_fifo, str[i]);
        break;
      }
      break;
    }
    i++;
  }
done_parsing_url:
  FifoU8Flush(consume_fifo);
  FifoU8Del(consume_fifo);
  return url;
}

I64 @http_parse_response_headers(@http_response *resp, U8 *buffer, I64 length) {
  if (!resp || !buffer || !length)
    return NULL;
  U64 response_data_ptr = StrFind("\r\n\r\n", buffer);
  if (!response_data_ptr)
    return NULL;
  // buffer[length] = NULL;
  resp->body.data = response_data_ptr + 4;
  resp->body.data[-4] = NULL;
  // resp->body.length = (buffer + length) - response_data_ptr - 5;

  I64 i;
  I64 j;
  I64 lines_cnt = NULL;
  U8 **lines = String.Split(buffer, , &lines_cnt);

  U8 *status_code_str = StrFirstOcc(buffer, " ") + 1;
  resp->status.text = StrFirstOcc(status_code_str, " ") + 1;
  StrFirstOcc(status_code_str, " ")[0] = NULL;
  resp->status.code = Str2I64(status_code_str);
  StrFirstOcc(buffer, " ")[0] = NULL;
  resp->status.protocol = buffer;

  resp->headers.count = lines_cnt - 1;
  resp->headers.header = CAlloc(sizeof(@http_header *) * resp->headers.count);
  for (i = 0; i < resp->headers.count; i++)
    resp->headers.header[i] = CAlloc(sizeof(@http_header));

  CFifoU8 *consume_fifo = FifoU8New(HTTP_PARSE_HEADER_FIFO_SIZE);

  i = 1;
  j = 0;
  I64 state = HTTP_PARSE_HEADER_KEY;
  while (i < lines_cnt) {
    switch (lines[i][j]) {
    case '\r':
      break;
    case 0:
      switch (state) {
      case HTTP_PARSE_HEADER_VALUE:
        resp->headers.header[i - 1]->value =
            @http_string_from_fifo(consume_fifo);
        state = HTTP_PARSE_HEADER_KEY;
      default:
        FifoU8Flush(consume_fifo);
        j = -1;
        i++;
        break;
      }
      break;
    case ' ':
      switch (state) {
      case HTTP_PARSE_HEADER_SPC:
        resp->headers.header[i - 1]->key = @http_string_from_fifo(consume_fifo);
        state = HTTP_PARSE_HEADER_VALUE;
        break;
      case HTTP_PARSE_HEADER_VALUE:
        goto keep_consuming_header_chars;
        break;
      }
      break;
    case ':':
      switch (state) {
      case HTTP_PARSE_HEADER_KEY:
        state = HTTP_PARSE_HEADER_SPC;
        break;
      case HTTP_PARSE_HEADER_VALUE:
        goto keep_consuming_header_chars;
        break;
      }
      break;
    default:
    keep_consuming_header_chars:
      FifoU8Ins(consume_fifo, lines[i][j]);
      break;
    }
    j++;
  }
done_parsing_headers:
  FifoU8Flush(consume_fifo);
  FifoU8Del(consume_fifo);
  return i;
}

Bool @http_detect_response_headers(U8 *buf, I64 len) {
  if (len < 4)
    return FALSE;
  I64 i;
  for (i = 0; i < len - 4; i++) {
    if (!MemCmp(buf + i, "\r\n\r\n", 4))
      return TRUE;
  }
  return FALSE;
}

I64 @http_req(@http_request *req) {
  if (!req)
    return NULL;
  if (!req->url || !req->buf || !req->response)
    return NULL;
  if (!req->url->scheme || !req->url->host || !req->url->path)
    return NULL;
  if (req->type == HTTP_REQ_POST && !req->data)
    return NULL;
  if (req->type == HTTP_REQ_PUT && !req->data)
    return NULL;

  @http_response *resp = req->response;

  U32 ip = NULL;
  U8 *buf = NULL;
  I64 cnt = 1;
  I64 err = NULL;
  I64 len = NULL;

  Net.ResolveIPv4Address(req->url->host, &ip);
  if (!ip) {
    "didn't resolve ip\n";
    return NULL;
  }

  buf = CAlloc(HTTP_MIN_REQUEST_BUFFER_SIZE);

  switch (req->type) {
  case HTTP_REQ_GET:
    StrPrint(buf,
             "GET %s%s HTTP/1.0\r\n"
             "Host: %s\r\n\r\n",
             req->url->path, req->url->params, req->url->host);
    break;
  case HTTP_REQ_HEAD:
    StrPrint(buf,
             "HEAD %s%s HTTP/1.0\r\n"
             "Host: %s\r\n\r\n",
             req->url->path, req->url->params, req->url->host);
    break;
  case HTTP_REQ_POST:
    StrPrint(buf,
             "POST %s%s HTTP/1.0\r\n"
             "Host: %s\r\n"
             "Content-Length: %d\r\n\r\n",
             req->url->path, req->url->params, req->url->host,
             StrLen(req->data));
    StrPrint(buf + StrLen(buf), req->data);
    break;
  case HTTP_REQ_PUT:
    StrPrint(buf,
             "PUT %s%s HTTP/1.0\r\n"
             "Host: %s\r\n"
             "Content-Length: %d\r\n\r\n",
             req->url->path, req->url->params, req->url->host,
             StrLen(req->data));
    StrPrint(buf + StrLen(buf), req->data);
    break;
  }

  if (!StrCmp(req->url->scheme, "http://")) {
    I64 sock = socket(AF_INET, SOCK_STREAM);
    sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(req->url->port);
    addr.sin_addr.s_addr = ip;
    err = connect(sock, &addr, sizeof(addr));
    if (err) {
      http_debug(Fs, "@http_get: connect_error: %d", err);
      Free(buf);
      return NULL;
    }
    resp->state = HTTP_STATE_OPENED;
    send(sock, buf, StrLen(buf), 0);
    while (cnt) {
      cnt = recv(sock, req->buf + len, 1024, 0);
      len += cnt;
      switch (resp->state) {
      case HTTP_STATE_LOADING:
        resp->body.length += cnt;
        break;
      case HTTP_STATE_HEADERS_RECEIVED:
        resp->body.length = (req->buf + len) - resp->body.data - 1;
        resp->state = HTTP_STATE_LOADING;
        break;
      case HTTP_STATE_OPENED:
        if (@http_detect_response_headers(req->buf, len)) {
          @http_parse_response_headers(resp, req->buf, len);
          resp->state = HTTP_STATE_HEADERS_RECEIVED;
        }
        break;
      }
      Sleep(1);
    }
    resp->state = HTTP_STATE_DONE;
    req->buf[len - 1] = NULL;
    Free(buf);
    close(sock);
    Free(req);
    return len;
  }

  if (!StrCmp(req->url->scheme, "https://")) {
    @tls_context *ctx = @tls12_new_context;
    err = @tls12_connect(ctx, req->url->host, ip, req->url->port);
    if (err) {
      http_debug(Fs, "@http_get: tls12_connect_error: %d", err);
      Free(buf);
      return NULL;
    }
    resp->state = HTTP_STATE_OPENED;
    @tls12_send(ctx, buf, StrLen(buf));
    while (cnt) {
      cnt = @tls12_recv2(ctx, req->buf + len);
      len += cnt;
      switch (resp->state) {
      case HTTP_STATE_LOADING:
        resp->body.length += cnt;
        break;
      case HTTP_STATE_HEADERS_RECEIVED:
        resp->body.length = (req->buf + len) - resp->body.data - 1;
        resp->state = HTTP_STATE_LOADING;
        break;
      case HTTP_STATE_OPENED:
        if (@http_detect_response_headers(req->buf, len)) {
          @http_parse_response_headers(resp, req->buf, len);
          resp->state = HTTP_STATE_HEADERS_RECEIVED;
        }
        break;
      }
      Sleep(1);
    }
    resp->state = HTTP_STATE_DONE;
    req->buf[len - 1] = NULL;
    Free(buf);
    close(ctx->sock);
    return len;
  }
  return NULL;
}

@http_response *@http_get(@http_url *url, U8 *buf) {
  @http_response *resp = CAlloc(sizeof(@http_response));
  @http_request *req = CAlloc(sizeof(@http_request));
  req->url = url;
  req->buf = buf;
  req->type = HTTP_REQ_GET;
  req->response = resp;
  // Spawn(&@http_req, req, "HTTPGetRequest");
  @http_req(req);
  return resp;
}

@http_response *@http_head(@http_url *url, U8 *buf) {
  @http_response *resp = CAlloc(sizeof(@http_response));
  @http_request *req = CAlloc(sizeof(@http_request));
  req->url = url;
  req->buf = buf;
  req->type = HTTP_REQ_HEAD;
  req->response = resp;
  // Spawn(&@http_req, req, "HTTPHeadRequest");
  @http_req(req);
   return resp;
}

@http_response *@http_post(@http_url *url, U8 *buf, U8 *data) {
  @http_response *resp = CAlloc(sizeof(@http_response));
  @http_request *req = CAlloc(sizeof(@http_request));
  req->url = url;
  req->buf = buf;
  req->type = HTTP_REQ_POST;
  req->data = data;
  req->response = resp;
  Spawn(&@http_req, req, "HTTPPostRequest");
  return resp;
}

@http_response *@http_put(@http_url *url, U8 *buf, U8 *data) {
  @http_response *resp = CAlloc(sizeof(@http_response));
  @http_request *req = CAlloc(sizeof(@http_request));
  req->url = url;
  req->buf = buf;
  req->type = HTTP_REQ_PUT;
  req->data = data;
  req->response = resp;
  Spawn(&@http_req, req, "HTTPPutRequest");
  return resp;
}

class @http {
  @http_response *(*Get)(@http_url * url, U8 * buf);
  @http_response *(*Head)(@http_url * url, U8 * buf);
  @http_response *(*Post)(@http_url * url, U8 * buf, U8 * data);
  @http_response *(*Put)(@http_url * url, U8 * buf, U8 * data);
};

@http Http;

Http.Get = &@http_get;
Http.Head = &@http_head;
Http.Post = &@http_post;
Http.Put = &@http_put;

"[OK] http \n";
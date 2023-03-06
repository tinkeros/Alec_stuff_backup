CDC *hr_dc = DCNew(640, 2);
DCFill(hr_dc, DKGRAY);
CSprite *hr_s = DC2Sprite(hr_dc);

I64 img_resource_count = 0;

Bool @render_image(CDoc *doc, Node *node) {
  // PopUpOk(Json.Get(node->attributes, "src"));
  // return FALSE;
  U8 buf[512];
  StrCpy(buf, "https:"); // FIXME
  StrCpy(buf + StrLen(buf), Json.Get(node->attributes, "src"));

  I64 i;
  I64 content_length = 0;
  Bool is_animated_gif = FALSE;

  MemSet(web_resource_buffer, NULL, WEB_RESPONSE_BUFFER_SIZE);
  @http_response *resp = @http_get(@http_parse_url(buf), web_resource_buffer);
  if (!resp->body.data || !resp->body.length || resp->state != HTTP_STATE_DONE)
    return FALSE;

  for (i = 0; i < resp->headers.count; i++) {
    if (!StrICmp(resp->headers.header[i]->key, "Content-Length")) {
      content_length = Str2I64(resp->headers.header[i]->value);
      i = resp->headers.count;
    }
  }

  if (!MemCmp(resp->body.data, "GIF89a", 6))
    is_animated_gif = TRUE;

  // FIXME: A bug in TLS implementation chops off the last byte, which breaks
  // JPEG rendering. Let's add 0xd9 at the end of the buffer to workaround this
  // for now.
  U8 *ext = StrLastOcc(Json.Get(node->attributes, "src"), ".") + 1;
  if (!StrICmp(ext, "jpg") || !StrICmp(ext, "jpeg"))
    resp->body.data[content_length - 1] = 0xd9;

  CDC *img = Image.FromBuffer(resp->body.data, content_length);

  if (img) {
    CSprite *s = DC2Sprite(img);
    DocSprite(doc, s);
    DCDel(img);
    Free(s);
    return TRUE;
  }
  return FALSE;
}

U0 @calculate_indents_for_sprites(CDoc *haystack_doc) {
  U8 buf[512];

  CSpritePtWH *ptwh;
  CDocEntry *doc_e;
  doc_e = haystack_doc->head.next;
  while (doc_e != haystack_doc) {
    if (doc_e->type_u8 == DOCT_SPRITE) {
      ptwh = doc_e->bin_data->data;
      if (!(ptwh->width == 640 && ptwh->height == 2)) {
        haystack_doc->cur_entry = doc_e->next;
        StrPrint(buf, "\dID,%d\d", (ptwh->width / 8) + 2);
        DocPutS(haystack_doc, buf);
        DocRecalc(haystack_doc);
        DocGoToLine(haystack_doc, haystack_doc->y + (ptwh->height / 8) + 16);
        haystack_doc->x = 0;
        DocRecalc(haystack_doc, RECALCt_FIND_CURSOR);
        StrPrint(buf, "\dID,-%d\d", (ptwh->width / 8) + 2);
        DocPutS(haystack_doc, buf);
      }
    }
    doc_e = doc_e->next;
  }
}

U8 *@sanitize_node_text(U8 *text) {
  U8 *ch = text;
  Bool needs_sanitization = FALSE;
  while (*ch++ && !needs_sanitization) {
    switch (*ch) {
    case 0x11:
    case 0x12:
    case 0x24:
    case 0xc2:
    case 0xe2:
      needs_sanitization = TRUE;
      break;
    default:
      break;
    }
  }
  if (!needs_sanitization)
    return text;
  U8 *new_text = CAlloc(StrLen(text) * 2);
  I64 i = 0;
  while (i < StrLen(text)) {
    switch (text[i]) {
    case 0x11:
      StrCpy(new_text + StrLen(new_text), "&");
      i++;
      break;
    case 0x12:
      StrCpy(new_text + StrLen(new_text), "<");
      i++;
      break;
    case 0x24:
      StrCpy(new_text + StrLen(new_text), "\d\d");
      i++;
      break;
    case 0xc2:
      if (text[i + 1] == 0xa9) {
        StrCpy(new_text + StrLen(new_text), "(C)");
        i += 2;
        break;
      }
      if (text[i + 1] == 0xae) {
        StrCpy(new_text + StrLen(new_text), "(R)");
        i += 2;
        break;
      }
      break;
    case 0xe2:
      if (text[i + 1] == 0x80 && text[i + 2] == 0x99) {
        StrCpy(new_text + StrLen(new_text), "'");
        i += 3;
        break;
      }
      if (text[i + 1] == 0x84 && text[i + 2] == 0xa2) {
        StrCpy(new_text + StrLen(new_text), "\dSY,-3\dtm\dSY,0\d");
        i += 3;
        break;
      }
      break;
    default:
      StrPrint(new_text + StrLen(new_text), "%c", text[i]);
      i++;
      break;
    }
  }
  Free(text);
  return new_text;
}
extern I64 Navigate(CTask *task, U8 *url_string);

U0 NavigateTo(CDoc *doc, U8 *url) {
  switch (url[0]) {
  case '#':
    DocAnchorFind(DocPut, url + 1);
    return;
    break;
  default:
    Navigate(doc, url);
    break;
  }
}

U0 @render_node_tree(CDoc *render_doc, CDoc *doc, Node *node) {

  I64 i;
  I64 imgAnchorCount = 0;
  U8 buf[512];

  if (!render_doc)
    render_doc = doc;

  if (Json.Get(node->attributes, "id")) {
    StrPrint(buf, "\dAN,\"\",A=\"%s\"\d", Json.Get(node->attributes, "id"));
    DocPutS(doc, buf);
  }

  if (!StrICmp(node->tagName, "a")) {
    doc = DocNew;
  }

  if (!StrICmp(node->tagName, "b") || !StrICmp(node->tagName, "strong"))
    DocPutS(doc, "\dFG,0\d");

  if (!StrICmp(node->tagName, "blockquote"))
    DocPutS(doc, "\n\n\dID,2\d");

  if (!StrICmp(node->tagName, "br"))
    DocPutS(doc, "\n");

  if (!StrICmp(node->tagName, "hr")) {
    DocPutS(doc, "\n");
    DocSprite(doc, hr_s);
    DocPutS(doc, "\n");
  }

  if (!StrICmp(node->tagName, "span")) {
    if (!StrICmp(Json.Get(node->attributes, "class"), "quote"))
      DocPutS(doc, "\dFG,GREEN\d");
  }

  if (!StrICmp(node->tagName, "InternalTextNode")) {
    node->text = @sanitize_node_text(node->text);
    if (StrICmp(node->parentNode->tagName, "option") &&
        StrICmp(node->parentNode->tagName, "script") &&
        StrICmp(node->parentNode->tagName, "style") &&
        StrICmp(node->parentNode->tagName, "title"))
      DocPutS(doc, node->text);
    if (!StrICmp(node->parentNode->tagName, "title"))
      MemCpy(Fs->task_title, node->text, STR_LEN);
  }

  if (!StrICmp(node->tagName, "img")) {
    // StrPrint(buf, "\dAN,\"\",A=\"img%d\"\d", imgAnchorCount);
    // DocPutS(doc, buf);
    // load images async (is this thread safe?)

    StrPrint(progress1_desc, "Loading image %d of %d ...", progress1 + 1,
             progress1_max);
    @render_image(render_doc, node);
    progress1++;

    imgAnchorCount++;
  }

  if (node->children->length) {
    for (i = 0; i < node->children->length; i++)
      @render_node_tree(render_doc, doc, Json.ArrayIndex(node->children, i));
  }

  if (!StrICmp(node->tagName, "a")) {
    U8 *plain_text_buf = Doc2PlainText(doc, doc->head.next);
    plain_text_buf[StrLen(plain_text_buf) - 1] = NULL;
    StrCpy(buf, "\dMA+LIS,\"");
    StrCpy(buf + StrLen(buf), plain_text_buf + 4);
    StrPrint(buf + StrLen(buf), "\",LM=\"NavigateTo(0x%08x,\\\"%s\\\");\"\d",
             DocPut, Json.Get(node->attributes, "href"));
    DocPutS(render_doc, buf);
    Free(plain_text_buf);
  }

  if (!StrICmp(node->tagName, "b") || !StrICmp(node->tagName, "strong"))
    DocPutS(doc, "\dFG,8\d");

  if (!StrICmp(node->tagName, "blockquote"))
    DocPutS(doc, "\dID,-2\d\n\n");

  if (!StrICmp(node->tagName, "div"))
    DocPutS(doc, "\n");

  if (!StrICmp(node->tagName, "span")) {
    if (!StrICmp(Json.Get(node->attributes, "class"), "quote"))
      DocPutS(doc, "\dFG,DKGRAY\d");
  }
}

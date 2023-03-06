#define JSON_SAME -1
#define JSON_UNDEFINED 0
#define JSON_OBJECT 1
#define JSON_ARRAY 2
#define JSON_STRING 3
#define JSON_NUMBER 4
#define JSON_BOOLEAN 5
#define JSON_NULL 6
#define JSON_HTML 7

#define JSON_STATE_OBJECT_OR_ARRAY 0

#define JSON_STATE_OBJECT 100
#define JSON_STATE_OBJECT_KEY 101
#define JSON_STATE_OBJECT_SEPARATOR 102
#define JSON_STATE_OBJECT_TYPE 103
#define JSON_STATE_OBJECT_NEXT 104

#define JSON_STATE_OBJECT_OBJECT 105
#define JSON_STATE_OBJECT_ARRAY 106
#define JSON_STATE_OBJECT_STRING 107
#define JSON_STATE_OBJECT_NUMBER 108
#define JSON_STATE_OBJECT_BOOLEAN 109
#define JSON_STATE_OBJECT_NULL 110

#define JSON_STATE_ARRAY 200
#define JSON_STATE_ARRAY_TYPE 201
#define JSON_STATE_ARRAY_NEXT 202

#define JSON_STATE_ARRAY_OBJECT 203
#define JSON_STATE_ARRAY_ARRAY 204
#define JSON_STATE_ARRAY_STRING 205
#define JSON_STATE_ARRAY_NUMBER 206
#define JSON_STATE_ARRAY_BOOLEAN 207
#define JSON_STATE_ARRAY_NULL 208

#define JSON_PARSER_FIFO_SIZE 16384
#define JSON_STRINGIFY_BUF_SIZE 1048576

I64 T(Bool _condition, I64 _true, I64 _false) {
  if (_condition)
    return _true;
  return _false;
}

class @json_element {
  @json_element *prev;
  @json_element *next;
  I64 type;
};

class @json_key : @json_element {
  U8 *name;
  U64 value;
};

class @json_item : @json_element {
  U64 value;
};

class @json_object : @json_element {
  I64 length;
  @json_key *keys;
};

class @json_array : @json_element {
  I64 length;
  @json_item *items;
};

class @json_parser {
  U8 *stream;
  U8 token;
  CFifoU8 *consumed;
  I64 pos;
  I64 state;
  Bool debug;
};

#define JsonArray @json_array
#define JsonElement @json_element
#define JsonItem @json_item
#define JsonKey @json_key
#define JsonObject @json_object

U0 @json_debug_parser_state(@json_parser *parser) {
  switch (parser->state) {
  case JSON_STATE_OBJECT:
    "JSON_STATE_OBJECT\n";
    break;
  case JSON_STATE_OBJECT_KEY:
    "JSON_STATE_OBJECT_KEY\n";
    break;
  case JSON_STATE_OBJECT_SEPARATOR:
    "JSON_STATE_OBJECT_SEPARATOR\n";
    break;
  case JSON_STATE_OBJECT_TYPE:
    "JSON_STATE_OBJECT_TYPE\n";
    break;
  case JSON_STATE_OBJECT_NEXT:
    "JSON_STATE_OBJECT_NEXT\n";
    break;
  case JSON_STATE_OBJECT_STRING:
    "JSON_STATE_OBJECT_STRING\n";
    break;
  case JSON_STATE_OBJECT_NUMBER:
    "JSON_STATE_OBJECT_NUMBER\n";
    break;
  case JSON_STATE_ARRAY:
    "JSON_STATE_ARRAY\n";
    break;
  case JSON_STATE_ARRAY_TYPE:
    "JSON_STATE_ARRAY_TYPE\n";
    break;
  case JSON_STATE_ARRAY_NEXT:
    "JSON_STATE_ARRAY_NEXT\n";
    break;
  case JSON_STATE_ARRAY_STRING:
    "JSON_STATE_ARRAY_STRING\n";
    break;
  case JSON_STATE_ARRAY_NUMBER:
    "JSON_STATE_ARRAY_NUMBER\n";
    break;
  }
}

U8 *@json_string_from_fifo(CFifoU8 *f) {
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

U0 @json_insert_key(@json_object *obj, @json_key *key) {
  if (!obj)
    return;
  if (!obj->keys) {
    obj->keys = key;
    obj->length++;
    return;
  }
  @json_key *k = obj->keys;
  while (k->next)
    k = k->next;
  k->next = key;
  key->prev = k;
  obj->length++;
}

U0 @json_insert_item(@json_array *arr, @json_item *item) {
  if (!arr)
    return;
  if (!arr->items) {
    arr->items = item;
    arr->length++;
    return;
  }
  @json_item *i = arr->items;
  while (i->next)
    i = i->next;
  i->next = item;
  item->prev = i;
  arr->length++;
}

extern @json_element *@json_parse_object_or_array(@json_parser *parser);

U0 @json_parse_object(@json_parser *parser, @json_object *obj) {
  @json_key *key = NULL;
  while (1) {
    switch (parser->stream[parser->pos]) {
    case '}':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_NUMBER:
        key->value = @json_string_from_fifo(parser->consumed);
        key->value = Str2F64(key->value);
        @json_insert_key(obj, key);
        return;
        break;
      case JSON_STATE_OBJECT_BOOLEAN:
        key->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("true", key->value) && StrCmp("false", key->value)) {
          PrintErr("@json_parse_object: Illegal boolean value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        if (!StrCmp("true", key->value))
          key->value = TRUE;
        else
          key->value = FALSE;
        @json_insert_key(obj, key);
        return;
        break;
      case JSON_STATE_OBJECT_NULL:
        key->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("null", key->value)) {
          PrintErr("@json_parse_object: Illegal null value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        key->value = NULL;
        @json_insert_key(obj, key);
        return;
        break;
      case JSON_STATE_OBJECT:
      case JSON_STATE_OBJECT_NEXT:
        return;
        break;
      }
      break;
    case ',':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_NUMBER:
        key->value = @json_string_from_fifo(parser->consumed);
        key->value = Str2F64(key->value);
        @json_insert_key(obj, key);
        parser->state = JSON_STATE_OBJECT;
        break;
      case JSON_STATE_OBJECT_BOOLEAN:
        key->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("true", key->value) && StrCmp("false", key->value)) {
          PrintErr("@json_parse_object: Illegal boolean value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        if (!StrCmp("true", key->value))
          key->value = TRUE;
        else
          key->value = FALSE;
        @json_insert_key(obj, key);
        parser->state = JSON_STATE_OBJECT;
        break;
      case JSON_STATE_OBJECT_NULL:
        key->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("null", key->value)) {
          PrintErr("@json_parse_object: Illegal null value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        key->value = NULL;
        @json_insert_key(obj, key);
        parser->state = JSON_STATE_OBJECT;
        break;
      case JSON_STATE_OBJECT_NEXT:
        parser->state = JSON_STATE_OBJECT;
        break;
      }
      break;
    case ':':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_SEPARATOR:
        parser->state = JSON_STATE_OBJECT_TYPE;
        break;
      }
      break;
    case '[':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_TYPE:
        key->type = JSON_ARRAY;
        key->value = @json_parse_object_or_array(parser);
        @json_insert_key(obj, key);
        parser->state = JSON_STATE_OBJECT_NEXT;
        break;
      }
      break;
    case '{':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_TYPE:
        key->type = JSON_OBJECT;
        key->value = @json_parse_object_or_array(parser);
        @json_insert_key(obj, key);
        parser->state = JSON_STATE_OBJECT_NEXT;
        break;
      }
      break;
    case '"':
      switch (parser->state) {
      case JSON_STATE_OBJECT_STRING:
        key->value = @json_string_from_fifo(parser->consumed);
        @json_insert_key(obj, key);
        parser->state = JSON_STATE_OBJECT_NEXT;
        break;
      case JSON_STATE_OBJECT_TYPE:
        key->type = JSON_STRING;
        parser->state = JSON_STATE_OBJECT_STRING;
        break;
      case JSON_STATE_OBJECT_KEY:
        key->name = @json_string_from_fifo(parser->consumed);
        parser->state = JSON_STATE_OBJECT_SEPARATOR;
        break;
      case JSON_STATE_OBJECT:
        key = CAlloc(sizeof(@json_key));
        parser->state = JSON_STATE_OBJECT_KEY;
        break;
      }
      break;
    case '-':
    case '0' ... '9':
    case '.':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
      case JSON_STATE_OBJECT_NUMBER:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_TYPE:
        key->type = JSON_NUMBER;
        parser->state = JSON_STATE_OBJECT_NUMBER;
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    case 't':
    case 'f':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_TYPE:
        key->type = JSON_BOOLEAN;
        parser->state = JSON_STATE_OBJECT_BOOLEAN;
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    case 'n':
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_TYPE:
        key->type = JSON_NULL;
        parser->state = JSON_STATE_OBJECT_NULL;
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    default:
      switch (parser->state) {
      case JSON_STATE_OBJECT_KEY:
      case JSON_STATE_OBJECT_STRING:
      case JSON_STATE_OBJECT_BOOLEAN:
      case JSON_STATE_OBJECT_NULL:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    }
    if (parser->debug) {
      @json_debug_parser_state(parser);
      "Object: %08X, Pos: %d, Token: %c\n", obj, parser->pos,
          parser->stream[parser->pos];
      Sleep(50);
    }
    parser->pos++;
  }
}

U0 @json_parse_array(@json_parser *parser, @json_array *arr) {
  @json_item *item = NULL;
  while (1) {
    if (parser->state == JSON_STATE_ARRAY) {
      switch (parser->stream[parser->pos]) {
      case 0:
        PrintErr("@json_parse_array: Malformed array");
        while (1)
          Sleep(1);
        break;
      case ']':
        return;
        break;
      }
      item = CAlloc(sizeof(@json_item));
      parser->state = JSON_STATE_ARRAY_TYPE;
    }
    switch (parser->stream[parser->pos]) {
    case ']':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_ARRAY_NUMBER:
        item->value = @json_string_from_fifo(parser->consumed);
        item->value = Str2F64(item->value);
        @json_insert_item(arr, item);
        return;
        break;
      case JSON_STATE_ARRAY_BOOLEAN:
        item->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("true", item->value) && StrCmp("false", item->value)) {
          PrintErr("@json_parse_array: Illegal boolean value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        if (!StrCmp("true", item->value))
          item->value = TRUE;
        else
          item->value = FALSE;
        @json_insert_item(arr, item);
        break;
      case JSON_STATE_ARRAY_NULL:
        item->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("null", item->value)) {
          PrintErr("@json_parse_array: Illegal null value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        item->value = NULL;
        @json_insert_item(arr, item);
        break;
      case JSON_STATE_ARRAY:
      case JSON_STATE_ARRAY_NEXT:
        return;
        break;
      }
      break;
    case ',':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_ARRAY_NUMBER:
        item->value = @json_string_from_fifo(parser->consumed);
        item->value = Str2F64(item->value);
        @json_insert_item(arr, item);
        parser->state = JSON_STATE_ARRAY;
        break;
      case JSON_STATE_ARRAY_BOOLEAN:
        item->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("true", item->value) && StrCmp("false", item->value)) {
          PrintErr("@json_parse_array: Illegal boolean value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        if (!StrCmp("true", item->value))
          item->value = TRUE;
        else
          item->value = FALSE;
        @json_insert_item(arr, item);
        parser->state = JSON_STATE_ARRAY;
        break;
      case JSON_STATE_ARRAY_NULL:
        item->value = @json_string_from_fifo(parser->consumed);
        if (StrCmp("null", item->value)) {
          PrintErr("@json_parse_array: Illegal null value at position %d",
                   parser->pos);
          while (1)
            Sleep(1);
        }
        item->value = NULL;
        @json_insert_item(arr, item);
        parser->state = JSON_STATE_ARRAY;
        break;
      case JSON_STATE_ARRAY_NEXT:
        parser->state = JSON_STATE_ARRAY;
        break;
      }
      break;
    case '[':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_ARRAY_TYPE:
        item->type = JSON_ARRAY;
        item->value = @json_parse_object_or_array(parser);
        @json_insert_item(arr, item);
        parser->state = JSON_STATE_ARRAY_NEXT;
        break;
      }
      break;
    case '{':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_ARRAY_TYPE:
        item->type = JSON_OBJECT;
        item->value = @json_parse_object_or_array(parser);
        @json_insert_item(arr, item);
        parser->state = JSON_STATE_ARRAY_NEXT;
        break;
      }
      break;
    case '"':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
        item->value = @json_string_from_fifo(parser->consumed);
        @json_insert_item(arr, item);
        parser->state = JSON_STATE_ARRAY_NEXT;
        break;
      case JSON_STATE_ARRAY_TYPE:
        item->type = JSON_STRING;
        parser->state = JSON_STATE_ARRAY_STRING;
        break;
      }
      break;
    case '-':
    case '0' ... '9':
    case '.':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
      case JSON_STATE_ARRAY_NUMBER:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_ARRAY_TYPE:
        item->type = JSON_NUMBER;
        parser->state = JSON_STATE_ARRAY_NUMBER;
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    case 't':
    case 'f':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_ARRAY_TYPE:
        item->type = JSON_BOOLEAN;
        parser->state = JSON_STATE_ARRAY_BOOLEAN;
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    case 'n':
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      case JSON_STATE_OBJECT_TYPE:
        item->type = JSON_NULL;
        parser->state = JSON_STATE_ARRAY_NULL;
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    default:
      switch (parser->state) {
      case JSON_STATE_ARRAY_STRING:
      case JSON_STATE_ARRAY_BOOLEAN:
      case JSON_STATE_ARRAY_NULL:
        FifoU8Ins(parser->consumed, parser->stream[parser->pos]);
        break;
      }
      break;
    }
    if (parser->debug) {
      @json_debug_parser_state(parser);
      "Array: %08X, Pos: %d, Token: %c\n", arr, parser->pos,
          parser->stream[parser->pos];
      Sleep(50);
    }
    parser->pos++;
  }
}

@json_element *@json_parse_object_or_array(@json_parser *parser) {
  @json_element *el = CAlloc(sizeof(@json_element) * 2);
  while (1) {
    switch (parser->stream[parser->pos]) {
    case 0:
      return el;
      break;
    case ' ':
    case '\r':
    case '\n':
    case '\t':
      break;
    case '{':
      el->type = JSON_OBJECT;
      parser->pos++;
      parser->state = JSON_STATE_OBJECT;
      @json_parse_object(parser, el);
      return el;
      break;
    case '[':
      el->type = JSON_ARRAY;
      parser->pos++;
      parser->state = JSON_STATE_ARRAY;
      @json_parse_array(parser, el);
      return el;
      break;
    default:
      PrintErr("@json_parse_object_or_array: Invalid token");
      while (1) {
        Sleep(1);
      };
      break;
    }
    parser->pos++;
    Sleep(1);
  }
}

@json_element *@json_parse(U8 *str) {
  @json_parser *parser = CAlloc(sizeof(@json_parser));
  parser->consumed = FifoU8New(JSON_PARSER_FIFO_SIZE);
  // parser->debug = TRUE;
  parser->stream = str;
  @json_element *root = @json_parse_object_or_array(parser);
  FifoU8Flush(parser->consumed);
  FifoU8Del(parser->consumed);
  Free(parser);
  return root;
}

U0 @json_stringify_append_char(U8 *str, U8 char) {
  I64 len = StrLen(str);
  str[len] = char;
  str[len + 1] = NULL;
}

U0 @json_stringify_append_str(U8 *str, U8 *str2) {
  while (*str2) {
    @json_stringify_append_char(str, *str2);
    str2++;
  }
}

U0 @json_stringify_append_number(U8 *str, F64 num) {
  U8 buf[16];
  StrPrint(buf, "%.7f", num);
  I64 i = StrLen(buf) - 1;
  while (buf[i] == '0') {
    buf[i] = NULL;
    i--;
  }
  i = StrLen(buf) - 1;
  if (buf[i] == '.')
    buf[i] = NULL;
  @json_stringify_append_str(str, buf);
}

extern U0 @json_stringify_object_or_array(U8 *str, @json_element *el);

U0 @json_stringify_object(U8 *str, @json_object *obj) {
  @json_stringify_append_char(str, '{');
  @json_key *key = obj->keys;
  while (key) {
    @json_stringify_append_char(str, '"');
    @json_stringify_append_str(str, key->name);
    @json_stringify_append_char(str, '"');
    @json_stringify_append_char(str, ':');
    switch (key->type) {
    case JSON_OBJECT:
    case JSON_ARRAY:
      @json_stringify_object_or_array(str, key->value);
      break;
    case JSON_STRING:
      @json_stringify_append_char(str, '"');
      @json_stringify_append_str(str, key->value);
      @json_stringify_append_char(str, '"');
      break;
    case JSON_NUMBER:
      @json_stringify_append_number(str, key->value);
      break;
    case JSON_BOOLEAN:
      @json_stringify_append_str(str, T(key->value, "true", "false"));
      break;
    case JSON_NULL:
      @json_stringify_append_str(str, "null");
      break;
    default:
      PrintErr("@json_stringify_object: Invalid element type");
      while (1) {
        Sleep(1);
      };
    }
    if (key->next)
      @json_stringify_append_char(str, ',');
    key = key->next;
  }
  @json_stringify_append_char(str, '}');
}

U0 @json_stringify_array(U8 *str, @json_array *arr) {
  @json_stringify_append_char(str, '[');
  @json_item *item = arr->items;
  while (item) {
    switch (item->type) {
    case JSON_OBJECT:
    case JSON_ARRAY:
      @json_stringify_object_or_array(str, item->value);
      break;
    case JSON_STRING:
      @json_stringify_append_char(str, '"');
      @json_stringify_append_str(str, item->value);
      @json_stringify_append_char(str, '"');
      break;
    case JSON_NUMBER:
      @json_stringify_append_number(str, item->value);
      break;
    case JSON_BOOLEAN:
      @json_stringify_append_str(str, T(item->value, "true", "false"));
      break;
    case JSON_NULL:
      @json_stringify_append_str(str, "null");
      break;
    default:
      PrintErr("@json_stringify_array: Invalid element type");
      while (1) {
        Sleep(1);
      };
    }
    if (item->next)
      @json_stringify_append_char(str, ',');
    item = item->next;
  }
  @json_stringify_append_char(str, ']');
}

U0 @json_stringify_object_or_array(U8 *str, @json_element *el) {
  while (el) {
    switch (el->type) {
    case JSON_OBJECT:
      @json_stringify_object(str, el);
      break;
    case JSON_ARRAY:
      @json_stringify_array(str, el);
      break;
    default:
      PrintErr("@json_stringify_object_or_array: Invalid element type");
      while (1) {
        Sleep(1);
      };
      break;
    }
    el = el->next;
  }
}

U8 *@json_stringify(@json_element *el, I64 buf_size = JSON_STRINGIFY_BUF_SIZE) {
  U8 *str = CAlloc(buf_size);
  @json_stringify_object_or_array(str, el);
  return str;
}

U64 @json_get(@json_object *obj, U8 *key, Bool return_key = FALSE) {
  if (!obj || !key)
    return NULL;
  if (!obj->keys || obj->type != JSON_OBJECT)
    return NULL;
  @json_key *iter_key = obj->keys;
  while (iter_key) {
    if (!StrCmp(iter_key->name, key))
      if (return_key)
        return iter_key;
      else
        return iter_key->value;
    iter_key = iter_key->next;
  }
  return NULL;
}

U0 @json_set(@json_object *obj, U8 *key, U64 value, I64 type = JSON_SAME) {
  if (!obj || !key || !type)
    return;
  if (obj->type != JSON_OBJECT)
    return;
  @json_key *iter_key = obj->keys;
  while (iter_key) {
    if (!StrCmp(iter_key->name, key)) {
      if (type != JSON_SAME)
        iter_key->type = type;
      iter_key->value = value;
      return;
    }
    iter_key = iter_key->next;
  }
  @json_key *new_key = CAlloc(sizeof(@json_key));
  new_key->name = StrNew(key);
  new_key->type = type;
  new_key->value = value;
  @json_insert_key(obj, new_key);
}

@json_object *@json_create_object() {
  @json_object *obj = CAlloc(sizeof(@json_object));
  obj->type = JSON_OBJECT;
  return obj;
}

@json_array *@json_create_array() {
  @json_array *arr = CAlloc(sizeof(@json_array));
  arr->type = JSON_ARRAY;
  arr->items = CAlloc(sizeof(@json_item));
  return arr;
}

U0 @json_append_item(@json_array *arr, @json_item *append_item) {
  if (!arr || !append_item)
    return;
  if (arr->type != JSON_ARRAY)
    return;
  @json_item *item = arr->items;
  while (item->next) {
    item = item->next;
  }
  item->next = append_item;
  append_item->prev = item;
  arr->length++;
}

U64 @json_array_index(@json_array *arr, I64 index, Bool return_item = FALSE) {
  if (!arr)
    return NULL;
  if (arr->type != JSON_ARRAY)
    return NULL;
  if (index > arr->length - 1)
    return NULL;
  @json_item *item = arr->items->next;
  if (!item)
    return NULL;
  I64 i;
  for (i = 0; i < index; i++)
    item = item->next;
  if (return_item)
    return item;
  else
    return item->value;
}

class @json {
  U0 (*AppendItem)(@json_array * arr, @json_item * append_item);
  U64 (*ArrayIndex)(@json_array * arr, I64 index, Bool return_item = FALSE);
  @json_object *(*CreateObject)();
  @json_array *(*CreateArray)();
  @json_element *(*Parse)(U8 * str);
  U64(*Get)
  (@json_object * obj, U8 * key, Bool return_key = FALSE);
  U0 (*Set)(@json_object * obj, U8 * key, U64 value, I64 type);
  U8 *(*Stringify)(@json_element * el, I64 buf_size = JSON_STRINGIFY_BUF_SIZE);
};

@json Json;
Json.AppendItem = &@json_append_item;
Json.ArrayIndex = &@json_array_index;
Json.CreateArray = &@json_create_array;
Json.CreateObject = &@json_create_object;
Json.Get = &@json_get;
Json.Parse = &@json_parse;
Json.Set = &@json_set;
Json.Stringify = &@json_stringify;

"[OK] json \n";
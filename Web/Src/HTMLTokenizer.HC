#define GROWABLE_STRING_INCREMENT_SIZE 16

#define HTML_STATE_INVALID 0
#define HTML_STATE_DATA 1
#define HTML_STATE_RCDATA 2
#define HTML_STATE_RAWTEXT 3
#define HTML_STATE_SCRIPT_DATA 4
#define HTML_STATE_PLAINTEXT 5
#define HTML_STATE_TAG_OPEN 6
#define HTML_STATE_END_TAG_OPEN 7
#define HTML_STATE_TAG_NAME 8
#define HTML_STATE_RCDATA_LESS_THAN_SIGN 9
#define HTML_STATE_RCDATA_END_TAG_OPEN 10
#define HTML_STATE_RCDATA_END_TAG_NAME 11
#define HTML_STATE_RAWTEXT_LESS_THAN_SIGN 12
#define HTML_STATE_RAWTEXT_END_TAG_OPEN 13
#define HTML_STATE_RAWTEXT_END_TAG_NAME 14
#define HTML_STATE_SCRIPT_DATA_LESS_THAN_SIGN 15
#define HTML_STATE_SCRIPT_DATA_END_TAG_OPEN 16
#define HTML_STATE_SCRIPT_DATA_END_TAG_NAME 17
#define HTML_STATE_SCRIPT_DATA_ESCAPE_START 18
#define HTML_STATE_SCRIPT_DATA_ESCAPE_START_DASH 19
#define HTML_STATE_SCRIPT_DATA_ESCAPED 20
#define HTML_STATE_SCRIPT_DATA_ESCAPED_DASH 21
#define HTML_STATE_SCRIPT_DATA_ESCAPED_DASH_DASH 22
#define HTML_STATE_SCRIPT_DATA_ESCAPED_LESS_THAN 23
#define HTML_STATE_SCRIPT_DATA_ESCAPED_END_TAG_OPEN 24
#define HTML_STATE_SCRIPT_DATA_ESCAPED_END_TAG_NAME 25
#define HTML_STATE_SCRIPT_DATA_DOUBLE_ESCAPE_START 26
#define HTML_STATE_SCRIPT_DATA_DOUBLE_ESCAPED 27
#define HTML_STATE_SCRIPT_DATA_DOUBLE_ESCAPED_DASH 28
#define HTML_STATE_SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH 29
#define HTML_STATE_SCRIPT_DATA_DOUBLE_ESCAPED_LESS_THAN 30
#define HTML_STATE_SCRIPT_DATA_DOUBLE_ESCAPE_END 31
#define HTML_STATE_BEFORE_ATTRIBUTE_NAME 32
#define HTML_STATE_ATTRIBUTE_NAME 33
#define HTML_STATE_AFTER_ATTRIBUTE_NAME 34
#define HTML_STATE_BEFORE_ATTRIBUTE_VALUE 35
#define HTML_STATE_ATTRIBUTE_VALUE_DOUBLE_QUOTED 36
#define HTML_STATE_ATTRIBUTE_VALUE_SINGLE_QUOTED 37
#define HTML_STATE_ATTRIBUTE_VALUE_UNQUOTED 38
#define HTML_STATE_AFTER_ATTRIBUTE_VALUE_QUOTED 39
#define HTML_STATE_SELF_CLOSING_START_TAG 40
#define HTML_STATE_BOGUS_COMMENT 41
#define HTML_STATE_MARKUP_DECLARATION_OPEN 42
#define HTML_STATE_COMMENT_START 43
#define HTML_STATE_COMMENT_START_DASH 44
#define HTML_STATE_COMMENT 45
#define HTML_STATE_COMMENT_LESS_THAN_SIGN 46
#define HTML_STATE_COMMENT_LESS_THAN_SIGN_BANG 47
#define HTML_STATE_COMMENT_LESS_THAN_SIGN_BANG_DASH 48
#define HTML_STATE_COMMENT_LESS_THAN_SIGN_BANG_DASH_DASH 49
#define HTML_STATE_COMMENT_END_DASH 50
#define HTML_STATE_COMMENT_END 51
#define HTML_STATE_COMMENT_END_BANG 52
#define HTML_STATE_DOCTYPE 53
#define HTML_STATE_BEFORE_DOCTYPE_NAME 54
#define HTML_STATE_DOCTYPE_NAME 55
#define HTML_STATE_AFTER_DOCTYPE_NAME 56
#define HTML_STATE_AFTER_DOCTYPE_PUBLIC_KEYWORD 57
#define HTML_STATE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER 58
#define HTML_STATE_DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED 59
#define HTML_STATE_DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED 60
#define HTML_STATE_AFTER_DOCTYPE_PUBLIC_IDENTIFIER 61
#define HTML_STATE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS 62
#define HTML_STATE_AFTER_DOCTYPE_SYSTEM_KEYWORD 63
#define HTML_STATE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER 64
#define HTML_STATE_DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED 65
#define HTML_STATE_DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED 66
#define HTML_STATE_AFTER_DOCTYPE_SYSTEM_IDENTIFIER 67
#define HTML_STATE_BOGUS_DOCTYPE 68
#define HTML_STATE_CDATA_SECTION 69
#define HTML_STATE_CDATA_SECTION_BRACKET 70
#define HTML_STATE_CDATA_SECTION_END 71
#define HTML_STATE_CHARACTER_REFERENCE 72
#define HTML_STATE_NAMED_CHARACTER_REFERENCE 73
#define HTML_STATE_AMBIGUOUS_AMPERSAND 74
#define HTML_STATE_NUMERIC_CHARACTER_REFERENCE 75
#define HTML_STATE_HEXADECIMAL_CHARACTER_REFERENCE_START 76
#define HTML_STATE_DECIMAL_CHARACTER_REFERENCE_START 77
#define HTML_STATE_HEXADECIMAL_CHARACTER_REFERENCE 78
#define HTML_STATE_DECIMAL_CHARACTER_REFERENCE 79
#define HTML_STATE_NUMERIC_CHARACTER_REFERENCE_END 80

class Node : JsonElement {
  Node *parentNode;
  U8 tagName[32];
  JsonObject *attributes;
  JsonArray *children;
  U8 *text;
};

class InputBuffer {
  U8 *data;
  I64 size;
  I64 pos;
};

class Tokenizer {
  InputBuffer inputBuffer;
  I64 state;
  I64 returnState;
  U8 currentInputChar;
  JsonKey *currentAttribute;
  Node *appendNode;
  Node *currentNode;
  Node *originNode;
  I64 nodeTreeDepth;
  I64 dataStateCounter;
  InputBuffer tempBuffer;
  Bool consumeTempBuffer;
  I64 numOfImgNodes;
};

U8 *@init_growable_string() { return CAlloc(GROWABLE_STRING_INCREMENT_SIZE); }

U8 *@append_char_to_growable_string(U8 *s, I64 char) {
  I64 oldBufSize = roundUp(StrLen(s), GROWABLE_STRING_INCREMENT_SIZE - 1);
  I64 newBufSize = roundUp(StrLen(s) + 1, GROWABLE_STRING_INCREMENT_SIZE - 1);
  if (newBufSize > oldBufSize) {
    U8 *newBuf =
        CAlloc(roundUp(StrLen(s) + 1, GROWABLE_STRING_INCREMENT_SIZE - 1) * 2);
    StrCpy(newBuf, s);
    newBuf[StrLen(newBuf)] = char;
    Free(s);
    return newBuf;
  } else {
    s[StrLen(s)] = char;
    return s;
  }
}

U0 @empty_temp_buffer(Tokenizer *t) {
  MemSet(t->tempBuffer.data, NULL, 512);
  t->tempBuffer.size = 0;
  t->tempBuffer.pos = 0;
}

U0 @recalculate_temp_buffer_size(Tokenizer *t) {
  t->tempBuffer.size = StrLen(t->tempBuffer.data);
  t->tempBuffer.pos = 0;
}

U0 @replace_temp_buffer_with_named_character_reference(Tokenizer *t) {

  if (!StrICmp(t->tempBuffer.data, "&amp;")) {
    StrCpy(t->tempBuffer.data, "\x11");
    @recalculate_temp_buffer_size(t);
    return;
  }
  if (!StrICmp(t->tempBuffer.data, "&bull;")) {
    StrPrint(t->tempBuffer.data, "%c", 254);
    @recalculate_temp_buffer_size(t);
    return;
  }
  if (!StrICmp(t->tempBuffer.data, "&copy;")) {
    StrCpy(t->tempBuffer.data, "(c)");
    @recalculate_temp_buffer_size(t);
    return;
  }
  if (!StrICmp(t->tempBuffer.data, "&nbsp;")) {
    StrCpy(t->tempBuffer.data, " ");
    @recalculate_temp_buffer_size(t);
    return;
  }
  if (!StrICmp(t->tempBuffer.data, "&lt;")) {
    StrCpy(t->tempBuffer.data, "\x12");
    @recalculate_temp_buffer_size(t);
    return;
  }
  if (!StrICmp(t->tempBuffer.data, "&gt;")) {
    StrCpy(t->tempBuffer.data, ">");
    @recalculate_temp_buffer_size(t);
    return;
  }
  if (!StrICmp(t->tempBuffer.data, "&quot;")) {
    StrCpy(t->tempBuffer.data, "\"");
    @recalculate_temp_buffer_size(t);
    return;
  }

  @debug("\n$FG,0$HTML Tokenization error: Unimplemented named character "
         "reference "
         "InputBuffer position: %d\nName: %s$FD$\n",
         t->inputBuffer.pos, t->tempBuffer.data);
  "\n";
  PressAKey;
}

U0 @replace_temp_buffer_with_hex_character_reference(Tokenizer *t) {
  // TODO: convert hex to dec in buffer and call
  // @replace_temp_buffer_with_dec_character_reference
  no_warn t;
  "unimplemented: @replace_temp_buffer_with_hex_character_reference\n";
  PressAKey;
}

U0 @replace_temp_buffer_with_dec_character_reference(Tokenizer *t) {
  t->tempBuffer.data[StrLen(t->tempBuffer.data) - 1] =
      NULL; // chop off semicolon
  I64 charCode = Str2I64(t->tempBuffer.data + 2);

  switch (charCode) {
  case 32...127:
    StrPrint(t->tempBuffer.data, "%c", charCode);
    @recalculate_temp_buffer_size(t);
    break;
  case 9660:
    StrCpy(t->tempBuffer.data, "");
    @recalculate_temp_buffer_size(t);
    return;
    break;
  default:

    @debug("\n$FG,0$HTML Tokenization error: Unimplemented decimal character "
           "reference "
           "InputBuffer position: %d\nValue: %d$FD$\n",
           t->inputBuffer.pos, charCode);
    "\n";
    PressAKey;
    break;
  }
}

U0 @replace_temp_buffer_with_numeric_character_reference(Tokenizer *t) {
  switch (t->tempBuffer.data[2]) {
  case 'x':
    @replace_temp_buffer_with_hex_character_reference(t);
    break;
  default:
    @replace_temp_buffer_with_dec_character_reference(t);
    break;
  }
}

U0 @append_char_to_temp_buffer(Tokenizer *t, I64 char) {
  t->tempBuffer.data[StrLen(t->tempBuffer.data)] = char;
  t->tempBuffer.size++;
}

Node *@create_new_node(U8 *tagName) {
  Node *node = CAlloc(sizeof(Node));
  StrCpy(node->tagName, tagName);
  node->attributes = Json.CreateObject();
  node->children = Json.CreateArray();
  node->text = @init_growable_string;
  node->type = JSON_HTML;
  return node;
}

U0 @init_tokenizer(Tokenizer *t, U8 *data, I64 size) {
  t->inputBuffer.data = data;
  t->inputBuffer.size = size;
  t->inputBuffer.pos = 0;
  t->state = HTML_STATE_DATA;
  t->tempBuffer.data = CAlloc(512);
  t->tempBuffer.size = size;
  t->tempBuffer.pos = 0;
  t->originNode = @create_new_node("Document");
  t->appendNode = t->originNode;
  t->currentNode = t->originNode;
  t->consumeTempBuffer = FALSE;
  t->dataStateCounter = 0;
  t->numOfImgNodes = 0;
}

U0 @consume_next_input_char(Tokenizer *t) {
  if (t->consumeTempBuffer) {
    if (t->tempBuffer.pos < t->tempBuffer.size) {
      t->currentInputChar = t->tempBuffer.data[t->tempBuffer.pos++];
      return;
    } else {
      t->consumeTempBuffer = FALSE;
    }
  }
  t->currentInputChar = t->inputBuffer.data[t->inputBuffer.pos++];
}

U0 @emit_current_character(Tokenizer *t) {
  if (!t->dataStateCounter) {
    Node *node = @create_new_node("InternalTextNode");
    t->currentNode = node;
  }
  t->currentNode->text = @append_char_to_growable_string(t->currentNode->text,
                                                         t->currentInputChar);
  t->dataStateCounter++;
}

Bool @node_is_self_closing(Node *node) {
  if (!StrICmp(node->tagName, "InternalTextNode"))
    return TRUE;
  if (!StrICmp(node->tagName, "area"))
    return TRUE;
  if (!StrICmp(node->tagName, "base"))
    return TRUE;
  if (!StrICmp(node->tagName, "br"))
    return TRUE;
  if (!StrICmp(node->tagName, "col"))
    return TRUE;
  if (!StrICmp(node->tagName, "embed"))
    return TRUE;
  if (!StrICmp(node->tagName, "hr"))
    return TRUE;
  if (!StrICmp(node->tagName, "img"))
    return TRUE;
  if (!StrICmp(node->tagName, "input"))
    return TRUE;
  if (!StrICmp(node->tagName, "link"))
    return TRUE;
  if (!StrICmp(node->tagName, "meta"))
    return TRUE;
  if (!StrICmp(node->tagName, "param"))
    return TRUE;
  if (!StrICmp(node->tagName, "source"))
    return TRUE;
  if (!StrICmp(node->tagName, "track"))
    return TRUE;
  if (!StrICmp(node->tagName, "wbr"))
    return TRUE;
  return FALSE;
}

U0 @emit_current_node(Tokenizer *t) {
  Node *origAppendNode = t->appendNode;
  if (t->currentNode->tagName[0] == '/') {
    if (StrICmp(t->appendNode->tagName, t->currentNode->tagName + 1)) {
      /* end tag tagName for currentNode does not match appendNode tagName,
       * traverse up parentNode until we find a match */
      while (StrICmp(t->appendNode->tagName, t->currentNode->tagName + 1)) {
        if (!StrICmp(t->appendNode->tagName,
                     "Document")) { // If we've traversed this far up, then the
                                    // closing tag is invalid
          t->appendNode = origAppendNode;
          return;
        }
        t->appendNode = t->appendNode->parentNode;
      }
    }
    t->appendNode = t->appendNode->parentNode;
    return;
  }
  JsonItem *nodeItem = CAlloc(sizeof(JsonItem));
  t->currentNode->parentNode = t->appendNode;
  nodeItem->value = t->currentNode;
  Json.AppendItem(t->appendNode->children, nodeItem);
  if (!@node_is_self_closing(t->currentNode))
    t->appendNode = t->currentNode;
}

U0 @set_current_attribute_on_current_node(Tokenizer *t) {
  Json.Set(t->currentNode->attributes, t->currentAttribute->name,
           t->currentAttribute->value, JSON_STRING);
}

U0 @tokenizer_html_state_data(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '&':
    // Set the return state to the data state. Switch to the character reference
    // state.
    t->returnState = HTML_STATE_DATA;
    t->state = HTML_STATE_CHARACTER_REFERENCE;
    break;
  case '<':
    // Switch to the tag open state.
    if (t->dataStateCounter)
      @emit_current_node(t);
    t->dataStateCounter = 0;
    t->state = HTML_STATE_TAG_OPEN;
    break;
  default:
    // Emit the current input character as a character token.
    @emit_current_character(t);
    break;
  }
}

U0 @tokenizer_html_state_tag_open(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '!':
    // Switch to the markup declaration open state.
    t->state = HTML_STATE_MARKUP_DECLARATION_OPEN;
    break;
  case '/':
    // Switch to the end tag open state.
    t->state = HTML_STATE_END_TAG_OPEN;
    break;
  case 'A' ... 'Z':
  case 'a' ... 'z':
    // Create a new start tag token, set its tag name to the empty string.
    // Reconsume in the tag name state.
    Node *node = @create_new_node("");
    t->currentNode = node;
    t->inputBuffer.pos--;
    t->state = HTML_STATE_TAG_NAME;
    break;
  case '?':
    // This is an unexpected-question-mark-instead-of-tag-name parse error.
    // Create a comment token whose data is the empty string. Reconsume in the
    // bogus comment state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_BOGUS_COMMENT;
    break;
  default:
    // This is an invalid-first-character-of-tag-name parse error. Emit a U+003C
    // LESS-THAN SIGN character token. Reconsume in the data state.
    @emit_current_character(t);
    t->inputBuffer.pos--;
    t->state = HTML_STATE_DATA;
    break;
  }
}

U0 @tokenizer_html_state_markup_declaration_open(Tokenizer *t) {
  if ((t->inputBuffer.data[t->inputBuffer.pos] == '-') &&
      (t->inputBuffer.data[t->inputBuffer.pos + 1] == '-')) {
    // Consume those two characters, create a comment token whose data is the
    // empty string, and switch to the comment start state.
    t->inputBuffer.pos += 2;
    t->state = HTML_STATE_COMMENT_START;
    return;
  }
  U8 buf[8];
  buf[7] = NULL;
  MemCpy(buf, t->inputBuffer.data + t->inputBuffer.pos, 7);
  if (!StrICmp(buf, "DOCTYPE")) {
    // Consume those characters and switch to the DOCTYPE state.
    t->inputBuffer.pos += 7;
    t->state = HTML_STATE_DOCTYPE;
    return;
  }
  t->state = HTML_STATE_BOGUS_COMMENT;
}

U0 @tokenizer_html_state_doctype(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Switch to the before DOCTYPE name state.
    t->state = HTML_STATE_BEFORE_DOCTYPE_NAME;
    break;
  case '>':
    // Reconsume in the before DOCTYPE name state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_BEFORE_DOCTYPE_NAME;
    break;
  default:
    // This is a missing-whitespace-before-doctype-name parse error. Reconsume
    // in the before DOCTYPE name state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_BEFORE_DOCTYPE_NAME;
    break;
  }
}

U0 @tokenizer_html_state_before_doctype_name(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Ignore the character.
    break;
  case 'A' ... 'Z':
    // Create a new DOCTYPE token. Set the token's name to the lowercase version
    // of the current input character (add 0x0020 to the character's code
    // point). Switch to the DOCTYPE name state.
    t->state = HTML_STATE_DOCTYPE_NAME;
    break;
  case '>':
    // This is a missing-doctype-name parse error. Create a new DOCTYPE token.
    // Set its force-quirks flag to on. Switch to the data state. Emit the
    // current token.
    @emit_current_character(t);
    t->state = HTML_STATE_DATA;
    break;
  default:
    // Create a new DOCTYPE token. Set the token's name to the current input
    // character. Switch to the DOCTYPE name state.
    t->state = HTML_STATE_DOCTYPE_NAME;
    break;
  }
}

U0 @tokenizer_html_state_doctype_name(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Switch to the after DOCTYPE name state.
    t->state = HTML_STATE_AFTER_DOCTYPE_NAME;
    break;
  case '>':
    // Switch to the data state. Emit the current DOCTYPE token.
    t->state = HTML_STATE_DATA;
    break;
  case 'A' ... 'Z':
    // Append the lowercase version of the current input character (add 0x0020
    // to the character's code point) to the current DOCTYPE token's name.
    break;
  default:
    // Append the current input character to the current DOCTYPE token's name.
    break;
  }
}

U0 @tokenizer_html_state_after_doctype_name(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Ignore the character.
    break;
  case 'A' ... 'Z':
    // Create a new DOCTYPE token. Set the token's name to the lowercase version
    // of the current input character (add 0x0020 to the character's code
    // point). Switch to the DOCTYPE name state.
    t->state = HTML_STATE_DOCTYPE_NAME;
    break;
  case '>':
    // Switch to the data state. Emit the current DOCTYPE token.
    t->state = HTML_STATE_DATA;
    break;
  default:
    // Reconsume in the bogus DOCTYPE state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_BOGUS_DOCTYPE;
    break;
  }
}

U0 @tokenizer_html_state_bogus_doctype(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '>':
    // Switch to the data state. Emit the DOCTYPE token.
    t->state = HTML_STATE_DATA;
    break;
  default:
    // Ignore the character.
    break;
  }
}

U0 @tokenizer_html_state_tag_name(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Switch to the before attribute name state.
    t->state = HTML_STATE_BEFORE_ATTRIBUTE_NAME;
    break;
  case '/':
    // Switch to the self-closing start tag state.
    t->state = HTML_STATE_SELF_CLOSING_START_TAG;
    break;
  case '>':
    // Switch to the data state. Emit the current tag token.
    @emit_current_node(t);
    t->state = HTML_STATE_DATA;
    break;
  case 'A' ... 'Z':
    // Append the lowercase version of the current input character (add 0x0020
    // to the character's code point) to the current tag token's tag name.
    t->currentNode->tagName[StrLen(t->currentNode->tagName)] =
        t->currentInputChar + 0x20;
    if (!StrICmp(t->currentNode->tagName, "img"))
      t->numOfImgNodes++;
    break;
  default:
    // Append the current input character to the current tag token's tag name.
    t->currentNode->tagName[StrLen(t->currentNode->tagName)] =
        t->currentInputChar;
    if (!StrICmp(t->currentNode->tagName, "img"))
      t->numOfImgNodes++;
    break;
  }
}

U0 @tokenizer_html_state_before_attribute_name(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Ignore the character.
    break;
  case '/':
  case '>':
    // Reconsume in the after attribute name state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_AFTER_ATTRIBUTE_NAME;
    break;
  case '=':
    // This is an unexpected-equals-sign-before-attribute-name parse error.
    // Start a new attribute in the current tag token. Set that attribute's name
    // to the current input character, and its value to the empty string. Switch
    // to the attribute name state.
    t->currentAttribute = CAlloc(sizeof(JsonKey));
    t->currentAttribute->name = @init_growable_string;
    t->currentAttribute->value = @init_growable_string;
    t->currentAttribute->name = @append_char_to_growable_string(
        t->currentAttribute->name, t->currentInputChar);
    t->state = HTML_STATE_ATTRIBUTE_NAME;
    break;
  default:
    // Start a new attribute in the current tag token. Set that attribute name
    // and value to the empty string. Reconsume in the attribute name state.
    t->currentAttribute = CAlloc(sizeof(JsonKey));
    t->currentAttribute->name = @init_growable_string;
    t->currentAttribute->value = @init_growable_string;
    t->inputBuffer.pos--;
    t->state = HTML_STATE_ATTRIBUTE_NAME;
    break;
  }
}

U0 @tokenizer_html_state_attribute_name(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
  case '/':
  case '>':
    // Reconsume in the after attribute name state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_AFTER_ATTRIBUTE_NAME;
    break;
  case '=':
    // Switch to the before attribute value state.
    t->state = HTML_STATE_BEFORE_ATTRIBUTE_VALUE;
    break;
  case 'A' ... 'Z':
    // Append the lowercase version of the current input character (add 0x0020
    // to the character's code point) to the current attribute's name.
    t->currentAttribute->name = @append_char_to_growable_string(
        t->currentAttribute->name, t->currentInputChar + 0x20);
    break;
  case '"':
  case '\'':
  case '<':
  // This is an unexpected-character-in-attribute-name parse error. Treat it as
  // per the "anything else" entry below.
  default:
    // Append the current input character to the current attribute's name.
    t->currentAttribute->name = @append_char_to_growable_string(
        t->currentAttribute->name, t->currentInputChar);
    break;
  }
}

U0 @tokenizer_html_state_before_attribute_value(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Ignore the character.
    break;
  case '"':
    // Switch to the attribute value (double-quoted) state.
    t->state = HTML_STATE_ATTRIBUTE_VALUE_DOUBLE_QUOTED;
    break;
  case '\'':
    // Switch to the attribute value (single-quoted) state.
    t->state = HTML_STATE_ATTRIBUTE_VALUE_SINGLE_QUOTED;
    break;
  case '>':
    // This is a missing-attribute-value parse error. Switch to the data state.
    // Emit the current tag token.
    @emit_current_node(t);
    t->state = HTML_STATE_DATA;
    break;
  default:
    // Reconsume in the attribute value (unquoted) state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_ATTRIBUTE_VALUE_UNQUOTED;
    break;
  }
}

U0 @tokenizer_html_state_attribute_value_double_quoted(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '"':
    // Switch to the after attribute value (quoted) state.
    @set_current_attribute_on_current_node(t);
    t->state = HTML_STATE_AFTER_ATTRIBUTE_VALUE_QUOTED;
    break;
  /*
  case '&':
    // Set the return state to the attribute value (double-quoted) state. Switch
    // to the character reference state.
    t->returnState = HTML_STATE_ATTRIBUTE_VALUE_DOUBLE_QUOTED;
    t->state = HTML_STATE_CHARACTER_REFERENCE;
    break;
  */
  default:
    // Append the current input character to the current attribute's value.
    t->currentAttribute->value = @append_char_to_growable_string(
        t->currentAttribute->value, t->currentInputChar);
    break;
  }
}

U0 @tokenizer_html_state_attribute_value_single_quoted(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\'':
    // Switch to the after attribute value (quoted) state.
    @set_current_attribute_on_current_node(t);
    t->state = HTML_STATE_AFTER_ATTRIBUTE_VALUE_QUOTED;
    break;
  /*
  case '&':
    // Set the return state to the attribute value (double-quoted) state. Switch
    // to the character reference state.
    t->returnState = HTML_STATE_ATTRIBUTE_VALUE_SINGLE_QUOTED;
    t->state = HTML_STATE_CHARACTER_REFERENCE;
    break;
  */
  default:
    // Append the current input character to the current attribute's value.
    t->currentAttribute->value = @append_char_to_growable_string(
        t->currentAttribute->value, t->currentInputChar);
    break;
  }
}

U0 @tokenizer_html_state_after_attribute_value_quoted(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Switch to the before attribute name state.
    t->state = HTML_STATE_BEFORE_ATTRIBUTE_NAME;
    break;
  case '/':
    // Switch to the self-closing start tag state.
    t->state = HTML_STATE_SELF_CLOSING_START_TAG;
    break;
  case '>':
    // Switch to the data state. Emit the current tag token.
    @emit_current_node(t);
    t->state = HTML_STATE_DATA;
    break;
  default:
    // This is a missing-whitespace-between-attributes parse error. Reconsume in
    // the before attribute name state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_BEFORE_ATTRIBUTE_NAME;
    break;
  }
}

U0 @tokenizer_html_state_end_tag_open(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case 'A' ... 'Z':
  case 'a' ... 'z':
    // Create a new end tag token, set its tag name to the empty string.
    // Reconsume in the tag name state.
    Node *node = @create_new_node("/");
    t->currentNode = node;
    t->inputBuffer.pos--;
    t->state = HTML_STATE_TAG_NAME;
    break;
  case '>':
    // This is a missing-end-tag-name parse error. Switch to the data state.
    t->state = HTML_STATE_DATA;
    break;
  default:
    // This is an invalid-first-character-of-tag-name parse error. Create a
    // comment token whose data is the empty string. Reconsume in the bogus
    // comment state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_BOGUS_COMMENT;
    break;
  }
}

U0 @tokenizer_html_state_after_attribute_name(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '\n':
  case '\r':
  case '\t':
  case ' ':
    // Ignore the character.
    break;
  /*
  case '"':
    // Switch to the attribute value (double-quoted) state.
    t->state = HTML_STATE_ATTRIBUTE_VALUE_DOUBLE_QUOTED;
    break;
  case '\'':
    // Switch to the attribute value (single-quoted) state.
    t->state = HTML_STATE_ATTRIBUTE_VALUE_SINGLE_QUOTED;
    break;
  */
  case '/':
    // Switch to the self-closing start tag state.
    t->state = HTML_STATE_SELF_CLOSING_START_TAG;
    break;
  case '=':
    // Switch to the before attribute value state.
    t->state = HTML_STATE_BEFORE_ATTRIBUTE_VALUE;
    break;
  case '>':
    // Switch to the data state. Emit the current tag token.
    @set_current_attribute_on_current_node(t);
    @emit_current_node(t);
    t->state = HTML_STATE_DATA;
    break;
  default:
    // Start a new attribute in the current tag token. Set that attribute name
    // and value to the empty string. Reconsume in the attribute name state.
    t->currentAttribute = CAlloc(sizeof(JsonKey));
    t->currentAttribute->name = @init_growable_string;
    t->currentAttribute->value = @init_growable_string;
    t->inputBuffer.pos--;
    t->state = HTML_STATE_ATTRIBUTE_NAME;
    break;
  }
}

U0 @tokenizer_html_state_self_closing_start_tag(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '>':
    // Set the self-closing flag of the current tag token. Switch to the data
    // state. Emit the current tag token.
    @emit_current_node(t);
    t->state = HTML_STATE_DATA;
    break;
  default:
    // This is an unexpected-solidus-in-tag parse error. Reconsume in the before
    // attribute name state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_BEFORE_ATTRIBUTE_NAME;
    break;
  }
}

U0 @tokenizer_html_state_character_reference(Tokenizer *t) {
  // Set the temporary buffer to the empty string.
  @empty_temp_buffer(t);
  // Append a U+0026 AMPERSAND (&) character to the temporary buffer.
  @append_char_to_temp_buffer(t, '&');
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case 'A' ... 'Z':
  case 'a' ... 'z':
    // Reconsume in the named character reference state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_NAMED_CHARACTER_REFERENCE;
    break;
  case '#':
    // Append the current input character to the temporary buffer. Switch to the
    // numeric character reference state.
    @append_char_to_temp_buffer(t, '#');
    t->state = HTML_STATE_NUMERIC_CHARACTER_REFERENCE;
    break;
  default:
    // Flush code points consumed as a character reference. Reconsume in the
    // return state.
    t->consumeTempBuffer = TRUE;
    t->state = t->returnState;
    break;
  }
}

U0 @tokenizer_html_state_named_character_reference(Tokenizer *t) {
  // Consume the maximum number of characters possible, where the consumed
  // characters are one of the identifiers in the first column of the named
  // character references table. Append each character to the temporary buffer
  // when it's consumed.
  @consume_next_input_char(t);
  @append_char_to_temp_buffer(t, t->currentInputChar);
  switch (t->currentInputChar) {
  case ';':
    @replace_temp_buffer_with_named_character_reference(t);
    t->consumeTempBuffer = TRUE;
    t->state = t->returnState;
    break;
  default:
    break;
  }
}

U0 @tokenizer_html_state_numeric_character_reference(Tokenizer *t) {
  @consume_next_input_char(t);
  @append_char_to_temp_buffer(t, t->currentInputChar);
  switch (t->currentInputChar) {
  case ';':
    @replace_temp_buffer_with_numeric_character_reference(t);
    t->consumeTempBuffer = TRUE;
    t->state = t->returnState;
    break;
  default:
    break;
  }
}

U0 @tokenizer_html_state_comment_start(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '-':
    // Switch to the comment start dash state.
    t->state = HTML_STATE_COMMENT_START_DASH;
    break;
  case '>':
    // This is an abrupt-closing-of-empty-comment parse error. Switch to the
    // data state. Emit the current comment token.
    t->state = HTML_STATE_DATA;
    break;
  default:
    // Reconsume in the comment state.
    t->inputBuffer.pos--;
    t->state = HTML_STATE_COMMENT;
    break;
  }
}

U0 @tokenizer_html_state_comment(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '<':
    // Append the current input character to the comment token's data. Switch to
    // the comment less-than sign state.
    t->state = HTML_STATE_COMMENT_LESS_THAN_SIGN;
    break;
  case '-':
    // Switch to the comment end dash state.
    t->state = HTML_STATE_COMMENT_END_DASH;
    break;
  default:
    // Append the current input character to the comment token's data.
    break;
  }
}

U0 @tokenizer_html_state_comment_end_dash(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '-':
    // Switch to the comment end state.
    t->state = HTML_STATE_COMMENT_END;
    break;
  default:
    // Append a U+002D HYPHEN-MINUS character (-) to the comment token's data.
    // Reconsume in the comment state.
    t->inputBuffer.pos--;
    t->inputBuffer.data[t->inputBuffer.pos] = '-';
    t->state = HTML_STATE_COMMENT;
    break;
  }
}

U0 @tokenizer_html_state_comment_end(Tokenizer *t) {
  @consume_next_input_char(t);
  switch (t->currentInputChar) {
  case '>':
    // Switch to the data state. Emit the current comment token.
    t->state = HTML_STATE_DATA;
    break;
  case '!':
    // Switch to the comment end bang state.
    t->state = HTML_STATE_COMMENT_END_BANG;
    break;
  case '-':
    // Append a U+002D HYPHEN-MINUS character (-) to the comment token's data.
    break;
  default:
    // Append two U+002D HYPHEN-MINUS characters (-) to the comment token's
    // data. Reconsume in the comment state.
    t->inputBuffer.pos--;
    t->inputBuffer.data[t->inputBuffer.pos] = '-';
    t->inputBuffer.pos--;
    t->inputBuffer.data[t->inputBuffer.pos] = '-';
    t->state = HTML_STATE_COMMENT;
    break;
  }
}

U0 @dump_node(Tokenizer *t, Node *node) {

  I64 i;

  if (StrICmp(node->tagName, "InternalTextNode") &&
      StrICmp(node->tagName, "Document")) {
    for (i = 0; i < t->nodeTreeDepth; i++)
      "-";
    "<%s> : parentNode: <%s 0x%08x>\n", node->tagName,
        node->parentNode->tagName, node->parentNode;
  }

  if (node->children->length) {
    t->nodeTreeDepth += 2;
    for (i = 0; i < node->children->length; i++)
      @dump_node(t, Json.ArrayIndex(node->children, i));
    t->nodeTreeDepth -= 2;
  }
}

U0 @dump_node_tree(Tokenizer *t) {
  t->nodeTreeDepth = -2;
  @dump_node(t, t->originNode);
  "\n";
}

Bool tokenizer_debug = FALSE;

Node *@html_tokenize_and_create_node_tree(U8 *buffer, I64 size,
                                          I64 *num_of_images) {
  Tokenizer t;
  U8 buf[512];
  U8 *buf2;
  no_warn buf, buf2;
  @init_tokenizer(&t, buffer, size);
  while (t.inputBuffer.pos < t.inputBuffer.size && buffer[t.inputBuffer.pos]) {

    if (tokenizer_debug) {
      StrPrint(buf, "pos: %d, char: %c, state: %d\n", t.inputBuffer.pos,
               t.inputBuffer.data[t.inputBuffer.pos], t.state);
      buf2 = &buf;
      while (*buf2)
        OutU8(0x504, *buf2++);
    }

    switch (t.state) {
    case HTML_STATE_DATA:
      @tokenizer_html_state_data(&t);
      break;
    case HTML_STATE_TAG_OPEN:
      @tokenizer_html_state_tag_open(&t);
      break;
    case HTML_STATE_MARKUP_DECLARATION_OPEN:
      @tokenizer_html_state_markup_declaration_open(&t);
      break;
    case HTML_STATE_DOCTYPE:
      @tokenizer_html_state_doctype(&t);
      break;
    case HTML_STATE_BEFORE_DOCTYPE_NAME:
      @tokenizer_html_state_before_doctype_name(&t);
      break;
    case HTML_STATE_DOCTYPE_NAME:
      @tokenizer_html_state_doctype_name(&t);
      break;
    case HTML_STATE_TAG_NAME:
      @tokenizer_html_state_tag_name(&t);
      break;
    case HTML_STATE_BEFORE_ATTRIBUTE_NAME:
      @tokenizer_html_state_before_attribute_name(&t);
      break;
    case HTML_STATE_ATTRIBUTE_NAME:
      @tokenizer_html_state_attribute_name(&t);
      break;
    case HTML_STATE_BEFORE_ATTRIBUTE_VALUE:
      @tokenizer_html_state_before_attribute_value(&t);
      break;
    case HTML_STATE_ATTRIBUTE_VALUE_DOUBLE_QUOTED:
      @tokenizer_html_state_attribute_value_double_quoted(&t);
      break;
    case HTML_STATE_AFTER_ATTRIBUTE_VALUE_QUOTED:
      @tokenizer_html_state_after_attribute_value_quoted(&t);
      break;
    case HTML_STATE_CHARACTER_REFERENCE:
      @tokenizer_html_state_character_reference(&t);
      break;
    case HTML_STATE_END_TAG_OPEN:
      @tokenizer_html_state_end_tag_open(&t);
      break;
    case HTML_STATE_AFTER_ATTRIBUTE_NAME:
      @tokenizer_html_state_after_attribute_name(&t);
      break;
    case HTML_STATE_ATTRIBUTE_VALUE_SINGLE_QUOTED:
      @tokenizer_html_state_attribute_value_single_quoted(&t);
      break;
    case HTML_STATE_NAMED_CHARACTER_REFERENCE:
      @tokenizer_html_state_named_character_reference(&t);
      break;
    case HTML_STATE_NUMERIC_CHARACTER_REFERENCE:
      @tokenizer_html_state_numeric_character_reference(&t);
      break;
    case HTML_STATE_AFTER_DOCTYPE_NAME:
      @tokenizer_html_state_after_doctype_name(&t);
      break;
    case HTML_STATE_BOGUS_DOCTYPE:
      @tokenizer_html_state_bogus_doctype(&t);
      break;
    case HTML_STATE_SELF_CLOSING_START_TAG:
      @tokenizer_html_state_self_closing_start_tag(&t);
      break;
    case HTML_STATE_COMMENT_START:
      @tokenizer_html_state_comment_start(&t);
      break;
    case HTML_STATE_COMMENT:
      @tokenizer_html_state_comment(&t);
      break;
    case HTML_STATE_COMMENT_END_DASH:
      @tokenizer_html_state_comment_end_dash(&t);
      break;
    case HTML_STATE_COMMENT_END:
      @tokenizer_html_state_comment_end(&t);
      break;
    case HTML_STATE_INVALID:
    default:
      @debug("\n$FG,0$HTML Tokenization error: Invalid or unimplemented "
             "state\nInputBuffer position: %d\nState: %d$FD$\n",
             t.inputBuffer.pos, t.state);
      "\n";
      //@dump_node_tree(&t);
      PressAKey;
      break;
    }
  }
  //@dump_node_tree(&t);
  Node *node_tree = t.originNode;
  *num_of_images = t.numOfImgNodes;
  return node_tree;
}
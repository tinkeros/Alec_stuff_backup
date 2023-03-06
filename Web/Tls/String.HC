U8 **@string_split(U8 *s, U8 ch = '\n', I64 *cnt) {
  U8 *p = s;
  cnt[0] = 0;
  while (*p) {
    if (*p == ch)
      cnt[0]++;
    p++;
  }
  if (!(cnt[0]))
    return NULL;
  cnt[0]++;
  I64 i = -1;
  U8 **arr = CAlloc(sizeof(U8 *) * cnt[0]);
  p = s;
  while (*p) {
    if (*p == ch || i < 0) {
      i++;
      arr[i] = p;
      if (*p == ch) {
        arr[i]++;
        *p = NULL;
      }
    }
    p++;
  }
  return arr;
}

U0 @string_append(U8 *dst, U8 *fmt,
                  ...) { // Append to pre-alloced string. COMPLETELY unsafe.
  U8 *buf;
  if (argc) {
    buf = StrPrintJoin(NULL, fmt, argc, argv);
  } else {
    buf = StrNew(fmt);
  }
  U8 *src = buf;
  StrCpy(dst + StrLen(dst), src);
  Free(buf);
}

Bool @string_is_number(U8 *s) {
  while (*s) {
    switch (*s) {
    case '-':
    case '.':
    case '0' ... '9':
      break;
    default:
      return FALSE;
      break;
    }
    s++;
  }
  return TRUE;
}

U8 *@string_replace(U8 *s, U8 *oldW, U8 *newW) {
  if (!StrFind(oldW, s)) {
    return StrNew(s);
  }
  U8 *result;
  I64 i, cnt = 0;
  I64 newWlen = StrLen(newW);
  I64 oldWlen = StrLen(oldW);

  // Counting the number of times old word
  // occur in the string
  for (i = 0; s[i] != '\0'; i++) {
    if (StrFind(oldW, &s[i]) == &s[i]) {
      cnt++;

      // Jumping to index after the old word.
      i += oldWlen - 1;
    }
  }

  // Making new string of enough length
  result = MAlloc(i + cnt * (newWlen - oldWlen) + 1);

  i = 0;
  while (*s) {
    // compare the substring with the result
    if (StrFind(oldW, s) == s) {
      StrCpy(&result[i], newW);
      i += newWlen;
      s += oldWlen;
    } else
      result[i++] = *s++;
  }

  result[i] = '\0';
  return result;
}

class @string {
  U0 (*Append)(U8 * dst, U8 * fmt, ...);
  Bool (*IsNumber)(U8 * s);
  U8 *(*Replace)(U8 * s, U8 * oldW, U8 * newW);
  U8 **(*Split)(U8 * s, U8 ch = '\n', I64 * cnt);
};

@string String;
String.Append = &@string_append;
String.IsNumber = &@string_is_number;
String.Replace = &@string_replace;
String.Split = &@string_split;

"[OK] string \n";
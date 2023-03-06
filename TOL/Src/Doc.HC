U0 @task_doc_push(U64 desc) {
  CDoc *push_doc = DocNew;
  push_doc->desc = desc;
  push_doc->parent_doc = Fs->display_doc;
  Fs->display_doc = push_doc;
  Fs->put_doc = push_doc;
}

U0 @task_doc_pop() {
  CDoc *pop_doc = Fs->display_doc;
  Fs->display_doc = pop_doc->parent_doc;
  Fs->put_doc = pop_doc->parent_doc;
  DocDel(pop_doc);
}

U8 @popup_get_str_task(U8 *prompt) {
  DocClear;
  "\n";
  "\dFG,0\d %s\dFD\d", prompt;
  return GetStr;
}

U8 @popup_get_str(U8 *title, U8 *prompt) {
  CTask *p = User("Fs->user_data = @popup_get_str_task(0x%08x);\n", prompt);
  while (!p->user_data) {
    StrCpy(p->task_title, title);
    p->win_top = 20;
    p->win_bottom = p->win_top + 2;
    p->put_doc->desc = NULL;
    Sleep(1);
  }
  U8 *res = StrNew(p->user_data);
  Kill(p);
  return res;
}
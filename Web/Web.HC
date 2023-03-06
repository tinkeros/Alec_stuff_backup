
I64 roundUp(I64 numToRound, I64 multiple) {
  if (multiple == 0)
    return numToRound;

  I64 remainder = Abs(numToRound) % multiple;
  if (remainder == 0)
    return numToRound;

  if (numToRound < 0)
    return -(Abs(numToRound) - remainder);
  else
    return numToRound + multiple - remainder;
}

#define WEB_RESPONSE_BUFFER_SIZE 1048576 * 4

U8 *web_page_buffer = CAlloc(WEB_RESPONSE_BUFFER_SIZE);
U8 *web_resource_buffer = CAlloc(WEB_RESPONSE_BUFFER_SIZE);

/* clang-format off */

#include "TGL";

#include "Src/Debug";
#include "Src/Doc";
#include "Src/Json";
#include "Src/HTMLTokenizer";
#include "Src/HTMLRenderer";

/* clang-format on */

U0 @set_title_src(CTask *task) {
  while (1) {
    StrCpy(task->task_title, "title");
    StrCpy(task->task_name, "title");
    Sleep(1);
  }
}

I64 Web(U8 *url_string) {
  no_warn url_string;
  @task_doc_push('Web');

  "$WW$";

  progress1 = 0;
  progress1_max = 1;

  StrPrint(progress1_desc, "Loading web page ...");

  MemSet(web_page_buffer, NULL, WEB_RESPONSE_BUFFER_SIZE);
  @http_get(@http_parse_url(url_string), web_page_buffer);

  // I64 data_size;
  // U8 *data = FileRead("T:/Tests/86902743.html", &data_size);

  U8 *buffer = web_page_buffer;
  while (MemCmp(buffer, "\x0a\x0d\x0a", 3))
    buffer++;
  buffer += 3;

  I64 num_of_images = 0;

  StrPrint(progress1_desc, "Processing HTML data ...");

  Node *node_tree = @html_tokenize_and_create_node_tree(
      buffer, WEB_RESPONSE_BUFFER_SIZE, &num_of_images);

  progress1_max = num_of_images;

  CDoc *render_doc = DocPut;

  // DocPrint(Fs->border_doc, "\nURL: %s\n", url_string);

  DocClear(render_doc);
  DocPrint(render_doc, "\dWW\d\dFG,8\d");

  @render_node_tree(NULL, render_doc, node_tree);
  @calculate_indents_for_sprites(render_doc);

  progress1_max = 0;

  DocTop(render_doc);
  while (1) {
    GetStr;
  }
  DocClear(render_doc);

  @task_doc_pop;
  return 0;
}

WinMax;

Web(PopUpGetStr("URL: "));
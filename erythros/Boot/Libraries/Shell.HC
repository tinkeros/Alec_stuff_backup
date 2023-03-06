#define SHELL_INPUT_FIFO_SIZE 4096

class @shell_autocomplete {
  I64 depth;
  I64 length[8];
  U8 ***entries;
};

class @shell_history {
  I64 limit;
  I64 pos;
  U8 **entries;
};

class @shell_readline {
  @shell_autocomplete autocomplete;
  @shell_history history;
};

class @shell {
  CFifoU8 *input;
  CFifoU8 *output;
  CTask *task;
  Bool exit;
  @shell_readline readline;
  U8 PS1[512];
  U8 PS2[512];
  U8 PS3[512];
  U8 PS4[512];
};

"shell ";
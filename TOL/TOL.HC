#include "PacketData";

#define AOL_HOST "reaol.org"
#define AOL_PORT 5190

class AolPacketHeader {
  U8 start_of_frame;
  U16 checksum;
  U16 length;
  U8 tx_seq;
  U8 rx_seq;
  U8 type;
};

class AolDataPacket : AolPacketHeader {
  U8 token[2];
  U8 data;
};

U8 *aol_recv_buf = CAlloc(1048576 * 4);
U8 *aol_send_buf = CAlloc(1048576 * 4);

U0 @tol_send_init(I64 s) {
  I64 len = 58;
  U8 *buf = @aol_packet_init;
  buf[1] = '*';
  buf[2] = '*';
  send(s, buf, len, 0);
}

U0 @tol_sign_in_as_guest(I64 s) {
  I64 len = 66;
  U8 *buf = @aol_packet_sign_in_as_guest;
  buf[1] = '*';
  buf[2] = '*';
  send(s, buf, len, 0);
}

U0 @tol_send_sc(I64 s) {
  I64 len = 26;
  U8 *buf = @aol_packet_sc;
  buf[1] = '*';
  buf[2] = '*';
  send(s, buf, len, 0);
}

U0 @tol_join_room(I64 s, U8 *name) {
  I64 len = 36;
  U8 *buf = CAlloc(1024);
  U8 *tbuf = @aol_packet_join_chat_room;
  MemCpy(buf, tbuf, len);

  AolPacketHeader *pkt = buf;

  buf[1] = '*';
  buf[2] = '*';

  buf[0x18] = StrLen(name);
  MemCpy(buf + 0x19, name, StrLen(name));
  buf[0x19 + StrLen(name) + 0] = 0x00;
  buf[0x19 + StrLen(name) + 1] = 0x02;
  buf[0x19 + StrLen(name) + 2] = 0x00;
  buf[0x19 + StrLen(name) + 3] = 0x0d;

  pkt->length = 0x19 + StrLen(name) + 4;

  send(s, buf, pkt->length, 0);
  Free(buf);
}

Bool @wait_for_ack(I64 s) {
  AolPacketHeader *pkt = aol_recv_buf;
  I64 len = recv(s, aol_recv_buf, 1024, 0);
  if (pkt->type == 0x24) {
    return FALSE;
  }
  return TRUE;
}

U8 *@terminate_buffer(U8 *s) {
  U8 *res = s;
  while (*s != 0x0d)
    s++;
  *s = NULL;
  return res;
}

U8 *@skip_null_padding(U8 *s) {
  while (!(*s))
    s++;
  return s;
}

U0 @send_msg(I64 s, U8 *my_msg) {

  I64 len = 45;
  U8 *buf = CAlloc(1024);
  U8 *tbuf = @aol_packet_send_chat_message;
  MemCpy(buf, tbuf, len);

  AolPacketHeader *pkt = buf;

  buf[1] = '*';
  buf[2] = '*';

  buf[0x1f] = StrLen(my_msg);
  MemCpy(buf + 0x20, my_msg, StrLen(my_msg));
  buf[0x20 + StrLen(my_msg) + 0] = 0x00;
  buf[0x20 + StrLen(my_msg) + 1] = 0x02;
  buf[0x20 + StrLen(my_msg) + 2] = 0x00;
  buf[0x20 + StrLen(my_msg) + 3] = 0x0d;

  pkt->length = 0x20 + StrLen(my_msg) + 4;

  send(s, buf, pkt->length, 0);
  Free(buf);
}

U0 @send_im(I64 s, U8 *name, U8 *my_msg) {

  I64 len = 73;
  U8 *buf = CAlloc(1024);
  U8 *tbuf = @aol_packet_send_im;
  MemCpy(buf, tbuf, len);

  AolPacketHeader *pkt = buf;

  buf[1] = '*';
  buf[2] = '*';

  buf[0x1f] = StrLen(name);
  MemCpy(buf + 0x20, name, StrLen(name));

  buf[0x20 + StrLen(name) + 00] = 0x01;
  buf[0x20 + StrLen(name) + 01] = 0x1d;
  buf[0x20 + StrLen(name) + 02] = 0x00;
  buf[0x20 + StrLen(name) + 03] = 0x01;
  buf[0x20 + StrLen(name) + 04] = 0x0a;
  buf[0x20 + StrLen(name) + 05] = 0x04;
  buf[0x20 + StrLen(name) + 06] = 0x00;
  buf[0x20 + StrLen(name) + 07] = 0x00;
  buf[0x20 + StrLen(name) + 08] = 0x00;
  buf[0x20 + StrLen(name) + 09] = 0x02;
  buf[0x20 + StrLen(name) + 10] = 0x03;
  buf[0x20 + StrLen(name) + 11] = 0x01;

  buf[0x20 + StrLen(name) + 12] = StrLen(my_msg);
  MemCpy(buf + 0x20 + StrLen(name) + 13, my_msg, StrLen(my_msg));

  buf[0x20 + StrLen(name) + 13 + StrLen(my_msg) + 00] = 0x01;
  buf[0x20 + StrLen(name) + 13 + StrLen(my_msg) + 01] = 0x1d;
  buf[0x20 + StrLen(name) + 13 + StrLen(my_msg) + 02] = 0x00;
  buf[0x20 + StrLen(name) + 13 + StrLen(my_msg) + 03] = 0x00;
  buf[0x20 + StrLen(name) + 13 + StrLen(my_msg) + 04] = 0x02;
  buf[0x20 + StrLen(name) + 13 + StrLen(my_msg) + 05] = 0x00;
  buf[0x20 + StrLen(name) + 13 + StrLen(my_msg) + 06] = 0x0d;

  pkt->length = 0x20 + StrLen(name) + 13 + StrLen(my_msg) + 07;

  send(s, buf, pkt->length, 0);
  Free(buf);
}

U0 @tol_send_im_loop(U8 *name) {
  U8 *msg;
  while (1) {
    DocClear;
    msg = GetStr;
    if (StrLen(msg))
      @send_im(aol_socket, name, msg);
    DocPrint(Fs->parent_task->put_doc, "\dFG,RED\d%s:  \dFG,BLACK\d%s\n\dFD\d",
             "Me", msg);
    Play("st4C#F#sB");
  }
}

U0 @tol_init_im_window(U8 *name) {
  // Set window x, y, w, h

  I64 ww = 36;
  I64 hh = 15;

  Fs->win_left = (TEXT_COLS / 2) - (ww / 2);
  Fs->win_right = Fs->win_left + ww;
  Fs->win_top = 12;
  Fs->win_bottom = Fs->win_top + hh;

  // Set receive window details
  U8 buf[512];
  StrPrint(buf, "Instant Message from: %s", name);
  StrCpy(Fs->task_title, buf);
  Fs->put_doc->desc = 'Msg';

  // Clear document
  DocClear(Fs->put_doc);

  // Create Task for send window
  StrPrint(buf, "@tol_send_im_loop(\"%s\");\n", name);
  CTask *send_task = User(buf);
  send_task->parent_task = Fs;
  Sleep(200);

  // Set send window details
  send_task->put_doc->desc = '';
  send_task->border_doc = NULL;

  // Loop: send window follows recevive window
  while (1) {
    send_task->win_left = Fs->win_left;
    send_task->win_right = Fs->win_right;
    send_task->win_top = Fs->win_bottom + 3;
    send_task->win_bottom = send_task->win_top + 6;
    Sleep(1);
  }
}

U8 im_marker[5] = {0x0a, 0x01, 0x03, 0x01, 0x14};
U8 dialog_marker[6] = {0x00, 0x01, 0x01, 0x00, 0x01, 0x00};
U8 dialog_text_marker[4] = {0x01, 0x0a, 0x01, 0x14};

U0 @display_im(U8 *name, U8 *msg) {

  U8 buf[512];
  CDoc *doc = NULL;

  // Check if we already have a window open to display messages.
  PUSHFD
  CLI

      CCPU *c = &cpu_structs[0];
  CTask *task = c->seth_task;
  CTask *task1;
  task1 = task->next_child_task;
  while (task1 !=
         (&task->next_child_task)(U8 *)-offset(CTask.next_sibling_task)) {
    if (!StrICmp(task1->user_data, name)) {
      doc = task1->put_doc;
      WinToTop(task1);
      goto im_window_exists;
    }
    task1 = task1->next_sibling_task;
  }

im_window_exists:
  POPFD

  // If not, create one.

  if (!doc) {
    StrPrint(buf, "@tol_init_im_window(\"%s\");\n", name);
    CTask *new_im_task = User(buf);
    Sleep(500);
    new_im_task->user_data = StrNew(name);
    doc = new_im_task->put_doc;
  }

  DocPrint(doc, "\dFG,BLUE\d%s:  \dFG,BLACK\d%s\n\dFD\d", name, msg);
  Play("st4BF#sC#");
}

U0 @handle_atom_stream(I64 s) {

  I64 i;
  I64 j;
  I64 k;

  U8 ch;

  if (!MemCmp(aol_recv_buf + 12, dialog_marker, 6)) {

    // Received a Dialog box message
    U8 *title = aol_recv_buf + 0x14;
    *(StrFirstOcc(title, "\x10"))(U8 *) = NULL;

    for (i = title + StrLen(title) - aol_recv_buf; i < 1024 - 5; i++) {

      if (!MemCmp(aol_recv_buf + i, dialog_text_marker, 4)) {
        U8 *dialog_msg = CAlloc(1024);
        StrPrint(dialog_msg, "%s\n\n", title);
        I64 dialog_msg_length = *(aol_recv_buf + i + 0x4)(U8 *);

        // TODO: Parse whatever subset of HTML that AOL uses for its dialog
        // boxes

        k = 0;
        for (j = 0; j < dialog_msg_length; j++) {
          ch = aol_recv_buf[i + 0x5 + j];
          if (ch == '<')
            k = 1;
          if (ch == '>')
            k = 2;
          if (!k)
            dialog_msg[StrLen(dialog_msg)] = ch;
          if (k > 1)
            k = 0;
        }

        PopUpOk(dialog_msg);
        Free(dialog_msg);

        return;
      }
    }
  }

  for (i = 0; i < 1024 - 5; i++) {
    if (!MemCmp(aol_recv_buf + i, im_marker, 5)) {

      // Received an Instant Message, copy into temp buffer
      U8 *raw_im = CAlloc(1024);
      I64 raw_im_length = *(aol_recv_buf + i + 0x5)(U8 *);
      MemCpy(raw_im, aol_recv_buf + i + 0x6, raw_im_length);

      // Translate '\n'
      for (j = 0; j < StrLen(raw_im); j++)
        if (raw_im[j] == 0x7f)
          raw_im[j] = '\n';

      // Separate sender name and message
      U8 *msg = StrFirstOcc(raw_im, ":  ") + 3;
      U8 *name = raw_im;
      *(StrFirstOcc(raw_im, ":  "))(U8 *) = NULL;

      @display_im(name, msg);

      Free(raw_im);

      return;
    }
  }

  /*
  if (!MemCmp(aol_recv_buf + 0x44, "i2", 2)) {
  }
  */
}

U0 @event_handler(I64 s) {

  AolDataPacket *pkt = aol_recv_buf;
  U8 *name;
  U8 *msg;

  MemSet(aol_recv_buf, NULL, 1024);
  I64 len = recv(s, aol_recv_buf, 1024, 0);

  if (!MemCmp(pkt->token, "AT", 2)) {
    @handle_atom_stream(s);
  };
}

I64 TOL() {

  I64 err;

  sockaddr_in addr;
  I64 s = socket(AF_INET, SOCK_STREAM);
  if (s == -1) {
    PrintErr("Can't create socket.\n");
    return -1;
  }

  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = inet_addr(AOL_HOST);
  addr.sin_port = htons(AOL_PORT);

  err = connect(s, &addr, sizeof(addr));
  if (err == -1) {
    PrintErr("Can't connect to AOL server.\n");
    return -1;
  }

  "socket @ 0x%08x\n", s;
  aol_socket = s;

  "Connecting to Re-AOL ... \n";

  @tol_send_init(s);
  err = @wait_for_ack(s);
  if (err) {
    PrintErr("Malformed result; expected ACK\n");
    return -1;
  }
  @tol_sign_in_as_guest(s);
  @tol_send_sc(s);

  "Signed in as Guest\n";

  Sleep(2000);

  U8 *room_name = "TempleOS";
  @tol_join_room(s, room_name);

  "Joined chat room '%s'\n", room_name;
  "\n";

  while (1) {
    @event_handler(s);
    Sleep(1);
  }

  return 0;
}
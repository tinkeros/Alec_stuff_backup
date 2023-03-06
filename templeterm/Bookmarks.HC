#define TT_MAX_ENTRIES 64

class TTConnEntryForm
{
  U8 name[STR_LEN] format "$$DA-P,A=\"Name:%s\"$$\n";
  U8 host[STR_LEN] format "$$DA-P,A=\"Host:%s\"$$\n";
  I64 port format "$$DA,A=\"Port:%d\"$$\n";
  U8 user[STR_LEN] format "$$DA-P,A=\"Username:%s\"$$\n";
  U8 pass[STR_LEN] format "$$DA-P,A=\"Password:%s\"$$\n";
};

class TTConnEntry {
  U8 name[STR_LEN];
  U8 host[STR_LEN];
  I64 port;
  U8 user[STR_LEN];
  U8 pass[STR_LEN];
};

TTConnEntry *conn_entries;

TTConnEntry *conn_rc_entries;

TTConnEntryForm *add_form;
TTConnEntryForm *edit_form;

I64 conn_len=0;
I64 conn_idx=0;

U8 *conn_list;  
U8 *conn_edlist;  

U0 ConnEntriesRecalc()
{

  I64 oi=0;
  I64 ri=0;

  I64 p=0;
  while (p<sizeof(TTConnEntry)*TT_MAX_ENTRIES)
  {
    conn_list[p]=0;
    conn_edlist[p]=0;
    conn_rc_entries(U8*)[p]=0;
    p++;
  };
 
  while (oi<TT_MAX_ENTRIES)
  {
    if (conn_entries[oi].port>0)
    {
      StrPrint(conn_rc_entries[ri].name,conn_entries[oi].name);
      StrPrint(conn_rc_entries[ri].host,conn_entries[oi].host);
      conn_rc_entries[ri].port=conn_entries[oi].port;
      StrPrint(conn_rc_entries[ri].user,conn_entries[oi].user);
      StrPrint(conn_rc_entries[ri].pass,conn_entries[oi].pass);
      ri++;
    };
    oi++;
  };

  MemCpy(conn_entries, conn_rc_entries, sizeof(TTConnEntry)*TT_MAX_ENTRIES);

  conn_idx=0;
  conn_len=0;

  while (conn_idx<TT_MAX_ENTRIES)
  {
    if (conn_entries[conn_idx].port>0)
    {
      StrPrint(conn_list+conn_len,conn_entries[conn_idx].name);
      StrPrint(conn_edlist+conn_len,conn_entries[conn_idx].name);
      conn_len+=StrLen(conn_entries[conn_idx].name)+1;
      conn_idx++;
    }
    else
    {
      break;
    };
  }

}

public I64 PopUpBookmarkLst(U8 *lst)
{//Prompt for lst entry in PopUp win task.
  I64 res,i=0;
  CDoc *doc=DocNew;
  DocPrint(doc,"$$GREEN$$$$TX+CX,\"Connection List\"$$\n\n");
  DocPrint(doc,"$$LTBLUE$$");
  while (*lst) {
    if (*lst=='@') {//Check for '@' alias lst entry
      i--;
      lst++;
    }
    DocPrint(doc,"$$MU,\"%s\",LE=%d$$\n",lst,i++);
    lst+=StrLen(lst)+1;
  }
  DocPrint(doc,"\n$$MU,\"Add Entry\",LE=%d$$\n",i++);
  DocPrint(doc,"$$RED$$");
  DocPrint(doc,"$$MU,\"Delete Entry\",LE=%d$$\n",i++);
  DocPrint(doc,"$$LTBLUE$$");
  DocPrint(doc,"$$MU,\"Edit Entry\",LE=%d$$\n",i++);
  DocPrint(doc,"\n$$MU,\"CANCEL\",LE=DOCM_CANCEL$$\n");

  res=PopUpMenu(doc);
  DocDel(doc);
  return res;
}

public I64 PopUpDelLst(U8 *lst)
{//Prompt for lst entry in PopUp win task.
  I64 res,i=0;
  CDoc *doc=DocNew;
  DocPrint(doc,"$$RED$$$$TX+CX,\"Delete Entry\"$$\n\n");
  while (*lst) {
    if (*lst=='@') {//Check for '@' alias lst entry
      i--;
      lst++;
    }
    DocPrint(doc,"$$MU,\"%s\",LE=%d$$\n",lst,i++);
    lst+=StrLen(lst)+1;
  }
  DocPrint(doc,"\n$$LTBLUE$$");
  DocPrint(doc,"$$MU,\"CANCEL\",LE=DOCM_CANCEL$$\n");

  res=PopUpMenu(doc);
  DocDel(doc);
  return res;
}


public I64 PopUpEditLst(U8 *lst)
{//Prompt for lst entry in PopUp win task.
  I64 res,i=0;
  CDoc *doc=DocNew;
  DocPrint(doc,"$$BLUE$$$$TX+CX,\"Edit Entry\"$$\n\n");
  DocPrint(doc,"$$LTBLUE$$");
  while (*lst) {
    if (*lst=='@') {//Check for '@' alias lst entry
      i--;
      lst++;
    }
    DocPrint(doc,"$$MU,\"%s\",LE=%d$$\n",lst,i++);
    lst+=StrLen(lst)+1;
  }
  DocPrint(doc,"\n$$MU,\"CANCEL\",LE=DOCM_CANCEL$$\n");

  res=PopUpMenu(doc);
  DocDel(doc);
  return res;
}


U0 wswrite(I64 sock, U8 *str)
{
  sendString(sock, str, 0);
}

I64 DirList(I64 sock, U8 *files_find_mask)
{//List directory.
  CDirEntry *tmpde1=NULL,*tmpde2;
  U8 buf[256];
  U8 *st;
  CDateStruct ds;
  I64 csize=0xFFFF,c=0xFFFF,res=0;
  tmpde1=FilesFind(files_find_mask);
  if (!(st=DirCur))
    PrintErr("Invalid Drive\n");
  else {
    if (tmpde1) {
      Free(st);
      st=MAllocIdent(tmpde1->full_name);
      StrLastRem(st,"/");
      if (!st[2])
	StrCpy(st+2,"/");
//Find max columns
      tmpde2=tmpde1;
      while (tmpde2) {
	if (tmpde2->size>csize)
	  csize=tmpde2->size;
	if (tmpde2->clus>c)
	  c=tmpde2->clus;
	tmpde2=tmpde2->next;
      }
      csize=Bsr(csize)/4+1;
      c=Bsr(c)/4+1;

      StrPrint(buf, "<h2>Index of %s</h2><br>",st+2);
      wswrite(sock, buf);

      wswrite(sock, "<table>");      
      StrPrint(buf, "<tr><td>DATE_</td><td>TIME_</td><td>%*ts</td></tr>",csize,"SIZE");
      wswrite(sock, buf);
 
      while (tmpde1) {
	      tmpde2=tmpde1->next;
      	res++;
        Date2Struct(&ds,tmpde1->datetime+local_time_offset);
        StrPrint(buf, "<tr><td>%02d/%02d</td><td>%02d:%02d</td><td>%0*tX</td><td>",ds.mon,ds.day_of_mon,ds.hour,ds.min,
          csize,tmpde1->size);
        wswrite(sock, buf);
        StrPrint(buf, "<a href='%s'>", StrFirstOcc(tmpde1->full_name,"/"));
        wswrite(sock, buf);
        StrPrint(buf, "%s</a></td></tr>", tmpde1->name);
        wswrite(sock, buf);
      
	DirEntryDel(tmpde1);
	tmpde1=tmpde2;
      }
    } else {
        StrPrint(buf, "No matching entries<br>");
        wswrite(sock, buf);
    };
    
    Free(st);
  }
  wswrite(sock, "</table>");
  return res;
}

I64 Selaphiel(U8 *p_ipaddr, I64 p_port)
{
  // Single thread woooo, Spawn for each request
  I64 filesize=0;
  I64 err=0;
  I64 log_stat;
  I64 sock=socket(AF_INET, SOCK_STREAM);
  U8 buf[256];
  U8 log_ip[16];
  U8 log_req[256];
  U8 recv_str[256];
  U8 req[256];
  U8 SWS_VERSION_STR[64];
  U8 SWS_HOSTNAME[128];
  I64 SWS_PORT=80;
  StrCpy(SWS_VERSION_STR,"Selaphiel/0.1");
  StrCpy(SWS_HOSTNAME,"contoso.com");
  sockaddr_in p_addr;
  p_addr.sin_family = AF_INET;
  p_addr.sin_port = htons(p_port);
  inet_aton(p_ipaddr,&p_addr.sin_addr);

  err = connect(sock, &p_addr, sizeof(p_addr));
  if (err < 0)
  {
    close(sock);
    return -1;
  };

  StrCpy(log_ip,"");
  StrCpy(log_req,"");
  log_stat=200;

  // Incoming request
  err=recvLine(sock, recv_str, sizeof(recv_str), 0);
  if (err < 0) {
    //Error on receive?
    close(sock);
    return -1;
  };

  // get timestamp
  CDirEntry fde;
  CDateStruct ds;
  Date2Struct(&ds,Now+local_time_offset);
  
  StrCpy(log_req,recv_str);
  
  // convert request to path on disk
  recv_str[StrLen(recv_str)-StrLen(" HTTP/1.1")]=0;
  StrPrint(req, "D:%s", StrFirstOcc(recv_str, "/"));
  I64 recv_pos=0;
  while (recv_pos<StrLen(recv_str))
  {
    if (recv_str[recv_pos]=='#' || recv_str[recv_pos]=='?')
    {
      recv_str[recv_pos]=0;
    };
    recv_pos++;
  };

  // handle remaining headers
  while (StrCmp(recv_str,"")!=0)
  {
    err=recvLine(sock, recv_str, sizeof(recv_str), 0);
    if (err < 0) {
      //Error on receive?
      close(sock);
      return -1;
    };
    if (StrFind("CF-Connecting-IP",recv_str))
    {
      StrCpy(log_ip,StrFirstOcc(recv_str," ")+1);
    };
  };

  Bool not_found=FALSE;
  if (StrCmp(req,"D:/")==1)
  {
    if (req[StrLen(req)-1]=='/')
    {
      req[StrLen(req)-1]=0;
    };
    if (!FileFind(req, &fde))
    {
      log_stat=404;
      not_found=TRUE;
    };
  };

  AdamLog("%s %3tZ %02d/%02d %02d:%02d:%02d %d %s\n",
  log_ip,ds.day_of_week,"ST_DAYS_OF_WEEK",ds.mon,ds.day_of_mon,
  ds.hour,ds.min,ds.sec,log_stat,log_req);
  
  if (not_found)
  {
    wswrite(sock, "HTTP/1.1 404 Not Found\r\n");
    StrPrint(buf, "Date: %3tZ, %02d %3tZ %d %02d:%02d:%02d EST\r\n",
    ds.day_of_week,"ST_DAYS_OF_WEEK",ds.day_of_mon,ds.mon-1,"ST_MONTHS",ds.year,ds.hour,ds.min,ds.sec);
    wswrite(sock, buf);
    StrPrint(buf, "Server: %s\r\n", SWS_VERSION_STR);
    wswrite(sock, buf);
    wswrite(sock, "Content-Type: text/html\r\n");
    wswrite(sock, "Pragma: no-cache\r\n");
    wswrite(sock, "\r\n");
    wswrite(sock, "File not found");
    Sleep(20);
    close(sock);
    return 0;
  }

  // check for root
  if (StrFind("GET / HTTP",log_req))
  {
    wswrite(sock, "HTTP/1.1 200 OK\r\n");
    StrPrint(buf, "Date: %3tZ, %02d %3tZ %d %02d:%02d:%02d EST\r\n",
    ds.day_of_week,"ST_DAYS_OF_WEEK",ds.day_of_mon,ds.mon-1,"ST_MONTHS",ds.year,ds.hour,ds.min,ds.sec);
    wswrite(sock, buf);
    StrPrint(buf, "Server: %s\r\n", SWS_VERSION_STR);
    wswrite(sock, buf);
    wswrite(sock, "Content-Type: text/html\r\n");
    wswrite(sock, "Pragma: no-cache\r\n");
    I64 *rootbuf=FileReadRaw("D:/index.html",&filesize);
    StrPrint(buf,"Content-Length: %d\r\n",filesize);
    wswrite(sock, buf);
    wswrite(sock, "\r\n");
    send(sock,rootbuf,filesize,0);
    Sleep(20);
    Free(rootbuf);
    close(sock);
    return 0;
  };

  // check for index.html
  if (StrCmp(req,"D:/")==0)
  {
    StrPrint(buf, "D:/index.html");
  }
  else
  {
   StrPrint(buf, "%s/index.html", fde.full_name);
  };

  if (FileFind(buf))
  {
    wswrite(sock, "HTTP/1.1 200 OK\r\n");
    StrPrint(buf, "Date: %3tZ, %02d %3tZ %d %02d:%02d:%02d EST\r\n",
    ds.day_of_week,"ST_DAYS_OF_WEEK",ds.day_of_mon,ds.mon-1,"ST_MONTHS",ds.year,ds.hour,ds.min,ds.sec);
    wswrite(sock, buf);
    StrPrint(buf, "Server: %s\r\n", SWS_VERSION_STR);
    wswrite(sock, buf);
    wswrite(sock, "Content-Type: text/html\r\n");
    wswrite(sock, "Pragma: no-cache\r\n");

    if (StrCmp(req,"D:/")==0)
    {
      StrPrint(buf, "D:/index.html");
    }
    else
    {
     StrPrint(buf, "%s/index.html", fde.full_name);
    };

    I64 *htmlbuf=FileReadRaw(buf,&filesize);
    StrPrint(buf,"Content-Length: %d\r\n",filesize);
    wswrite(sock, buf);
    wswrite(sock, "\r\n");
    send(sock,htmlbuf,filesize,0);
    Sleep(20);
    Free(htmlbuf);    
    close(sock);
    return 0;
  };

  if (fde.attr & RS_ATTR_DIR)
  {
    wswrite(sock, "HTTP/1.1 200 OK\r\n");
    StrPrint(buf, "Date: %3tZ, %02d %3tZ %d %02d:%02d:%02d EST\r\n",
    ds.day_of_week,"ST_DAYS_OF_WEEK",ds.day_of_mon,ds.mon-1,"ST_MONTHS",ds.year,ds.hour,ds.min,ds.sec);
    wswrite(sock, buf);
    StrPrint(buf, "Server: %s\r\n", SWS_VERSION_STR);
    wswrite(sock, buf);
    wswrite(sock, "Content-Type: text/html\r\n");
    wswrite(sock, "Pragma: no-cache\r\n");
    wswrite(sock, "\r\n");
    wswrite(sock, "<html><head><title>Selaphiel</title>");
    wswrite(sock, "<style type='text/css'>");
    wswrite(sock, "body { ");
    wswrite(sock, "font-family:Helvetica;");
    wswrite(sock, " }");
    wswrite(sock, "</style>");
    wswrite(sock, "</head>");
    wswrite(sock, "<body><div id='a' style='display:none'>");
    DirList(sock, req);
    StrPrint(buf, "<hr><small>%s (%s) %s Port %d",SWS_VERSION_STR,Define("DD_OS_NAME_VERSION"),SWS_HOSTNAME,SWS_PORT);
    wswrite(sock, buf);
    wswrite(sock, "</small></div></body><script type='text/javascript'>");
    wswrite(sock, "document.getElementById('a').style='';</script>");
    wswrite(sock, "</html>"); 
    Sleep(20);
    close(sock);
    return 0;
  }
  else
  {
    U8 mimetype[256];
    StrCpy(mimetype, "application/octet-stream");
    wswrite(sock, "HTTP/1.1 200 OK\r\n");
    StrPrint(buf, "Date: %3tZ, %02d %3tZ %d %02d:%02d:%02d EST\r\n",
    ds.day_of_week,"ST_DAYS_OF_WEEK",ds.day_of_mon,ds.mon-1,"ST_MONTHS",ds.year,ds.hour,ds.min,ds.sec);
    wswrite(sock, buf);

    // TODO: move mimetypes to include file w/ LinkedLst
    if (StrFind(".html",fde.full_name))
    {
       StrCpy(mimetype, "text/html");
    };
    if (StrFind(".txt",fde.full_name) || StrFind(".TXT",fde.full_name))
    {
       StrCpy(mimetype, "text/plain");
    };
    if (StrFind(".hc",fde.full_name) || StrFind(".HC",fde.full_name))
    {
       StrCpy(mimetype, "text/plain");
    };
    if (StrFind(".jpeg",fde.full_name) || StrFind(".JPEG",fde.full_name))
    {
       StrCpy(mimetype, "image/jpeg");
    };
    if (StrFind(".jpg",fde.full_name) || StrFind(".JPG",fde.full_name))
    {
       StrCpy(mimetype, "image/jpeg");
    };
    if (StrFind(".Z",fde.full_name))
    {
       StrCpy(mimetype, "application/octet-stream");
    };

    StrPrint(buf, "Server: %s\r\n", SWS_VERSION_STR);
    wswrite(sock, buf);
    StrPrint(buf, "Content-Type: %s\r\n", mimetype);
    wswrite(sock, buf);
    wswrite(sock, "Pragma: no-cache\r\n");
    I64 *filebuf=FileReadRaw(fde.full_name,&filesize);
    StrPrint(buf,"Content-Length: %d\r\n",filesize);
    wswrite(sock, buf);
    wswrite(sock, "\r\n");
    send(sock,filebuf,filesize,0);
    Sleep(20);
    Free(filebuf);    
    close(sock);
    return 0;
  };
};


#define IRCD_USERMODE_v 0x1
#define IRCD_USERMODE_h 0x2
#define IRCD_USERMODE_o 0x4
#define IRCD_USERMODE_a 0x8
#define IRCD_USERMODE_q 0x10

class IrcClient
{
IrcClient *prev;
IrcClient *next;
CTcpSocket *s;
U8 *nick;
U8 *username;
U8 *realname;
U8 *server;
U8 *host;
U32 ip;
U8 *vhost;
CFifoI64 *msgs;
I64 idle;
I64 limit;
I64 ping;
Bool auth;
Bool closed;
Bool disconnected;
};

class IrcUser
{
IrcUser *prev;
IrcUser *next;
IrcClient *client;
U64 flags;
};

class IrcChannel
{
IrcChannel *prev;
IrcChannel *next;
U8 *name;
U8 *topic;
IrcUser *users;
};

extern U0 IrcParseCommand(IrcClient *client, U8 *str);
extern U0 IrcChannelsQuit(IrcClient *client, U8 *msg=NULL);

IrcClient *client_head = CAlloc(sizeof(IrcClient));
IrcChannel *channel_head = CAlloc(sizeof(IrcChannel));

U0 IrcClientClose(IrcClient *client)
{
	if (client->closed) return;
	client->closed = TRUE;
	if (client->s->state==TCP_STATE_CLOSING || client->s->state==TCP_STATE_CLOSED) return;
	close(client->s);
}

U0 IrcClientAdd(IrcClient *client)
{
	IrcClient *clients = client_head;
	while (clients->next)
	{
		clients = clients->next;
	}
	client->prev = clients;
	clients->next = client;
	ircd_clients_total++;
}

U0 IrcClientDel(IrcClient *client)
{
	IrcClient *prev = client->prev;
	IrcClient *next = client->next;
	prev->next = next;
	next->prev = prev;
	FifoI64Del(client->msgs);
	MemSet(client, 0, sizeof(IrcClient));
	Free(client);
	ircd_clients_total--;
}

IrcClient *IrcGetClientByNick(U8 *nick)
{
	IrcClient *client = client_head->next;
	while (client)
	{
		if (!StrCmp(client->nick, nick)) return client;
		client = client->next;
	}
	return NULL;
}

U0 IrcClientSetNick(IrcClient *client, U8 *nick)
{
	I64 i;
	U8 *buf = CAlloc(2048);
	IrcClient *chk_client = client_head->next;

	// check if in use, owned, forbidden, etc..
	while (chk_client)
	{
		if (!StrICmp(chk_client->nick, nick))
		{
			StrPrint(buf, ":%s 433 %s %s :Nickname is already in use.\r\n", ircd_hostname, client->username,
			         nick);
			FifoI64Ins(client->msgs, StrNew(buf));
			Free(buf);
			return;
		}
		chk_client = chk_client->next;
	}
	for (i=0; i<service_cnt; i++)
	{
		if (!StrICmp(service_nick[i], nick))
		{
			StrPrint(buf, ":%s 432 %s %s :Invalid nickname: Reserved for Services\r\n", ircd_hostname, client->username,
			         nick);
			FifoI64Ins(client->msgs, StrNew(buf));
			Free(buf);
			return;
		}
	}

	client->nick = StrNew(nick);
	AdamLog("** Gihon - log: nick: %s\n", client->nick);
	Free(buf);
}

U0 IrcClientSetUser(IrcClient *client, U8 *username, U8 *host, U8 *server, U8 *realname)
{
	// check user params
	client->username = StrNew(username);
	client->host = StrNew(host);
	client->realname = StrNew(realname);
	client->server = StrNew(server);
	AdamLog("** Gihon - log: username: %s, host: %s, realname: %s\n", client->username, client->host, client->realname);
}

U0 IrcClientNotice(IrcClient *client, U8 *msg)
{
	U8 *buf = CAlloc(2048);
	StrPrint(buf, ":%s NOTICE Auth :%s\r\n", ircd_hostname, msg);
	FifoI64Ins(client->msgs, StrNew(buf));
	Free(buf);
}

U0 IrcClientMotd(IrcClient *client)
{
	IrcClientNotice(client, "Welcome to Gihon IRC Server!");
	IrcClientNotice(client, "This server is running Gihon, an IRCd for TempleOS");
	I64 i;
	U8 *buf = CAlloc(2048);
	StrPrint(buf, ":%s 375 %s :-\r\n", ircd_hostname, client->username);
	FifoI64Ins(client->msgs, StrNew(buf));
	for (i=0; i<motd_line_cnt; i++)
	{
		StrPrint(buf, ":%s 372 %s :%s\r\n", ircd_hostname, client->username, motd_lines[i]);
		FifoI64Ins(client->msgs, StrNew(buf));
	}
	StrPrint(buf, ":%s 376 %s :>\r\n", ircd_hostname, client->username);
	FifoI64Ins(client->msgs, StrNew(buf));
	Free(buf);
}

U0 IrcClientJoin(U8 *dst, IrcClient *tx_client)
{
	U8 *buf = CAlloc(2048);
	IrcClient *rx_client = client_head->next;
	IrcChannel *rx_channel = channel_head->next;
	IrcUser *rx_user;
	while (rx_channel)
	{
		if (!StrCmp(rx_channel->name, dst))
		{ //PRIVMSG to channel
			rx_user = rx_channel->users->next;
			while (rx_user)
			{
				rx_client = rx_user->client;
				StrPrint(buf, ":%s!%s@%s JOIN :%s\r\n", tx_client->nick, tx_client->username,
				         tx_client->host, dst);
				FifoI64Ins(rx_client->msgs, StrNew(buf));
				rx_user = rx_user->next;
			}
			return;
		}
		rx_channel = rx_channel->next;
	}
	Free(buf);
}

U0 IrcClientNames(IrcClient *client, U8 *dst)
{
	U8 *buf = CAlloc(2048);
	U8 *mode = CAlloc(16);
	IrcChannel *channel = channel_head->next;
	IrcUser *user;
	StrPrint(buf, ":%s 353 %s = %s :", ircd_hostname, client->username, dst);
	while (channel)
	{
		if (!StrCmp(channel->name, dst))
		{
			user = channel->users->next;
			while (user)
			{
				StrPrint(mode, "");
				if (user->flags & IRCD_USERMODE_q) StrPrint(mode, "@");
				if (user->flags & IRCD_USERMODE_o) StrPrint(mode, "@");
				if (user->flags & IRCD_USERMODE_h) StrPrint(mode, "\%");
				if (user->flags & IRCD_USERMODE_v) StrPrint(mode, "+");
				StrPrint(buf+StrLen(buf), "%s%s ", mode, user->client->nick);
				user = user->next;
			}
			StrPrint(buf+StrLen(buf), "\r\n");
			FifoI64Ins(client->msgs, StrNew(buf));
			StrPrint(buf, ":%s 366 %s %s :End of /NAMES list.\r\n", ircd_hostname, client->username, dst);
			FifoI64Ins(client->msgs, StrNew(buf));
			Free(mode);
			Free(buf);
			return;
		}
		channel = channel->next;
	}
	Free(mode);
	Free(buf);
}

U0 IrcClientTopic(IrcClient *client, U8 *dst)
{
	U8 *buf = CAlloc(2048);
	IrcChannel *channel = channel_head->next;
	while (channel)
	{
		if (!StrCmp(channel->name, dst))
		{
			if (StrLen(channel->topic))
			{
				StrPrint(buf, ":%s 332 %s %s :%s\r\n", ircd_hostname, client->username, dst, channel->topic);
				FifoI64Ins(client->msgs, StrNew(buf));
			}
			Free(buf);
			return;
		}
		channel = channel->next;
	}
	Free(buf);
}

U0 IrcClientPart(U8 *dst, IrcClient *tx_client, U8 *msg=NULL)
{
	U8 *buf = CAlloc(2048);
	IrcClient *rx_client = client_head->next;
	IrcChannel *rx_channel = channel_head->next;
	IrcUser *rx_user;
	while (rx_channel)
	{
		if (!StrCmp(rx_channel->name, dst))
		{ //PRIVMSG to channel
			rx_user = rx_channel->users->next;
			while (rx_user)
			{
				rx_client = rx_user->client;
				if (msg)
				{
					StrPrint(buf, ":%s!%s@%s PART %s :%s\r\n", tx_client->nick, tx_client->username,
					         tx_client->host, dst, msg);
				}
				else
				{
					StrPrint(buf, ":%s!%s@%s PART %s\r\n", tx_client->nick, tx_client->username,
					         tx_client->host, dst);
				}
				FifoI64Ins(rx_client->msgs, StrNew(buf));
				rx_user = rx_user->next;
			}
			return;
		}
		rx_channel = rx_channel->next;
	}
	Free(buf);
}

U0 IrcClientPing(IrcClient *client, U8 *msg)
{
	U8 *buf = CAlloc(2048);
	StrPrint(buf, ":%s PONG %s :%s\r\n", ircd_hostname, ircd_hostname, msg);
	FifoI64Ins(client->msgs, StrNew(buf));
	Free(buf);
}

U0 IrcClientPrivMsg(IrcClient *tx_client, U8 *dst, U8 *msg)
{
	U8 *buf = CAlloc(2048);
	IrcClient *rx_client = client_head->next;
	while (rx_client)
	{
		if (!StrCmp(rx_client->nick, dst))
		{ //PRIVMSG to nick
			StrPrint(buf, ":%s!%s@%s PRIVMSG %s :%s\r\n", tx_client->nick, tx_client->username,
			         tx_client->host, dst, msg);
			FifoI64Ins(rx_client->msgs, StrNew(buf));
			Free(buf);
			return;
		}
		rx_client = rx_client->next;
	}
	IrcChannel *rx_channel = channel_head->next;
	IrcUser *rx_user;
	while (rx_channel)
	{
		if (!StrCmp(rx_channel->name, dst))
		{ //PRIVMSG to channel
			rx_user = rx_channel->users->next;
			while (rx_user)
			{
				rx_client = rx_user->client;
				if (!!StrCmp(rx_client->nick, tx_client->nick))
				{
					StrPrint(buf, ":%s!%s@%s PRIVMSG %s :%s\r\n", tx_client->nick, tx_client->username,
					         tx_client->host, dst, msg);
					FifoI64Ins(rx_client->msgs, StrNew(buf));
				}
				rx_user = rx_user->next;
			}
			Free(buf);
			return;
		}
		rx_channel = rx_channel->next;
	}
	Free(buf);
}

U0 IrcClientQuit(U8 *dst, IrcClient *tx_client, U8 *msg=NULL)
{
	U8 *buf = CAlloc(2048);
	IrcClient *rx_client = client_head->next;
	IrcChannel *rx_channel = channel_head->next;
	IrcUser *rx_user;
	while (rx_channel)
	{
		if (!StrCmp(rx_channel->name, dst))
		{ //PRIVMSG to channel
			rx_user = rx_channel->users->next;
			while (rx_user)
			{
				rx_client = rx_user->client;
				if (msg)
				{
					StrPrint(buf, ":%s!%s@%s QUIT :%s\r\n", tx_client->nick, tx_client->username,
					         tx_client->host, msg);
				}
				else
				{
					StrPrint(buf, ":%s!%s@%s QUIT\r\n", tx_client->nick, tx_client->username,
					         tx_client->host);
				}
				FifoI64Ins(rx_client->msgs, StrNew(buf));
				rx_user = rx_user->next;
			}
			return;
		}
		rx_channel = rx_channel->next;
	}
	Free(buf);
}

U0 IrcClientWho(IrcClient *client, U8 *dst)
{
	U8 *buf = CAlloc(2048);
	IrcChannel *channel = channel_head->next;
	IrcUser *user;
	while (channel)
	{
		if (!StrCmp(channel->name, dst))
		{
			user = channel->users->next;
			while (user)
			{
				StrPrint(buf, ":%s 352 %s %s %s %s * %s H :0 %s\r\n", ircd_hostname, client->username, dst,
				         user->client->username, user->client->host, user->client->nick,
				         user->client->realname);
				FifoI64Ins(client->msgs, StrNew(buf));
				user = user->next;
			}
			StrPrint(buf, ":%s 315 %s %s :End of /WHO list.\r\n", ircd_hostname, client->username, dst);
			FifoI64Ins(client->msgs, StrNew(buf));
			Free(buf);
			return;
		}
		channel = channel->next;
	}
	Free(buf);
}

U0 IrcClientRxHandler(CTcpSocket *s)
{
	IrcClient *client = CAlloc(sizeof(IrcClient));
	client->s = s;
	client->ip = s->local_addr;
	client->limit = IRCD_LIMIT_MAX;
	client->msgs = FifoI64New(IRCD_TXFIFO_SIZE);
	client->idle = cnts.jiffies;
	if (!ircd_password) client->auth = TRUE;
	spin_lock(&spinlock);
	IrcClientAdd(client);
	spin_unlock(&spinlock);

	AdamLog("** Gihon - Client connected: %16X\n", client);
	I64 err = NULL;
	U8 *rxbuf = CAlloc(IRCD_RXBUF_SIZE);
	while (err > -1)
	{
		err = recvLine(s, rxbuf, IRCD_RXBUF_SIZE, 0);
		spin_lock(&spinlock);
		//AdamLog(rxbuf);
		//AdamLog("\n");
		client->limit--;
		if (client->limit)
		{
			IrcParseCommand(client, rxbuf);
		}
		else
		{
			IrcChannelsQuit(client, "Excess flood");
			err = -2;
		}
		spin_unlock(&spinlock);
	}
	if (err == -1)
	{
		spin_lock(&spinlock);
		IrcChannelsQuit(client, "Connection reset by peer");
		spin_unlock(&spinlock);		
	}
	if (!client->disconnected)
	{
		client->disconnected = TRUE;
		IrcClientClose(client);
	}
	Free(rxbuf);
	AdamLog("** Gihon - Client disconnected: %16X\n", client);
}

U0 IrcClientTxHandler()
{
	I64 sec = NULL;
	CDateStruct ds;
	U8 *buf = CAlloc(2048);
	I64 msg = NULL;
	IrcClient *client;
	while (1)
	{
		spin_lock(&spinlock);
		client = client_head->next;
		while (client)
		{
			if (client->disconnected)
			{
				IrcClientDel(client);
				client = client_head;
			}
			client = client->next;
		}

		if (sec != ds.sec)
		{
			client = client_head->next;
			while (client)
			{
				client->limit = Min(IRCD_LIMIT_MAX, client->limit+1);
				client = client->next;
			}
			sec = ds.sec;
		}

		client = client_head->next;
		while (client)
		{
			if (client->idle+IRCD_PING_INTERVAL == cnts.jiffies)
			{
				client->ping++;
				if (client>1)
				{
					IrcChannelsQuit(client, "Ping timeout");
					// IrcClientClose(client);
					client->disconnected = TRUE;
				}
				StrPrint(buf, "PING :%s\r\n", ircd_hostname);
				FifoI64Ins(client->msgs, StrNew(buf));
			}
			while (FifoI64Cnt(client->msgs))
			{
				FifoI64Rem(client->msgs, &msg);
				if (!client->closed) sendString(client->s, msg, 0);
				Free(msg);
			}
			client = client->next;
		}
		spin_unlock(&spinlock);

		Date2Struct(&ds, Now);
		Sleep(1);
	}
}
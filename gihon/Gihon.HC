#define IRCD_LIMIT_MAX      20
#define IRCD_PING_INTERVAL  60000
#define IRCD_PORT           6667
#define IRCD_RXBUF_SIZE     4096
#define IRCD_TXBUF_SIZE     4096
#define IRCD_TXFIFO_SIZE    128

U8 *ircd_hostname = "irc.gihon.local";
U8 *ircd_password = NULL; // server password if you want one
I64 ircd_chans_total = 0;
I64 ircd_clients_total = 0;

#include "Lock";
#include "Motd";
#include "Service";
#include "Arg";
#include "Client";
#include "Channel";
#include "Command";

I64 Gihon()
{
	DocClear(adam_task->put_doc);
	DocMax(adam_task->put_doc);
	WinToTop(adam_task);
	while (!my_ip) { Sleep(1); }; // Wait for Netcfg
	CTcpSocket *sock = socket(AF_INET, SOCK_STREAM);
	if (sock < 0)
		return -1;
	sockaddr_in addr;
	addr.sin_family = AF_INET;
	addr.sin_port = htons(IRCD_PORT);
	addr.sin_addr.s_addr = INADDR_ANY;
	if (bind(sock, &addr, sizeof(addr)) < 0) {
		close(sock); /* Failed to bind to port */
		return -1;
	}
	I64 error = listen(sock, 1);
	if (error < 0) { /* listen: error */
		return -1;
	}
	Spawn(&IrcClientTxHandler,, "Gihon ClientTxHandler");
	AdamLog("** Gihon - Server started\n");
	while (1)
	{
		I64 client = accept(sock, 0, 0);
		Spawn(&IrcClientRxHandler, client, "Gihon ClientRxHandler");
		Sleep(1);
	}
	close(sock);
	AdamLog("** Gihon - Server exited\n");
	return 0;
}

Spawn(&Gihon,,"Gihon Server");

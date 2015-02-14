#include <stdio.h>
#include "mySocket.h"

#ifdef _MSC_VER
#include <WinSock.h>
#pragma comment(lib,"Ws2_32.lib")
#endif

mySocket::mySocket() : m_fpLog(0), m_sock(-1)
{
}

mySocket::~mySocket()
{
}

bool mySocket::Open (const char *pszIP, int port)
{
	bool status = false;
	if (!m_fpLog) {
		m_fpLog = fopen ("addonlog.txt", "w");
	}
	fprintf (m_fpLog, "socket open\n");

	if (m_sock == -1) {
#ifdef _MSC_VER
		WSADATA wsaData;
		int iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
		if (iResult != NO_ERROR) {
			fprintf (m_fpLog, "wsastartup error\n");
		}
		else {
			fprintf (m_fpLog, "wsastartup ok\n");
		}
#endif
		//Create socket
		struct sockaddr_in server;
		m_sock = socket(AF_INET , SOCK_STREAM , IPPROTO_TCP);

		if (m_sock != -1) {
		
			fprintf (m_fpLog, "socket create ok\n");
			if (*pszIP == '\0')
				pszIP = "127.0.0.1";
			server.sin_addr.s_addr = inet_addr( pszIP );

			server.sin_family = AF_INET;
			server.sin_port = htons(port);

			//Connect to remote server
			fprintf (m_fpLog, "socket connecting: ip[%] port[%d]\n", pszIP, port);
			if (connect(m_sock , (struct sockaddr *)&server , sizeof(server)) < 0) {
				fprintf (m_fpLog, "error connecting\n");
				closesocket (m_sock);
				m_sock = -1;
			}
			else {
				status = true;
				fprintf (m_fpLog, "connect ok\n");
			}
		}
		else {
			fprintf (m_fpLog, "error creating socket\n");
		}
	}
	return status;
}

bool mySocket::IsOpen ()
{
	return m_sock != -1;
}

bool mySocket::Send (const char *pszData, int length)
{
	bool bOK = false;
	if (m_sock != -1) {
		//send the message
		fprintf (m_fpLog, "sending: %d bytes\n", length);
		int iResult = send (m_sock, pszData, length, 0);
		if (iResult == SOCKET_ERROR) {
			fprintf (m_fpLog, "SEND failed\n");
		}
		else {
			bOK = true;
		}
	}
	return bOK;
}

void mySocket::Close ()
{
	fprintf (m_fpLog, "closing\n");
	closesocket (m_sock);
	m_sock = -1;
#ifdef _MSC_VER
	WSACleanup();
#endif
}



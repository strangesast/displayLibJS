#ifndef __MYSOCKET_H__
#define __MYSOCKET_H__

#include <stdio.h>

class mySocket
{
public:
	mySocket();
	~mySocket();

	bool Open(const char *pszIP, int port);
	void Close();
	bool IsOpen();
	bool Send (const char *pszBuffer, int length);

private:
	FILE *m_fpLog;
	int m_sock;




};

#endif
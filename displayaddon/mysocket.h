/* Copyright (c) 2015, Jim Zagrobelny  <jimzagrobelny@gmail.com>
*  This is proprietary software.  All rights reserved.
*  In no event shall the author be liable for any claim or damages.
*/
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
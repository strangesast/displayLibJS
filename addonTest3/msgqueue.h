#ifndef __MSGQUEUE_H_
#define __MSGQUEUE_H_

#include <v8.h>
#include <node.h>
#include <node_buffer.h>
#ifdef _MSC_VER
#include <assert.h>
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#endif
#include "mysocket.h"

#ifndef _MSC_VER
#define DWORD int
#define HANDLE int
#define WINAPI
#define LPVOID void*
#define nullptr NULL

#endif
using namespace v8;


class msgQueue {
public:
	msgQueue();
	~msgQueue();
	static msgQueue &TheQueue();

	void SetEmulator (const char *ip, int port);
	int GetRequestCount ();
	void Start();
	void Stop();
	int AddItem (char *bufferData, int length);
	void Loop();
	static DWORD WINAPI Thread_Start (LPVOID lpParam);


private:
	bool lock();
	void unlock();
	struct QueueEntry {
		char *msg;
		int length;
		QueueEntry		*next;

		QueueEntry():msg(nullptr), length(0), next(nullptr) {}
		~QueueEntry() {}
		void Create (char *msg_a, int length_a) {
			msg = new char[length_a+10];
			memcpy (msg, msg_a, length_a);
			length = length_a;
		}
		void Destroy () {
			if (msg) {
				delete [] msg;
			}
			msg = nullptr;
			length = 0;
		}
	};

	static msgQueue	*m_pSingle;
#ifdef _MSC_VER
	DWORD			m_threadId;
	HANDLE			m_hThread;
#else
	pthread_t		m_threadId;
	pthread_t		m_hThread;
#endif
	int				m_refcount;
	HANDLE			m_lock;
	bool		m_exit;
	QueueEntry m_list;
	char			m_emulator_ip[20];
	int				m_emulator_port;
	int				m_request_count;

	FILE *m_fpLog;
};

#endif

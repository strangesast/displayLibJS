#ifndef __MSGQUEUE_H_
#define __MSGQUEUE_H_

#include <v8.h>
#include <node.h>
#include <node_buffer.h>
#include <assert.h>
#include <windows.h>
#include "mySocket.h"
using namespace v8;


class msgQueue {
public:
	msgQueue();
	~msgQueue();
	static msgQueue &TheQueue();

	void SetEmulator (const char *ip, int port);
	void Start();
	void Stop();
	int AddItem (char *bufferData, int length);
	void Loop();
//	LPTHREAD_START_ROUTINE
	static DWORD WINAPI Thread_Start (LPVOID lpParam);
	void StartLoop();


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
	DWORD			m_threadId;
	int				m_refcount;
	HANDLE			m_hThread;
	HANDLE			m_lock;
	bool		m_exit;
	int m_item_count;
	QueueEntry m_list;
	char			m_emulator_ip[20];
	int				m_emulator_port;

	FILE *m_fpLog;
};

#endif

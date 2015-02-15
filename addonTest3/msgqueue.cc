#include "msgqueue.h"
#include "mysocket.h"
#ifndef _MSC_VER
#include <time.h>
#endif

void* Thread_Start_linux (void* lpParam);

msgQueue *msgQueue::m_pSingle = nullptr;

msgQueue::msgQueue () :
m_threadId(0), m_hThread(0), m_refcount(0), m_lock(0), 
m_exit(false), m_emulator_port(0), m_request_count(0), m_fpLog(nullptr)
{
	*m_emulator_ip = '\0';
}

msgQueue::~msgQueue ()
{
}

msgQueue &msgQueue::TheQueue ()
{
	if (!m_pSingle) {
		m_pSingle = new msgQueue();
		if (!m_pSingle->m_fpLog) {
			m_pSingle->m_fpLog = fopen ("log_msgqueue.txt", "w");
		}
		fprintf (m_pSingle->m_fpLog, "create queue object\n");
		m_pSingle->Start();
	}
	return *m_pSingle;
}

void msgQueue::Start()
{
//	m_lock = ::CreateMutex(NULL, FALSE, NULL);
	DWORD dwThreadID;
	fprintf (m_fpLog, "queue starting\n");
#ifdef _MSC_VER
	m_hThread = CreateThread (0, 0, (LPTHREAD_START_ROUTINE)Thread_Start, this, 0, &dwThreadID);
#else
	int err = pthread_create(&m_hThread, NULL, &Thread_Start_linux, this);
	fprintf (m_fpLog, "thread create: status[%d]\n", err);
#endif
}

void msgQueue::Stop()
{
	m_exit = true;
	while (m_exit) {
#ifdef _MSC_VER
		Sleep(100);
#else
		timespec sleep_time;
		sleep_time.tv_sec = 0;
		sleep_time.tv_nsec = 50*1000000;
		nanosleep (&sleep_time, NULL);
#endif
	}
	if (m_fpLog) {
		fclose (m_fpLog);
		m_fpLog = nullptr;
	}
}

void msgQueue::SetEmulator (const char *ip, int port)
{
	fprintf (m_fpLog, "SetEmulator: ip[%s] port[%d]\n", ip, port);
	strcpy (m_emulator_ip, ip);
	m_emulator_port = port;
}

int msgQueue::GetRequestCount()
{
	return m_request_count;
}


int msgQueue::AddItem (char *bufferData, int length)
{
	int how_many = 0;
	QueueEntry *pQ = new QueueEntry();
	pQ->Create (bufferData, length);
	QueueEntry *pTarget = &m_list;
	//find end
	while (pTarget->next) {
		pTarget = pTarget->next;
		how_many++;
	}
	//add
	pTarget->next = pQ;
	how_many++;
	fprintf (m_fpLog, "AddItem: item added - this[%d] total[%d]\n", 
		(int)this, how_many);
	m_request_count++;
	return how_many;

}


void msgQueue::Loop()
{
	FILE *fpLog = fopen ("log_msgqueue_T.txt", "w");

	//instantiate socket connection
	mySocket client;
	bool status = false;
	if (*m_emulator_ip != '\0') {
		fprintf (fpLog, "Loop init: open socket - ip[%s] port[%d] status[%d]\n", 
			m_emulator_ip, m_emulator_port, status);
		status = client.Open (m_emulator_ip, m_emulator_port);
	}
	else {
		fprintf (fpLog, "Loop init: no emulator\n");
	}

	fprintf (fpLog, "Loop: beginning monitor queue - this[%d] exit_flag[%d]\n", (int)this, m_exit);
	while (!m_exit) {
#ifdef _MSC_VER
		Sleep(100);
#else
		timespec sleep_time;
		sleep_time.tv_sec = 0;
		sleep_time.tv_nsec = 50*1000000;
		nanosleep (&sleep_time, NULL);
#endif
//		fprintf (fpLog, "Loop: checking..\n");

		//take an item off the top
		QueueEntry *pTop = m_list.next;
		if (pTop) {
			fprintf (fpLog, "processing item\n");
			m_list.next = pTop->next;
			fprintf (fpLog, "Sending item: ptr[%d] len[%d]\n", 
				(int)pTop->msg, pTop->length);
			status = client.Send (pTop->msg, pTop->length);
			fprintf (fpLog, "Send complete: status[%d]\n", status);

			pTop->Destroy();
			delete pTop;
		}

	}
	fclose (fpLog);
	m_exit = false;
}

DWORD WINAPI msgQueue::Thread_Start (LPVOID lpParam)
{
	msgQueue *pThis = (msgQueue*)lpParam;
	pThis->Loop ();
	return 0;
}

bool msgQueue::lock ()
{
	bool return_status = false;
#ifdef _MSC_VER
	if (GetCurrentThreadId() == m_threadId) {
		m_refcount++;
		return true;
	}
	DWORD dwResult = WaitForSingleObject (m_lock, -1);
	switch (dwResult) {
	case WAIT_OBJECT_0:
		return_status = true;
		break;
	case WAIT_TIMEOUT:
		return_status = false;
		break;
	case WAIT_ABANDONED:
		return_status = false;
		break;
	default:
		return_status = false;
	}
	if (return_status) {
		m_refcount = 1;
		m_threadId = GetCurrentThreadId();
	}
#else
#endif
	return return_status;

}

void msgQueue::unlock ()
{
	if (m_refcount > 0)
		m_refcount--;
	if (m_refcount > 0)
		return;
	m_threadId = 0;
#ifdef _MSC_VER
	ReleaseMutex (m_lock);
#else
#endif
}

void* Thread_Start_linux (void* lpParam)
{
	msgQueue *pThis = (msgQueue*)lpParam;
	pThis->Loop ();
	return NULL;
}


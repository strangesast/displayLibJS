#include "msgQueue.h"
#include "mysocket.h"

msgQueue *msgQueue::m_pSingle = nullptr;

msgQueue::msgQueue () :m_hThread(0), m_item_count(0), m_lock(0), 
	m_threadId(0), m_refcount(0), m_fpLog(nullptr), m_exit(false), m_emulator_port(0)
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
			m_pSingle->m_fpLog = fopen ("queuelog.txt", "w");
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
	m_hThread = CreateThread (0, 0, (LPTHREAD_START_ROUTINE)Thread_Start, this, 0, &dwThreadID);
}

void msgQueue::Stop()
{
	m_exit = true;
	while (m_exit) {
		Sleep(100);
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
	fprintf (m_fpLog, "AddItem: item added - total[%d]\n", how_many);
	return how_many;

}


void msgQueue::Loop()
{
	FILE *fpLog = fopen ("queuelogT.txt", "w");

	//instantiate socket connection
	mySocket client;
	bool status = false;
	if (*m_emulator_ip != '\0') {
		fprintf (fpLog, "Loop init: open socket - ip[%s] port[%d] status[%d]\n", 
			m_emulator_ip, m_emulator_port, status);
		status = client.Open (m_emulator_ip, m_emulator_port);
//		status = client.Open ("127.0.0.1", 1001);
	}
	else {
		fprintf (fpLog, "Loop init: no emulator");
	}

	while (!m_exit) {
		Sleep(100);

		//take an item off the top
		QueueEntry *pTop = m_list.next;
		if (pTop) {
			fprintf (fpLog, "processing item\n");
			m_list.next = pTop->next;
			fprintf (fpLog, "Sending item: ptr[%d] len[%d]\n", pTop->msg, pTop->length);
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

void msgQueue::StartLoop()
{
}

bool msgQueue::lock ()
{
	if (GetCurrentThreadId() == m_threadId) {
		m_refcount++;
		return true;
	}
	DWORD dwResult = WaitForSingleObject (m_lock, -1);
	bool return_status = false;
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
	return return_status;

}

void msgQueue::unlock ()
{
	if (m_refcount > 0)
		m_refcount--;
	if (m_refcount > 0)
		return;
	m_threadId = 0;
	ReleaseMutex (m_lock);
}



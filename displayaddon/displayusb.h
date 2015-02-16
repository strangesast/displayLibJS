/* Copyright (c) 2015, Jim Zagrobelny  <jimzagrobelny@gmail.com>
*  This is proprietary software.  All rights reserved.
*  In no event shall the author be liable for any claim or damages.
*/
#ifndef __displayUSB_H__
#define __displayUSB_H__

#include <stdio.h>
#ifdef _MSC_VER
#define libusb_device_handle int
#else
#include <libusb.h>
#endif

#define MAX_USB_DEVICES 20

class displayUSB
{
public:
	displayUSB();
	~displayUSB();

	bool Open();
	void Close();
	bool IsOpen();
	bool Send (const char *pszBuffer, int length, int dest=-1);

private:
	struct UsbInfo {
		libusb_device_handle *device_handle;
		int port;

		UsbInfo ():device_handle(NULL), port(0) {}
		~UsbInfo () {}
		const UsbInfo &operator= (const UsbInfo &ref) {
			if (this != &ref) {
				device_handle = ref.device_handle;
				port = ref.port;
			}return *this;}
		UsbInfo (const UsbInfo &ref) {operator= (ref);}
	};

	UsbInfo m_usbList[MAX_USB_DEVICES];
	int m_usbList_count;

	FILE *m_fpLog;




};

#endif

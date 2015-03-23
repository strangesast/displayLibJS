/* Copyright (c) 2015, Jim Zagrobelny  <jimzagrobelny@gmail.com>
*  This is proprietary software.  All rights reserved.
*  In no event shall the author be liable for any claim or damages.
*/

#include <stdio.h>
#include "displayusb.h"

#ifdef _MSC_VER
#include <memory.h>
#include <algorithm>
using namespace std;
#else
#include <iostream>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include <errno.h>

//using namespace std;

#include <libusb.h>
//#include <libusb-1.0/libusb.h>


#include <stdlib.h>
#include <unistd.h>
//#include <sys/types.h>
//#include <sys/socket.h>
//#include <netinet/in.h>
//#include <arpa/inet.h>
//#include <netdb.h>

#endif

#define LOG_MESSAGES 0

displayUSB::displayUSB() : m_usbList_count(0), m_fpLog(0)
{
}

displayUSB::~displayUSB()
{
}

bool displayUSB::Open ()
{
	bool status = false;
	if (!m_fpLog) {
		m_fpLog = fopen ("log_usb.txt", "w");
	}
	fprintf (m_fpLog, "usb init\n");

	if (m_usbList_count > 0) {
		Close();
	}

#ifdef _MSC_VER
#else
    libusb_context *context = NULL;
    libusb_device **list = NULL;
    int rc = 0;
    ssize_t count = 0;

	fprintf (m_fpLog, "initializing usb\n");
    rc = libusb_init(&context);
	fprintf (m_fpLog, "usb init: status[%s]\n", rc==0?"ok":"fail");
	if (rc != 0)
		return status;

    count = libusb_get_device_list(context, &list);
	fprintf (m_fpLog, "get usb device list: count[%d]\n", count);

    for (size_t idx = 0; idx < count; ++idx) {
        libusb_device *device = list[idx];
        libusb_device_descriptor desc = {0};

        rc = libusb_get_device_descriptor(device, &desc);
//        assert(rc == 0);

        fprintf(m_fpLog, "Vendor:Device = %04x:%04x\n", desc.idVendor, desc.idProduct);
		if (desc.idVendor == 0x16c0 && desc.idProduct == 0x486 && m_usbList_count < MAX_USB_DEVICES) {
			libusb_device_handle* handle = 0;
			int status = libusb_open (device, &handle);
			fprintf (m_fpLog, "Teensy device: open - status[%d] handle[%d]\n", 
				status, (int)handle);
			if (handle) {
				bool bOk = true;
				int res=0;

				if (libusb_kernel_driver_active (handle, 0)) {
					fprintf (m_fpLog, "kernel driver attached\n");
					res=libusb_detach_kernel_driver(handle, 0);
					if (res != 0) {
						bOk = false;
						fprintf (m_fpLog, "error detaching\n");
					}
				}

				res = libusb_claim_interface (handle, 0);
				if (res != 0) {
					bOk = false;
					fprintf (m_fpLog, "error claiming\n");
				}
				else {
					fprintf (m_fpLog, "claimed ok\n");
				}
				if (bOk) {
					m_usbList[m_usbList_count].device_handle = handle;
					m_usbList_count++;
					fprintf (m_fpLog, "Adding device: index[%d]\n", m_usbList_count);
				}
			}
		}
    }
	libusb_free_device_list (list, 1);
#endif

	return m_usbList_count > 0;
}

bool displayUSB::IsOpen ()
{
	return m_usbList_count > 0;
}
static int g_lastmsg=1;
//destination is 1-based: 1 = first USB port, 2 = second USB port, etc
bool displayUSB::Send (const char *pszData, int length, int dest)
{
#if LOG_MESSAGES == 1
	char msgfile[20];
	sprintf (msgfile, "log_msg%02d.txt", g_lastmsg++);
	FILE *fp_msg = fopen (msgfile, "w");
#endif
	bool bOK = false;
	//send to all interfaces
	for (int i=0; i<m_usbList_count; i++) {
		if (dest == i+1 || dest == -1) {
			int write_pos = 0;
			while (write_pos < length) {
				//break the message into 64 byte packets
				int write_chunk = std::min (64, length-write_pos);
				unsigned char usb_buffer[64];
				memset (usb_buffer, 0, sizeof(usb_buffer));
				memcpy (usb_buffer, pszData+write_pos, write_chunk);
				write_pos += write_chunk;
				int numbytes = 0;
				int res = 0;
#ifdef _MSC_VER
#else
				res = libusb_interrupt_transfer(m_usbList[i].device_handle, 0x4, usb_buffer, 64, &numbytes, 500);
#if LOG_MESSAGES == 1
				for (int x=0; x<64; x++)
					fputc (usb_buffer[x], fp_msg);
#endif

#endif
				fprintf (m_fpLog, "send: dest[%d] result[%d] bytes[%d] errno[%d]\n", 
					i, res, numbytes, errno);
				if (res == 0)
					bOK = true;
			}
		}
	}
#if LOG_MESSAGES == 1
	fclose (fp_msg);
#endif
	return bOK;
}

void displayUSB::Close ()
{
#ifdef _MSC_VER
#else
	fprintf (m_fpLog, "closing\n");
	for (int i=0; i<m_usbList_count; i++) {
		libusb_close (m_usbList[i].device_handle);
	}
#endif
}



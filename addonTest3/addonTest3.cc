#include <v8.h>
#include <node.h>
#include <node_buffer.h>
#include <assert.h>
#include <stdio.h>
#include "msgqueue.h"

#define SIZE 8

using namespace v8;

struct js_work {
  uv_work_t req;
  Persistent<Function> callback;
  char* request_data;
  size_t request_len;
  char* response_data;
  size_t response_len;
};

//Referring back to the first section you'll see work->req.data = work;. The uv_work_t has a data field where we can store a void pointer. So by creating this loop reference to work we'll be able to get at either later on.
void get_status_work(uv_work_t* req) {

  js_work* work = static_cast<js_work*>(req->data);
  char* data = new char[100];
  sprintf (data, "requests: %d", msgQueue::TheQueue().GetRequestCount());
  work->response_data = data;
  work->response_len = strlen(data);
}


void get_status_callback (uv_work_t* req, int status) {
  HandleScope scope;

  js_work* work = static_cast<js_work*>(req->data);
  char* data = work->response_data;
  node::Buffer* buf = node::Buffer::New(data, work->response_len);

  Handle<Value> argv[1] = { buf->handle_ };

  // proper way to reenter the js world
  node::MakeCallback(Context::GetCurrent()->Global(),
                     work->callback,
                     1,
                     argv);

  // properly cleanup, or death by millions of tiny leaks
  work->callback.Dispose();
  work->callback.Clear();
  // unfortunately in v0.10 Buffer::New(char*, size_t) makes a copy
  // and we don't have the Buffer::Use() api yet
  delete[] data;
  delete work;
}

void send_request_work(uv_work_t* req) {

	js_work* work = static_cast<js_work*>(req->data);

	//TODO: call an AddRequest function which returns a session identifier,
	//  then poll and wait for the response.  Return the data via the callback mechanism.
	//For now, just call AddItem
	msgQueue::TheQueue().AddItem (work->request_data, work->request_len);

	work->response_data = new char[100];
	sprintf (work->response_data, "Item Added - TODO: provide response data");
	work->response_len = strlen(work->response_data);
}


void send_request_callback (uv_work_t* req, int status) {
  HandleScope scope;

  js_work* work = static_cast<js_work*>(req->data);
  char* data = work->response_data;
  node::Buffer* buf = node::Buffer::New(data, work->response_len);

  Handle<Value> argv[1] = { buf->handle_ };

  // proper way to reenter the js world
  node::MakeCallback(Context::GetCurrent()->Global(),
                     work->callback,
                     1,
                     argv);

  // properly cleanup, or death by millions of tiny leaks
  work->callback.Dispose();
  work->callback.Clear();
  // unfortunately in v0.10 Buffer::New(char*, size_t) makes a copy
  // and we don't have the Buffer::Use() api yet
  delete[] data;
  delete work;
}

Handle<Value> GetStatus(const Arguments& args) {
  HandleScope scope;
  assert(args[0]->IsFunction());

  js_work* work = new js_work;
  work->req.data = work;
  work->callback = Persistent<Function>::New(args[0].As<Function>());

  // pretty simple, right?
  uv_queue_work(uv_default_loop(), &work->req, get_status_work, get_status_callback);
  return Undefined();
}

Handle<Value> SendRequest(const Arguments& args) {
  HandleScope scope;
  assert(args[1]->IsFunction());

  js_work* work = new js_work;
  work->req.data = work;
  work->callback = Persistent<Function>::New(args[1].As<Function>());
	Local<Object> bufferObj    = args[0]->ToObject();
	char*         bufferData   = node::Buffer::Data(bufferObj);
	work->request_len = node::Buffer::Length(bufferObj);
	work->request_data = new char[work->request_len+10];
	memcpy (work->request_data, bufferData, work->request_len);

  // pretty simple, right?
  uv_queue_work(uv_default_loop(), &work->req, send_request_work, send_request_callback);
  return Undefined();
}

Handle<Value> SetEmulator (const Arguments& args) {

	v8::String::Utf8Value  str(args[0]->ToString());
	const char*		ip = *str;
	int port = args[1]->NumberValue();
	msgQueue::TheQueue().SetEmulator (ip, port);
	return Undefined();
}

Handle<Value> Send(const Arguments& args) {
  HandleScope scope;

	Local<Object> bufferObj    = args[0]->ToObject();
	char*         bufferData   = node::Buffer::Data(bufferObj);
	size_t        bufferLength = node::Buffer::Length(bufferObj); 
	FILE *fpLog = fopen ("log_addon.txt", "a");
	fprintf (fpLog, "add item: buffer[%d] length[%d]\n", (int)bufferData, bufferLength);
	fclose (fpLog);

  msgQueue::TheQueue().AddItem (bufferData, bufferLength);
	fpLog = fopen ("log_addon.txt", "a");
	fprintf (fpLog, "add item: done\n");
	fclose (fpLog);


  return Undefined();
}

void Init(Handle<Object> target) {
  HandleScope scope;
  target->Set(String::New("send"),
      FunctionTemplate::New(Send)->GetFunction());
  target->Set(String::New("set_emulator"),
      FunctionTemplate::New(SetEmulator)->GetFunction());
  target->Set(String::New("get_status"),
      FunctionTemplate::New(GetStatus)->GetFunction());
  target->Set(String::New("send_request"),
      FunctionTemplate::New(SendRequest)->GetFunction());
}

NODE_MODULE(addontest3, Init)

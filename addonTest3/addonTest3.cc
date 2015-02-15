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
  char* data;
  size_t len;
};

//Referring back to the first section you'll see work->req.data = work;. The uv_work_t has a data field where we can store a void pointer. So by creating this loop reference to work we'll be able to get at either later on.

void run_work(uv_work_t* req) {

  //add the item to the queue
//  node::Buffer new_buffer = new node::Buffer(100);
//  new_buffer.data;
//  new_buffer.len = 10;
//  int temp = msgQueue::TheQueue().AddItem (temp);
  js_work* work = static_cast<js_work*>(req->data);
  char* data = new char[SIZE];
  for (int i = 0; i < SIZE; i++)
    data[i] = 97;
  work->data = data;
  work->len = SIZE;
}

void run_callback(uv_work_t* req, int status) {
  HandleScope scope;

  js_work* work = static_cast<js_work*>(req->data);
  char* data = work->data;
  node::Buffer* buf = node::Buffer::New(data, work->len);

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


Handle<Value> Run(const Arguments& args) {
  HandleScope scope;
  assert(args[0]->IsFunction());

  js_work* work = new js_work;
  work->req.data = work;
  work->callback = Persistent<Function>::New(args[0].As<Function>());

  // pretty simple, right?
  uv_queue_work(uv_default_loop(), &work->req, run_work, run_callback);
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
}

NODE_MODULE(addontest3, Init)
